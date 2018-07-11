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
  override class var shared: TestNetworkClient{
    return TestNetworkClient()
  }

  override init() {
    super.init()
    enableLog = true
  }

}
