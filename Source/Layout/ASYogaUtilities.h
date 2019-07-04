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
AS_EXTERN void ASDisplayNodePerformBlockOnEveryYogaChild(ASDisplayNode *node, void(^block)(ASDisplayNode *node));

#pragma mark - Yoga Type Conversion Helpers

AS_EXTERN YGAlign yogaAlignItems(ASStackLayoutAlignItems alignItems);
AS_EXTERN ASStackLayoutAlignItems stackAlignItems(YGAlign alignItems);
AS_EXTERN YGJustify yogaJustifyContent(ASStackLayoutJustifyContent justifyContent);
AS_EXTERN ASStackLayoutJustifyContent stackJustifyContent(YGJustify justifyContent);
AS_EXTERN YGAlign yogaAlignSelf(ASStackLayoutAlignSelf alignSelf);
AS_EXTERN ASStackLayoutAlignSelf stackAlignSelf(YGAlign alignSelf);
AS_EXTERN YGFlexDirection yogaFlexDirection(ASStackLayoutDirection direction);
AS_EXTERN ASStackLayoutDirection stackFlexDirection(YGFlexDirection direction);
AS_EXTERN float yogaFloatForCGFloat(CGFloat value);
AS_EXTERN CGFloat cgFloatForYogaFloat(float yogaFloat, CGFloat undefinedDefault);
AS_EXTERN float yogaDimensionToPoints(ASDimension dimension);
AS_EXTERN float yogaDimensionToPercent(ASDimension dimension);
AS_EXTERN YGValue yogaValueForDimension(ASDimension dimension);
AS_EXTERN ASDimension dimensionForYogaValue(YGValue value);
AS_EXTERN ASDimension dimensionForEdgeWithEdgeInsets(YGEdge edge, ASEdgeInsets insets);

AS_EXTERN void ASLayoutElementYogaUpdateMeasureFunc(YGNodeRef yogaNode, id <ASLayoutElement> layoutElement);
AS_EXTERN float ASLayoutElementYogaBaselineFunc(YGNodeRef yogaNode, const float width, const float height);
AS_EXTERN YGSize ASLayoutElementYogaMeasureFunc(YGNodeRef yogaNode,
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

#define AS_EDGE_INSETS_FROM_YGNODE_STYLE(yogaNode, property, dimensionFunc) \
  ASEdgeInsets insets;\
  YGEdge edge = YGEdgeLeft; \
  for (int i = 0; i < YGEdgeAll + 1; ++i) { \
    ASDimension dimension = dimensionFunc(YGNodeStyleGet##property(yogaNode, edge)); \
    switch (edge) { \
      case YGEdgeLeft: \
        insets.left = dimension; \
        break; \
      case YGEdgeTop: \
        insets.top = dimension; \
        break; \
      case YGEdgeRight: \
        insets.right = dimension; \
        break; \
      case YGEdgeBottom: \
        insets.bottom = dimension; \
        break; \
      case YGEdgeStart: \
        insets.start = dimension; \
        break; \
      case YGEdgeEnd: \
        insets.end = dimension; \
        break; \
      case YGEdgeHorizontal: \
        insets.horizontal = dimension; \
        break; \
      case YGEdgeVertical: \
        insets.vertical = dimension; \
        break; \
      case YGEdgeAll: \
        insets.all = dimension; \
        break; \
    } \
    edge = (YGEdge)(edge + 1); \
  } \
  return insets; \

#endif /* YOGA */
