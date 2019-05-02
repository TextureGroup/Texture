//
//  ASBackgroundDeallocLeak.m
//  AsyncDisplayKitTests
//
//  Created by Michael Zuccarino on 4/30/19.
//

#import <XCTest/XCTest.h>

#import <AsyncDisplayKit/AsyncDisplayKit.h>

@interface ASBackgroundDeallocLeak : XCTestCase

@end

@interface ASConfigurationManager (GucciSlides)
- (BOOL)activateExperimentalFeature:(ASExperimentalFeatures)requested;
@end

@implementation ASBackgroundDeallocLeak

- (void)testNode
{
  __weak ASViewController *weakViewController = nil;
  __weak ASDisplayNode *weakNode = nil;

  @autoreleasepool {
    ASDisplayNode *node = [[ASDisplayNode alloc] init];
    weakNode = node;

    ASViewController *viewController = [[ASViewController alloc] initWithNode:node];
    weakViewController = viewController;

    viewController = nil;
  }

  // Let things clean up.
  [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];

  XCTAssertNil(weakViewController);
  XCTAssertNil(weakNode);
}

- (void)testViewBacked_Background
{
  __weak ASViewController *weakViewController = nil;
  __weak ASDisplayNode *weakNode = nil;
  __weak id displayLayer = nil;

  @autoreleasepool {
    ASDisplayNode *node = [[ASDisplayNode alloc] init];
    weakNode = node;

    ASViewController *viewController = [[ASViewController alloc] initWithNode:node];
    weakViewController = viewController;
    displayLayer = viewController.node.view;

    viewController = nil;
  }

  // Let things clean up.
  [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];

  XCTAssertNil(weakViewController);
  XCTAssertNil(weakNode);
  XCTAssertNil(displayLayer);
}

- (void)testLayerBacked_Background
{
  __weak ASViewController *weakViewController = nil;
  __weak ASDisplayNode *weakNode = nil;
  __weak id displayLayer = nil;

  @autoreleasepool {
    ASDisplayNode *node = [[ASDisplayNode alloc] init];
    weakNode = node;

    ASViewController *viewController = [[ASViewController alloc] initWithNode:node];
    weakViewController = viewController;
    displayLayer = viewController.node.layer;

    viewController = nil;
  }

  // Let things clean up.
  [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];

  XCTAssertNil(weakViewController);
  XCTAssertNil(weakNode);
  XCTAssertNil(displayLayer);
}

- (void)testViewBacked_Default
{
  __weak ASViewController *weakViewController = nil;
  __weak ASDisplayNode *weakNode = nil;
  __weak id displayLayer = nil;

  ASConfiguration *config = [[ASConfiguration alloc] initWithDictionary:nil];
  config.experimentalFeatures = ASExperimentalOOMBackgroundDeallocDisable;
  [ASConfigurationManager test_resetWithConfiguration:config];

  @autoreleasepool {
    ASDisplayNode *node = [[ASDisplayNode alloc] init];
    weakNode = node;

    ASViewController *viewController = [[ASViewController alloc] initWithNode:node];
    weakViewController = viewController;
    displayLayer = viewController.node.view;

    viewController = nil;
  }

  // Let things clean up.
  [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];

  XCTAssertNil(weakViewController);
  XCTAssertNil(weakNode);
  XCTAssertNil(displayLayer);
}

- (void)testLayerBacked_Default
{
  __weak ASViewController *weakViewController = nil;
  __weak ASDisplayNode *weakNode = nil;
  __weak id displayLayer = nil;

  ASConfiguration *config = [[ASConfiguration alloc] initWithDictionary:nil];
  config.experimentalFeatures = ASExperimentalOOMBackgroundDeallocDisable;
  [ASConfigurationManager test_resetWithConfiguration:config];

  @autoreleasepool {
    ASDisplayNode *node = [[ASDisplayNode alloc] init];
    weakNode = node;

    ASViewController *viewController = [[ASViewController alloc] initWithNode:node];
    weakViewController = viewController;
    displayLayer = viewController.node.layer;

    viewController = nil;
  }

  // Let things clean up.
  [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.2]];

  XCTAssertNil(weakViewController);
  XCTAssertNil(weakNode);
  XCTAssertNil(displayLayer);
}

@end
