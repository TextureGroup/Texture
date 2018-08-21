//
//  ViewController.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "ViewController.h"
#import "ScreenNode.h"

@interface ViewController()
{
  ScreenNode *_screenNode;
}

@end

@implementation ViewController

- (instancetype)init
{
  ScreenNode *node = [[ScreenNode alloc] init];
  if (!(self = [super initWithNode:node]))
    return nil;

  _screenNode = node;

  return self;
}

- (void)viewWillAppear:(BOOL)animated
{
  // This should be done before calling super's viewWillAppear which triggers data fetching on the node.
  [_screenNode start];
  [super viewWillAppear:animated];
}

@end
