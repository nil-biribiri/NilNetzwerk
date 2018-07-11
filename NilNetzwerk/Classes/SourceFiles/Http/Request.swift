import Foundation

/// Enum for the different types of http methods.
public enum HTTPMethod: String {
  case GET
  case POST
  case PUT
  case HEAD
  case DELETE
  case PATCH
  case TRACE
  case OPTIONS
  case CONNECT
}

/// The Request type which the HTTP protocol expects.
///
/// All of its properties are immutable. 
/// Different init methods are provided, with or without the ServiceEndpoint and RequestGenerator.
public struct Request: Equatable {
  fileprivate(set) var url: URL
  fileprivate(set) var method: HTTPMethod
  fileprivate(set) var parameters: Any?
  fileprivate(set) var headerFields: [String: String] = [:]
  fileprivate(set) var body: Data? = nil

  public static func ==(l: Request, r: Request) -> Bool {
    return l.url.absoluteString == r.url.absoluteString
      && l.body == r.body
      && l.headerFields == r.headerFields
      && l.method == r.method
  }

  /// Initialize with a given service endpoint.
  ///
  /// It is the caller's responsibility to ensure that the values represent valid `ServiceEndpoint` values, if that is what is desired.
  public init(endpoint: ServiceEndpoint) {
    var mutableRequest = endpoint.requestGenerator.generateRequest(withMethod: endpoint.method)
    mutableRequest.updateParameters(parameters: endpoint.parameters)
    mutableRequest.updateQueryParameters(parameters: endpoint.queryParameters)
    mutableRequest.updateHTTPHeaderFields(headerFields: endpoint.headerParameters)
    let path = endpoint.baseURL.appendingPathComponent(endpoint.path)

    self.url = path
    self.method = endpoint.method
    self.parameters = mutableRequest.parameters

    buildURLRequest(mutableRequest: mutableRequest,
                    requestUrl: path)

    updateURLEncode(mutableRequest: &mutableRequest)
  }

  public init(url: URL,
              method: HTTPMethod,
              parameters: Codable? = nil,
              queryParameters: [String: String]? = [:],
              headerParameters: [String: String]? = [:],
              requestGenerator: RequestGenerator) {
    var mutableRequest = requestGenerator.generateRequest(withMethod: method)
    mutableRequest.updateParameters(parameters: parameters)
    mutableRequest.updateQueryParameters(parameters: queryParameters)
    mutableRequest.updateHTTPHeaderFields(headerFields: headerParameters)

    self.url = url
    self.method = method
    self.parameters = mutableRequest.parameters

    buildURLRequest(mutableRequest: mutableRequest,
                    requestUrl: url)

    updateURLEncode(mutableRequest: &mutableRequest)
  }

  public init(url: URL, method: HTTPMethod = .GET, queryParameters: [String: String] = [:]) {
    let requestGenerator = StandardRequestGenerator()
    self.init(url: url,
              method: method,
              queryParameters: queryParameters,
              requestGenerator: requestGenerator)
  }

  public mutating func updateHTTPHeaderFields(headerFields: [String: String]) {
    self.headerFields += headerFields
  }

}

fileprivate extension Request {

  mutating func buildURLRequest(mutableRequest: MutableRequest,
                                        requestUrl: URL) {
    if method == .GET && mutableRequest.queryString != nil {
      if let queryString = requestUrl.appendQueryString(queryString: mutableRequest.queryString!) {
        self.url = queryString
      } else {
        self.url = requestUrl
      }
    } else {
      self.url = requestUrl
    }

  }

  mutating func updateURLEncode(mutableRequest: inout MutableRequest) {
    if mutableRequest.parameters != nil && mutableRequest.method != .GET {
      if mutableRequest.headerFields[Constants.ContentType]?.contains(Constants.XWwwForm) ?? false {
        if let params = mutableRequest.parameters as? [String: Any] {
          mutableRequest.parameters = params.urlEncodedQueryStringWithEncoding()
        }
      }
      mutableRequest.createJsonBodyFromParameters()
      self.body = mutableRequest.body
    } else {
      self.body = nil
    }
    self.headerFields = mutableRequest.headerFields
  }

}

/// Mutable structure used only in the creation of the request.
/// This type is sent through the pipes, where they append some customisation to the request.
public struct MutableRequest : RequestGenerator {

  var method: HTTPMethod
  var parameters: Any?
  var headerFields: [String: String]
  var body: Data?
  var queryString: String?

  init(method: HTTPMethod) {
    self.method = method
    self.headerFields = [:]
    self.parameters = [:]
  }

  public func httpMethod() -> HTTPMethod {
    return self.method
  }

  public mutating func updateParameters(parameters: Codable?) {
    self.parameters = parameters?.toDictionary
    if let param = parameters?.jsonData {
      self.body = param
    }
  }

  public mutating func updateQueryParameters(parameters: Any?) {
    if let params = parameters as? [String: AnyObject] {
      self.queryString =
        params.urlEncodedQueryStringWithEncoding()
    }
  }

  public mutating func updateHTTPHeaderFields(headerFields: [String: String]?) {
    if let headerFields = headerFields {
      self.headerFields += headerFields
    }
  }

  public mutating func createJsonBodyFromParameters() {
    do {
      if let dictionary = self.parameters as? [String : Any] {
        self.body = try JSONSerialization.data(withJSONObject: dictionary,
                                               options: .prettyPrinted)
      } else if let encodableObject = self.parameters as? Serializable {
        self.body = encodableObject.toData()
      } else if let array = self.parameters as? [Any] {
        self.body = try JSONSerialization.data(withJSONObject: array,
                                               options: .prettyPrinted)
      } else if let string = self.parameters as? String {
        self.body = string.data(using: .utf8, allowLossyConversion: true)!
      }

    } catch {
      Logger.log(message: "Error creating body from parameters.", event: .e)
    }
  }

}

extension Encodable {
  var toDictionary: [String: Any]? {
    guard let data = try? JSONEncoder().encode(self) else { return nil }
    return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] }
  }

  var jsonData: Data? {
    let encoder = JSONEncoder()
    encoder.outputFormatting  = .prettyPrinted
    do {
      return try encoder.encode(self)
    } catch {
      print(error.localizedDescription)
      return nil
    }
  }
}
