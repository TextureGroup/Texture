//
//  ASConfiguration.m
//  Texture
//
//  Copyright (c) 2018-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASConfiguration.h>
#import <AsyncDisplayKit/ASConfigurationInternal.h>

/// Not too performance-sensitive here.

/// Get this from C++, without the extra exception handling.
#define autotype __auto_type

@implementation ASConfiguration

- (instancetype)initWithJSONObject:(NSDictionary *)jsonObject
{
  if (self = [self init]) {
    autotype featureStrings = ASDynamicCast(jsonObject[@"experimental_features"], NSArray);
    self.experimentalFeatures = ASExperimentalFeaturesFromArray(featureStrings);
  }
  return self;
}

- (id)copyWithZone:(NSZone *)zone
{
  ASConfiguration *config = [[ASConfiguration alloc] init];
  config.experimentalFeatures = self.experimentalFeatures;
  config.delegate = self.delegate;
  return config;
}

@end
