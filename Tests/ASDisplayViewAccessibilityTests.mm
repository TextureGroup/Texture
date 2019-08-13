//
//  ASDisplayViewAccessibilityTests.mm
//  Texture
//
//  Copyright (c) 2018-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <XCTest/XCTest.h>

#import <AsyncDisplayKit/ASDisplayNode.h>
#import <AsyncDisplayKit/ASDisplayNode+Beta.h>
#import <AsyncDisplayKit/ASTextNode.h>
#import <AsyncDisplayKit/ASConfiguration.h>
#import <AsyncDisplayKit/ASConfigurationInternal.h>
#import <OCMock/OCMock.h>
#import "ASDisplayNodeTestsHelper.h"

@interface ASDisplayViewAccessibilityTests : XCTestCase
@end

@implementation ASDisplayViewAccessibilityTests

- (void)testAccessibilityElementsAccessors
{
  // Setup nodes with accessibility info
  ASDisplayNode *node = nil;
  ASDisplayNode *subnode = nil;
  node = [[ASDisplayNode alloc] init];
  subnode = [[ASDisplayNode alloc] init];
  NSString *label = @"foo";
  subnode.isAccessibilityElement = YES;
  subnode.accessibilityLabel = label;
  [node addSubnode:subnode];
  XCTAssertEqualObjects([node.view.accessibilityElements.firstObject accessibilityLabel], label);
  // NOTE: The following tests will fail unless accessibility is enabled, e.g. by turning the
  // accessibility inspector on. See https://github.com/TextureGroup/Texture/pull/1069 for details.
  /*XCTAssertEqualObjects([[node.view accessibilityElementAtIndex:0] accessibilityLabel], label);
  XCTAssertEqual(node.view.accessibilityElementCount, 1);
  XCTAssertEqual([node.view indexOfAccessibilityElement:node.view.accessibilityElements.firstObject], 0);*/
}

- (void)testThatSubnodeAccessibilityLabelAggregationWorks
{
  // Setup nodes
  ASDisplayNode *node = nil;
  ASDisplayNode *innerNode1 = nil;
  ASDisplayNode *innerNode2 = nil;
  node = [[ASDisplayNode alloc] init];
  innerNode1 = [[ASDisplayNode alloc] init];
  innerNode2 = [[ASDisplayNode alloc] init];

  // Initialize nodes with relevant accessibility data
  node.isAccessibilityContainer = YES;
  innerNode1.accessibilityLabel = @"hello";
  innerNode2.accessibilityLabel = @"world";

  // Attach the subnodes to the parent node, then ensure their accessibility labels have been'
  // aggregated to the parent's accessibility label
  [node addSubnode:innerNode1];
  [node addSubnode:innerNode2];
  XCTAssertEqualObjects([node.view.accessibilityElements.firstObject accessibilityLabel],
                        @"hello, world", @"Subnode accessibility label aggregation broken %@",
                        [node.view.accessibilityElements.firstObject accessibilityLabel]);
}

- (void)testThatContainerAccessibilityLabelOverrideStopsAggregation
{
  // Setup nodes
  ASDisplayNode *node = nil;
  ASDisplayNode *innerNode = nil;
  node = [[ASDisplayNode alloc] init];
  innerNode = [[ASDisplayNode alloc] init];

  // Initialize nodes with relevant accessibility data
  node.isAccessibilityContainer = YES;
  node.accessibilityLabel = @"hello";
  innerNode.accessibilityLabel = @"world";

  // Attach the subnode to the parent node, then ensure the parent's accessibility label does not
  // get aggregated with the subnode's label
  [node addSubnode:innerNode];
  XCTAssertEqualObjects([node.view.accessibilityElements.firstObject accessibilityLabel], @"hello",
                        @"Container accessibility label override broken %@",
                        [node.view.accessibilityElements.firstObject accessibilityLabel]);
}

