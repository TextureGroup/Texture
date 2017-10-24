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

@interface ASScrollNodeTests : XCTestCase
@end

@implementation ASScrollNodeTests {
  ASScrollNode *_scrollNode;
  ASDisplayNode *_subnode;
}

- (void)setUp
{
  ASDisplayNode *subnode = [[ASDisplayNode alloc] init];
  _subnode = subnode;

  _scrollNode = [[ASScrollNode alloc] init];
  _scrollNode.scrollableDirections = ASScrollDirectionVerticalDirections;
  _scrollNode.automaticallyManagesContentSize = YES;
  _scrollNode.automaticallyManagesSubnodes = YES;
  _scrollNode.layoutSpecBlock = ^ASLayoutSpec * _Nonnull(__kindof ASDisplayNode * _Nonnull node, ASSizeRange constrainedSize) {
    return [[ASWrapperLayoutSpec alloc] initWithLayoutElement:subnode];
  };
  [_scrollNode view];
}

- (void)testSubnodeLayoutCalculatedWithUnconstrainedMaxSizeInScrollableDirection
{
  CGSize parentSize = CGSizeMake(100, 100);
  ASSizeRange sizeRange = ASSizeRangeMake(parentSize);

  [_scrollNode layoutThatFits:sizeRange parentSize:parentSize];

  ASSizeRange subnodeSizeRange = sizeRange;
  subnodeSizeRange.max.height = CGFLOAT_MAX;
  XCTAssertEqual(_scrollNode.scrollableDirections, ASScrollDirectionVerticalDirections);
  XCTAssertTrue(ASSizeRangeEqualToSizeRange(_subnode.constrainedSizeForCalculatedLayout, subnodeSizeRange));

  // Same test for horizontal scrollable directions
  _scrollNode.scrollableDirections = ASScrollDirectionHorizontalDirections;
  [_scrollNode layoutThatFits:sizeRange parentSize:parentSize];

  subnodeSizeRange = sizeRange;
  subnodeSizeRange.max.width = CGFLOAT_MAX;

  XCTAssertTrue(ASSizeRangeEqualToSizeRange(_subnode.constrainedSizeForCalculatedLayout, subnodeSizeRange));
}

- (void)testAutomaticallyManagesContentSizeUnderflow
{
  CGSize subnodeSize = CGSizeMake(100, 100);
  CGSize parentSize = CGSizeMake(100, 200);
  ASSizeRange sizeRange = ASSizeRangeUnconstrained;

  _subnode.style.preferredSize = subnodeSize;

  ASLayout *layout = [_scrollNode layoutThatFits:sizeRange parentSize:parentSize];
  [_scrollNode layout];

  XCTAssertTrue(CGSizeEqualToSize(layout.size, parentSize));
  XCTAssertTrue(CGSizeEqualToSize(_scrollNode.view.contentSize, subnodeSize));
}

- (void)testAutomaticallyManagesContentSizeOverflow
{
  CGSize subnodeSize = CGSizeMake(100, 500);
  CGSize parentSize = CGSizeMake(100, 200);
  ASSizeRange sizeRange = ASSizeRangeUnconstrained;

  _subnode.style.preferredSize = subnodeSize;

  ASLayout *layout = [_scrollNode layoutThatFits:sizeRange parentSize:parentSize];
  [_scrollNode layout];

  XCTAssertTrue(CGSizeEqualToSize(layout.size, parentSize));
  XCTAssertTrue(CGSizeEqualToSize(_scrollNode.view.contentSize, subnodeSize));
}

- (void)testAutomaticallyManagesContentSizeWithSizeRangeSmallerThanParentSize
{
  CGSize subnodeSize = CGSizeMake(100, 100);
  CGSize parentSize = CGSizeMake(100, 500);
  ASSizeRange sizeRange = ASSizeRangeMake(CGSizeMake(100, 100), CGSizeMake(100, 200));

  _subnode.style.preferredSize = subnodeSize;

  ASLayout *layout = [_scrollNode layoutThatFits:sizeRange parentSize:parentSize];
  [_scrollNode layout];

  XCTAssertTrue(CGSizeEqualToSize(layout.size, sizeRange.max));
  XCTAssertTrue(CGSizeEqualToSize(_scrollNode.view.contentSize, subnodeSize));
}

- (void)testAutomaticallyManagesContentSizeWithSizeRangeBiggerThanParentSize
{
  CGSize subnodeSize = CGSizeMake(100, 200);
  CGSize parentSize = CGSizeMake(100, 100);
  ASSizeRange sizeRange = ASSizeRangeMake(CGSizeMake(100, 150));

  _subnode.style.preferredSize = subnodeSize;

  ASLayout *layout = [_scrollNode layoutThatFits:sizeRange parentSize:parentSize];
  [_scrollNode layout];

  XCTAssertTrue(CGSizeEqualToSize(layout.size, sizeRange.min));
  XCTAssertTrue(CGSizeEqualToSize(_scrollNode.view.contentSize, subnodeSize));
}

- (void)testAutomaticallyManagesContentSizeWithInvalidCalculatedSizeForLayout
{
  CGSize subnodeSize = CGSizeMake(100, 200);
  CGSize parentSize = CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX);
  ASSizeRange sizeRange = ASSizeRangeUnconstrained;

  _subnode.style.preferredSize = subnodeSize;

  ASLayout *layout = [_scrollNode layoutThatFits:sizeRange parentSize:parentSize];
  [_scrollNode layout];

  XCTAssertTrue(CGSizeEqualToSize(layout.size, subnodeSize));
  XCTAssertTrue(CGSizeEqualToSize(_scrollNode.view.contentSize, subnodeSize));
}

@end
