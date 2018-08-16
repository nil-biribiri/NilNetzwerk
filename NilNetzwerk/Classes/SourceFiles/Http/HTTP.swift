import Foundation

/// Enumeration representing result from http request.
/// The successfull result can be any type (Response, Image, etc).
public enum Result<T> {
  
  /// When the request was successful.
  case success(Response<T>)
  
  /// When the request failed.
  case failure(Error)
  
  /// Returns `true` if the result is a success, `false` otherwise.
  public var isSuccess: Bool {
    switch self {
    case .success:
      return true
    case .failure:
      return false
    }
  }
  
  /// Returns `true` if the result is a failure, `false` otherwise.
  public var isFailure: Bool {
    return !isSuccess
  }
  
  /// Returns the associated value if the result is a success, `nil` otherwise.
  public var value: Response<T>? {
    switch self {
    case .success(let value):
      return value
    case .failure:
      return nil
    }
  }
  
  /// Returns the associated error value if the result is a failure, `nil` otherwise.
  public var error: Error? {
    switch self {
    case .success:
      return nil
    case .failure(let error):
      return error
    }
  }
  
}

/// Type representing response from the server.
public struct Response<T> {

  /// public initializer
  public init(statusCode: Int,
              body: Data?,
              bodyObject: T,
              responseHeaders: [AnyHashable : Any]?,
              url: URL?) {
      self.statusCode         = statusCode
      self.body               = body
      self.bodyObject         = bodyObject
      self.responseHeaders    = responseHeaders
      self.url                = url
  }

  /// The status code of the response.
  public let statusCode: Int
  
  /// Optional body of the response.
  public let body: Data?
  
  /// Generic body object of the response.
  public let bodyObject: T
  
  // Contains the headers of the response.
  public let responseHeaders: [AnyHashable : Any]?
  
  // The url of the response.
  public let url: URL?
}

/// The protocol that declares methods for http communication. 
/// Note that it currently has only the ones needed for this project.
public protocol HTTP {
  
  /// Executes the provided request and returns enumeration of type Result.
  ///
  /// - Parameter request: The request object containing all required data.
  /// - Returns: The http result containing a repsone object and an error object if the request fails.
  func executeRequest<_Result: Codable>(request: Request) -> Result<_Result>
  
  /// Executes the provided request and returns enumeration of type Result.
  ///
  /// - Parameter request: The request object containing all required data.
  /// - Parameter completionHandler: completion handler with the result of the request.
  func executeRequest<_Result: Codable>(request: Request,
                                        completionHandler: @escaping (Result<_Result>) -> Void)
  
  /// Executes get request with the provided url.
  ///
  /// - Parameter url: The url of the endpoint.
  /// - Returns: The http result containing a repsone object and an error object if the request fails.
  func get<_Result: Codable>(url: URL) -> Result<_Result>
  
  /// Executes get request with the provided url.
  ///
  /// - Parameter url: The url of the endpoint.
  /// - Parameter completionHandler: completion handler with the result of the request.
  func get<_Result: Codable>(url: URL,
                             completionHandler: @escaping (Result<_Result>) -> Void)

}

