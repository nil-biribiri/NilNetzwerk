import Foundation

class NetworkBaseService: NSObject {
  static func transformServiceResponse<T>(_ original: Result<T>) -> Result<T> {
    switch original {
      
    case .success(let value):
      return .success(value)
      
    case .failure(let error):
      switch error {
        
      case NetworkServiceError.receiveErrorFromService(let errorCode, let displayCode, let message):
        return .failure(NetworkErrorResponse(message: message,
                                             code: errorCode,
                                             displayCode: displayCode))
        
      case NetworkServiceError.urlError:
        return .failure(NetworkErrorResponse(message: "Invalid URL request."))
        
      case NetworkServiceError.noInternetConnection(let message):
        return .failure(NetworkErrorResponse(message: message,
                                             code: 10000,
                                             displayCode: "APP10000"))
        
      case NetworkServiceError.cannotGetErrorMessage:
        return .failure(NetworkErrorResponse(message: "Unknown Error.",
                                             code: 10001,
                                             displayCode: "APP10001"))
        
      case NetworkServiceError.parseJSONError(let resultType, let errorMessage):
        return .failure(NetworkErrorResponse(message: "ParseJSON \(resultType) Error: \(errorMessage).",
          code: 10002,
          displayCode: "APP10002"))

      case NetworkServiceError.connectionTimeout(let message):
        return .failure(NetworkErrorResponse(message: message,
                                             code: 10003,
                                             displayCode: "APP10003"))
        
      case NetworkServiceError.unknownError(let message):
        return .failure(NetworkErrorResponse(message: message,
                                             code: 10004,
                                             displayCode: "APP10004"))
        
      default:
        return .failure(NetworkErrorResponse())
      }
    }
  }
}

public struct NetworkErrorResponse: Error {
  let code: Int?
  let displayCode: String?
  let message: String
  init(message: String = "Error", code: Int? = nil, displayCode: String? = nil) {
    self.message = message
    self.code = code
    self.displayCode = displayCode
  }
}

extension NetworkErrorResponse: LocalizedError {
  public var errorDescription: String? {
    return self.message
  }
}

public extension Error {
  var errorObject: NetworkErrorResponse {
    return self as? NetworkErrorResponse ?? NetworkErrorResponse()
  }
}
