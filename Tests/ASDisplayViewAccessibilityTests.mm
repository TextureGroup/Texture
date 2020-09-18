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

#import <AsyncDisplayKit/_ASDisplayView.h>
#import <AsyncDisplayKit/_ASDisplayViewAccessiblity.h>
#import <AsyncDisplayKit/ASButtonNode.h>
#import <AsyncDisplayKit/ASDisplayNode.h>
#import <AsyncDisplayKit/ASDisplayNode+Beta.h>
#import <AsyncDisplayKit/ASTextNode.h>
#import <AsyncDisplayKit/ASConfiguration.h>
#import <AsyncDisplayKit/ASConfigurationInternal.h>
#import <AsyncDisplayKit/ASScrollNode.h>
#import <AsyncDisplayKit/ASDKViewController.h>
#import <OCMock/OCMock.h>
#import "ASDisplayNodeTestsHelper.h"

extern void SortAccessibilityElements(NSMutableArray *elements);

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
  
  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 560)];
  [window addSubnode:node];
  [window makeKeyAndVisible];

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

  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 560)];
  [window addSubnode:node];
  [window makeKeyAndVisible];

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

  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 560)];
  [window addSubnode:node];
  [window makeKeyAndVisible];

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
  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 560)];
  [window addSubnode:container];
  [window makeKeyAndVisible];

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

#pragma mark -
#pragma mark AccessibilityElements

// dummy action for a button
- (void)fakeSelector:(id)sender { }

- (void)testThatAccessibilityElementsWorks {
  
  ASDisplayNode *containerNode = [[ASDisplayNode alloc] init];
  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 560)];
  [window addSubnode:containerNode];
  [window makeKeyAndVisible];
  
  containerNode.frame = CGRectMake(0, 0, 100, 200);

  ASTextNode *label = [[ASTextNode alloc] init];
  label.attributedText = [[NSAttributedString alloc] initWithString:@"test label"];
  label.frame = CGRectMake(0, 0, 100, 20);
  
  ASButtonNode *button = [[ASButtonNode alloc] init];
  [button setTitle:@"tap me" withFont:[UIFont systemFontOfSize:17] withColor:nil forState:UIControlStateNormal];
  [button addTarget:self action:@selector(fakeSelector:) forControlEvents:ASControlNodeEventTouchUpInside];
  button.frame = CGRectMake(0, 25, 100, 20);
  
  [containerNode addSubnode:label];
  [containerNode addSubnode:button];
  
  // force load
  __unused UIView *view = containerNode.view;
  
  NSArray *elements = [containerNode.view accessibilityElements];
  XCTAssertTrue(elements.count == 2);
  XCTAssertEqual([elements.firstObject asyncdisplaykit_node], label);
  XCTAssertEqual([elements.lastObject asyncdisplaykit_node], button);
}

- (void)testThatAccessibilityElementsOverrideWorks {
  ASDisplayNode *containerNode = [[ASDisplayNode alloc] init];
  containerNode.frame = CGRectMake(0, 0, 100, 200);

  ASTextNode *label = [[ASTextNode alloc] init];
  label.attributedText = [[NSAttributedString alloc] initWithString:@"test label"];
  label.frame = CGRectMake(0, 0, 100, 20);
  
  ASButtonNode *button = [[ASButtonNode alloc] init];
  [button setTitle:@"tap me" withFont:[UIFont systemFontOfSize:17] withColor:nil forState:UIControlStateNormal];
  [button addTarget:self action:@selector(fakeSelector:) forControlEvents:ASControlNodeEventTouchUpInside];
  button.frame = CGRectMake(0, 25, 100, 20);
  
  [containerNode addSubnode:label];
  [containerNode addSubnode:button];
  containerNode.accessibilityElements = @[ label ];
  
  // force load
  __unused UIView *view = containerNode.view;
  
  NSArray *elements = [containerNode.view accessibilityElements];
  XCTAssertTrue(elements.count == 1);
  XCTAssertEqual(elements.firstObject, label);
}

