//
//  ASContentSizeCategory.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>

#import <AsyncDisplayKit/ASContentSizeCategory.h>
#import <AsyncDisplayKit/ASAvailability.h>

// UIContentSizeCategoryUnspecified is available only in iOS 10.0 and later.
// This constant is used as a fallback for older iOS versions.
UIContentSizeCategory const AS_UIContentSizeCategoryUnspecified = @"_UICTContentSizeCategoryUnspecified";

/**
 * Defines a dictionary of pairs of corresponding ASContentSizeCategory and UIContentSizeCategory values.
 */
ASDISPLAYNODE_INLINE NSDictionary<NSNumber *, UIContentSizeCategory> *_as_contentSizeCategory_correspondingValues() {
  static NSDictionary<NSNumber *, UIContentSizeCategory> *correspondingValues;

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    correspondingValues =
      @{
        // We will fallback to ASContentSizeCategoryUnspecified so there is no need to include it in this dictionary.

        [NSNumber numberWithInteger:ASContentSizeCategoryExtraSmall]: UIContentSizeCategoryExtraSmall,
        [NSNumber numberWithInteger:ASContentSizeCategorySmall]: UIContentSizeCategorySmall,
        [NSNumber numberWithInteger:ASContentSizeCategoryMedium]: UIContentSizeCategoryMedium,
        [NSNumber numberWithInteger:ASContentSizeCategoryLarge]: UIContentSizeCategoryLarge,
        [NSNumber numberWithInteger:ASContentSizeCategoryExtraLarge]: UIContentSizeCategoryExtraLarge,
        [NSNumber numberWithInteger:ASContentSizeCategoryExtraExtraLarge]: UIContentSizeCategoryExtraExtraLarge,
        [NSNumber numberWithInteger:ASContentSizeCategoryExtraExtraExtraLarge]: UIContentSizeCategoryExtraExtraExtraLarge,

        [NSNumber numberWithInteger:ASContentSizeCategoryAccessibilityMedium]: UIContentSizeCategoryAccessibilityMedium,
        [NSNumber numberWithInteger:ASContentSizeCategoryAccessibilityLarge]: UIContentSizeCategoryAccessibilityLarge,
        [NSNumber numberWithInteger:ASContentSizeCategoryAccessibilityExtraLarge]: UIContentSizeCategoryAccessibilityExtraLarge,
        [NSNumber numberWithInteger:ASContentSizeCategoryAccessibilityExtraExtraLarge]: UIContentSizeCategoryAccessibilityExtraExtraLarge,
        [NSNumber numberWithInteger:ASContentSizeCategoryAccessibilityExtraExtraExtraLarge]: UIContentSizeCategoryAccessibilityExtraExtraExtraLarge,
        };
  });

  return correspondingValues;
}

ASContentSizeCategory ASContentSizeCategoryFromUIContentSizeCategory(UIContentSizeCategory contentSizeCategory) {
  if (!contentSizeCategory) {
    return ASContentSizeCategoryUnspecified;
  }

  NSNumber *key = [[_as_contentSizeCategory_correspondingValues() allKeysForObject:contentSizeCategory] firstObject];
  if (key) {
    return key.integerValue;
  }
  else {
    return ASContentSizeCategoryUnspecified;
  }
}

UIContentSizeCategory UIContentSizeCategoryFromASContentSizeCategory(ASContentSizeCategory contentSizeCategory) {
  UIContentSizeCategory result = _as_contentSizeCategory_correspondingValues()[[NSNumber numberWithInteger:contentSizeCategory]];
  if (result) {
    return result;
  } else if (AS_AT_LEAST_IOS10) {
    return UIContentSizeCategoryUnspecified;
  } else {
    return AS_UIContentSizeCategoryUnspecified;
  }
}
