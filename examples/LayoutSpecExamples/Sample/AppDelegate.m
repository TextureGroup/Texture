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
#import "OverviewViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  self.window.backgroundColor = [UIColor whiteColor];
  self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[OverviewViewController new]];
  [self.window makeKeyAndVisible];
  
  [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:47/255.0 green:184/255.0 blue:253/255.0 alpha:1.0]];
  [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
  [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]}];;
  
  return YES;
}

@end
