//
//  ASConfigurationManager.m
//  Texture
//
//  Copyright (c) 2018-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASConfigurationManager.h"
#import <AsyncDisplayKit/ASConfiguration.h>
#import <AsyncDisplayKit/ASConfigurationDelegate.h>
#import <stdatomic.h>

@interface ASConfiguration () {
@package
  ASExperimentalFeatureSet _experimentalFeatures;
  id<ASConfigurationDelegate> _delegate;
}
@end

@interface ASConfigurationManager () {
  _Atomic(ASExperimentalFeatureSet) _activatedExperiments;
}
@property (nonatomic, readonly) dispatch_queue_t delegateQueue;
@property (nonatomic, readonly) ASConfiguration *config;
@end

@implementation ASConfigurationManager

+ (__unsafe_unretained ASConfigurationManager *)sharedInstance
{
  static ASConfigurationManager *inst;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    inst = [[ASConfigurationManager alloc] init];
  });
  return inst;
}

- (instancetype)init
{
  if (self = [super init]) {
    _delegateQueue = dispatch_queue_create("org.TextureGroup.Texture.ConfigNotifyQueue", DISPATCH_QUEUE_SERIAL);
    if ([ASConfiguration respondsToSelector:@selector(textureConfiguration)]) {
      _config = [[ASConfiguration textureConfiguration] copy];
    }
  }
  return self;
}

- (BOOL)activateExperimentalFeature:(ASExperimentalFeatureSet)requested
{
  if (_config == nil) {
    return NO;
  }
  
  NSAssert(__builtin_popcount(requested) == 1, @"Cannot activate multiple features at once with this method.");
  
  // If they're disabled, ignore them.
  ASExperimentalFeatureSet enabled = requested & _config->_experimentalFeatures;
  ASExperimentalFeatureSet prevTriggered = atomic_fetch_or(&_activatedExperiments, enabled);
  ASExperimentalFeatureSet newlyTriggered = enabled & ~prevTriggered;
  
  // Notify delegate if needed.
  if (newlyTriggered != 0) {
    id<ASConfigurationDelegate> del = _config->_delegate;
    if ([del respondsToSelector:@selector(textureDidActivateExperimentalFeatures:)]) {
      dispatch_async([self delegateQueue], ^{
        [del textureDidActivateExperimentalFeatures:newlyTriggered];
      });
    }
  }
  
  return (enabled != 0);
}

#if DEBUG
+ (void)test_resetWithConfiguration:(ASConfiguration *)configuration
{
  ASConfigurationManager *inst = [self sharedInstance];
  inst->_config = configuration;
  atomic_store(&inst->_activatedExperiments, 0);
}
#endif

@end

BOOL ASActivateExperimentalFeature(ASExperimentalFeatureSet feature)
{
  __unsafe_unretained ASConfigurationManager *inst = [ASConfigurationManager sharedInstance];
  return [inst activateExperimentalFeature:feature];
}
