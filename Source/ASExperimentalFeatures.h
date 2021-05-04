//
//  ASExperimentalFeatures.h
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/ASAvailability.h>
#import <AsyncDisplayKit/ASBaseDefines.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A bit mask of features. Make sure to update configuration.json when you add entries.
 */
typedef NS_OPTIONS(NSUInteger, ASExperimentalFeatures) {
  // If AS_ENABLE_TEXTNODE=0 or TextNode2 subspec is used this setting is a no op and ASTextNode2
  // will be used in all cases
  ASExperimentalTextNode = 1 << 0,                        // exp_text_node
  ASExperimentalInterfaceStateCoalescing = 1 << 1,        // exp_interface_state_coalesce
  ASExperimentalUnfairLock = 1 << 2,                      // exp_unfair_lock
  ASExperimentalLayerDefaults = 1 << 3,                   // exp_infer_layer_defaults
  ASExperimentalCollectionTeardown = 1 << 4,              // exp_collection_teardown
  ASExperimentalFramesetterCache = 1 << 5,                // exp_framesetter_cache
  ASExperimentalSkipClearData = 1 << 6,                   // exp_skip_clear_data
  ASExperimentalDidEnterPreloadSkipASMLayout = 1 << 7,    // exp_did_enter_preload_skip_asm_layout
  ASExperimentalDispatchApply = 1 << 8,                   // exp_dispatch_apply
  ASExperimentalOOMBackgroundDeallocDisable = 1 << 9,     // exp_oom_bg_dealloc_disable
  ASExperimentalRemoveTextKitInitialisingLock = 1 << 10,  // exp_remove_textkit_initialising_lock
  ASExperimentalDrawingGlobal = 1 << 11,                  // exp_drawing_global
  ASExperimentalDeferredNodeRelease = 1 << 12,            // exp_deferred_node_release
  ASExperimentalFasterWebPDecoding = 1 << 13,             // exp_faster_webp_decoding
  ASExperimentalFasterWebPGraphicsImageRenderer = 1
                                                  << 14,  // exp_faster_webp_graphics_image_renderer
  ASExperimentalAnimatedWebPNoCache = 1 << 15,            // exp_animated_webp_no_cache
  ASExperimentalDeallocElementMapOffMain = 1 << 16,       // exp_dealloc_element_map_off_main
  ASExperimentalUnifiedYogaTree = 1 << 17,                // exp_unified_yoga_tree
  ASExperimentalCoalesceRootNodeInTransaction = 1 << 18,  // exp_coalesce_root_node_in_transaction
  ASExperimentalUseNonThreadLocalArrayWhenApplyingLayout = 1 << 19,
                                                          // exp_use_non_tls_array
  ASExperimentalOptimizeDataControllerPipeline = 1 << 20,   // exp_optimize_data_controller_pipeline
  ASExperimentalTraitCollectionDidChangeWithPreviousCollection = 1 << 21,   // exp_trait_collection_did_change_with_previous_collection
  ASExperimentalFillTemplateImagesWithTintColor = 1 << 22,  // exp_fill_template_images_with_tint_color
  ASExperimentalDoNotCacheAccessibilityElements = 1 << 23,  // exp_do_not_cache_accessibility_elements
  ASExperimentalDisableGlobalTextkitLock = 1 << 24,         // exp_disable_global_textkit_lock
  ASExperimentalMainThreadOnlyDataController = 1 << 25,     // exp_main_thread_only_data_controller,
  ASExperimentalEnableNodeIsHiddenFromAcessibility = 1 << 26, // exp_enable_node_is_hidden_from_accessibility
  ASExperimentalEnableAcessibilityElementsReturnNil = 1 << 27, // exp_enable_accessibility_elements_return_nil
  ASExperimentalRangeUpdateOnChangesetUpdate = 1 << 28,                     // exp_range_update_on_changeset_update
  ASExperimentalFeatureAll = 0xFFFFFFFF
};

/// Convert flags -> name array.
ASDK_EXTERN NSArray<NSString *> *ASExperimentalFeaturesGetNames(ASExperimentalFeatures flags);

/// Convert name array -> flags.
ASDK_EXTERN ASExperimentalFeatures ASExperimentalFeaturesFromArray(NSArray<NSString *> *array);

// This is trying to merge non-rangeManaged with rangeManaged, so both range-managed and standalone nodes wait before firing their exit-visibility handlers, as UIViewController transitions now do rehosting at both start & end of animation.
// Enable this will mitigate interface updating state when coalescing disabled.
// TODO(wsdwsd0829): Rework enabling code to ensure that interface state behavior is not altered when ASCATransactionQueue is disabled.
// TODO Make this a real experiment flag
#define ENABLE_NEW_EXIT_HIERARCHY_BEHAVIOR 1

NS_ASSUME_NONNULL_END
