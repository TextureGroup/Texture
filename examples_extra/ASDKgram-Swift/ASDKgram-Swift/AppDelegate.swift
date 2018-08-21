//
//  AppDelegate.swift
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
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
		tabBarController.tabBar.tintColor = UIColor.mainBarTintColor

		// Nav Bar appearance

		UINavigationBar.appearance().barTintColor = UIColor.mainBarTintColor

		// UIWindow

		window = UIWindow()
		window?.backgroundColor = .white
		window?.rootViewController = tabBarController
		window?.makeKeyAndVisible()

		return true
	}

}
