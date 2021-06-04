//
//  ASDisplayNodeYoga2Tests.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <XCTest/XCTest.h>
#import "ASXCTExtensions.h"
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import <AsyncDisplayKit/ASDisplayNode+Beta.h>
#import <AsyncDisplayKit/ASDisplayNodeInternal.h>
#import <AsyncDisplayKit/ASDisplayNode+FrameworkPrivate.h>
#import <AsyncDisplayKit/ASDisplayNode+Yoga2.h>

@interface ASDisplayNodeYoga2TestNode : ASDisplayNode
@property (assign) BOOL test_isFlattenable;
@end

@implementation ASDisplayNodeYoga2TestNode
-  (BOOL)isFlattenable {
  return _test_isFlattenable;
}

- (CGSize)calculateSizeThatFits:(CGSize)constrainedSize {
  return CGSizeMake(50, 50);
}

@end

@interface ASDisplayNodeYoga2Tests : XCTestCase
@end

@implementation ASDisplayNodeYoga2Tests

- (ASDisplayNode *)newNode {
  ASDisplayNode *node = [[ASDisplayNode alloc] init];
  [node enableYoga];
  return node;
}

- (ASDisplayNodeYoga2TestNode *)newYoga2TestNode {
  ASDisplayNodeYoga2TestNode *node = [[ASDisplayNodeYoga2TestNode alloc] init];
  [node enableYoga];
  node.shouldSuppressYogaCustomMeasure = YES;
  return node;
}

- (id<CAAction>)opacityAction {
  CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
  animation.duration = 0.0;
  animation.toValue = @(0.0);
  return animation;
}

// Tests measure function decide node's final size.
- (void)testMeasureFunctionRegister {
  ASDisplayNode *container = [self newNode];
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
  container.frame = CGRectMake(0, 0, 100, 100);
  [view addSubnode:container];

  ASDisplayNode *node = [self newYoga2TestNode];
  node.shouldSuppressYogaCustomMeasure = NO;
  container.style.alignItems = ASStackLayoutAlignItemsCenter;
  [container addYogaChild:node];
  [view layoutIfNeeded];
  XCTAssertTrue(CGSizeEqualToSize(node.frame.size, CGSizeMake(50, 50)));
}

// Tests remove measure function and layout is relying on yoga styles.
- (void)testMeasureFunctionUnregister {
  ASDisplayNode *container = [self newNode];
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
  container.frame = CGRectMake(0, 0, 100, 100);
  [view addSubnode:container];
  ASDisplayNode *node = [self newYoga2TestNode];
  node.shouldSuppressYogaCustomMeasure = NO;
  container.style.alignItems = ASStackLayoutAlignItemsCenter;
  [container addYogaChild:node];
  [container layoutIfNeeded];
  XCTAssertTrue(CGSizeEqualToSize(node.frame.size, CGSizeMake(50, 50)));

  node.shouldSuppressYogaCustomMeasure = YES;
  node.style.minWidth = ASDimensionMake(20);
  node.style.minHeight = ASDimensionMake(20);
  [container layoutIfNeeded];
  XCTAssertTrue(CGSizeEqualToSize(node.frame.size, CGSizeMake(20, 20)));
}

- (void)testInsertNode {
  ASDisplayNode *node = [self newNode];
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  [view addSubnode:node];

  ASDisplayNode *subnode = [self newNode];
  [node addYogaChild:subnode];
  [view layoutIfNeeded];

  ASDisplayNode *insertedSubnode = [self newNode];
  [node addYogaChild:insertedSubnode];
  [view layoutIfNeeded];

  NSArray *expected = @[ subnode, insertedSubnode ];
  XCTAssertEqualObjects(node.subnodes, expected);
}

- (void)testRemoveNode {
  ASDisplayNode *node = [self newNode];
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  [view addSubnode:node];

  ASDisplayNode *subnode1 = [self newNode];
  [node addYogaChild:subnode1];
  ASDisplayNode *subnode2 = [self newNode];
  [node addYogaChild:subnode2];
  [view layoutIfNeeded];

  [node removeYogaChild:subnode1];
  [view layoutIfNeeded];

  NSArray *expected = @[ subnode2 ];
  XCTAssertEqualObjects(node.subnodes, expected);
}

