//
//  ASScrollNodeTests.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "ASXCTExtensions.h"

@interface ASScrollNodeTests : XCTestCase
@end

@implementation ASScrollNodeTests {
  ASScrollNode *scrollNode;
  ASDisplayNode *subnode;
}

- (void)setUp
{
  subnode = [[ASDisplayNode alloc] init];;

  scrollNode = [[ASScrollNode alloc] init];
  scrollNode.scrollableDirections = ASScrollDirectionVerticalDirections;
  scrollNode.automaticallyManagesContentSize = YES;
  scrollNode.automaticallyManagesSubnodes = YES;
  __weak __typeof(self) weakSelf = self;
  scrollNode.layoutSpecBlock = ^ASLayoutSpec * _Nonnull(__kindof ASDisplayNode * _Nonnull node, ASSizeRange constrainedSize) {
    __strong __typeof(weakSelf) strongSelf = weakSelf;
    return [[ASWrapperLayoutSpec alloc] initWithLayoutElement:strongSelf.subnode];
  };
}

- (void)testSubnodeLayoutCalculatedWithUnconstrainedMaxSizeInScrollableDirection
{
  CGSize parentSize = CGSizeMake(100, 100);
  ASSizeRange sizeRange = ASSizeRangeMake(parentSize);

  [scrollNode layoutThatFits:sizeRange parentSize:parentSize];

  ASSizeRange subnodeSizeRange = sizeRange;
  subnodeSizeRange.max.height = CGFLOAT_MAX;
  XCTAssertEqual(scrollNode.scrollableDirections, ASScrollDirectionVerticalDirections);
  ASXCTAssertEqualSizeRanges(subnode.constrainedSizeForCalculatedLayout, subnodeSizeRange);

  // Same test for horizontal scrollable directions
  scrollNode.scrollableDirections = ASScrollDirectionHorizontalDirections;
  [scrollNode layoutThatFits:sizeRange parentSize:parentSize];

  subnodeSizeRange = sizeRange;
  subnodeSizeRange.max.width = CGFLOAT_MAX;

  ASXCTAssertEqualSizeRanges(subnode.constrainedSizeForCalculatedLayout, subnodeSizeRange);
}

- (void)testAutomaticallyManagesContentSizeUnderflow
{
  CGSize subnodeSize = CGSizeMake(100, 100);
  CGSize parentSize = CGSizeMake(100, 200);
  ASSizeRange sizeRange = ASSizeRangeUnconstrained;

  subnode.style.preferredSize = subnodeSize;

  ASLayout *layout = [scrollNode layoutThatFits:sizeRange parentSize:parentSize];
  [scrollNode layout];

  ASXCTAssertEqualSizes(layout.size, parentSize);
  ASXCTAssertEqualSizes(scrollNode.view.contentSize, subnodeSize);
}

- (void)testAutomaticallyManagesContentSizeOverflow
{
  CGSize subnodeSize = CGSizeMake(100, 500);
  CGSize parentSize = CGSizeMake(100, 200);
  ASSizeRange sizeRange = ASSizeRangeUnconstrained;

  subnode.style.preferredSize = subnodeSize;

  ASLayout *layout = [scrollNode layoutThatFits:sizeRange parentSize:parentSize];
  [scrollNode layout];

  ASXCTAssertEqualSizes(layout.size, parentSize);
  ASXCTAssertEqualSizes(scrollNode.view.contentSize, subnodeSize);
}

- (void)testAutomaticallyManagesContentSizeWithSizeRangeSmallerThanParentSize
{
  CGSize subnodeSize = CGSizeMake(100, 100);
  CGSize parentSize = CGSizeMake(100, 500);
  ASSizeRange sizeRange = ASSizeRangeMake(CGSizeMake(100, 100), CGSizeMake(100, 200));

  subnode.style.preferredSize = subnodeSize;

  ASLayout *layout = [scrollNode layoutThatFits:sizeRange parentSize:parentSize];
  [scrollNode layout];

  ASXCTAssertEqualSizes(layout.size, sizeRange.max);
  ASXCTAssertEqualSizes(scrollNode.view.contentSize, subnodeSize);
}

- (void)testAutomaticallyManagesContentSizeWithSizeRangeBiggerThanParentSize
{
  CGSize subnodeSize = CGSizeMake(100, 200);
  CGSize parentSize = CGSizeMake(100, 100);
  ASSizeRange sizeRange = ASSizeRangeMake(CGSizeMake(100, 150));

  subnode.style.preferredSize = subnodeSize;

  ASLayout *layout = [scrollNode layoutThatFits:sizeRange parentSize:parentSize];
  [scrollNode layout];

  ASXCTAssertEqualSizes(layout.size, sizeRange.min);
  ASXCTAssertEqualSizes(scrollNode.view.contentSize, subnodeSize);
}

- (void)testAutomaticallyManagesContentSizeWithInvalidCalculatedSizeForLayout
{
  CGSize subnodeSize = CGSizeMake(100, 200);
  CGSize parentSize = CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX);
  ASSizeRange sizeRange = ASSizeRangeUnconstrained;

  subnode.style.preferredSize = subnodeSize;

  ASLayout *layout = [scrollNode layoutThatFits:sizeRange parentSize:parentSize];
  [scrollNode layout];

  ASXCTAssertEqualSizes(layout.size, subnodeSize);
  ASXCTAssertEqualSizes(scrollNode.view.contentSize, subnodeSize);
}

@end
