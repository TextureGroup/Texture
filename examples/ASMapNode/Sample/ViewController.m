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

#import "MapHandlerNode.h"

@interface ViewController ()

@end

@implementation ViewController


#pragma mark - Lifecycle

- (instancetype)init
{
  self = [super initWithNode:[[MapHandlerNode alloc] init]];
  if (self == nil) { return self; }

  return self;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  self.navigationController.navigationBarHidden = YES;
}

@end
