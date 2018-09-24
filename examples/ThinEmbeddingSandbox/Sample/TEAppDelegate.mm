//
//  TEAppDelegate.m
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "TEAppDelegate.h"

#import "TECollectionViewController.h"
#import "TETableViewController.h"

@implementation TEAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  // Appearance bits.
  UINavigationBar.appearance.barStyle = UIBarStyleBlack;
  UITabBar.appearance.barStyle = UIBarStyleBlack;
  UITableView.appearance.backgroundColor = UIColor.blackColor;
  
  // Root VC.
  UITabBarController *tabCtrl = [[UITabBarController alloc] init];
  UINavigationController *cNav = [[UINavigationController alloc] initWithRootViewController:[TECollectionViewController new]];
  cNav.tabBarItem.title = @"Collection";
  UINavigationController *tNav = [[UINavigationController alloc] initWithRootViewController:[TETableViewController new]];
  tNav.tabBarItem.title = @"Table";
  tabCtrl.viewControllers = @[ cNav, tNav ];
  
  // Window.
  _window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
  _window.tintColor = UIColor.orangeColor;
  _window.rootViewController = tabCtrl;
  [_window makeKeyAndVisible];
  
  return YES;
}

@end
