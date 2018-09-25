//
//  ASExperimentalFeatures.m
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASExperimentalFeatures.h>

#import <AsyncDisplayKit/ASCollections.h>

NSArray<NSString *> *ASExperimentalFeaturesGetNames(ASExperimentalFeatures flags)
{
  NSArray *allNames = ASCreateOnce((@[@"exp_graphics_contexts",
                                      @"exp_text_node",
                                      @"exp_interface_state_coalesce",
                                      @"exp_unfair_lock",
                                      @"exp_infer_layer_defaults",
                                      @"exp_network_image_queue",
                                      @"exp_dealloc_queue_v2",
                                      @"exp_collection_teardown",
                                      @"exp_framesetter_cache",
                                      @"exp_skip_clear_data"]));
  
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
  ASExperimentalFeatures result = 0;
  for (NSString *str in array) {
    NSUInteger i = [allNames indexOfObject:str];
    if (i != NSNotFound) {
      result |= (1 << i);
    }
  }
  return result;
}
