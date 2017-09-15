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
#import "TextCellNode.h"

@interface ViewController () <ASTableDelegate, ASTableDataSource> {
  ASTableNode* _tableNode;
  NSArray<NSString*>* _labels;
  NSArray<NSString*>* _examples;
  TextCellNode* _cellNode;
}

@end

@implementation ViewController

- (instancetype) init {
  _tableNode = [[ASTableNode alloc] initWithStyle:UITableViewStylePlain];
  self = [super initWithNode:_tableNode];
  if (self) {
    _tableNode.delegate = self;
    _tableNode.dataSource = self;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  _tableNode.backgroundColor = [UIColor whiteColor];
  _labels = @[@"Fight of the Living Dead: Experiment 88Fight of the Living Dead: Exper", @"S1 • E1"];
}

-(void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];

}


-(NSInteger)tableNode:(ASTableNode *)tableNode numberOfRowsInSection:(NSInteger)section {
  return 1;
}

- (ASCellNodeBlock)tableNode:(ASTableNode *)tableNode nodeBlockForRowAtIndexPath:(NSIndexPath *)indexPath {
  return ^{
    _cellNode = [[TextCellNode alloc] initWithText1:_labels[0] text2:_labels[1]];
    return _cellNode;
  };
}

-(void)tableNode:(ASTableNode *)tableNode didSelectRowAtIndexPath:(NSIndexPath *)indexPath {


}


@end
