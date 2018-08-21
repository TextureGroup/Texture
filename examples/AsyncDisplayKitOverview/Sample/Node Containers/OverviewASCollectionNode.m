//
//  OverviewASCollectionNode.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "OverviewASCollectionNode.h"

#import <AsyncDisplayKit/AsyncDisplayKit.h>

@interface OverviewASCollectionNode () <ASCollectionDataSource, ASCollectionDelegate>
@property (nonatomic, strong) ASCollectionNode *node;
@end

@implementation OverviewASCollectionNode

#pragma mark - Lifecycle

- (instancetype)init
{
    self = [super init];
    if (self == nil) { return self; }
    
    UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
    _node = [[ASCollectionNode alloc] initWithCollectionViewLayout:flowLayout];
    _node.dataSource = self;
    _node.delegate = self;
    [self addSubnode:_node];;
    
    return self;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
    // 100% of container
    _node.style.width = ASDimensionMakeWithFraction(1.0);
    _node.style.height = ASDimensionMakeWithFraction(1.0);
    return [ASWrapperLayoutSpec wrapperWithLayoutElement:_node];
}

#pragma mark - <ASCollectionDataSource, ASCollectionDelegate>

- (NSInteger)collectionNode:(ASCollectionNode *)collectionNode numberOfItemsInSection:(NSInteger)section
{
    return 100;
}

- (ASCellNodeBlock)collectionNode:(ASCollectionNode *)collectionNode nodeBlockForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return ^{
        ASTextCellNode *cellNode = [ASTextCellNode new];
        cellNode.backgroundColor = [UIColor lightGrayColor];
        cellNode.text = [NSString stringWithFormat:@"Row: %ld", indexPath.row];
        return cellNode;
    };
}

- (ASSizeRange)collectionNode:(ASCollectionNode *)collectionNode constrainedSizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return ASSizeRangeMake(CGSizeMake(100, 100));
}

@end
