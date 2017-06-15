//
//  TDDebugger.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASAvailability.h>

#if AS_TEXTURE_DEBUGGER

#import <AsyncDisplayKit/TDDebugger.h>
#import <AsyncDisplayKit/TDElementDomainController.h>

@implementation TDDebugger

+ (TDDebugger *)defaultInstance
{
  static dispatch_once_t onceToken;
  static TDDebugger *defaultInstance = nil;
  dispatch_once(&onceToken, ^{
    defaultInstance = [[[self class] alloc] init];
  });
  
  return defaultInstance;
}

- (void)enableLayoutElementDebuggingWithApplication:(UIApplication *)application
{
  TDElementDomainController *elementController = [TDElementDomainController defaultInstance];
  [self addController:elementController];
  [elementController startMonitoringWithApplication:application];
}

@end

#endif // AS_TEXTURE_DEBUGGER