- (void)testHiddenAccessibilityElements {
  ASDisplayNode *containerNode = [[ASDisplayNode alloc] init];
  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 560)];
  [window addSubnode:containerNode];
  [window makeKeyAndVisible];

  containerNode.frame = CGRectMake(0, 0, 100, 200);

  ASTextNode *label = [[ASTextNode alloc] init];
  label.attributedText = [[NSAttributedString alloc] initWithString:@"test label"];
  label.frame = CGRectMake(0, 0, 100, 20);

  ASTextNode *hiddenLabel = [[ASTextNode alloc] init];
  hiddenLabel.attributedText = [[NSAttributedString alloc] initWithString:@"hidden label"];
  hiddenLabel.frame = CGRectMake(0, 24, 100, 20);
  hiddenLabel.hidden = YES;
  
  [containerNode addSubnode:label];
  [containerNode addSubnode:hiddenLabel];
  
  // force load
  __unused UIView *view = containerNode.view;
  
  NSArray *elements = [containerNode.view accessibilityElements];
  XCTAssertTrue(elements.count == 1);
  XCTAssertEqual(elements.firstObject, label.view);
}

- (void)testTransparentAccessibilityElements {
  ASDisplayNode *containerNode = [[ASDisplayNode alloc] init];
  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 560)];
  [window addSubnode:containerNode];
  [window makeKeyAndVisible];
  containerNode.frame = CGRectMake(0, 0, 100, 200);

  ASTextNode *label = [[ASTextNode alloc] init];
  label.attributedText = [[NSAttributedString alloc] initWithString:@"test label"];
  label.frame = CGRectMake(0, 0, 100, 20);

  ASTextNode *hiddenLabel = [[ASTextNode alloc] init];
  hiddenLabel.attributedText = [[NSAttributedString alloc] initWithString:@"hidden label"];
  hiddenLabel.frame = CGRectMake(0, 24, 100, 20);
  hiddenLabel.alpha = 0.0;
  
  [containerNode addSubnode:label];
  [containerNode addSubnode:hiddenLabel];
  
  // force load
  __unused UIView *view = containerNode.view;
  
  NSArray *elements = [containerNode.view accessibilityElements];
  XCTAssertTrue(elements.count == 1);
  XCTAssertEqual(elements.firstObject, label.view);
}

- (void)testAccessibilityElementsNotInAppWindow {
  
  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 568)];
  ASDisplayNode *node = [[ASDisplayNode alloc] init];
  node.automaticallyManagesSubnodes = YES;
  
  ASDKViewController *vc = [[ASDKViewController alloc] initWithNode:node];
  window.rootViewController = vc;
  [window makeKeyAndVisible];
  [window layoutIfNeeded];

  CGSize windowSize = window.frame.size;
  ASTextNode *label = [[ASTextNode alloc] init];
  label.attributedText = [[NSAttributedString alloc] initWithString:@"on screen"];
  label.frame = CGRectMake(0, 0, 100, 20);

  ASTextNode *partiallyOnScreenNodeY = [[ASTextNode alloc] init];
  partiallyOnScreenNodeY.attributedText = [[NSAttributedString alloc] initWithString:@"partially on screen y"];
  partiallyOnScreenNodeY.frame = CGRectMake(0, windowSize.height - 10, 100, 20);

  ASTextNode *partiallyOnScreenNodeX = [[ASTextNode alloc] init];
  partiallyOnScreenNodeX.attributedText = [[NSAttributedString alloc] initWithString:@"partially on screen x"];
  partiallyOnScreenNodeX.frame = CGRectMake(windowSize.width - 10, 100, 100, 20);

  ASTextNode *offScreenNodeY = [[ASTextNode alloc] init];
  offScreenNodeY.attributedText = [[NSAttributedString alloc] initWithString:@"off screen y"];
  offScreenNodeY.frame = CGRectMake(0, windowSize.height + 10, 100, 20);

  ASTextNode *offScreenNodeX = [[ASTextNode alloc] init];
  offScreenNodeX.attributedText = [[NSAttributedString alloc] initWithString:@"off screen x"];
  offScreenNodeX.frame = CGRectMake(windowSize.width + 1, 200, 100, 20);

  ASTextNode *offScreenNode = [[ASTextNode alloc] init];
  offScreenNode.attributedText = [[NSAttributedString alloc] initWithString:@"off screen"];
  offScreenNode.frame = CGRectMake(windowSize.width + 1, windowSize.height + 1, 100, 20);

  [node addSubnode:label];
  [node addSubnode:partiallyOnScreenNodeY];
  [node addSubnode:partiallyOnScreenNodeX];
  [node addSubnode:offScreenNodeY];
  [node addSubnode:offScreenNodeX];
  [node addSubnode:offScreenNode];

  NSArray *elements = [node.view accessibilityElements];
  XCTAssertTrue(elements.count == 3);
  XCTAssertTrue([elements containsObject:label.view]);
  XCTAssertTrue([elements containsObject:partiallyOnScreenNodeX.view]);
  XCTAssertTrue([elements containsObject:partiallyOnScreenNodeY.view]);
}

