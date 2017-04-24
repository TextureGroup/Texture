//
//  AppDelegate.swift
//  ASDKgram-Swift
//
//  Created by Calum Harris on 06/01/2017.
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the /ASDK-Licenses directory of this source tree. An additional
//  grant of patent rights can be found in the PATENTS file in the same directory.
//
//  Modifications to this file made after 4/13/2017 are: Copyright (c) 2017-present,
//  Pinterest, Inc.  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//  FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
//   ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

import UIKit
import AsyncDisplayKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

		// UIKit Home Feed viewController & navController

		let UIKitNavController = UINavigationController(rootViewController: PhotoFeedTableViewController())
		UIKitNavController.tabBarItem.title = "UIKit"

		// ASDK Home Feed viewController & navController

		let ASDKNavController = UINavigationController(rootViewController: PhotoFeedTableNodeController())
		ASDKNavController.tabBarItem.title = "ASDK"

		// UITabBarController

		let tabBarController = UITabBarController()
		tabBarController.viewControllers = [UIKitNavController, ASDKNavController]
		tabBarController.selectedIndex = 1
		tabBarController.tabBar.tintColor = UIColor.mainBarTintColor()

		// Nav Bar appearance

		UINavigationBar.appearance().barTintColor = UIColor.mainBarTintColor()

		// UIWindow

		window = UIWindow()
		window?.backgroundColor = .white
		window?.rootViewController = tabBarController
		window?.makeKeyAndVisible()

		return true
	}

}
