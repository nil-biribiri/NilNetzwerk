//
//  TestNetworkClient.swift
//  NilNetzwerk_Example
//
//  Created by Tanasak.Nge on 11/7/2561 BE.
//  Copyright © 2561 CocoaPods. All rights reserved.
//

import Foundation
import NilNetzwerk

class TestNetworkClient: NilNetzwerk {
  static let shared = TestNetworkClient()

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
