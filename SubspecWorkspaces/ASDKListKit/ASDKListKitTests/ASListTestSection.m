//
//  ASListTestSection.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASListTestSection.h"
#import "ASListTestCellNode.h"

@implementation ASListTestSection

- (instancetype)init
{
  if (self = [super init])
{
    _selectedItemIndex = NSNotFound;
  }
  return self;
}

- (NSInteger)numberOfItems
{
  return self.itemCount;
}

- (CGSize)sizeForItemAtIndex:(NSInteger)index
{
  return [ASIGListSectionControllerMethods sizeForItemAtIndex:index];
}

- (__kindof UICollectionViewCell *)cellForItemAtIndex:(NSInteger)index
{
  return [ASIGListSectionControllerMethods cellForItemAtIndex:index sectionController:self];
}

- (void)didUpdateToObject:(id)object
{
  if ([object isKindOfClass:[NSNumber class]])
{
    self.itemCount = [object integerValue];
  }
}

- (void)didSelectItemAtIndex:(NSInteger)index
{
  self.selectedItemIndex = index;
}

- (ASCellNodeBlock)nodeBlockForItemAtIndex:(NSInteger)index
{
  return ^{
    ASListTestCellNode *node = [[ASListTestCellNode alloc] init];
    node.style.preferredSize = CGSizeMake(100, 10);
    return node;
  };
}

@end