- (void)testAccessibilityLayerBackedContainerWithinAccessibilityContainer
{
  ASDisplayNode *container = [[ASDisplayNode alloc] init];
  container.frame = CGRectMake(50, 50, 200, 600);
  container.isAccessibilityContainer = YES;

  ASDisplayNode *subContainer = [[ASDisplayNode alloc] init];
  subContainer.frame = CGRectMake(50, 50, 200, 600);

  subContainer.layerBacked = YES;
  subContainer.isAccessibilityContainer = YES;
  [container addSubnode:subContainer];

  ASTextNode *text1 = [[ASTextNode alloc] init];
  text1.attributedText = [[NSAttributedString alloc] initWithString:@"hello"];
  text1.frame = CGRectMake(50, 100, 200, 200);
  text1.layerBacked = YES;
  [subContainer addSubnode:text1];

  ASTextNode *text2 = [[ASTextNode alloc] init];
  text2.attributedText = [[NSAttributedString alloc] initWithString:@"world"];
  text2.frame = CGRectMake(50, 300, 200, 200);
  text2.layerBacked = YES;
  [subContainer addSubnode:text2];

  NSArray<UIAccessibilityElement *> *accessibilityElements = container.view.accessibilityElements;
  XCTAssertEqual(accessibilityElements.count, 2);
  XCTAssertEqualObjects(accessibilityElements[1].accessibilityLabel, @"hello, world");
}

- (void)testAccessibilityNonLayerbackedNodesOperationInNonContainer
{
  ASDisplayNode *container = [[ASDisplayNode alloc] init];
  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 560)];
  [window addSubnode:container];
  [window makeKeyAndVisible];

  container.frame = CGRectMake(50, 50, 200, 600);
  container.backgroundColor = [UIColor grayColor];
  // Do any additional setup after loading the view, typically from a nib.
  ASTextNode *text1 = [[ASTextNode alloc] init];
  text1.attributedText = [[NSAttributedString alloc] initWithString:@"hello"];
  text1.frame = CGRectMake(50, 100, 200, 200);
  [container addSubnode:text1];
  [container layoutIfNeeded];
  [container.layer displayIfNeeded];
  NSArray<UIAccessibilityElement *> *elements = container.view.accessibilityElements;
  XCTAssertTrue(elements.count == 1);
  XCTAssertTrue([[elements.firstObject accessibilityLabel] isEqualToString:@"hello"]);
  ASTextNode *text2 = [[ASTextNode alloc] init];
  text2.attributedText = [[NSAttributedString alloc] initWithString:@"world"];
  text2.frame = CGRectMake(50, 300, 200, 200);
  [container addSubnode:text2];
  [container layoutIfNeeded];
  [container.layer displayIfNeeded];
   ASCATransactionQueueWait(nil);
  NSArray<UIAccessibilityElement *> *updatedElements = container.view.accessibilityElements;
  XCTAssertTrue(updatedElements.count == 2);
  XCTAssertTrue([[updatedElements.firstObject accessibilityLabel] isEqualToString:@"hello"]);
  XCTAssertTrue([[updatedElements.lastObject accessibilityLabel] isEqualToString:@"world"]);
  ASTextNode *text3 = [[ASTextNode alloc] init];
  text3.attributedText = [[NSAttributedString alloc] initWithString:@"!!!!"];
  text3.frame = CGRectMake(50, 400, 200, 100);
  [text2 addSubnode:text3];
  [container layoutIfNeeded];
  [container.layer displayIfNeeded];
  ASCATransactionQueueWait(nil);
  NSArray<UIAccessibilityElement *> *updatedElements2 = container.view.accessibilityElements;
  //text3 won't be read out cause it's overshadowed by text2
  XCTAssertTrue(updatedElements2.count == 2);
  XCTAssertTrue([[updatedElements2.firstObject accessibilityLabel] isEqualToString:@"hello"]);
  XCTAssertTrue([[updatedElements2.lastObject accessibilityLabel] isEqualToString:@"world"]);
}

#pragma mark -
#pragma mark UIAccessibilityAction Forwarding

- (void)testActionForwarding {
  ASDisplayNode *node = [ASDisplayNode new];
  UIView *view = node.view;
  
  id mockNode = OCMPartialMock(node);
  
  OCMExpect([mockNode accessibilityActivate]);
  [view accessibilityActivate];
  
  OCMExpect([mockNode accessibilityIncrement]);
  [view accessibilityIncrement];

  OCMExpect([mockNode accessibilityDecrement]);
  [view accessibilityDecrement];

  OCMExpect([mockNode accessibilityScroll:UIAccessibilityScrollDirectionDown]);
  [view accessibilityScroll:UIAccessibilityScrollDirectionDown];

  OCMExpect([mockNode accessibilityPerformEscape]);
  [view accessibilityPerformEscape];

  OCMExpect([mockNode accessibilityPerformMagicTap]);
  [view accessibilityPerformMagicTap];

  OCMVerifyAll(mockNode);
}

@end
