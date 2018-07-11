//
//  ViewController.swift
//  NilNetzwerk
//
//  Created by nilc.nolan@gmail.com on 07/11/2018.
//  Copyright (c) 2018 nilc.nolan@gmail.com. All rights reserved.
//
import NilNetzwerk

import UIKit

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    let testRequest = Request(endpoint: TestFetchEndPoint.testPost(name: "Nil", job: "iOS"))

    testAsyncCall(request: testRequest)

    testSyncCall(request: testRequest)

  }

  func testAsyncCall(request: Request) {
    TestNetworkClient.shared.executeRequest(request: request) { (result: Result<TestPostModel>) in
      switch result {
      case .success(let response):
        print(response)
      case .failure(let error):
        print(error)
      }
    }
  }

  func testSyncCall(request: Request) {
    DispatchQueue.global(qos: .background).async {
      let result: Result<TestPostModel> =  TestNetworkClient.shared.executeRequest(request: request)
      print("TestNetworkClient: \(result.isSuccess)")
      let result2: Result<TestPostModel> =  TestNetworkClient.shared.executeRequest(request: request)
      print("TestNetworkClient: \(result.isSuccess) & \(result2.isSuccess)")
    }

  }
}

