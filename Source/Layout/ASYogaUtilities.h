//
//  ASYogaUtilities.h
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASAvailability.h>

#if YOGA /* YOGA */

#import <AsyncDisplayKit/ASLayout.h>
#import <AsyncDisplayKit/ASLog.h>
#import <AsyncDisplayKit/ASDisplayNode+Beta.h>

// Should pass a string literal, not an NSString as the first argument to ASYogaLog
#define ASYogaLog(x, ...) as_log_verbose(ASLayoutLog(), x, ##__VA_ARGS__);

@interface ASDisplayNode (YogaHelpers)

+ (ASDisplayNode *)yogaNode;
+ (ASDisplayNode *)yogaSpacerNode;
+ (ASDisplayNode *)yogaVerticalStack;
+ (ASDisplayNode *)yogaHorizontalStack;

@end

// pre-order, depth-first
ASDK_EXTERN void ASDisplayNodePerformBlockOnEveryYogaChild(ASDisplayNode *node, void(^block)(ASDisplayNode *node));

#pragma mark - Yoga Type Conversion Helpers

ASDK_EXTERN YGAlign yogaAlignItems(ASStackLayoutAlignItems alignItems);
ASDK_EXTERN YGJustify yogaJustifyContent(ASStackLayoutJustifyContent justifyContent);
ASDK_EXTERN YGAlign yogaAlignSelf(ASStackLayoutAlignSelf alignSelf);
ASDK_EXTERN YGFlexDirection yogaFlexDirection(ASStackLayoutDirection direction);
ASDK_EXTERN float yogaFloatForCGFloat(CGFloat value);
ASDK_EXTERN float yogaDimensionToPoints(ASDimension dimension);
ASDK_EXTERN float yogaDimensionToPercent(ASDimension dimension);
ASDK_EXTERN ASDimension dimensionForEdgeWithEdgeInsets(YGEdge edge, ASEdgeInsets insets);

ASDK_EXTERN void ASLayoutElementYogaUpdateMeasureFunc(YGNodeRef yogaNode, id <ASLayoutElement> layoutElement);
ASDK_EXTERN float ASLayoutElementYogaBaselineFunc(YGNodeRef yogaNode, const float width, const float height);
ASDK_EXTERN YGSize ASLayoutElementYogaMeasureFunc(YGNodeRef yogaNode,
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

#endif /* YOGA */
