//
//  TestEndPoint.swift
//  NilNetzwerk_Example
//
//  Created by Tanasak.Nge on 11/7/2561 BE.
//  Copyright © 2561 CocoaPods. All rights reserved.
//

import Foundation
import NilNetzwerk

struct TestRequestGenerator: RequestGenerator {
  func generateRequest(withMethod method: HTTPMethod) -> MutableRequest {
    return request(withMethod: method) |> withJsonSupport
  }
}

enum TestFetchEndPoint {
  case testPost(name: String, job: String)
}

extension TestFetchEndPoint: ServiceEndpoint {

  var requestGenerator: RequestGenerator {
    return TestRequestGenerator()
  }

  var parameters: Codable?{
    switch self {
    case .testPost(let name, let job):
      return TestPostModel(name: name, job: job)
    }
  }

  var baseURL: URL {
    switch self {
    case .testPost:
      return URL(string: "https://reqres.in/api")!
    }
  }

  var method: HTTPMethod {
    switch self {
    case .testPost:
      return .POST
    }
  }

  var path: String {
    switch self {
    case .testPost:
      return "/users"
    }
  }

  var queryParameters: [String : String]? {
    switch self {
    case .testPost:
      return nil
    }
  }
}
