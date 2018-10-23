//
//  AppDelegate.m
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "AppDelegate.h"

#import "ViewController.h"
#import <AsyncDisplayKit/AsyncDisplayKit.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  self.window.backgroundColor = [UIColor whiteColor];
  self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[ViewController alloc] init]];
  [self.window makeKeyAndVisible];
  
  return YES;
}

@end

@implementation ASConfiguration (UserProvided)

+ (ASConfiguration *)textureConfiguration
{
  ASConfiguration *configuration = [ASConfiguration new];
  configuration.experimentalFeatures = ASExperimentalTextNode; 
  return configuration;
  
}

@end
