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

  ### Making simple get request
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

## Author

Nil-Biribiri, nilc.nolan@gmail.com

## License

NilNetzwerk is available under the MIT license. See the LICENSE file for more info.
