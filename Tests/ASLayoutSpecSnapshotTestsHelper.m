//
//  ASLayoutSpecSnapshotTestsHelper.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASLayoutSpecSnapshotTestsHelper.h"

#import <AsyncDisplayKit/ASDisplayNode.h>
#import <AsyncDisplayKit/ASLayoutSpec.h>
#import <AsyncDisplayKit/ASLayout.h>
#import <AsyncDisplayKit/ASDisplayNode+Beta.h>

@interface ASTestNode : ASDisplayNode
@property (nonatomic, nullable) ASLayoutSpec *layoutSpecUnderTest;
@end

@implementation ASLayoutSpecSnapshotTestCase

- (void)setUp
{
  [super setUp];
  self.recordMode = NO;
}

- (void)testLayoutSpec:(ASLayoutSpec *)layoutSpec
             sizeRange:(ASSizeRange)sizeRange
              subnodes:(NSArray *)subnodes
            identifier:(NSString *)identifier
{
  ASTestNode *node = [[ASTestNode alloc] init];

  for (ASDisplayNode *subnode in subnodes) {
    [node addSubnode:subnode];
  }
  
  node.layoutSpecUnderTest = layoutSpec;
  
  ASDisplayNodeSizeToFitSizeRange(node, sizeRange);
  ASSnapshotVerifyNode(node, identifier);
}

@end

@implementation ASTestNode
- (instancetype)init
{
  if (self = [super init]) {
    self.layerBacked = YES;
  }
  return self;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
  return _layoutSpecUnderTest;
}

@end
