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
    ASExperimentalUnfairLock,
    ASExperimentalLayerDefaults,
    ASExperimentalCollectionTeardown,
    ASExperimentalFramesetterCache,
    ASExperimentalSkipClearData,
    ASExperimentalDidEnterPreloadSkipASMLayout,
    ASExperimentalDispatchApply,
    ASExperimentalOOMBackgroundDeallocDisable,
    ASExperimentalRemoveTextKitInitialisingLock,
    ASExperimentalDrawingGlobal,
    ASExperimentalDeferredNodeRelease,
    ASExperimentalFasterWebPDecoding,
    ASExperimentalFasterWebPGraphicsImageRenderer,
    ASExperimentalAnimatedWebPNoCache,
    ASExperimentalDeallocElementMapOffMain,
    ASExperimentalUnifiedYogaTree,
    ASExperimentalCoalesceRootNodeInTransaction,
    ASExperimentalUseNonThreadLocalArrayWhenApplyingLayout,
    ASExperimentalOptimizeDataControllerPipeline,
    ASExperimentalTraitCollectionDidChangeWithPreviousCollection,
    ASExperimentalFillTemplateImagesWithTintColor,
    ASExperimentalDoNotCacheAccessibilityElements,
    ASExperimentalDisableGlobalTextkitLock,
    ASExperimentalMainThreadOnlyDataController,
    ASExperimentalEnableNodeIsHiddenFromAcessibility,
    ASExperimentalEnableAcessibilityElementsReturnNil,
    ASExperimentalRangeUpdateOnChangesetUpdate,
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
    @"exp_unfair_lock",
    @"exp_infer_layer_defaults",
    @"exp_collection_teardown",
    @"exp_framesetter_cache",
    @"exp_skip_clear_data",
    @"exp_did_enter_preload_skip_asm_layout",
    @"exp_dispatch_apply",
    @"exp_oom_bg_dealloc_disable",
    @"exp_remove_textkit_initialising_lock",
    @"exp_drawing_global",
    @"exp_deferred_node_release",
    @"exp_faster_webp_decoding",
    @"exp_faster_webp_graphics_image_renderer",
    @"exp_animated_webp_no_cache",
    @"exp_dealloc_element_map_off_main",
    @"exp_unified_yoga_tree",
    @"exp_coalesce_root_node_in_transaction",
    @"exp_use_non_tls_array",
    @"exp_optimize_data_controller_pipeline",
    @"exp_trait_collection_did_change_with_previous_collection",
    @"exp_fill_template_images_with_tint_color",
    @"exp_do_not_cache_accessibility_elements",
    @"exp_disable_global_textkit_lock",
    @"exp_main_thread_only_data_controller",
    @"exp_enable_node_is_hidden_from_accessibility",
    @"exp_enable_accessibility_elements_return_nil",
    @"exp_range_update_on_changeset_update",
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
  ASExperimentalFeatures featuresWithBadBit = allFeatures | (1 << 27);
  NSArray *expectedNames = [ASConfigurationTests names];
  NSArray *actualNames = ASExperimentalFeaturesGetNames(featuresWithBadBit);
  XCTAssertEqualObjects(expectedNames, actualNames);
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
    NSLog(@"i:%lu", i);
    XCTAssertEqual(features[i], ASExperimentalFeaturesFromArray(@[names[i]]));
    NSLog(@"i:%lu", i);
  }
}

- (void)testNameMatchFlag {
  NSArray *names = [ASConfigurationTests names];
  for (NSInteger i = 0; i < names.count; i++) {
    XCTAssertEqualObjects(@[names[i]], ASExperimentalFeaturesGetNames(features[i]));
  }
}

@end
