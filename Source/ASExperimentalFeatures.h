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
  ASExperimentalTextNode = 1 << 0,                                          // exp_text_node
  ASExperimentalInterfaceStateCoalescing = 1 << 1,                          // exp_interface_state_coalesce
  ASExperimentalLayerDefaults = 1 << 2,                                     // exp_infer_layer_defaults
  ASExperimentalCollectionTeardown = 1 << 3,                                // exp_collection_teardown
  ASExperimentalFramesetterCache = 1 << 4,                                  // exp_framesetter_cache
  ASExperimentalSkipClearData = 1 << 5,                                     // exp_skip_clear_data
  ASExperimentalDidEnterPreloadSkipASMLayout = 1 << 6,                      // exp_did_enter_preload_skip_asm_layout
  ASExperimentalDispatchApply = 1 << 7,                                     // exp_dispatch_apply
  ASExperimentalDrawingGlobal = 1 << 8,                                     // exp_drawing_global
  ASExperimentalOptimizeDataControllerPipeline = 1 << 9,                    // exp_optimize_data_controller_pipeline
  ASExperimentalDisableGlobalTextkitLock = 1 << 10,                         // exp_disable_global_textkit_lock
  ASExperimentalMainThreadOnlyDataController = 1 << 11,                     // exp_main_thread_only_data_controller
  ASExperimentalFeatureAll = 0xFFFFFFFF
};

/// Convert flags -> name array.
ASDK_EXTERN NSArray<NSString *> *ASExperimentalFeaturesGetNames(ASExperimentalFeatures flags);

/// Convert name array -> flags.
ASDK_EXTERN ASExperimentalFeatures ASExperimentalFeaturesFromArray(NSArray<NSString *> *array);

NS_ASSUME_NONNULL_END
