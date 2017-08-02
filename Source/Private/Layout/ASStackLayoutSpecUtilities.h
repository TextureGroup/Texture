//
//  ASStackLayoutSpecUtilities.h
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

#import <AsyncDisplayKit/ASStackLayoutSpec.h>

typedef struct {
  ASStackLayoutDirection direction;
  CGFloat spacing;
  ASStackLayoutJustifyContent justifyContent;
  ASStackLayoutAlignItems alignItems;
  ASStackLayoutFlexWrap flexWrap;
  ASStackLayoutAlignContent alignContent;
  CGFloat lineSpacing;
} ASStackLayoutSpecStyle;

inline CGFloat stackDimension(const ASStackLayoutDirection direction, const CGSize size)
{
  return (direction == ASStackLayoutDirectionVertical) ? size.height : size.width;
}

inline CGFloat crossDimension(const ASStackLayoutDirection direction, const CGSize size)
{
  return (direction == ASStackLayoutDirectionVertical) ? size.width : size.height;
}

inline BOOL compareCrossDimension(const ASStackLayoutDirection direction, const CGSize a, const CGSize b)
{
  return crossDimension(direction, a) < crossDimension(direction, b);
}

inline CGPoint directionPoint(const ASStackLayoutDirection direction, const CGFloat stack, const CGFloat cross)
{
  return (direction == ASStackLayoutDirectionVertical) ? CGPointMake(cross, stack) : CGPointMake(stack, cross);
}

inline CGSize directionSize(const ASStackLayoutDirection direction, const CGFloat stack, const CGFloat cross)
{
  return (direction == ASStackLayoutDirectionVertical) ? CGSizeMake(cross, stack) : CGSizeMake(stack, cross);
}

inline void setStackValueToPoint(const ASStackLayoutDirection direction, const CGFloat stack, CGPoint &point) {
  (direction == ASStackLayoutDirectionVertical) ? (point.y = stack) : (point.x = stack);
}

inline ASSizeRange directionSizeRange(const ASStackLayoutDirection direction,
                                      const CGFloat stackMin,
                                      const CGFloat stackMax,
                                      const CGFloat crossMin,
                                      const CGFloat crossMax)
{
  return {directionSize(direction, stackMin, crossMin), directionSize(direction, stackMax, crossMax)};
}

inline ASStackLayoutAlignItems alignment(ASStackLayoutAlignSelf childAlignment, ASStackLayoutAlignItems stackAlignment)
{
  switch (childAlignment) {
    case ASStackLayoutAlignSelfCenter:
      return ASStackLayoutAlignItemsCenter;
    case ASStackLayoutAlignSelfEnd:
      return ASStackLayoutAlignItemsEnd;
    case ASStackLayoutAlignSelfStart:
      return ASStackLayoutAlignItemsStart;
    case ASStackLayoutAlignSelfStretch:
      return ASStackLayoutAlignItemsStretch;
    case ASStackLayoutAlignSelfAuto:
    default:
      return stackAlignment;
  }
}

inline ASStackLayoutAlignItems alignment(ASHorizontalAlignment alignment, ASStackLayoutAlignItems defaultAlignment)
{
  switch (alignment) {
    case ASHorizontalAlignmentLeft:
      return ASStackLayoutAlignItemsStart;
    case ASHorizontalAlignmentMiddle:
      return ASStackLayoutAlignItemsCenter;
    case ASHorizontalAlignmentRight:
      return ASStackLayoutAlignItemsEnd;
    case ASHorizontalAlignmentNone:
    default:
      return defaultAlignment;
  }
}

inline ASStackLayoutAlignItems alignment(ASVerticalAlignment alignment, ASStackLayoutAlignItems defaultAlignment)
{
  switch (alignment) {
    case ASVerticalAlignmentTop:
      return ASStackLayoutAlignItemsStart;
    case ASVerticalAlignmentCenter:
      return ASStackLayoutAlignItemsCenter;
    case ASVerticalAlignmentBottom:
      return ASStackLayoutAlignItemsEnd;
    case ASVerticalAlignmentNone:
    default:
      return defaultAlignment;
  }
}

inline ASStackLayoutJustifyContent justifyContent(ASHorizontalAlignment alignment, ASStackLayoutJustifyContent defaultJustifyContent)
{
  switch (alignment) {
    case ASHorizontalAlignmentLeft:
      return ASStackLayoutJustifyContentStart;
    case ASHorizontalAlignmentMiddle:
      return ASStackLayoutJustifyContentCenter;
    case ASHorizontalAlignmentRight:
      return ASStackLayoutJustifyContentEnd;
    case ASHorizontalAlignmentNone:
    default:
      return defaultJustifyContent;
  }
}

inline ASStackLayoutJustifyContent justifyContent(ASVerticalAlignment alignment, ASStackLayoutJustifyContent defaultJustifyContent)
{
  switch (alignment) {
    case ASVerticalAlignmentTop:
      return ASStackLayoutJustifyContentStart;
    case ASVerticalAlignmentCenter:
      return ASStackLayoutJustifyContentCenter;
    case ASVerticalAlignmentBottom:
      return ASStackLayoutJustifyContentEnd;
    case ASVerticalAlignmentNone:
    default:
      return defaultJustifyContent;
  }
}