- (void)testAccessibilityElementsNotInAppWindowButInScrollView {
  
  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 568)];
  ASScrollNode *node = [[ASScrollNode alloc] init];
  node.automaticallyManagesSubnodes = YES;
  
  ASDKViewController *vc = [[ASDKViewController alloc] initWithNode:node];
  window.rootViewController = vc;
  [window makeKeyAndVisible];
  [window layoutIfNeeded];

  CGSize windowSize = window.frame.size;
  node.view.contentSize = CGSizeMake(window.frame.size.width, window.frame.size.height * 2.0);
  ASTextNode *label = [[ASTextNode alloc] init];
  label.attributedText = [[NSAttributedString alloc] initWithString:@"on screen"];
  label.frame = CGRectMake(0, 0, 100, 20);

  ASTextNode *partiallyOnScreenNodeY = [[ASTextNode alloc] init];
  partiallyOnScreenNodeY.attributedText = [[NSAttributedString alloc] initWithString:@"partially on screen y"];
  partiallyOnScreenNodeY.frame = CGRectMake(0, windowSize.height - 10, 100, 20);

  ASTextNode *partiallyOnScreenNodeX = [[ASTextNode alloc] init];
  partiallyOnScreenNodeX.attributedText = [[NSAttributedString alloc] initWithString:@"partially on screen x"];
  partiallyOnScreenNodeX.frame = CGRectMake(windowSize.width - 10, 100, 100, 20);

  ASTextNode *offScreenNodeY = [[ASTextNode alloc] init];
  offScreenNodeY.attributedText = [[NSAttributedString alloc] initWithString:@"off screen y"];
  offScreenNodeY.frame = CGRectMake(0, windowSize.height + 10, 100, 20);

  ASTextNode *offScreenNodeX = [[ASTextNode alloc] init];
  offScreenNodeX.attributedText = [[NSAttributedString alloc] initWithString:@"off screen x"];
  offScreenNodeX.frame = CGRectMake(windowSize.width + 1, 200, 100, 20);

  ASTextNode *offScreenNode = [[ASTextNode alloc] init];
  offScreenNode.attributedText = [[NSAttributedString alloc] initWithString:@"off screen"];
  offScreenNode.frame = CGRectMake(windowSize.width + 1, windowSize.height + 1, 100, 20);

  [node addSubnode:label];
  [node addSubnode:partiallyOnScreenNodeY];
  [node addSubnode:partiallyOnScreenNodeX];
  [node addSubnode:offScreenNodeY];
  [node addSubnode:offScreenNodeX];
  [node addSubnode:offScreenNode];

  NSArray *elements = [node.view accessibilityElements];
  XCTAssertTrue(elements.count == 6);
  XCTAssertTrue([elements containsObject:label.view]);
  XCTAssertTrue([elements containsObject:partiallyOnScreenNodeX.view]);
  XCTAssertTrue([elements containsObject:partiallyOnScreenNodeY.view]);
  XCTAssertTrue([elements containsObject:offScreenNodeY.view]);
  XCTAssertTrue([elements containsObject:offScreenNodeX.view]);
  XCTAssertTrue([elements containsObject:offScreenNode.view]);
}

- (void)testAccessibilitySort {
  ASDisplayNode *node1 = [[ASDisplayNode alloc] init];
  node1.accessibilityFrame = CGRectMake(0, 0, 50, 200);
  
  ASDisplayNode *node2 = [[ASDisplayNode alloc] init];
  node2.accessibilityFrame = CGRectMake(0, 0, 100, 200);

  ASDisplayNode *node3 = [[ASDisplayNode alloc] init];
  node3.accessibilityFrame = CGRectMake(0, 1, 100, 200);

  ASDisplayNode *node4 = [[ASDisplayNode alloc] init];
  node4.accessibilityFrame = CGRectMake(1, 1, 100, 200);
  
  NSMutableArray *elements = [@[node2, node4, node3, node1] mutableCopy];
  SortAccessibilityElements(elements);
  XCTAssertEqual(elements[0], node1);
  XCTAssertEqual(elements[1], node2);
  XCTAssertEqual(elements[2], node3);
  XCTAssertEqual(elements[3], node4);
}

