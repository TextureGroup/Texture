//
//  ASTextCacheKey.m
//  Texture
//
//  Copyright (c) 2018-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASTextCacheKey.h>

#import <AsyncDisplayKit/ASHashing.h>
#import <AsyncDisplayKit/ASTextLayout.h>


@interface ASTextCacheKey ()
@property (atomic) NSUInteger cachedHash;
@property (atomic) ASTextLayout *layout;
@end

@implementation ASTextCacheKey {
  NSAttributedString *_attributedString;
  ASTextContainer *_container;
}

- (instancetype)initWithContainer:(ASTextContainer *)container attributedString:(NSAttributedString *)attributedString
{
  if (self = [super init]) {
    _container = container;
    _attributedString = [attributedString copy];
    self.cachedHash = NSUIntegerMax;
  }
  return self;
}

- (NSUInteger)hash
{
  NSUInteger cached = self.cachedHash;
  if (cached != NSUIntegerMax) {
    return cached;
  }
  
  // Don't include size in hash. Size -> layout mapping is many-to-one (fuzzy).
#pragma clang diagnostic push
#pragma clang diagnostic warning "-Wpadded"
  struct {
    size_t attributedStringHash;
    size_t containerHash;
#pragma clang diagnostic pop
  } data = {
    _attributedString.hash,
    [_container hashIncludingSize:NO],
  };
  NSUInteger result = ASHashBytes(&data, sizeof(data));
  self.cachedHash = result;
  return result;
}

- (ASTextLayout *)createLayout
{
  NSAssert(self.layout == nil, @"Multiple calls to -createLayout.");
  ASTextLayout *l = [ASTextLayout layoutWithContainer:_container text:_attributedString];
  self.layout = l;
  return l;
}

- (BOOL)isEqual:(ASTextCacheKey *)otherKey
{
  // NOTE: Skip the class check for this specialized "Key" object.
  
  // Either we have the layout (we are inside the cache)
  // or we do not (we are being checked against an entry
  // in the cache).
  
  ASTextLayout *layout = self.layout;
  if (layout) {
    // We have the layout, they are being checked for compatibility.
    return [layout isCompatibleWithContainer:otherKey->_container text:otherKey->_attributedString];
  } else {
    // They have the layout, we are being checked for compatibility.
    return [otherKey.layout isCompatibleWithContainer:_container text:_attributedString];
  }
}

@end
