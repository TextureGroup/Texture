//
//  AsyncDisplayKitUITests.swift
//  AsyncDisplayKitUITests
//
//  Created by Zev Eisenberg on 1/27/21.
//  Copyright © 2021 Pinterest. All rights reserved.
//

import XCTest

class AsyncDisplayKitUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    func testWebViewAccessibility() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

      XCTAssert(app.staticTexts["Texture is Awesome!"].exists)
      XCTAssert(app.staticTexts["Especially when web views inside nodes are accessible."].exists)
  }
}
