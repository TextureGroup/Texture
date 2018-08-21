//
//  AppDelegate.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "AppDelegate.h"

#import "AsyncTableViewController.h"
#import "AsyncViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  self.window.backgroundColor = [UIColor whiteColor];
  
  UITabBarController *tabBarController = [[UITabBarController alloc] initWithNibName:nil bundle:nil];
  self.window.rootViewController = tabBarController;
  
  [tabBarController setViewControllers:@[[[AsyncTableViewController alloc] init], [[AsyncViewController alloc] init]]];
  
  [self.window makeKeyAndVisible];
  return YES;
}

@end
