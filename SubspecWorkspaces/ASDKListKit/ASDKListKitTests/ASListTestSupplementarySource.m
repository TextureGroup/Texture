//
//  ASListTestSupplementarySource.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASListTestSupplementarySource.h"
#import "ASListTestSupplementaryNode.h"

@implementation ASListTestSupplementarySource

- (__kindof UICollectionReusableView *)viewForSupplementaryElementOfKind:(NSString *)elementKind atIndex:(NSInteger)index
{
  return [ASIGListSupplementaryViewSourceMethods viewForSupplementaryElementOfKind:elementKind atIndex:index sectionController:self.sectionController];
}

- (CGSize)sizeForSupplementaryViewOfKind:(NSString *)elementKind atIndex:(NSInteger)index
{
  return [ASIGListSupplementaryViewSourceMethods sizeForSupplementaryViewOfKind:elementKind atIndex:index];
}

- (ASCellNodeBlock)nodeBlockForSupplementaryElementOfKind:(NSString *)elementKind atIndex:(NSInteger)index
{
  return ^{
    ASListTestSupplementaryNode *node = [[ASListTestSupplementaryNode alloc] init];
    node.style.preferredSize = CGSizeMake(100, 10);
    return node;
  };
}

@end
