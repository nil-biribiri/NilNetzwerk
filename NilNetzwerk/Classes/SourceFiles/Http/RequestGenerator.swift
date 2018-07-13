import Foundation

/// Protocol defining methods for customising the request (mostly by manipulating the headers).
///
/// The methods can be piped and return mutable requests which are then used in the init method of
/// the request to create constant values of it.
/// Can be extended with other methods as needed.
public protocol RequestGenerator {

  /// Creates a default request.
  ///
  /// - Parameter method: The method how the request should be done.
  /// - Returns: A mutable request which can be changed afterwards.
  func request(withMethod method: HTTPMethod) -> MutableRequest

  /// Creates a request with basic auth.
  ///
  /// - Parameter request: An existing request which will be edited.
  /// - Returns: The given request with the extended basic authentication
  func withBasicAuth(request: MutableRequest) -> MutableRequest

  /// Creates a request with json support.
  ///
  /// - Parameter request: An existing request which will be edited.
  /// - Returns: The given request with the extended json support.
  func withJsonSupport(request: MutableRequest) -> MutableRequest

  /// Generates the request. This is the place where it's decided which methods will be used to
  /// customise the request.
  ///
  /// - Parameter method: The method of the http request.
  /// - Returns: A mutable request which can be changed afterwards.
  func generateRequest(withMethod method: HTTPMethod) -> MutableRequest


  /// Auth username using for basic authen.
  var authUserName: String? { get }

  /// Auth password using for basic authen.
  var authPassword: String? { get }

}

/// Default implementation of the RequestGenerator.
public extension RequestGenerator {

  public func request(withMethod method: HTTPMethod) -> MutableRequest {
    return MutableRequest(method: method)
  }

  public func withBasicAuth(request: MutableRequest) -> MutableRequest {
    var request = request

    if let username = authUserName, let password = authPassword {
      let authorizationString = "\(username):\(password)"
      if let authorizationData = authorizationString.data(using: String.Encoding.utf8) {
        let base64Data =
          authorizationData.base64EncodedString()
        let authorization = "\(Constants.BasicAuth) \(base64Data)"
        let authorizationHeader = [Constants.Authorization : authorization]
        request.updateHTTPHeaderFields(headerFields: authorizationHeader)
        request.updateHTTPHeaderFields(headerFields: [Constants.ContentType : Constants.XWwwForm])
      }
    }
    return request
  }

  public func withJsonSupport(request: MutableRequest) -> MutableRequest {
    var request = request
    let jsonHeader = [Constants.Accept : Constants.JSONHeader]
    let jsonContentType = [Constants.ContentType : Constants.JSONHeader]
    request.updateHTTPHeaderFields(headerFields: jsonHeader)
    request.updateHTTPHeaderFields(headerFields: jsonContentType)
    return request
  }

  public func generateRequest(withMethod method: HTTPMethod) -> MutableRequest {
    return request(withMethod: method) |> withJsonSupport
  }

  var authUserName: String? {
    return nil
  }

  var authPassword: String? {
    return nil
  }

}

struct StandardRequestGenerator: RequestGenerator {}
