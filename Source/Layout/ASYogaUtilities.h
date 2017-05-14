//
//  ASYogaUtilities.h
//  AsyncDisplayKit
//
//  Created by Scott Goodson on 5/7/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import <AsyncDisplayKit/ASAvailability.h>

#if YOGA /* YOGA */

#import <AsyncDisplayKit/ASLayout.h>
#import <AsyncDisplayKit/ASDisplayNode+Beta.h>

extern void ASDisplayNodePerformBlockOnEveryYogaChild(ASDisplayNode *node, void(^block)(ASDisplayNode *node));

ASDISPLAYNODE_EXTERN_C_BEGIN

#pragma mark - Yoga Type Conversion Helpers

YGAlign yogaAlignItems(ASStackLayoutAlignItems alignItems);
YGJustify yogaJustifyContent(ASStackLayoutJustifyContent justifyContent);
YGAlign yogaAlignSelf(ASStackLayoutAlignSelf alignSelf);
YGFlexDirection yogaFlexDirection(ASStackLayoutDirection direction);
float yogaFloatForCGFloat(CGFloat value);
float yogaDimensionToPoints(ASDimension dimension);
float yogaDimensionToPercent(ASDimension dimension);
ASDimension dimensionForEdgeWithEdgeInsets(YGEdge edge, ASEdgeInsets insets);

YGSize ASLayoutElementYogaMeasureFunc(YGNodeRef yogaNode,
                                      float width, YGMeasureMode widthMode,
                                      float height, YGMeasureMode heightMode);

#pragma mark - Yoga Style Setter Helpers

#define YGNODE_STYLE_SET_DIMENSION(yogaNode, property, dimension) \
  if (dimension.unit == ASDimensionUnitPoints) { \
    YGNodeStyleSet##property(yogaNode, yogaDimensionToPoints(dimension)); \
  } else if (dimension.unit == ASDimensionUnitFraction) { \
    YGNodeStyleSet##property##Percent(yogaNode, yogaDimensionToPercent(dimension)); \
  } else { \
    YGNodeStyleSet##property(yogaNode, YGUndefined); \
  }\

#define YGNODE_STYLE_SET_DIMENSION_WITH_EDGE(yogaNode, property, dimension, edge) \
  if (dimension.unit == ASDimensionUnitPoints) { \
    YGNodeStyleSet##property(yogaNode, edge, yogaDimensionToPoints(dimension)); \
  } else if (dimension.unit == ASDimensionUnitFraction) { \
    YGNodeStyleSet##property##Percent(yogaNode, edge, yogaDimensionToPercent(dimension)); \
  } else { \
    YGNodeStyleSet##property(yogaNode, edge, YGUndefined); \
  } \

#define YGNODE_STYLE_SET_FLOAT_WITH_EDGE(yogaNode, property, dimension, edge) \
  if (dimension.unit == ASDimensionUnitPoints) { \
    YGNodeStyleSet##property(yogaNode, edge, yogaDimensionToPoints(dimension)); \
  } else if (dimension.unit == ASDimensionUnitFraction) { \
    ASDisplayNodeAssert(NO, @"Unexpected Fraction value in applying ##property## values to YGNode"); \
  } else { \
    YGNodeStyleSet##property(yogaNode, edge, YGUndefined); \
  } \

ASDISPLAYNODE_EXTERN_C_END

#endif /* YOGA */
