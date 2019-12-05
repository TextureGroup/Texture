//
//  ASViewControllerTests.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <XCTest/XCTest.h>

#import <OCMock/OCMock.h>

#import <AsyncDisplayKit/AsyncDisplayKit.h>

#import "NSInvocation+ASTestHelpers.h"

@interface ASViewControllerTests : XCTestCase

@end

@implementation ASViewControllerTests

- (void)testThatAutomaticSubnodeManagementScrollViewInsetsAreApplied
{
  UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  [window makeKeyAndVisible];
  
  ASDisplayNode *node = [[ASDisplayNode alloc] init];
  node.automaticallyManagesSubnodes = YES;
  ASScrollNode *scrollNode = [[ASScrollNode alloc] init];
  node.layoutSpecBlock = ^(ASDisplayNode *node, ASSizeRange constrainedSize){
    return [ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsZero child:scrollNode];
  };
  ASViewController *vc = [[ASViewController alloc] initWithNode:node];
  window.rootViewController = [[UINavigationController alloc] initWithRootViewController:vc];
  [window makeKeyAndVisible];
  [window layoutIfNeeded];
  
  XCTAssertEqualObjects(NSStringFromCGRect(window.bounds), NSStringFromCGRect(node.frame));
  XCTAssertEqual(scrollNode.view.contentInset.top, 0);
}

- (void)testThatViewControllerFrameIsRightAfterCustomTransitionWithNonextendedEdges
{
  UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  [window makeKeyAndVisible];
  
  ASDisplayNode *node = [[ASDisplayNode alloc] init];

  ASViewController *vc = [[ASViewController alloc] initWithNode:node];
  vc.node.backgroundColor = [UIColor greenColor];
  vc.edgesForExtendedLayout = UIRectEdgeNone;

  UIViewController * oldVC = [[UIViewController alloc] init];
  UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:oldVC];
  id navDelegate = [OCMockObject niceMockForProtocol:@protocol(UINavigationControllerDelegate)];
  id animator = [OCMockObject niceMockForProtocol:@protocol(UIViewControllerAnimatedTransitioning)];
  [[[[navDelegate expect] ignoringNonObjectArgs] andReturn:animator] navigationController:[OCMArg any] animationControllerForOperation:UINavigationControllerOperationPush fromViewController:[OCMArg any] toViewController:[OCMArg any]];
  [[[animator expect] andReturnValue:@0.3] transitionDuration:[OCMArg any]];
  XCTestExpectation *e = [self expectationWithDescription:@"Transition completed"];
  [[[animator expect] andDo:^(NSInvocation *invocation) {
    id<UIViewControllerContextTransitioning> ctx = [invocation as_argumentAtIndexAsObject:2];
    UIView *container = [ctx containerView];
    [container addSubview:vc.view];
    vc.view.alpha = 0;
    vc.view.frame = [ctx finalFrameForViewController:vc];
    [UIView animateWithDuration:0.3 animations:^{
      vc.view.alpha = 1;
      oldVC.view.alpha = 0;
    } completion:^(BOOL finished) {
      [oldVC.view removeFromSuperview];
      [ctx completeTransition:finished];
      [e fulfill];
    }];
  }] animateTransition:[OCMArg any]];
  nav.delegate = navDelegate;
  window.rootViewController = nav;
  [window makeKeyAndVisible];
  [[NSRunLoop mainRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate date]];
  [nav pushViewController:vc animated:YES];

  [self waitForExpectationsWithTimeout:2 handler:nil];
 
  CGFloat navHeight = CGRectGetMaxY([nav.navigationBar convertRect:nav.navigationBar.bounds toView:window]);
  CGRect expectedRect, slice;
  CGRectDivide(window.bounds, &slice, &expectedRect, navHeight, CGRectMinYEdge);
  XCTAssertEqualObjects(NSStringFromCGRect(expectedRect), NSStringFromCGRect(node.frame));
  [navDelegate verify];
  [animator verify];
}

@end
