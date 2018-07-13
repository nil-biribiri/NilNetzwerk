import Foundation

public protocol HTTPClientProtocol {

  /// Adapter method that run before execute any request.
  ///
  /// - Parameter request: The given url request.
  func adapter(request: inout Request)

  /// Handle method that run if request is unauthorized.
  ///
  /// - Parameter request: The given url request.
  /// - Parameter: completion that tell refresh token status.
  func handleUnauthorized(request: Request, completion: @escaping (Bool) -> Result<Error>?)

  /// Get error message from payload.
  ///
  /// - Parameter json: data response in json format.
  /// - Returns: touple of statusCode and statusMessage.
  func getErrorFromPayload(json: [String:AnyObject]??) -> (statusCode: String?, statusMessage: String?)?

  /// Set network logger.
  var enableLog: Bool {get set}
}

/// NSURLSession implementation of the HTTP protocol.
///
/// The requests are done synchronously. The logic behind the sync requests is that we can easily
/// plug in RX extensions or promises to this implementation.
/// If you want to use it directly (without RX extensions or promises), you should do it in a
/// background thread.
///
/// You can also use async requests with completion handler.
open class NilNetzwerk: HTTPClientProtocol{

  /// Singleton object of NilNetzwerk class.
  open class var shared: NilNetzwerk {
    return NilNetzwerk()
  }
  /// Queue of unauthorized request.
  public var requestsToRetry: Queue<() -> Void> = Queue()
  public var enableLog: Bool = true

  fileprivate let urlSession: URLSession
  fileprivate(set) var requestsPool: [Request] = [Request]()

  /// Init method with possibility to customise the NSURLSession used for the requests.
  public init(urlSession: URLSession) {
    self.urlSession = urlSession
  }

  /// Init method that creates default NSURLSession with no cache.
  public init() {
    let configuration                           = URLSessionConfiguration.default
    configuration.requestCachePolicy            = .reloadIgnoringLocalAndRemoteCacheData
    configuration.urlCache                      = nil

    self.urlSession = URLSession(configuration: configuration,
                                 delegate: nil,
                                 delegateQueue: nil)
  }

  open func adapter(request: inout Request) {}

  open func handleUnauthorized(request: Request, completion: @escaping (Bool) -> Result<Error>?) {}

  open func getErrorFromPayload(json: [String:AnyObject]??) -> (statusCode: String?, statusMessage: String?)? {
    guard let serializeJSON = json, let convertedJSON = serializeJSON else {
      return nil
    }
    if let statusCode = convertedJSON["status_code"],
      let statusMessage = convertedJSON["status_message"] {
      return (statusCode: statusCode as? String, statusMessage: statusMessage as? String)
    }

    if let errorArr = convertedJSON["errors"],
      let errorStatus = (errorArr as? [String])?.first {
      return (nil, statusMessage: errorStatus)
    }
    return nil
  }

}

// MARK: - HTTP protocol
extension NilNetzwerk: HTTP {

  enum ParseResult<_Result: Codable> {
    case success(_Result)
    case error(Error)
  }

  public func executeRequest<_Result: Codable>(request: Request) -> Result<_Result> {
    var result: Result<_Result> = Result.failure(NetworkServiceError.cannotGetErrorMessage)
    var mutableRequest = request

    adapter(request: &mutableRequest)
    let urlRequest: URLRequest = URLRequest(request: mutableRequest)
    requestsPool.append(mutableRequest)
    enableLog ? Logger.log(message: "Request: \(mutableRequest)", event: .d) : nil

    urlSession.sendSynchronousRequest(request: urlRequest) { [unowned self]
      data, urlResponse, error in
      self.removeFromPool(request: request)
      if let checkedResult: Result<_Result> = self.handleResponse(withData: data,
                                                                  urlResponse: urlResponse,
                                                                  error: error,
                                                                  request: request) {
        result = checkedResult
      }
    }
    return NetworkBaseService.transformServiceResponse(result)
  }

  public func get<_Result: Codable>(url: URL) -> Result<_Result> {
    let request = Request(url: url)
    return self.executeRequest(request: request)
  }

  public func executeRequest<_Result: Codable>(request: Request,
                                               completionHandler: @escaping (Result<_Result>) -> Void) {
    var mutableRequest = request

    adapter(request: &mutableRequest)
    let urlRequest: URLRequest = URLRequest(request: mutableRequest)
    requestsPool.append(mutableRequest)
    enableLog ? Logger.log(message: "Request: \(mutableRequest)", event: .d) : nil

    urlSession.dataTask(with: urlRequest) { (data, urlResponse, error) in
      self.removeFromPool(request: request)
      let result: Result<_Result>? = self.handleResponse(withData: data,
                                                         urlResponse: urlResponse,
                                                         error: error,
                                                         request: request,
                                                         completion: completionHandler)
      DispatchQueue.main.async {
        if let result = result {
          completionHandler(NetworkBaseService.transformServiceResponse(result))
        }
      }
      }.resume()
  }

