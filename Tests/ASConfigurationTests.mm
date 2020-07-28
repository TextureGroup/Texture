//
//  ASConfigurationTests.m
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <XCTest/XCTest.h>

#import <AsyncDisplayKit/ASAvailability.h>
#import <AsyncDisplayKit/ASConfiguration.h>
#import <AsyncDisplayKit/ASConfigurationDelegate.h>
#import <AsyncDisplayKit/ASConfigurationInternal.h>

#import "ASTestCase.h"

static ASExperimentalFeatures features[] = {
#if AS_ENABLE_TEXTNODE
  ASExperimentalTextNode,
#endif
  ASExperimentalInterfaceStateCoalescing,
  ASExperimentalLayerDefaults,
  ASExperimentalCollectionTeardown,
  ASExperimentalFramesetterCache,
  ASExperimentalSkipClearData,
  ASExperimentalDidEnterPreloadSkipASMLayout,
  ASExperimentalDispatchApply,
  ASExperimentalDrawingGlobal,
  ASExperimentalOptimizeDataControllerPipeline,
};

@interface ASConfigurationTests : ASTestCase <ASConfigurationDelegate>

@end

@implementation ASConfigurationTests {
  void (^onActivate)(ASConfigurationTests *self, ASExperimentalFeatures feature);
}

+ (NSArray *)names {
  return @[
    @"exp_text_node",
    @"exp_interface_state_coalesce",
    @"exp_infer_layer_defaults",
    @"exp_collection_teardown",
    @"exp_framesetter_cache",
    @"exp_skip_clear_data",
    @"exp_did_enter_preload_skip_asm_layout",
    @"exp_dispatch_apply",
    @"exp_drawing_global",
    @"exp_optimize_data_controller_pipeline",
  ];
}

- (ASExperimentalFeatures)allFeatures
{
  ASExperimentalFeatures allFeatures = 0;
  for (int i = 0; i < sizeof(features)/sizeof(ASExperimentalFeatures); i++) {
    allFeatures |= features[i];
  }
  return allFeatures;
}

#if AS_ENABLE_TEXTNODE

- (void)testExperimentalFeatureConfig
{
  // Set the config
  ASConfiguration *config = [[ASConfiguration alloc] initWithDictionary:nil];
  config.experimentalFeatures = ASExperimentalLayerDefaults;
  config.delegate = self;
  [ASConfigurationManager test_resetWithConfiguration:config];
  
  // Set an expectation for a callback, and assert we only get one.
  XCTestExpectation *e = [self expectationWithDescription:@"Callbacks done."];
  e.expectedFulfillmentCount = 2;
  e.assertForOverFulfill = YES;
  onActivate = ^(ASConfigurationTests *self, ASExperimentalFeatures feature) {
    [e fulfill];
  };
  
  // Now activate the graphics experiment and expect it works.
  XCTAssertTrue(ASActivateExperimentalFeature(ASExperimentalLayerDefaults));
  // We should get a callback here
  // Now activate text node and expect it fails.
  XCTAssertFalse(ASActivateExperimentalFeature(ASExperimentalTextNode));
  // But we should get another callback.
  [self waitForExpectationsWithTimeout:3 handler:nil];
}

#endif

- (void)textureDidActivateExperimentalFeatures:(ASExperimentalFeatures)feature
{
  if (onActivate) {
    onActivate(self, feature);
  }
}

- (void)testMappingNamesToFlags
{
  // Throw in a bad bit.
  ASExperimentalFeatures allFeatures = [self allFeatures];
  ASExperimentalFeatures featuresWithBadBit = allFeatures | (1 << 22);
  NSArray *expectedNames = [ASConfigurationTests names];
  XCTAssertEqualObjects(expectedNames, ASExperimentalFeaturesGetNames(featuresWithBadBit));
}

- (void)testMappingFlagsFromNames
{
  // Throw in a bad name.
  NSMutableArray *allNames = [[NSMutableArray alloc] initWithArray:[ASConfigurationTests names]];
  [allNames addObject:@"__invalid_name"];
  ASExperimentalFeatures expected = [self allFeatures];
  XCTAssertEqual(expected, ASExperimentalFeaturesFromArray(allNames));
}

- (void)testFlagMatchName
{
  NSArray *names = [ASConfigurationTests names];
  for (NSInteger i = 0; i < names.count; i++) {
    XCTAssertEqual(features[i], ASExperimentalFeaturesFromArray(@[names[i]]));
  }
}

- (void)testNameMatchFlag {
  NSArray *names = [ASConfigurationTests names];
  for (NSInteger i = 0; i < names.count; i++) {
    XCTAssertEqualObjects(@[names[i]], ASExperimentalFeaturesGetNames(features[i]));
  }
}

@end