- (void)testCustomAccessibilitySort {
  
  // silly custom sorter that puts items with the largest height first.
  setUserDefinedAccessibilitySortComparator(^NSComparisonResult(NSObject *a, NSObject *b) {
    if (a.accessibilityFrame.size.height == b.accessibilityFrame.size.height) {
      return NSOrderedSame;
    }
    return a.accessibilityFrame.size.height > b.accessibilityFrame.size.height ? NSOrderedAscending : NSOrderedDescending;
  });
  
  ASDisplayNode *node1 = [[ASDisplayNode alloc] init];
  node1.accessibilityFrame = CGRectMake(0, 0, 50, 300);
  
  ASDisplayNode *node2 = [[ASDisplayNode alloc] init];
  node2.accessibilityFrame = CGRectMake(0, 0, 100, 250);

  ASDisplayNode *node3 = [[ASDisplayNode alloc] init];
  node3.accessibilityFrame = CGRectMake(0, 0, 100, 200);

  ASDisplayNode *node4 = [[ASDisplayNode alloc] init];
  node4.accessibilityFrame = CGRectMake(0, 0, 100, 150);
  
  NSMutableArray *elements = [@[node2, node4, node3, node1] mutableCopy];
  SortAccessibilityElements(elements);
  XCTAssertEqual(elements[0], node1);
  XCTAssertEqual(elements[1], node2);
  XCTAssertEqual(elements[2], node3);
  XCTAssertEqual(elements[3], node4);
}

- (void)testSubnodeIsModal {
  
  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 568)];
  ASDisplayNode *node = [[ASDisplayNode alloc] init];
  node.automaticallyManagesSubnodes = YES;
  
  ASDKViewController *vc = [[ASDKViewController alloc] initWithNode:node];
  window.rootViewController = vc;
  [window makeKeyAndVisible];
  [window layoutIfNeeded];

  ASTextNode *label1 = [[ASTextNode alloc] init];
  label1.attributedText = [[NSAttributedString alloc] initWithString:@"label1"];
  label1.frame = CGRectMake(10, 80, 300, 20);
  [node addSubnode:label1];
  
  ASTextNode *label2 = [[ASTextNode alloc] init];
  label2.attributedText = [[NSAttributedString alloc] initWithString:@"label2"];
  label2.frame = CGRectMake(10, CGRectGetMaxY(label1.frame) + 8, 300, 20);
  [node addSubnode:label2];
  
  ASDisplayNode *modalNode = [[ASDisplayNode alloc] init];
  modalNode.frame = CGRectInset(CGRectUnion(label1.frame, label2.frame), -8, -8);
  
  // This is kind of cheating. When voice over is activated, the modal node will end up reporting that it
  // has 1 accessibilityElement. But getting that to happen in a unit test doesn't seem possible.
  id modalMock = OCMPartialMock(modalNode);
  OCMStub([modalMock accessibilityElementCount]).andReturn(1);
  [node addSubnode:modalMock];
  
  ASTextNode *label3 = [[ASTextNode alloc] init];
  label3.attributedText = [[NSAttributedString alloc] initWithString:@"label6"];
  label3.frame = CGRectMake(8, 4, 200, 20);

  [modalNode addSubnode:label3];
  modalNode.accessibilityViewIsModal = YES;
  NSArray *elements = [node.view accessibilityElements];
  XCTAssertTrue(elements.count == 1);
  XCTAssertTrue([elements containsObject:modalNode.view]);
}

