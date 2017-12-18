//
//  ASRectMap.mm
//  Texture
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the /ASDK-Licenses directory of this source tree. An additional
//  grant of patent rights can be found in the PATENTS file in the same directory.
//
//  Modifications to this file made after 4/13/2017 are: Copyright (c) 2017-present,
//  Pinterest, Inc.  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASRectMap.h"
#import "ASObjectDescriptionHelpers.h"
#import <UIKit/UIGeometry.h>
#import <unordered_map>

@implementation ASRectMap {
  std::unordered_map<void *, CGRect> _map;
}

+ (ASRectMap *)rectMapForWeakObjectPointers
{
  return [[self alloc] init];
}

- (CGRect)rectForKey:(id)key
{
  auto result = _map.find((__bridge void *)key);
  if (result != _map.end()) {
    // result->first is the key; result->second is the value, a CGRect.
    return result->second;
  } else {
    return CGRectNull;
  }
}

- (void)setRect:(CGRect)rect forKey:(id)key
{
  if (key) {
    _map[(__bridge void *)key] = rect;
  }
}

- (void)removeRectForKey:(id)key
{
  if (key) {
    _map.erase((__bridge void *)key);
  }
}

- (id)copyWithZone:(NSZone *)zone
{
  ASRectMap *copy = [ASRectMap rectMapForWeakObjectPointers];
  copy->_map = _map;
  return copy;
}

- (NSMutableArray<NSDictionary *> *)propertiesForDescription
{
  NSMutableArray *result = [NSMutableArray array];

  // { ptr1->rect1 ptr2->rect2 ptr3->rect3 }
  NSMutableString *str = [NSMutableString string];
  for (auto it = _map.begin(); it != _map.end(); it++) {
    [str appendFormat:@" %@->%@", it->first, NSStringFromCGRect(it->second)];
  }
  [result addObject:@{ @"ASRectMap": str }];

  return result;
}

- (NSString *)description
{
  return ASObjectDescriptionMakeWithoutObject([self propertiesForDescription]);
}

@end
