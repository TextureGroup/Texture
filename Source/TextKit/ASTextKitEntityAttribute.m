//
//  ASTextKitEntityAttribute.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASTextKitEntityAttribute.h>

@implementation ASTextKitEntityAttribute

- (instancetype)initWithEntity:(id<NSObject>)entity
{
  if (self = [super init]) {
    _entity = entity;
  }
  return self;
}

- (NSUInteger)hash
{
  return [_entity hash];
}

- (BOOL)isEqual:(id)object
{
  if (self == object) {
    return YES;
  }
  if (![object isKindOfClass:[self class]]) {
    return NO;
  }
  ASTextKitEntityAttribute *other = (ASTextKitEntityAttribute *)object;
  return _entity == other.entity || [_entity isEqual:other.entity];
}

@end
