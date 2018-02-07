//
//  ASTLayoutFixture.mm
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASTLayoutFixture.h"

@interface ASTLayoutFixture ()

/// The size ranges against which nodes are expected to be measured.
@property (nonatomic, strong, readonly) NSMapTable<ASDisplayNode *, NSMutableArray<NSValue *> *> *sizeRanges;

/// The overridden returned sizes for nodes where you want to trigger multipass layout.
@property (nonatomic, strong, readonly) NSMapTable<ASDisplayNode *, NSValue *> *returnedSizes;

@end

@implementation ASTLayoutFixture

- (instancetype)init
{
  if (self = [super init]) {
    _sizeRanges = [NSMapTable mapTableWithKeyOptions:NSMapTableObjectPointerPersonality valueOptions:NSMapTableStrongMemory];
    _layoutSpecBlocks = [NSMapTable mapTableWithKeyOptions:NSMapTableObjectPointerPersonality valueOptions:NSMapTableStrongMemory];
    _returnedSizes = [NSMapTable mapTableWithKeyOptions:NSMapTableObjectPointerPersonality valueOptions:NSMapTableStrongMemory];

  }
  return self;
}

- (void)addSizeRange:(ASSizeRange)sizeRange forNode:(ASLayoutTestNode *)node
{
  auto ranges = [_sizeRanges objectForKey:node];
  if (ranges == nil) {
    ranges = [NSMutableArray array];
    [_sizeRanges setObject:ranges forKey:node];
  }
  [ranges addObject:[NSValue valueWithBytes:&sizeRange objCType:@encode(ASSizeRange)]];
}

- (void)setReturnedSize:(CGSize)size forNode:(ASLayoutTestNode *)node
{
  [_returnedSizes setObject:[NSValue valueWithCGSize:size] forKey:node];
}

- (ASSizeRange)firstSizeRangeForNode:(ASLayoutTestNode *)node
{
  auto val = [_sizeRanges objectForKey:node].firstObject;
  ASSizeRange r;
  [val getValue:&r];
  return r;
}

- (void)withSizeRangesForNode:(ASLayoutTestNode *)node block:(void (^)(ASSizeRange))block
{
  for (NSValue *value in [_sizeRanges objectForKey:node]) {
    ASSizeRange r;
    [value getValue:&r];
    block(r);
  }
}

- (ASLayout *)layoutForNode:(ASLayoutTestNode *)node
{
  NSMutableArray *allLayouts = [NSMutableArray array];
  [ASTLayoutFixture collectAllLayoutsFromLayout:self.layout array:allLayouts];
  for (ASLayout *layout in allLayouts) {
    if (layout.layoutElement == node) {
      return layout;
    }
  }
  return nil;
}

/// A very dumb tree iteration approach. NSEnumerator or something would be way better.
+ (void)collectAllLayoutsFromLayout:(ASLayout *)layout array:(NSMutableArray<ASLayout *> *)array
{
  [array addObject:layout];
  for (ASLayout *sublayout in layout.sublayouts) {
    [self collectAllLayoutsFromLayout:sublayout array:array];
  }
}

- (ASLayoutTestNode *)rootNode
{
  return (ASLayoutTestNode *)self.layout.layoutElement;
}

- (NSSet<ASLayoutTestNode *> *)allNodes
{
  auto allLayouts = [NSMutableArray array];
  [ASTLayoutFixture collectAllLayoutsFromLayout:self.layout array:allLayouts];
  return [NSSet setWithArray:[allLayouts valueForKey:@"layoutElement"]];
}

- (void)apply
{
  // Update layoutSpecBlock for parent nodes, set automatic subnode management
  for (ASDisplayNode *node in _layoutSpecBlocks) {
    auto block = [_layoutSpecBlocks objectForKey:node];
    if (node.layoutSpecBlock != block) {
      node.automaticallyManagesSubnodes = YES;
      node.layoutSpecBlock = block;
      [node setNeedsLayout];
    }
  }

  [self setTestSizesOfLeafNodesInLayout:self.layout];
}

/// Go through the given layout, and for all the leaf nodes, set their preferredSize
/// to the layout size if needed, then call -setNeedsLayout
- (void)setTestSizesOfLeafNodesInLayout:(ASLayout *)layout
{
  auto node = (ASLayoutTestNode *)layout.layoutElement;
  if (layout.sublayouts.count == 0) {
    auto override = [self.returnedSizes objectForKey:node];
    node.testSize = override ? override.CGSizeValue : layout.size;
  } else {
    node.testSize = CGSizeZero;
    for (ASLayout *sublayout in layout.sublayouts) {
      [self setTestSizesOfLeafNodesInLayout:sublayout];
    }
  }
}

@end
