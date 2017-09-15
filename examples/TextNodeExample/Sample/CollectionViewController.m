//
//  CollectionViewController.m
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

#import "CollectionViewController.h"
#import "TextCellNode.h"

@interface CollectionViewController () <ASCollectionLayoutDelegate, ASCollectionDataSource, ASCollectionDelegate> {
  ASCollectionNode* _collectionNode;
  NSArray<NSString*>* _labels;
  TextCellNode* _cellNode;
}

@end

@implementation CollectionViewController

- (instancetype) init {
  UICollectionViewFlowLayout* flowLayout = [[UICollectionViewFlowLayout alloc] init];
  _collectionNode = [[ASCollectionNode alloc] initWithCollectionViewLayout:flowLayout];
  self = [super initWithNode:_collectionNode];
  if (self) {
    _collectionNode.delegate = self;
    _collectionNode.dataSource = self;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  //  self.edgesForExtendedLayout=UIRectEdgeNone;
  //  _tableNode.contentOffset = CGPointMake(0, -[[UIApplication sharedApplication] statusBarFrame].size.height);
  _collectionNode.backgroundColor = [UIColor whiteColor];
  _labels = @[@"Fight of the Living Dead: Experiment Fight of the Living Dead: Experiment", @"S1 • E1"];
}

-(void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];

}

-(NSInteger)collectionNode:(ASCollectionNode *)collectionNode numberOfItemsInSection:(NSInteger)section{
  return 1;
}
-(ASCellNodeBlock)collectionNode:(ASCollectionNode *)collectionNode nodeBlockForItemAtIndexPath:(NSIndexPath *)indexPath {
  return ^{
    _cellNode = [[TextCellNode alloc] initWithText1:_labels[0] text2:_labels[1]];
    //    ASCellNode* node = [[ASCellNode alloc] init];
    //    ASTextNode* textNode = [[ASTextNode alloc] initWithViewBlock:^UIView * _Nonnull{
    //      UILabel* label = [[UILabel alloc] init];
    //      label.text = @"hello";
    //      CGSize size = [label sizeThatFits:CGSizeMake(_tableNode.bounds.size.width, INT_MAX)];
    //      label.frame = CGRectMake(0, 0, size.width, size.height);
    //      return label;
    //    }];
    //    textNode.automaticallyManagesSubnodes = YES;
    //    textNode.layoutSpecBlock = ^ASLayoutSpec * _Nonnull(__kindof ASDisplayNode * _Nonnull node, ASSizeRange constrainedSize) {
    //      ASLayoutSpec* spec = [[ASLayoutSpec alloc] init];
    //      return spec;
    //    };
    //[node addSubnode:textNode];
    //node.frame = textNode.bounds;
    //    node.style.preferredSize = CGSizeMake(200, 100);
    return _cellNode;
  };
}
-(ASSizeRange)collectionNode:(ASCollectionNode *)collectionNode constrainedSizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  CGFloat width = collectionNode.view.bounds.size.width;
  return ASSizeRangeMake(CGSizeMake(width, 0.0f), CGSizeMake(width, CGFLOAT_MAX));
}

-(void)collectionNode:(ASCollectionNode *)collectionNode didSelectItemAtIndexPath:(NSIndexPath *)indexPath {

}

@end