- (void)testDeferredRemoveNode {
  ASDisplayNode *node = [self newNode];
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  [view addSubnode:node];

  ASDisplayNode *subnode1 = [self newNode];
  subnode1.disappearanceActions = @{ @"opacity": [self opacityAction] };
  [node addYogaChild:subnode1];
  ASDisplayNode *subnode2 = [self newNode];
  [node addYogaChild:subnode2];
  [view layoutIfNeeded];

  [node removeYogaChild:subnode1];

  XCTestExpectation *expectation = [self expectationWithDescription:@"Node removed after action"];
  [CATransaction begin];
  [CATransaction setCompletionBlock:^{
    NSArray *expected = @[ subnode2 ];
    XCTAssertEqualObjects(node.subnodes, expected);
    [expectation fulfill];
  }];
  [view layoutIfNeeded];

  NSArray *expected = @[ subnode1, subnode2 ];
  XCTAssertEqualObjects(node.subnodes, expected);

  [CATransaction commit];

  [self waitForExpectations:@[expectation] timeout:2.0];
}

- (void)testMoveNode {
  ASDisplayNode *node = [self newNode];
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  [view addSubnode:node];

  ASDisplayNode *subnode1 = [self newNode];
  [node addYogaChild:subnode1];
  ASDisplayNode *subnode2 = [self newNode];
  [node addYogaChild:subnode2];
  [view layoutIfNeeded];

  [node removeYogaChild:subnode1];
  [node addYogaChild:subnode1];
  [view layoutIfNeeded];

  NSArray *expected = @[ subnode2, subnode1 ];
  XCTAssertEqualObjects(node.subnodes, expected);
}

- (void)testInsertRemoveNodes {
  ASDisplayNode *node = [self newNode];
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  [view addSubnode:node];

  ASDisplayNode *subnode1 = [self newNode];
  [node addYogaChild:subnode1];
  ASDisplayNode *subnode2 = [self newNode];
  [node addYogaChild:subnode2];
  [view layoutIfNeeded];

  [node removeYogaChild:subnode1];
  ASDisplayNode *subnode3 = [self newNode];
  [node addYogaChild:subnode3];
  [view layoutIfNeeded];

  NSArray *expected = @[ subnode2, subnode3 ];
  XCTAssertEqualObjects(node.subnodes, expected);
}

- (void)testInsertDeferredRemoveNodes {
  ASDisplayNode *node = [self newNode];
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  [view addSubnode:node];

  ASDisplayNode *subnode1 = [self newNode];
  subnode1.disappearanceActions = @{ @"opacity": [self opacityAction] };
  [node addYogaChild:subnode1];
  ASDisplayNode *subnode2 = [self newNode];
  [node addYogaChild:subnode2];
  [view layoutIfNeeded];

  [node removeYogaChild:subnode1];
  ASDisplayNode *subnode3 = [self newNode];
  [node addYogaChild:subnode3];

  XCTestExpectation *expectation = [self expectationWithDescription:@"Node removed after action"];
  [CATransaction begin];
  [CATransaction setCompletionBlock:^{
    NSArray *expected = @[ subnode2, subnode3 ];
    XCTAssertEqualObjects(node.subnodes, expected);
    [expectation fulfill];
  }];
  [view layoutIfNeeded];

  NSArray *expected = @[ subnode1, subnode2, subnode3 ];
  XCTAssertEqualObjects(node.subnodes, expected);

  [CATransaction commit];

  [self waitForExpectations:@[expectation] timeout:2.0];
}

- (void)testInsertMoveNodes {
  ASDisplayNode *node = [self newNode];
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  [view addSubnode:node];

  ASDisplayNode *subnode1 = [self newNode];
  [node addYogaChild:subnode1];
  ASDisplayNode *subnode2 = [self newNode];
  [node addYogaChild:subnode2];
  [view layoutIfNeeded];

  [node removeYogaChild:subnode1];
  [node addYogaChild:subnode1];
  ASDisplayNode *subnode3 = [self newNode];
  [node addYogaChild:subnode3];
  [view layoutIfNeeded];

  NSArray *expected = @[ subnode2, subnode1, subnode3 ];
  XCTAssertEqualObjects(node.subnodes, expected);
}

