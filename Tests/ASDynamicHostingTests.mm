//
//  ASDynamicHostingTests.m
//  AsyncDisplayKitTests
//
//  Created by Adlai Holler on 3/3/19.
//  Copyright © 2019 Pinterest. All rights reserved.
//

#import "ASTestCase.h"

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import <OCMock/OCMock.h>

@interface ASDynamicHostingTests : ASTestCase

@end

@implementation ASDynamicHostingTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testHostingStartsUnspecified {
  ASDisplayNode *nR = [[ASDisplayNode alloc] init];
  XCTAssertEqual(nR.currentHosting, ASDisplayNodeHostingUnspecified);
}

- (void)testRootNodeMustAtLeastHaveLayer {
  ASDisplayNode *nR = [[ASDisplayNode alloc] init];
  id mockR = OCMPartialMock(nR);
  OCMExpect([mockR locked_preferredHosting]).andReturn(ASDisplayNodeHostingVirtual);
  UIView *v = [[UIView alloc] init];
  [v addSubnode:nR];
  XCTAssertEqual(nR.currentHosting, ASDisplayNodeHostingCALayer);
  XCTAssertNotNil(nR.layer);
}

- (void)testLayerWithViewSubnode {
  // Layer -> View should force the root node up to View hosting.
  ASDisplayNode *nR = [[ASDisplayNode alloc] init];
  ASDisplayNode *n0 = [[ASDisplayNode alloc] init];
  
  [nR addSubnode:n0];
  
  id mockR = OCMPartialMock(nR);
  OCMExpect([mockR locked_preferredHosting]).andReturn(ASDisplayNodeHostingCALayer);
  id mock0 = OCMPartialMock(n0);
  OCMExpect([mock0 locked_preferredHosting]).andReturn(ASDisplayNodeHostingUIView);
  UIView *v = [[UIView alloc] init];
  [v addSubnode:nR];
  OCMVerifyAll(mockR);
  OCMVerifyAll(mock0);
  XCTAssertEqual(nR.currentHosting, ASDisplayNodeHostingUIView);
  XCTAssertEqual(n0.currentHosting, ASDisplayNodeHostingUIView);
  XCTAssertNotNil(nR.view);
  XCTAssertNotNil(n0.view);
}

- (void)testRehostingLayer_ToView {
  ASDisplayNode *nR = [[ASDisplayNode alloc] init];
  ASDisplayNode *n0 = [[ASDisplayNode alloc] init];
  ASDisplayNode *n0_0 = [[ASDisplayNode alloc] init];
  
  // nR, the root node, is view-hosted.
  id mockR = OCMPartialMock(nR);
  OCMExpect([mockR locked_preferredHosting]).andReturn(ASDisplayNodeHostingUIView);

  // n0, the middle node, goes layer -> view.
  id mock0 = OCMPartialMock(n0);
  // Set a bridged property to make sure it is sustained.
  n0.alpha = 0.5;
  OCMExpect([mock0 locked_preferredHosting]).andReturn(ASDisplayNodeHostingCALayer);
  
  // n0_0, the bottom node, is layer-hosted.
  id mock0_0 = OCMPartialMock(n0_0); 
  OCMExpect([mock0_0 locked_preferredHosting]).andReturn(ASDisplayNodeHostingCALayer);
  
  UIView *v = [[UIView alloc] init];
  [v addSubnode:nR];
  OCMVerifyAll(mockR);
  OCMVerifyAll(mock0_0);
  OCMVerifyAll(mock0);
  
  // Model value check.
  XCTAssertEqual(nR.currentHosting, ASDisplayNodeHostingUIView);
  XCTAssertEqual(n0.currentHosting, ASDisplayNodeHostingCALayer);
  XCTAssertEqual(n0_0.currentHosting, ASDisplayNodeHostingCALayer);
  
  // View/layer tree check.
  XCTAssertNil(n0.view);
  XCTAssertNil(n0_0.view);
  XCTAssertEqualObjects(nR.view.subviews, @[]);
  XCTAssertEqual(n0.layer.opacity, 0.5);
  XCTAssertEqualObjects(nR.layer.sublayers, @[ n0.layer ]);
  XCTAssertEqualObjects(n0.layer.sublayers, @[ n0_0.layer ]);
  
  // Change middle node to view hosting.
  OCMExpect([mock0 locked_preferredHosting]).andReturn(ASDisplayNodeHostingUIView);
  [n0 invalidatePreferredHosting];
  // Spin the run loop once.
  [NSRunLoop.mainRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate date]];
  OCMVerifyAll(mock0);
  
  // Model value check.
  XCTAssertEqual(nR.currentHosting, ASDisplayNodeHostingUIView);
  XCTAssertEqual(n0.currentHosting, ASDisplayNodeHostingUIView);
  XCTAssertEqual(n0_0.currentHosting, ASDisplayNodeHostingUIView);
  
  // View tree check.
  XCTAssertNotNil(n0.view);
  XCTAssertEqual(n0.view.alpha, 0.5);
  XCTAssertEqualObjects(nR.view.subviews, n0.view);
  XCTAssertEqualObjects(n0.view.subviews, @[]);
  XCTAssertEqualObjects(n0.layer.sublayers, @[ n0_0.layer ]);
}

- (void)testRehostingViewToLayer {
  
}

- (void)testRehostingLayerToVirtual {
  
}

- (void)testHostingVirtualToLayer {
  
}

@end
