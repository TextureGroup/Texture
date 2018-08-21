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
#import "KittenNode.h"
#import "OverrideViewController.h"

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import <AsyncDisplayKit/ASAssert.h>

@interface ViewController ()
@end

@implementation ViewController

#pragma mark -
#pragma mark UIViewController.

- (instancetype)init
{
  KittenNode *displayNode = [[KittenNode alloc] init];
  if (!(self = [super initWithNode:displayNode]))
    return nil;

  self.title = @"Display Node";
  displayNode.imageTappedBlock = ^{
    [KittenNode defaultImageTappedAction:self];
  };
  return self;
}

- (void)viewWillLayoutSubviews
{
  [super viewWillLayoutSubviews];
}

@end