- (void)testRemoveAndDeferredRemoveNodes {
  ASDisplayNode *node = [self newNode];
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  [view addSubnode:node];

  ASDisplayNode *subnode1 = [self newNode];
  subnode1.disappearanceActions = @{ @"opacity": [self opacityAction] };
  [node addYogaChild:subnode1];
  ASDisplayNode *subnode2 = [self newNode];
  [node addYogaChild:subnode2];
  ASDisplayNode *subnode3 = [self newNode];
  [node addYogaChild:subnode3];
  [view layoutIfNeeded];

  [node removeYogaChild:subnode1];
  [node removeYogaChild:subnode2];

  XCTestExpectation *expectation = [self expectationWithDescription:@"Node removed after action"];
  [CATransaction begin];
  [CATransaction setCompletionBlock:^{
    NSArray *expected = @[ subnode3 ];
    XCTAssertEqualObjects(node.subnodes, expected);
    [expectation fulfill];
  }];
  [view layoutIfNeeded];

  NSArray *expected = @[ subnode1, subnode3 ];
  XCTAssertEqualObjects(node.subnodes, expected);

  [CATransaction commit];

  [self waitForExpectations:@[expectation] timeout:2.0];
}

- (void)testRemoveAndMoveNodes {
  ASDisplayNode *node = [self newNode];
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  [view addSubnode:node];

  ASDisplayNode *subnode1 = [self newNode];
  [node addYogaChild:subnode1];
  ASDisplayNode *subnode2 = [self newNode];
  [node addYogaChild:subnode2];
  ASDisplayNode *subnode3 = [self newNode];
  [node addYogaChild:subnode3];
  [view layoutIfNeeded];

  [node removeYogaChild:subnode1];
  [node removeYogaChild:subnode2];
  [node addYogaChild:subnode2];
  [view layoutIfNeeded];

  NSArray *expected = @[ subnode3, subnode2 ];
  XCTAssertEqualObjects(node.subnodes, expected);
}

- (void)testMoveAndDeferredRemoveNodes {
  ASDisplayNode *node = [self newNode];
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  [view addSubnode:node];

  ASDisplayNode *subnode1 = [self newNode];
  subnode1.disappearanceActions = @{ @"opacity": [self opacityAction] };
  [node addYogaChild:subnode1];
  ASDisplayNode *subnode2 = [self newNode];
  [node addYogaChild:subnode2];
  ASDisplayNode *subnode3 = [self newNode];
  [node addYogaChild:subnode3];
  [view layoutIfNeeded];

  [node removeYogaChild:subnode1];
  [node removeYogaChild:subnode2];
  [node addYogaChild:subnode2];

  XCTestExpectation *expectation = [self expectationWithDescription:@"Node removed after action"];
  [CATransaction begin];
  [CATransaction setCompletionBlock:^{
    NSArray *expected = @[ subnode3, subnode2 ];
    XCTAssertEqualObjects(node.subnodes, expected);
    [expectation fulfill];
  }];
  [view layoutIfNeeded];

  NSArray *expected = @[ subnode3, subnode2, subnode1 ];
  XCTAssertEqualObjects(node.subnodes, expected);

  [CATransaction commit];

  [self waitForExpectations:@[expectation] timeout:2.0];
}

