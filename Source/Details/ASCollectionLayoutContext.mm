//
//  ASCollectionLayoutContext.mm
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

#import <AsyncDisplayKit/ASCollectionLayoutContext.h>
#import <AsyncDisplayKit/ASCollectionLayoutContext+Private.h>

#import <AsyncDisplayKit/ASAssert.h>
#import <AsyncDisplayKit/ASElementMap.h>
#import <AsyncDisplayKit/ASEqualityHelpers.h>
#import <AsyncDisplayKit/ASHashing.h>

@implementation ASCollectionLayoutContext

- (instancetype)initWithViewportSize:(CGSize)viewportSize elements:(ASElementMap *)elements additionalInfo:(id)additionalInfo
{
  self = [super init];
  if (self) {
    _viewportSize = viewportSize;
    _elements = elements;
    _additionalInfo = additionalInfo;
  }
  return self;
}

- (BOOL)isEqualToContext:(ASCollectionLayoutContext *)context
{
  if (context == nil) {
    return NO;
  }
  return CGSizeEqualToSize(_viewportSize, context.viewportSize) && ASObjectIsEqual(_elements, context.elements) && ASObjectIsEqual(_additionalInfo, context.additionalInfo);
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
    NSUInteger elementsHash;
    NSUInteger addlInfoHash;
  } data = {
    _viewportSize,
    _elements.hash,
    [_additionalInfo hash]
  };
  return ASHashBytes(&data, sizeof(data));
}

@end
