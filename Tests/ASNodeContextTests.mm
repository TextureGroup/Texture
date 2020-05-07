//
//  ASNodeContextTests.m
//  AsyncDisplayKitTests
//
//  Created by Adlai Holler on 7/1/19.
//  Copyright © 2019 Pinterest. All rights reserved.
//

#import "ASTestCase.h"

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import <AsyncDisplayKit/ASNodeContext+Private.h>

@interface ASNodeContextTests : ASTestCase

@end

@implementation ASNodeContextTests

- (void)testBasicStackBehavior
{
  XCTAssertNil(ASNodeContextGet());
  ASNodeContext *ctx = [[ASNodeContext alloc] init];
  ASNodeContextPush(ctx);
  XCTAssertEqualObjects(ASNodeContextGet(), ctx);
  ASNodeContext *ctx2 = [[ASNodeContext alloc] init];
  ASNodeContextPush(ctx2);
  XCTAssertEqualObjects(ASNodeContextGet(), ctx2);
  ASNodeContextPop();
  XCTAssertEqualObjects(ASNodeContextGet(), ctx);
  ASNodeContextPop();
  XCTAssertNil(ASNodeContextGet());
}

- (void)testNodesInheritContext
{
  ASNodeContext *ctx = [[ASNodeContext alloc] init];
  ASNodeContextPush(ctx);
  ASDisplayNode *node = [[ASDisplayNode alloc] init];
  ASNodeContextPop();
  XCTAssertEqualObjects(node.nodeContext, ctx);
}

- (void)testNodesShareContextLock
{
  ASNodeContext *ctx = [[ASNodeContext alloc] init];
  ASNodeContextPush(ctx);
  ASDisplayNode *node = [[ASDisplayNode alloc] init];
  ASDisplayNode *n2 = [[ASDisplayNode alloc] init];
  ASNodeContextPop();
  XCTAssertEqualObjects(node.nodeContext, ctx);
  XCTAssertEqualObjects(n2.nodeContext, ctx);
  [node lock];
  // Jump to another thread and try to lock n2. It should fail.
  XCTestExpectation *e = [self expectationWithDescription:@"n2 was blocked"];
  [NSThread detachNewThreadWithBlock:^{
    XCTAssertFalse([n2 tryLock]);
    [e fulfill];
  }];
  [self waitForExpectationsWithTimeout:3 handler:nil];
  [node unlock];
}

- (void)testMixingContextsThrows
{
  ASNodeContext *ctx = [[ASNodeContext alloc] init];
  ASNodeContextPush(ctx);
  ASDisplayNode *node = [[ASDisplayNode alloc] init];
  ASNodeContextPop();
  ASDisplayNode *noContextNode = [[ASDisplayNode alloc] init];
  XCTAssertThrows([node addSubnode:noContextNode]);
}

@end
