//
//  ASRelativeLayoutSpec.h
//  Texture
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the /ASDK-Licenses directory of this source tree. An additional
//  grant of patent rights can be found in the PATENTS file in the same directory.
//
//  Modifications to this file made after 4/13/2017 are: Copyright (c) 2017-present,
//  Pinterest, Inc.  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASLayoutSpec.h>

/** 
  * How the child is positioned within the spec.
  *
  * The default option will position the child at point 0.
  * Swift: use [] for the default behavior.
  */
typedef NS_ENUM(NSUInteger, ASRelativeLayoutSpecPosition) {
  /** The child is positioned at point 0 */ 
  ASRelativeLayoutSpecPositionNone = 0,
  /** The child is positioned at point 0 relatively to the layout axis (ie left / top most) */
  ASRelativeLayoutSpecPositionStart = 1,
  /** The child is centered along the specified axis */
  ASRelativeLayoutSpecPositionCenter = 2,
  /** The child is positioned at the maximum point of the layout axis (ie right / bottom most) */
  ASRelativeLayoutSpecPositionEnd = 3,
};

/** 
  * How much space the spec will take up.
  *
  * The default option will allow the spec to take up the maximum size possible.
  * Swift: use [] for the default behavior.
  */
typedef NS_OPTIONS(NSUInteger, ASRelativeLayoutSpecSizingOption) {
  /** The spec will take up the maximum size possible */
  ASRelativeLayoutSpecSizingOptionDefault,
  /** The spec will take up the minimum size possible along the X axis */
  ASRelativeLayoutSpecSizingOptionMinimumWidth = 1 << 0,
  /** The spec will take up the minimum size possible along the Y axis */
  ASRelativeLayoutSpecSizingOptionMinimumHeight = 1 << 1,
  /** Convenience option to take up the minimum size along both the X and Y axis */
  ASRelativeLayoutSpecSizingOptionMinimumSize = ASRelativeLayoutSpecSizingOptionMinimumWidth | ASRelativeLayoutSpecSizingOptionMinimumHeight,
};

NS_ASSUME_NONNULL_BEGIN

/** Lays out a single layoutElement child and positions it within the layout bounds according to vertical and horizontal positional specifiers.
 *  Can position the child at any of the 4 corners, or the middle of any of the 4 edges, as well as the center - similar to "9-part" image areas.
 */
@interface ASRelativeLayoutSpec : ASLayoutSpec

// You may create a spec with alloc / init, then set any non-default properties; or use a convenience initialize that accepts all properties.
@property (nonatomic) ASRelativeLayoutSpecPosition horizontalPosition;
@property (nonatomic) ASRelativeLayoutSpecPosition verticalPosition;
@property (nonatomic) ASRelativeLayoutSpecSizingOption sizingOption;

/*!
 * @discussion convenience constructor for a ASRelativeLayoutSpec
 * @param horizontalPosition how to position the item on the horizontal (x) axis
 * @param verticalPosition how to position the item on the vertical (y) axis
 * @param sizingOption how much size to take up
 * @param child the child to layout
 * @return a configured ASRelativeLayoutSpec
 */
+ (instancetype)relativePositionLayoutSpecWithHorizontalPosition:(ASRelativeLayoutSpecPosition)horizontalPosition
                                                verticalPosition:(ASRelativeLayoutSpecPosition)verticalPosition
                                                    sizingOption:(ASRelativeLayoutSpecSizingOption)sizingOption
                                                           child:(id<ASLayoutElement>)child NS_RETURNS_RETAINED AS_WARN_UNUSED_RESULT;

/*!
 * @discussion convenience initializer for a ASRelativeLayoutSpec
 * @param horizontalPosition how to position the item on the horizontal (x) axis
 * @param verticalPosition how to position the item on the vertical (y) axis
 * @param sizingOption how much size to take up
 * @param child the child to layout
 * @return a configured ASRelativeLayoutSpec
 */
- (instancetype)initWithHorizontalPosition:(ASRelativeLayoutSpecPosition)horizontalPosition
                          verticalPosition:(ASRelativeLayoutSpecPosition)verticalPosition
                              sizingOption:(ASRelativeLayoutSpecSizingOption)sizingOption
                                     child:(id<ASLayoutElement>)child;

@end

NS_ASSUME_NONNULL_END

