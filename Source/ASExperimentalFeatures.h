//
//  ASExperimentalFeatures.h
//  AsyncDisplayKit
//
//  Created by Adlai on 1/15/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/ASBaseDefines.h>

NS_ASSUME_NONNULL_BEGIN
ASDISPLAYNODE_EXTERN_C_BEGIN

/**
 * A bit mask of features.
 */
typedef NS_OPTIONS(NSUInteger, ASExperimentalFeatures) {
  ASExperimentalGraphicsContexts = 1 << 0,  // exp_graphics_contexts
  ASExperimentalTextNode = 1 << 1,          // exp_text_node
  ASExperimentalFeatureAll = 0xFFFFFFFF
};

/// Convert flags -> name array.
NSArray<NSString *> *ASExperimentalFeaturesGetNames(ASExperimentalFeatures flags);

/// Convert name array -> flags.
ASExperimentalFeatures ASExperimentalFeaturesFromArray(NSArray<NSString *> *array);

ASDISPLAYNODE_EXTERN_C_END
NS_ASSUME_NONNULL_END