- (void)testCancelDeferredRemoveNodeByInserting {
  ASDisplayNode *node = [self newNode];
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  [view addSubnode:node];

  ASDisplayNode *subnode1 = [self newNode];
  subnode1.disappearanceActions = @{ @"opacity": [self opacityAction] };
  [node addYogaChild:subnode1];
  ASDisplayNode *subnode2 = [self newNode];
  [node addYogaChild:subnode2];
  ASDisplayNode *subnode3 = [self newNode];
  [node addYogaChild:subnode3];
  [view layoutIfNeeded];

  [node removeYogaChild:subnode1];

  XCTestExpectation *expectation = [self expectationWithDescription:@"Node not removed after action"];
  [CATransaction begin];
  [CATransaction setCompletionBlock:^{
    NSArray *expected = @[ subnode1, subnode2, subnode3 ];
    XCTAssertEqualObjects(node.subnodes, expected);
    [expectation fulfill];
  }];
  [view layoutIfNeeded];

  NSArray *expected = @[ subnode1, subnode2, subnode3 ];
  XCTAssertEqualObjects(node.subnodes, expected);

  // Cancel node removal
  [node insertYogaChild:subnode1 atIndex:0];
  [view layoutIfNeeded];

  [CATransaction commit];

  [self waitForExpectations:@[expectation] timeout:2.0];
}

- (void)testCancelDeferredRemoveNodeByMoving {
  ASDisplayNode *node = [self newNode];
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  [view addSubnode:node];

  ASDisplayNode *subnode1 = [self newNode];
  subnode1.disappearanceActions = @{ @"opacity": [self opacityAction] };
  [node addYogaChild:subnode1];
  ASDisplayNode *subnode2 = [self newNode];
  [node addYogaChild:subnode2];
  ASDisplayNode *subnode3 = [self newNode];
  [node addYogaChild:subnode3];
  [view layoutIfNeeded];

  [node removeYogaChild:subnode1];

  XCTestExpectation *expectation = [self expectationWithDescription:@"Node not removed after action"];
  [CATransaction begin];
  [CATransaction setCompletionBlock:^{
    NSArray *expected = @[ subnode2, subnode3, subnode1 ];
    XCTAssertEqualObjects(node.subnodes, expected);
    [expectation fulfill];
  }];
  [view layoutIfNeeded];

  NSArray *expected = @[ subnode1, subnode2, subnode3 ];
  XCTAssertEqualObjects(node.subnodes, expected);

  // Cancel node removal by moving previously-removed node to the end
  [node addYogaChild:subnode1];
  [view layoutIfNeeded];

  [CATransaction commit];

  [self waitForExpectations:@[expectation] timeout:2.0];
}

- (void)testInsertDeferredRemoveMultipleNodes {
  ASDisplayNode *node = [self newNode];
  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  [view addSubnode:node];

  ASDisplayNode *subnode1 = [self newNode];
  subnode1.disappearanceActions = @{ @"opacity": [self opacityAction] };
  [node addYogaChild:subnode1];
  ASDisplayNode *subnode2 = [self newNode];
  subnode2.disappearanceActions = @{ @"opacity": [self opacityAction] };
  [node addYogaChild:subnode2];
  ASDisplayNode *subnode3 = [self newNode];
  [node addYogaChild:subnode3];
  [view layoutIfNeeded];

  [node removeYogaChild:subnode1];
  [node removeYogaChild:subnode2];
  ASDisplayNode *subnode4 = [self newNode];
  ASDisplayNode *subnode5 = [self newNode];
  [node insertYogaChild:subnode4 atIndex:0];
  [node insertYogaChild:subnode5 atIndex:1];

  XCTestExpectation *expectation = [self expectationWithDescription:@"Nodes removed after action"];
  [CATransaction begin];
  [CATransaction setCompletionBlock:^{
    NSArray *expected = @[ subnode4, subnode5, subnode3 ];
    XCTAssertEqualObjects(node.subnodes, expected);
    [expectation fulfill];
  }];
  [view layoutIfNeeded];

  NSArray *expected = @[ subnode4, subnode5, subnode1, subnode2, subnode3 ];
  XCTAssertEqualObjects(node.subnodes, expected);

  [CATransaction commit];

  [self waitForExpectations:@[expectation] timeout:2.0];
}