- (void)testMultipleSubnodesAreModal {
  
  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 568)];
  ASDisplayNode *node = [[ASDisplayNode alloc] init];
  node.automaticallyManagesSubnodes = YES;
  
  ASDKViewController *vc = [[ASDKViewController alloc] initWithNode:node];
  window.rootViewController = vc;
  [window makeKeyAndVisible];
  [window layoutIfNeeded];

  ASTextNode *label1 = [[ASTextNode alloc] init];
  label1.attributedText = [[NSAttributedString alloc] initWithString:@"label1"];
  label1.frame = CGRectMake(10, 80, 300, 20);
  [node addSubnode:label1];
  
  ASTextNode *label2 = [[ASTextNode alloc] init];
  label2.attributedText = [[NSAttributedString alloc] initWithString:@"label2"];
  label2.frame = CGRectMake(10, CGRectGetMaxY(label1.frame) + 8, 300, 20);
  [node addSubnode:label2];
  
  ASDisplayNode *modalNode1 = [[ASDisplayNode alloc] init];
  modalNode1.frame = CGRectInset(CGRectUnion(label1.frame, label2.frame), -8, -8);
  
  // This is kind of cheating. When voice over is activated, the modal node will end up reporting that it
  // has 1 accessibilityElement. But getting that to happen in a unit test doesn't seem possible.
  id modalMock1 = OCMPartialMock(modalNode1);
  OCMStub([modalMock1 accessibilityElementCount]).andReturn(1);

  ASTextNode *label3 = [[ASTextNode alloc] init];
  label3.attributedText = [[NSAttributedString alloc] initWithString:@"label6"];
  label3.frame = CGRectMake(8, 4, 200, 20);
  [modalNode1 addSubnode:label3];
  modalNode1.accessibilityViewIsModal = YES;

  ASDisplayNode *modalNode2 = [[ASDisplayNode alloc] init];
  modalNode2.frame = CGRectOffset(modalNode1.frame, 0, modalNode1.frame.size.height + 10);
  id modalMock2 = OCMPartialMock(modalNode2);
  OCMStub([modalMock2 accessibilityElementCount]).andReturn(1);

  ASTextNode *label4 = [[ASTextNode alloc] init];
  label4.attributedText = [[NSAttributedString alloc] initWithString:@"label6"];
  label4.frame = CGRectMake(8, 4, 200, 20);
  [modalNode2 addSubnode:label4];
  modalNode2.accessibilityViewIsModal = YES;
  
  // add modalNode1 last, and assert that it is the one that appears in accessibilityElements
  // (UIKit uses the last modal subview in subviews as the modal element).
  [node addSubnode:modalMock2];
  [node addSubnode:modalMock1];

  NSArray *elements = [node.view accessibilityElements];
  XCTAssertTrue(elements.count == 1);
  XCTAssertTrue([elements containsObject:modalNode1.view]);
  
  // let's change which node is modal and make sure the elements get updated.
  modalNode1.accessibilityViewIsModal = NO;
  elements = [node.view accessibilityElements];
  XCTAssertTrue(elements.count == 1);
  XCTAssertTrue([elements containsObject:modalNode2.view]);
}

- (void)testAccessibilityElementsHidden {
  
  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 568)];
  ASDisplayNode *node = [[ASDisplayNode alloc] init];
  node.automaticallyManagesSubnodes = YES;
  
  ASDKViewController *vc = [[ASDKViewController alloc] initWithNode:node];
  window.rootViewController = vc;
  [window makeKeyAndVisible];
  [window layoutIfNeeded];

  ASTextNode *label1 = [[ASTextNode alloc] init];
  label1.attributedText = [[NSAttributedString alloc] initWithString:@"on screen"];
  label1.frame = CGRectMake(0, 0, 100, 20);

  ASTextNode *label2 = [[ASTextNode alloc] init];
  label2.attributedText = [[NSAttributedString alloc] initWithString:@"partially on screen y"];
  label2.frame = CGRectMake(0, 20, 100, 20);
  
  [node addSubnode:label1];
  [node addSubnode:label2];
  
  NSArray *elements = [node.view accessibilityElements];
  XCTAssertTrue(elements.count == 2);
  XCTAssertTrue([elements containsObject:label1.view]);
  XCTAssertTrue([elements containsObject:label2.view]);
  
  node.accessibilityElementsHidden = YES;
  elements = [node.view accessibilityElements];
  XCTAssertTrue(elements.count == 0);

  node.accessibilityElementsHidden = NO;
  elements = [node.view accessibilityElements];
  XCTAssertTrue(elements.count == 2);
  XCTAssertTrue([elements containsObject:label1.view]);
  XCTAssertTrue([elements containsObject:label2.view]);
}

@end
