//
//  ViewController.m
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

#import "ViewController.h"
#import "Post.h"
#import "PostNode.h"

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import <AsyncDisplayKit/ASAssert.h>

#include <stdlib.h>

@interface ViewController () <ASTableDataSource, ASTableDelegate>

@property (nonatomic, strong) ASTableNode *tableNode;
@property (nonatomic, strong) NSMutableArray *socialAppDataSource;

@end

#pragma mark - Lifecycle

@implementation ViewController

- (instancetype)init
{
  _tableNode = [[ASTableNode alloc] initWithStyle:UITableViewStylePlain];
  _tableNode.inverted = YES;
  self = [super initWithNode:_tableNode];
  
  
  if (self) {
    
    _tableNode.delegate = self;
    _tableNode.dataSource = self;
    self.title = @"Timeline";
    
    [self createSocialAppDataSource];
  }
  
  return self;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  CGFloat inset = [self topBarsHeight];
  self.tableNode.view.contentInset = UIEdgeInsetsMake(-inset, 0, inset, 0);
  self.tableNode.view.scrollIndicatorInsets = UIEdgeInsetsMake(-inset, 0, inset, 0);
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  // SocialAppNode has its own separator
  self.tableNode.view.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (CGFloat)topBarsHeight
{
  // No need to adjust if the edge isn't available
  if ((self.edgesForExtendedLayout & UIRectEdgeTop) == 0) {
    return 0.0;
  }
  return CGRectGetHeight(self.navigationController.navigationBar.frame) + CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);
}


#pragma mark - Data Model

- (void)createSocialAppDataSource
{
  _socialAppDataSource = [[NSMutableArray alloc] init];
  
  Post *newPost = [[Post alloc] init];
  newPost.name = @"Apple Guy";
  newPost.username = @"@appleguy";
  newPost.photo = @"https://avatars1.githubusercontent.com/u/565251?v=3&s=96";
  newPost.post = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.";
  newPost.time = @"3s";
  newPost.media = @"";
  newPost.via = 0;
  newPost.likes = arc4random_uniform(74);
  newPost.comments = arc4random_uniform(40);
  [_socialAppDataSource addObject:newPost];
  
  newPost = [[Post alloc] init];
  newPost.name = @"Huy Nguyen";
  newPost.username = @"@nguyenhuy";
  newPost.photo = @"https://avatars2.githubusercontent.com/u/587874?v=3&s=96";
  newPost.post = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.";
  newPost.time = @"1m";
  newPost.media = @"";
  newPost.via = 1;
  newPost.likes = arc4random_uniform(74);
  newPost.comments = arc4random_uniform(40);
  [_socialAppDataSource addObject:newPost];
  
  newPost = [[Post alloc] init];
  newPost.name = @"Alex Long Name";
  newPost.username = @"@veryyyylongusername";
  newPost.photo = @"https://avatars1.githubusercontent.com/u/8086633?v=3&s=96";
  newPost.post = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.";
  newPost.time = @"3:02";
  newPost.media = @"http://www.ngmag.ru/upload/iblock/f93/f9390efc34151456598077c1ba44a94d.jpg";
  newPost.via = 2;
  newPost.likes = arc4random_uniform(74);
  newPost.comments = arc4random_uniform(40);
  [_socialAppDataSource addObject:newPost];
  
  newPost = [[Post alloc] init];
  newPost.name = @"Vitaly Baev";
  newPost.username = @"@vitalybaev";
  newPost.photo = @"https://avatars0.githubusercontent.com/u/724423?v=3&s=96";
  newPost.post = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. https://github.com/facebook/AsyncDisplayKit Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.";
  newPost.time = @"yesterday";
  newPost.media = @"";
  newPost.via = 1;
  newPost.likes = arc4random_uniform(74);
  newPost.comments = arc4random_uniform(40);
  [_socialAppDataSource addObject:newPost];
}

#pragma mark - ASTableNode

- (ASCellNodeBlock)tableNode:(ASTableNode *)tableNode nodeBlockForRowAtIndexPath:(NSIndexPath *)indexPath
{
  Post *post = self.socialAppDataSource[indexPath.row];
  return ^{
    return [[PostNode alloc] initWithPost:post];
  };
}

- (NSInteger)tableNode:(ASTableNode *)tableNode numberOfRowsInSection:(NSInteger)section
{
  return self.socialAppDataSource.count;
}

@end
