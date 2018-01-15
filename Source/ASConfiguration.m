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

@implementation ASConfiguration

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  ASConfiguration *config = [[ASConfiguration alloc] init];
  config->_experimentalFeatures = _experimentalFeatures;
  config->_delegate = _delegate;
  return config;
}

@end
