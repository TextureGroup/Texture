//
//  AsyncViewController.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "AsyncViewController.h"
#import "RandomCoreGraphicsNode.h"

@implementation AsyncViewController

- (instancetype)init
{
  if (!(self = [super initWithNode:[[RandomCoreGraphicsNode alloc] init]])) {
    return nil;
  }

  self.neverShowPlaceholders = YES;
  self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemFavorites tag:0];
  return self;
}

- (void)viewWillAppear:(BOOL)animated
{
  // FIXME: This is only being called on the first time the UITabBarController shows us.
  [super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
  [self.node recursivelyClearContents];
  [super viewDidDisappear:animated];
}

@end
