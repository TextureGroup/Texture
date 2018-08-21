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
#import "WindowWithStatusBarUnderlay.h"
#import "Utilities.h"
#import "VideoFeedNodeController.h"


@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  // this UIWindow subclass is neccessary to make the status bar opaque
  _window                  = [[WindowWithStatusBarUnderlay alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  _window.backgroundColor  = [UIColor whiteColor];


  VideoFeedNodeController *asdkHomeFeedVC      = [[VideoFeedNodeController alloc] init];
  UINavigationController *asdkHomeFeedNavCtrl  = [[UINavigationController alloc] initWithRootViewController:asdkHomeFeedVC];


  _window.rootViewController = asdkHomeFeedNavCtrl;
  [_window makeKeyAndVisible];

  // Nav Bar appearance
  NSDictionary *attributes = @{NSForegroundColorAttributeName:[UIColor whiteColor]};
  [[UINavigationBar appearance] setTitleTextAttributes:attributes];
  [[UINavigationBar appearance] setBarTintColor:[UIColor lighOrangeColor]];
  [[UINavigationBar appearance] setTranslucent:NO];

  [application setStatusBarStyle:UIStatusBarStyleLightContent];


  return YES;
}
@end
