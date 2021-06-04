//
//  ASYogaUtilities.h
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASAvailability.h>

#import <AsyncDisplayKit/ASLayout.h>
#import <AsyncDisplayKit/ASLog.h>
#import <AsyncDisplayKit/ASDisplayNode+Beta.h>

#if YOGA /* YOGA */
AS_ASSUME_NORETAIN_BEGIN
NS_ASSUME_NONNULL_BEGIN

// Should pass a string literal, not an NSString as the first argument to ASYogaLog
#define ASYogaLog(x, ...) as_log_verbose(ASLayoutLog(), x, ##__VA_ARGS__);

/** Helper function for Yoga baseline measurement. */
ASDK_EXTERN CGFloat ASTextGetBaseline(CGFloat height, ASDisplayNode *_Nullable yogaParent,
                                    NSAttributedString *str);

@interface ASDisplayNode (YogaHelpers)

+ (ASDisplayNode *)yogaNode;
+ (ASDisplayNode *)yogaSpacerNode;
+ (ASDisplayNode *)yogaVerticalStack;
+ (ASDisplayNode *)yogaHorizontalStack;

@end

#pragma mark - Yoga Type Conversion Helpers

ASDK_EXTERN YGAlign yogaAlignItems(ASStackLayoutAlignItems alignItems);
ASDK_EXTERN ASStackLayoutAlignItems stackAlignItems(YGAlign alignItems, bool baseline_is_last);
ASDK_EXTERN YGJustify yogaJustifyContent(ASStackLayoutJustifyContent justifyContent);
ASDK_EXTERN ASStackLayoutJustifyContent stackJustifyContent(YGJustify justifyContent);
ASDK_EXTERN YGAlign yogaAlignSelf(ASStackLayoutAlignSelf alignSelf);
ASDK_EXTERN ASStackLayoutAlignSelf stackAlignSelf(YGAlign alignSelf);
ASDK_EXTERN YGFlexDirection yogaFlexDirection(ASStackLayoutDirection direction);
ASDK_EXTERN ASStackLayoutDirection stackFlexDirection(YGFlexDirection direction);
ASDK_EXTERN float yogaFloatForCGFloat(CGFloat value);
ASDK_EXTERN CGFloat cgFloatForYogaFloat(float yogaFloat, CGFloat undefinedDefault);
ASDK_EXTERN float yogaDimensionToPoints(ASDimension dimension);
ASDK_EXTERN float yogaDimensionToPercent(ASDimension dimension);
ASDK_EXTERN YGValue yogaValueForDimension(ASDimension dimension);
ASDK_EXTERN ASDimension dimensionForYogaValue(YGValue value);
ASDK_EXTERN ASDimension dimensionForEdgeWithEdgeInsets(YGEdge edge, ASEdgeInsets insets);

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

NS_ASSUME_NONNULL_END
AS_ASSUME_NORETAIN_END

#endif /* YOGA */

