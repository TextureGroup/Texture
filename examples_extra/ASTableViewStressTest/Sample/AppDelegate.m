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

#import "ViewController.h"

#import <AsyncDisplayKit/ASDisplayNode.h>
#import <AsyncDisplayKit/ASDisplayNode+Beta.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  self.window.backgroundColor = [UIColor whiteColor];
  self.window.rootViewController = [[UINavigationController alloc] init];
  
  [self pushNewViewControllerAnimated:NO];
  
  [self.window makeKeyAndVisible];
  
  return YES;
}

- (void)pushNewViewControllerAnimated:(BOOL)animated
{
  UINavigationController *navController = (UINavigationController *)self.window.rootViewController;
  
  UIViewController *viewController = [[ViewController alloc] init];
  viewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Push Another Copy" style:UIBarButtonItemStylePlain target:self action:@selector(pushNewViewController)];
  
  [navController pushViewController:viewController animated:animated];
}

- (void)pushNewViewController
{
  [self pushNewViewControllerAnimated:YES];
}

@end
