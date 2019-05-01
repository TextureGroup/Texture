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

- (void)testBackgroundDealloc
{
  __weak ASViewController *weakViewController = nil;
  __weak ASImageNode *weakImageNode = nil;
  __weak _ASDisplayLayer *displayLayer = nil;

  @autoreleasepool {
    ASViewController *viewController = [[ASViewController alloc] init];
    weakViewController = viewController;
    ASImageNode *node = [[ASImageNode alloc] init];
    weakImageNode = node;
    [node setImage:[ASViewControllerTests imageOfSize:CGSizeMake(120, 120) filledWithColor:[UIColor blueColor]]];
    XCTAssertNotNil(node.layer);
    displayLayer = (_ASDisplayLayer *)node.layer;
    [viewController.view addSubnode:node];
    [viewController.view layoutSubviews];
    viewController = nil;

    // intends to semaphore mainthread until an arbitrary amount dispatch queue creates and block dispatches
    // loosely confirm that all background queues have been flushed
    //    [ASViewControllerTests haltMainUntilBackgroundFlushes];

    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];
  }

  XCTAssertNil(weakViewController);
  XCTAssertNil(weakImageNode);
  XCTAssertNil(displayLayer);
}

- (void)testBackgroundDealloc2
{
  __weak ASViewController *weakViewController = nil;
  __weak ASImageNode *weakImageNode = nil;
  __weak _ASDisplayLayer *displayLayer = nil;
  // .image.CGImage declarations
  //    @property(nullable, nonatomic,readonly) CGImageRef CGImage; // returns underlying CGImageRef or nil if CIImage based
  //    - (nullable CGImageRef)CGImage NS_RETURNS_INNER_POINTER CF_RETURNS_NOT_RETAINED;
  CGDataProviderRef *observedColorSpaceRef = NULL; //typedef struct CF_BRIDGED_TYPE(id) CGColorSpace *CGColorSpaceRef;

  @autoreleasepool {
    ASViewController *viewController = [[ASViewController alloc] init];
    weakViewController = viewController;
    ASImageNode *node = [[ASImageNode alloc] init];
    weakImageNode = node;
    [node setImage:[ASViewControllerTests imageOfSize:CGSizeMake(120, 120) filledWithColor:[UIColor blueColor]]];
    XCTAssertNotNil(node.layer);
    displayLayer = (_ASDisplayLayer *)node.layer;
    [viewController.view addSubnode:node];
    [viewController.view layoutSubviews];
    CGDataProviderRef ref = CGImageGetDataProvider(node.image.CGImage);
    observedColorSpaceRef = &ref;
    viewController = nil;


    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:2]];
  }

//  XCTAssert([ASViewControllerTests haltMainUntilBackgroundFlushes]);

  XCTAssertNil(weakViewController);
  XCTAssertNil(weakImageNode);
  XCTAssertNil(displayLayer);
//  XCTAssert(*observedColorSpaceRef == NULL); //ignoring for now, undefined
}

+ (void)haltMainUntilBackgroundFlushes
{
  assert([NSThread isMainThread]);
  //    dispatch_semaphore_t sema = dispatch_semaphore_create(9001);
  int max_count = 10;
  //    __block BOOL GCDFlushed = NO;
  for (int i=0; i < max_count; i++) {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
      usleep(10000);
      //            if (i == 1000) {
      //                GCDFlushed = YES;
      //                dispatch_semaphore_signal(sema);
      //            }
    });
  }
  //    dispatch_semaphore_wait(sema, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 3));
  //    return GCDFlushed;
  return;
}

+ (UIImage *)imageOfSize:(CGSize)size filledWithColor:(UIColor *)color {
  UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGRect rect = (CGRect){CGPointZero, size};
  CGContextFillRect(context, rect);
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}


- (void)testThatAutomaticSubnodeManagementScrollViewInsetsAreApplied
{
  UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
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
  XCTAssertNotEqual(scrollNode.view.contentInset.top, 0);
}

- (void)testThatViewControllerFrameIsRightAfterCustomTransitionWithNonextendedEdges
{
  UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
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
