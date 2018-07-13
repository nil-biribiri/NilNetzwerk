# NilNetzwerk

[![CI Status](https://img.shields.io/travis/nilc.nolan@gmail.com/NilNetzwerk.svg?style=flat)](https://travis-ci.org/nilc.nolan@gmail.com/NilNetzwerk)
[![Version](https://img.shields.io/cocoapods/v/NilNetzwerk.svg?style=flat)](https://cocoapods.org/pods/NilNetzwerk)
[![License](https://img.shields.io/cocoapods/l/NilNetzwerk.svg?style=flat)](https://cocoapods.org/pods/NilNetzwerk)
[![Platform](https://img.shields.io/cocoapods/p/NilNetzwerk.svg?style=flat)](https://cocoapods.org/pods/NilNetzwerk)

A super-lightweight network client library. Heavily inspired by Moya, Alamofire.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

 - iOS 9.3+
 - Xcode 8.3+
 - Swift 3.2+

## Installation

NilNetzwerk is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'NilNetzwerk'
```

## Usage 

<details><summary>Create request.</summary>
<p>
 
  [Create a request](#create-a-request)
  
  [Create custom RequestGenerator](#create-custom-requestgenerator)
  
</p>
</details>
<p></p>

<details><summary>Execute request</summary>
<p>
 
  [Making a simple get request](#making-a-simple-get-request)
 
  [Making asynchronous request](#making-asynchronous-request)
  
  [Making synchronous request](#making-synchronous-request) 
  
</p>
</details>
<p></p>

<details><summary>Advance usage</summary>
<p>
 
  [Create custom NetworkClient](#create-custom-networkclient)

  [Adapter (intercept before execute request)](#adapter)
 
  [Handle unauthorized (getting called if host return 401)](#handle-unauthorized)
    
</p>
</details>

  ### Making a simple get request
  
```swift
import NilNetzwerk

NilNetzwerk.shared.get(url: URL(string: "https://httpbin.org/get")!) { (result: Result<SimpleModel>) in
      switch result {
      case .success(let response):
        print(response)
      case .failure(let error):
        print(error)
      }
    }

struct SimpleModel: Codable {}
```

  ### Create a request 
  
You can create a request by implementing "ServiceEndpoint" protocol with any type (enum, struct, class).
(enum is recommended)

```swift
import NilNetzwerk

// An instance of the request generator which prepares the HTTP request.
struct TestRequestGenerator: RequestGenerator {
  func generateRequest(withMethod method: HTTPMethod) -> MutableRequest {
    return request(withMethod: method) |> withJsonSupport
  }
}

// Endpoints that you want to use.
enum TestFetchEndPoint {
  case testPost(name: String, job: String)
}

// Implementing ServiceEndpoint protocol
extension TestFetchEndPoint: ServiceEndpoint {

  // An instance of the request generator which prepares the HTTP request.
  var requestGenerator: RequestGenerator {
    return TestRequestGenerator()
  }

  // The parameters of the endpoint.
  var parameters: Codable? {
    switch self {
    case .testPost(let name, let job):
      return TestPostModel(name: name, job: job)
    }
  }

  // The base url for the endpoint.
  var baseURL: URL {
    switch self {
    case .testPost:
      return URL(string: "https://reqres.in/api")!
    }
  }

  // The required method.
  var method: HTTPMethod {
    switch self {
    case .testPost:
      return .POST
    }
  }

  // The specific path of the endpoint.
  var path: String {
    switch self {
    case .testPost:
      return "/users"
    }
  }

  // The query parameters which are added to the url.
  var queryParameters: [String : String]? {
    switch self {
    case .testPost:
      return nil
    }
  }
  
  // The parameters which are added to the header.
  var headerParameters: [String : String]? {
    switch self {
    case .testPost:
      return nil
    }
  }
  
}

struct TestPostModel: Codable {
  let name: String
  let job: String
}
```

  ### Create custom RequestGenerator
  
You can create custom RequestGenerator by implementing RequestGenerator protocol.
(Json support, Basic auth)

```swift 
struct TestRequestGenerator: RequestGenerator {

  func generateRequest(withMethod method: HTTPMethod) -> MutableRequest {
    return request(withMethod: method) |> withJsonSupport |> withBasicAuth
  }
  
  var authUserName: String? {
    return "Auth UserName"
  }
  
  var authPassword: String? {
    return "Auth Password"
  }
 
}
```

  ### Making asynchronous request 

```swift
import NilNetzwerk

let testRequest = Request(endpoint: TestFetchEndPoint.testPost(name: "Nil", job: "iOS"))
NilNetzwerk.shared.executeRequest(request: testRequest) { (result: Result<TestPostModel>) in
      switch result {
      case .success(let response):
        print(response)
      case .failure(let error):
        print(error)
      }
    }
```

  ### Making synchronous request 

```swift
import NilNetzwerk

let testRequest = Request(endpoint: TestFetchEndPoint.testPost(name: "Nil", job: "iOS"))
let result: Result<TestPostModel> = NilNetzwerk.shared.executeRequest(request: testRequest)
switch result {
case .success(let response):
  print(response)
case .failure(let error):
  print(error)
``` 

  ### Create custom NetworkClient
  
You can use default network client by calling "NilNetzwerk.shared". However, if you want to create custom network client you can extend "NilNetzwerk" class then implement your own network client.

```swift
import NilNetzwerk

class TestNetworkClient: NilNetzwerk {

  override class var shared: TestNetworkClient{
    return TestNetworkClient()
  }

  private let urlSession: URLSession = {
    let configuration                           = URLSessionConfiguration.default
    configuration.requestCachePolicy            = .reloadIgnoringLocalAndRemoteCacheData
    configuration.timeoutIntervalForRequest     = 30
    configuration.urlCache                      = nil
    return URLSession(configuration: configuration)
  }()

  override init() {
    super.init(urlSession: urlSession)
    enableLog = true
  }

}
```

  #### Adapter 

Intercept method before execute request.

```swift
import NilNetzwerk

class CustomNetworkClient: NilNetzwerk {

  // intercept method 
  override func adapter(request: inout Request) {
    
  }

}
``` 

  #### Handle Unauthorized 

Every request that return 401 (unauthorized) will be enqueue to property "requestsToRetry" then this method will be executed.

```swift
import NilNetzwerk

class CustomNetworkClient: NilNetzwerk {

  // Handle unauthorized method 
  override func handleUnauthorized(request: Request, completion: @escaping (Bool) -> Result<Error>?) {
    // You can implement request, refresh token method here
    
    // This is a queue of unauthorized request, you can dequeue and execute request again.
    let allRequestsToRetry = self.requestsToRetry
  }

}
``` 

## Author

Nil-Biribiri, nilc.nolan@gmail.com

## License

NilNetzwerk is available under the MIT license. See the LICENSE file for more info.