- (void)testViewSimpleFlattening {
  ASDisplayNode *node = [self newNode];
  [node enableViewFlattening];

  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  [view addSubnode:node];

  ASDisplayNodeYoga2TestNode *containerNode = [self newYoga2TestNode];
  [containerNode enableViewFlattening];
  containerNode.test_isFlattenable = YES;
  [node addYogaChild:containerNode];
  ASDisplayNode *subnode =  [self newNode];
  [subnode enableViewFlattening];
  [containerNode addYogaChild:subnode];

  [view layoutIfNeeded];

  // Container node should be flattened away
  NSArray *expected = @[ subnode ];
  XCTAssertEqualObjects(node.subnodes, expected);
}

/**
 * Test flattening of a Texture node tree with a root tree that is flattenable results in a valid
 * tree.
 */
- (void)testViewFlatteningRootNodeIsFlattenable {
  ASDisplayNodeYoga2TestNode *rootNode = [self newYoga2TestNode];
  // Setting root node explicitly flattenable.
  rootNode.test_isFlattenable = YES;
  [rootNode enableViewFlattening];

  ASDisplayNode *subnode = [self newNode];
  [subnode enableViewFlattening];
  [rootNode addYogaChild:subnode];

  // Explicitly create view and trigger layout of root node.
  UIView *rootView = rootNode.view;
  [rootView setNeedsLayout];
  [rootView layoutIfNeeded];

  XCTAssertEqualObjects(rootNode.subnodes, @[ subnode ]);
}

/**
 * Test flattening of a Texture node tree with a root tree and a container node that are both
 * flattenable results in a valid tree.
 */
- (void)testViewFlatteningRootNodeAndContainerIsFlattenable {
  ASDisplayNodeYoga2TestNode *rootNode = [self newYoga2TestNode];
  // Setting root node explicitly flattenable.
  rootNode.test_isFlattenable = YES;
  [rootNode enableViewFlattening];

  ASDisplayNodeYoga2TestNode *containerNode = [self newYoga2TestNode];
  [containerNode enableViewFlattening];
  containerNode.test_isFlattenable = YES;
  [rootNode addYogaChild:containerNode];

  ASDisplayNode *subnode = [self newNode];
  [subnode enableViewFlattening];
  [containerNode addYogaChild:subnode];

  // Explicitly create view and trigger layout of root node.
  UIView *rootView = rootNode.view;
  [rootView setNeedsLayout];
  [rootView layoutIfNeeded];

  XCTAssertEqualObjects(rootNode.subnodes, @[ subnode ]);
}

- (void)testViewFlatteningContainerNodeChangesFlatteningStatus {
  // Initial case
  ASDisplayNode *node = [self newNode];
  [node enableViewFlattening];

  UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
  [view addSubnode:node];

  ASDisplayNodeYoga2TestNode *containerNode1 = [self newYoga2TestNode];
  [containerNode1 enableViewFlattening];
  [node addYogaChild:containerNode1];

  ASDisplayNode *subnode1 =  [self newNode];
  [subnode1 enableViewFlattening];
  [containerNode1 addYogaChild:subnode1];

  ASDisplayNode *subnode2 =  [self newNode];
  [subnode2 enableViewFlattening];
  [containerNode1 addYogaChild:subnode2];

  [view layoutIfNeeded];

  // Container node should be flattened away
  NSArray *expected = @[ subnode1,  subnode2];
  XCTAssertEqualObjects(containerNode1.subnodes, expected);

  [containerNode1 removeYogaChild:subnode1];
  [containerNode1 removeYogaChild:subnode2];

  // Update case with new Yoga tree
  ASDisplayNodeYoga2TestNode *containerNode2 = [self newYoga2TestNode];
  [containerNode2 enableViewFlattening];
  containerNode2.test_isFlattenable = NO;
  [containerNode2 addYogaChild:subnode1];
  [containerNode2 addYogaChild:subnode2];

  containerNode1.test_isFlattenable = YES;
  [containerNode1 addYogaChild:containerNode2];

  [view layoutIfNeeded];

  XCTAssertEqualObjects(node.subnodes, @[containerNode2]);
  XCTAssertEqualObjects(containerNode2.subnodes, expected);

  // Old subnode that was previously non flattenable and now is flattenable should be cleared
  XCTAssertTrue(containerNode1.subnodes.count == 0);
}

@end
