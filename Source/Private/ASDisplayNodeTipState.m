//
//  ASDisplayNodeTipState.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASDisplayNodeTipState.h"

@interface ASDisplayNodeTipState ()
@end

@implementation ASDisplayNodeTipState

- (instancetype)initWithNode:(ASDisplayNode *)node
{
  if (self = [super init]) {
    _node = node;
  }
  return self;
}

@end
