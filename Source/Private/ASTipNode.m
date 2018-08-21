//
//  ASTipNode.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASTipNode.h"

#if AS_ENABLE_TIPS

@implementation ASTipNode

- (instancetype)initWithTip:(ASTip *)tip
{
  if (self = [super init]) {
    self.backgroundColor = [UIColor colorWithRed:0 green:0.7 blue:0.2 alpha:0.3];
    _tip = tip;
    [self addTarget:nil action:@selector(didTapTipNode:) forControlEvents:ASControlNodeEventTouchUpInside];
  }
  return self;
}

@end

#endif // AS_ENABLE_TIPS
