//
//  ASDisplayNode+Ancestry.m
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

#import "ASDisplayNode+Ancestry.h"

AS_SUBCLASSING_RESTRICTED
@interface ASNodeAncestryEnumerator : NSEnumerator
@end

@implementation ASNodeAncestryEnumerator {
  /// Would be nice to use __unsafe_unretained but nodes can be
  /// deallocated on arbitrary threads so nope.
  __weak ASDisplayNode * _nextNode;
}

- (instancetype)initWithNode:(ASDisplayNode *)node
{
  if (self = [super init]) {
    _nextNode = node;
  }
  return self;
}

- (id)nextObject
{
  ASDisplayNode *node = _nextNode;
  _nextNode = [node supernode];
  return node;
}

@end

@implementation ASDisplayNode (Ancestry)

- (NSEnumerator *)ancestorEnumeratorWithSelf:(BOOL)includeSelf
{
  ASDisplayNode *node = includeSelf ? self : self.supernode;
  return [[ASNodeAncestryEnumerator alloc] initWithNode:node];
}

- (NSString *)ancestryDescription
{
  NSMutableArray *strings = [NSMutableArray array];
  for (ASDisplayNode *node in [self ancestorEnumeratorWithSelf:YES]) {
    [strings addObject:ASObjectDescriptionMakeTiny(node)];
  }
  return strings.description;
}

@end
