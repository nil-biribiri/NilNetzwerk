import Foundation

public enum NetworkServiceError: Error {
  case receiveErrorFromService(statusCode: Int, displayCode: String,  message: String)
  case unknownError(message: String)
  case urlError
  case noInternetConnection(message: String)
  case parseJSONError(resultType: String, message: String)
  case cannotGetErrorMessage
  case unauthorized
  case connectionTimeout(message: String)
}


public enum ResponseError: Error {
    case BadRequest
    case Unauthorized
    case Forbidden
    case NotFound
    case MethodNotAllowed
    case InternalServerError
    case NotImplemented
    case BadGateway
    case Unknown
}

extension ResponseError {
    public static func error(fromResponse response: HTTPURLResponse) -> ResponseError {
        switch response.statusCode {
        case 400:
            return .BadRequest
        case 401:
            return .Unauthorized
        case 403:
            return .Forbidden
        case 404:
            return .NotFound
        case 405:
            return .MethodNotAllowed
        case 500:
            return .InternalServerError
        case 501:
            return .NotImplemented
        case 502:
            return .BadGateway
        default:
            return .Unknown
        }
    }
}

