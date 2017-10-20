//
//  ASContentSizeCategory.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <UIKit/UIKit.h>
#import <AsyncDisplayKit/ASBaseDefines.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * ASContentSizeCategory is a UIContentSizeCategory that can be used in a struct.
 */
typedef NS_ENUM(NSInteger, ASContentSizeCategory) {
  ASContentSizeCategoryUnspecified,
  ASContentSizeCategoryExtraSmall,
  ASContentSizeCategorySmall,
  ASContentSizeCategoryMedium,
  ASContentSizeCategoryLarge,
  ASContentSizeCategoryExtraLarge,
  ASContentSizeCategoryExtraExtraLarge,
  ASContentSizeCategoryExtraExtraExtraLarge,

  // Accessibility sizes
  ASContentSizeCategoryAccessibilityMedium,
  ASContentSizeCategoryAccessibilityLarge,
  ASContentSizeCategoryAccessibilityExtraLarge,
  ASContentSizeCategoryAccessibilityExtraExtraLarge,
  ASContentSizeCategoryAccessibilityExtraExtraExtraLarge
};

/**
 * Mapping from UIContentSizeCategory
 */
extern ASContentSizeCategory ASContentSizeCategoryFromUIContentSizeCategory(UIContentSizeCategory contentSizeCategory);

/**
 * Mapping to UIContentSizeCategory
 */
extern UIContentSizeCategory UIContentSizeCategoryFromASContentSizeCategory(ASContentSizeCategory contentSizeCategory);

NS_ASSUME_NONNULL_END
