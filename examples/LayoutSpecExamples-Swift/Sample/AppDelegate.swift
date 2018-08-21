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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    let window = UIWindow(frame: UIScreen.main.bounds)
    window.backgroundColor = UIColor.white
    window.rootViewController = UINavigationController(rootViewController: OverviewViewController())
    window.makeKeyAndVisible()
    self.window = window

    UINavigationBar.appearance().barTintColor = UIColor(red: 47/255.0, green: 184/255.0, blue: 253/255.0, alpha: 1.0)
    UINavigationBar.appearance().tintColor = .white
    UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]

    return true
  }

}
