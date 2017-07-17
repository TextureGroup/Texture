//
//  ASCollectionLayoutContext.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASCollectionLayoutContext.h>
#import <AsyncDisplayKit/ASCollectionLayoutContext+Private.h>

#import <AsyncDisplayKit/ASAssert.h>
#import <AsyncDisplayKit/ASCollectionLayoutDelegate.h>
#import <AsyncDisplayKit/ASCollectionLayoutCache.h>
#import <AsyncDisplayKit/ASElementMap.h>
#import <AsyncDisplayKit/ASEqualityHelpers.h>
#import <AsyncDisplayKit/ASHashing.h>

@implementation ASCollectionLayoutContext {
  Class<ASCollectionLayoutDelegate> _layoutDelegateClass;

  // This ivar doesn't directly involve in the layout calculation process, i.e contexts can be equal regardless of the layout caches.
  // As a result, this ivar is ignored in -isEqualToContext: and -hash.
  __weak ASCollectionLayoutCache *_layoutCache;
}

- (instancetype)initWithViewportSize:(CGSize)viewportSize
                scrollableDirections:(ASScrollDirection)scrollableDirections
                            elements:(ASElementMap *)elements
                 layoutDelegateClass:(Class<ASCollectionLayoutDelegate>)layoutDelegateClass
                         layoutCache:(ASCollectionLayoutCache *)layoutCache
                      additionalInfo:(id)additionalInfo
{
  self = [super init];
  if (self) {
    _viewportSize = viewportSize;
    _scrollableDirections = scrollableDirections;
    _elements = elements;
    _layoutDelegateClass = layoutDelegateClass;
    _layoutCache = layoutCache;
    _additionalInfo = additionalInfo;
  }
  return self;
}

- (Class<ASCollectionLayoutDelegate>)layoutDelegateClass
{
  return _layoutDelegateClass;
}

- (ASCollectionLayoutCache *)layoutCache
{
  return _layoutCache;
}

- (BOOL)isEqualToContext:(ASCollectionLayoutContext *)context
{
  if (context == nil) {
    return NO;
  }

  // NOTE: ASObjectIsEqual returns YES when both objects are nil.
  // So don't use ASObjectIsEqual on _elements.
  // It is a weak property and 2 layouts generated from different sets of elements
  // should never be considered the same even if they are nil now.
  return CGSizeEqualToSize(_viewportSize, context.viewportSize)
  && _scrollableDirections == context.scrollableDirections
  && [_elements isEqual:context.elements]
  && _layoutDelegateClass == context.layoutDelegateClass
  && ASObjectIsEqual(_additionalInfo, context.additionalInfo);
}

- (BOOL)isEqual:(id)other
{
  if (self == other) {
    return YES;
  }
  if (! [other isKindOfClass:[ASCollectionLayoutContext class]]) {
    return NO;
  }
  return [self isEqualToContext:other];
}

- (NSUInteger)hash
{
  struct {
    CGSize viewportSize;
    ASScrollDirection scrollableDirections;
    NSUInteger elementsHash;
    NSUInteger layoutDelegateClassHash;
    NSUInteger additionalInfoHash;
  } data = {
    _viewportSize,
    _scrollableDirections,
    _elements.hash,
    _layoutDelegateClass.hash,
    [_additionalInfo hash]
  };
  return ASHashBytes(&data, sizeof(data));
}

@end
