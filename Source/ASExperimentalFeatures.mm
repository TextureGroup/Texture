//
//  ASExperimentalFeatures.mm
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASExperimentalFeatures.h>

#import <AsyncDisplayKit/ASCollections.h>

NSArray<NSString *> *ASExperimentalFeaturesGetNames(ASExperimentalFeatures flags)
{
  NSArray *allNames = ASCreateOnce((@[
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
  ]));
  if (flags == ASExperimentalFeatureAll) {
    return allNames;
  }
  
  // Go through all names, testing each bit.
  NSUInteger i = 0;
  return ASArrayByFlatMapping(allNames, NSString *name, ({
    (flags & (1 << i++)) ? name : nil;
  }));
}

// O(N^2) but with counts this small, it's probably faster
// than hashing the strings.
ASExperimentalFeatures ASExperimentalFeaturesFromArray(NSArray<NSString *> *array)
{
  NSArray *allNames = ASExperimentalFeaturesGetNames(ASExperimentalFeatureAll);
  ASExperimentalFeatures result = kNilOptions;
  for (NSString *str in array) {
    NSUInteger i = [allNames indexOfObject:str];
    if (i != NSNotFound) {
      result |= (1 << i);
    }
  }
  return result;
}
