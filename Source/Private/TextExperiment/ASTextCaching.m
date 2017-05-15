//
//  ASTextCaching.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASTextCaching.h"
#import <AsyncDisplayKit/ASDimension.h>
#import <AsyncDisplayKit/ASTextLayout.h>
#import <AsyncDisplayKit/ASInternalHelpers.h>

@interface ASTextLayoutKey : NSObject
- (instancetype)initForResultWithLayout:(ASTextLayout *)layout;

- (instancetype)initForQueryWithText:(NSAttributedString *)attributedString
                           container:(ASTextContainer *)container;
@property (nonatomic, strong, readonly) NSAttributedString *attributedString;
@property (nonatomic, strong, readonly) ASTextContainer *textContainer;
@property (nonatomic, readonly) ASSizeRange resultSizeRange;
@property (nonatomic, readonly) CGSize querySize;
@end

@implementation ASTextLayoutKey

- (instancetype)initForResultWithLayout:(ASTextLayout *)layout
{
  if (self = [super init]) {
    _textContainer = layout.container;
    _attributedString = layout.text;
    _resultSizeRange = ASSizeRangeMakeLoosely(_textContainer.size, layout.textBoundingSize);
  }
  return self;
}

- (instancetype)initForQueryWithText:(NSAttributedString *)attributedString container:(ASTextContainer *)container
{
  if (self = [super init]) {
    _textContainer = container;
    _attributedString = attributedString;
    _querySize = container.size;
  }
  return self;
}

- (NSUInteger)hash
{
  // Just use attributed string for hash. Previously we included container attributes
  // in the hash but it actually deteriorated cache performance (more collisions).
  return _attributedString.hash;
}

- (BOOL)isEqual:(id)object
{
  ASDisplayNodeAssert([object isKindOfClass:[ASTextLayoutKey class]], @"Unexpected object: %@", object);
  ASTextLayoutKey *otherKey = object;
  if (![_attributedString isEqualToAttributedString:otherKey->_attributedString] || ![_textContainer isEqualToContainerExcludingSize:otherKey->_textContainer]) {
    return NO;
  }
  
  ASDisplayNodeAssert(CGSizeEqualToSize(_querySize, CGSizeZero), @"Query-key should not be on the left-hand side of isEqual:.");
  
  BOOL otherIsResult = CGSizeEqualToSize(otherKey->_querySize, CGSizeZero);
  if (otherIsResult) {
    return ASSizeRangeEqualToSizeRange(_resultSizeRange, otherKey->_resultSizeRange);
  } else {
    return ASSizeRangeContainsSize(_resultSizeRange, otherKey->_querySize);
  }
}

@end

@implementation ASTextLayoutCache

#define ENABLE_ASTEXT_CACHE_LOG 0

+ (ASTextLayout *)layoutForText:(NSAttributedString *)attributedText
                      container:(ASTextContainer *)container
{
  static NSCache<ASTextLayoutKey *, ASTextLayout *> *textLayoutCache;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    textLayoutCache = [[NSCache alloc] init];
  });
  
  ASTextLayoutKey *cacheKey = [[ASTextLayoutKey alloc] initForQueryWithText:attributedText container:container];
  ASTextLayout *cachedLayout = [textLayoutCache objectForKey:cacheKey];
  if (cachedLayout != nil) {
    return cachedLayout;
  }
  
  // Cache Miss.
  
  // Compute the text layout.
  ASTextLayout *layout = [ASTextLayout layoutWithContainer:container text:attributedText];
  ASTextLayoutKey *key = [[ASTextLayoutKey alloc] initForResultWithLayout:layout];
  [textLayoutCache setObject:layout forKey:key];
  return layout;
}

@end
