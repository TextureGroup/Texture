//
//  ASInsetLayoutSpecSnapshotTests.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASLayoutSpecSnapshotTestsHelper.h"

#import <AsyncDisplayKit/ASBackgroundLayoutSpec.h>
#import <AsyncDisplayKit/ASInsetLayoutSpec.h>

typedef NS_OPTIONS(NSUInteger, ASInsetLayoutSpecTestEdge) {
  ASInsetLayoutSpecTestEdgeTop    = 1 << 0,
  ASInsetLayoutSpecTestEdgeLeft   = 1 << 1,
  ASInsetLayoutSpecTestEdgeBottom = 1 << 2,
  ASInsetLayoutSpecTestEdgeRight  = 1 << 3,
};

static CGFloat insetForEdge(NSUInteger combination, ASInsetLayoutSpecTestEdge edge, CGFloat insetValue)
{
  return combination & edge ? INFINITY : insetValue;
}

static UIEdgeInsets insetsForCombination(NSUInteger combination, CGFloat insetValue)
{
  return {
    .top = insetForEdge(combination, ASInsetLayoutSpecTestEdgeTop, insetValue),
    .left = insetForEdge(combination, ASInsetLayoutSpecTestEdgeLeft, insetValue),
    .bottom = insetForEdge(combination, ASInsetLayoutSpecTestEdgeBottom, insetValue),
    .right = insetForEdge(combination, ASInsetLayoutSpecTestEdgeRight, insetValue),
  };
}

static NSString *nameForInsets(UIEdgeInsets insets)
{
  return [NSString stringWithFormat:@"%.f_%.f_%.f_%.f", insets.top, insets.left, insets.bottom, insets.right];
}

@interface ASInsetLayoutSpecSnapshotTests : ASLayoutSpecSnapshotTestCase
@end

@implementation ASInsetLayoutSpecSnapshotTests

- (void)testInsetsWithVariableSize
{
  for (NSUInteger combination = 0; combination < 16; combination++) {
    UIEdgeInsets insets = insetsForCombination(combination, 10);
    ASDisplayNode *backgroundNode = ASDisplayNodeWithBackgroundColor([UIColor grayColor]);
    ASDisplayNode *foregroundNode = ASDisplayNodeWithBackgroundColor([UIColor greenColor], {10, 10});
    
    ASLayoutSpec *layoutSpec =
    [ASBackgroundLayoutSpec
     backgroundLayoutSpecWithChild:
     [ASInsetLayoutSpec
      insetLayoutSpecWithInsets:insets
      child:foregroundNode]
     background:backgroundNode];
    
    static ASSizeRange kVariableSize = {{0, 0}, {300, 300}};
    [self testLayoutSpec:layoutSpec
               sizeRange:kVariableSize
                subnodes:@[backgroundNode, foregroundNode]
              identifier:nameForInsets(insets)];
  }
}

- (void)testInsetsWithFixedSize
{
  for (NSUInteger combination = 0; combination < 16; combination++) {
    UIEdgeInsets insets = insetsForCombination(combination, 10);
    ASDisplayNode *backgroundNode = ASDisplayNodeWithBackgroundColor([UIColor grayColor]);
    ASDisplayNode *foregroundNode = ASDisplayNodeWithBackgroundColor([UIColor greenColor], {10, 10});
    
    ASLayoutSpec *layoutSpec =
    [ASBackgroundLayoutSpec
     backgroundLayoutSpecWithChild:
     [ASInsetLayoutSpec
      insetLayoutSpecWithInsets:insets
      child:foregroundNode]
     background:backgroundNode];

    static ASSizeRange kFixedSize = {{300, 300}, {300, 300}};
    [self testLayoutSpec:layoutSpec
               sizeRange:kFixedSize
                subnodes:@[backgroundNode, foregroundNode]
              identifier:nameForInsets(insets)];
  }
}

/** Regression test, there was a bug mixing insets with infinite and zero sizes */
- (void)testInsetsWithInfinityAndZeroInsetValue
{
  for (NSUInteger combination = 0; combination < 16; combination++) {
    UIEdgeInsets insets = insetsForCombination(combination, 0);
    ASDisplayNode *backgroundNode = ASDisplayNodeWithBackgroundColor([UIColor grayColor]);
    ASDisplayNode *foregroundNode = ASDisplayNodeWithBackgroundColor([UIColor greenColor], {10, 10});

    ASLayoutSpec *layoutSpec =
    [ASBackgroundLayoutSpec
     backgroundLayoutSpecWithChild:
     [ASInsetLayoutSpec
      insetLayoutSpecWithInsets:insets
      child:foregroundNode]
     background:backgroundNode];

    static ASSizeRange kFixedSize = {{300, 300}, {300, 300}};
    [self testLayoutSpec:layoutSpec
               sizeRange:kFixedSize
                subnodes:@[backgroundNode, foregroundNode]
              identifier:nameForInsets(insets)];
  }
}

@end