  public func get<_Result: Codable>(url: URL,
                                    completionHandler: @escaping (Result<_Result>) -> Void) {
    let request = Request(url: url)
    return self.executeRequest(request: request, completionHandler: completionHandler)
  }

  private func removeFromPool(request: Request) {
    if let index = self.requestsPool.index(of: request)  {
      self.requestsPool.remove(at: index)
    }
  }

  private func handleResponse<_Result: Codable>(withData data: Data?,
                                                urlResponse: URLResponse?,
                                                error: Error?,
                                                request: Request,
                                                completion: ((Result<_Result>) -> Void)? = nil) -> Result<_Result>? {
    if let data = data,
      let json  = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject],
      let logJson = json {
      enableLog ? Logger.log(message: "Response: \(logJson.prettyPrint())", event: .d) : nil
    }
    if let error = error {
      let errorCode = (error as NSError).code
      switch errorCode {
      case -1001:
        return Result.failure(NetworkServiceError.connectionTimeout(message: error.localizedDescription))
      case -1009:
        return Result.failure(NetworkServiceError.noInternetConnection(message: error.localizedDescription))
      default:
        return Result.failure(NetworkServiceError.unknownError(message: error.localizedDescription))
      }
    }
    if let httpResponse = urlResponse as? HTTPURLResponse {
      switch httpResponse.statusCode {
      case 200..<300:
        let bodyObject: ParseResult<_Result> = self.parseBody(data: data)
        switch bodyObject {
        case .success(let bodyObject):
          let response: Response<_Result> = Response(statusCode: httpResponse.statusCode,
                                                     body: data as Data?,
                                                     bodyObject: bodyObject,
                                                     responseHeaders: httpResponse.allHeaderFields,
                                                     url: httpResponse.url)
          return Result.success(response)
        case .error(let error):
          return Result.failure(error)
        }
      case 401:
        if let completionHandler = completion {
          requestsToRetry.enqueue {
            self.executeRequest(request: request, completionHandler: completionHandler)
          }
        } else {
          requestsToRetry.enqueue {
            let _: Result<_Result> = self.executeRequest(request: request)
          }
        }
        handleUnauthorized(request: request) { isSuccess -> Result<Error>? in
          if !isSuccess {
            return Result.failure(NetworkServiceError.cannotGetErrorMessage)
          } else {
            return nil
          }
        }
        return nil
      default:
        let responseError = parseError(data: data, statusCode: httpResponse.statusCode)
        return Result.failure(responseError)
      }
    }
    return Result.failure(NetworkServiceError.cannotGetErrorMessage)
  }
  
  /// Parses the response body data.
  ///
  /// - Parameter data: The data object which should be parsed.
  /// - Returns: The expected generic Object, nil when the data cannot be parsed.
  private func parseBody<_Result: Codable>(data: Data?) -> ParseResult<_Result> {
    do {
      // Decode result to object
      let jsonDecoder = JSONDecoder()
      if let data = data {
        let result  = try jsonDecoder.decode(_Result.self, from: data)
        return ParseResult.success(result)
      } else {
        return ParseResult.error(NetworkServiceError.cannotGetErrorMessage)
      }
    } catch let error {
      // parseJSON Error
      let decodingError = error as? DecodingError
      return ParseResult.error(NetworkServiceError.parseJSONError(resultType: String(describing: _Result.self), message: decodingError.debugDescription))
    }
  }

  private func parseError(data: Data?, statusCode: Int) -> Error {
    let errorMessage = "Unknown Error."
    if let data  = data {
      let logJson  = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject]
      if let errorMessageFromPayload = getErrorFromPayload(json: logJson){
        // Error message found in payload
        let displayCode = (errorMessageFromPayload.statusCode ?? String(statusCode))
        let message     = (errorMessageFromPayload.statusMessage ?? errorMessage)
        return NetworkServiceError.receiveErrorFromService(statusCode: statusCode,
                                                           displayCode: displayCode,
                                                           message: message)
      }
    }
    return NetworkServiceError.cannotGetErrorMessage
  }

}

/// Extension of the NSURLSession that blocks the data task with semaphore, so we can perform
/// a sync request.
extension URLSession {
  func sendSynchronousRequest(
    request: URLRequest,
    completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
    let semaphore = DispatchSemaphore(value: 0)
    let task = self.dataTask(with: request) { data, response, error in
      completionHandler(data, response, error)
      semaphore.signal()
    }

    task.resume()
    semaphore.wait()
  }
}

/// Adapting our definition of the Request to the one from the iOS SDK.
extension URLRequest {

  public init(request: Request) {
    self.init(url: request.url as URL)
    self.httpMethod = request.method.rawValue
    self.allHTTPHeaderFields = request.headerFields
    self.httpBody = request.body as Data?
  }

  func matches(request: Request) -> Bool {
    return self.url!.absoluteString == request.url.absoluteString
      && self.httpMethod! == request.method.rawValue
      && self.allHTTPHeaderFields! == request.headerFields
      && self.httpBody == request.body
  }
}
