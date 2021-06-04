//
//  ASYogaUtilities.mm
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASDisplayNode+Yoga2.h>
#import <AsyncDisplayKit/ASLayoutElementStylePrivate.h>
#import <AsyncDisplayKit/ASYogaUtilities.h>

#if YOGA /* YOGA */

AS_ASSUME_NORETAIN_BEGIN

using namespace AS;

CGFloat ASTextGetBaseline(CGFloat height, ASDisplayNode *yogaParent, NSAttributedString *str) {
  if (!yogaParent) return height;
  NSUInteger len = str.length;
  if (!len) return height;
  BOOL isLast = (yogaParent.style.alignItems == ASStackLayoutAlignItemsBaselineLast);
  UIFont *font = [str attribute:NSFontAttributeName
                        atIndex:(isLast ? len - 1 : 0)
                 effectiveRange:NULL];
  return isLast ? height + font.descender : font.ascender;
}

@implementation ASDisplayNode (YogaHelpers)

+ (ASDisplayNode *)yogaNode
{
  ASDisplayNode *node = [[ASDisplayNode alloc] init];
  [node enableYoga];
  [node enableViewFlattening];
  return node;
}

+ (ASDisplayNode *)yogaSpacerNode
{
  ASDisplayNode *node = [ASDisplayNode yogaNode];
  node.style.flexGrow = 1.0f;
  return node;
}

+ (ASDisplayNode *)yogaVerticalStack
{
  ASDisplayNode *node = [self yogaNode];
  node.style.flexDirection = ASStackLayoutDirectionVertical;
  return node;
}

+ (ASDisplayNode *)yogaHorizontalStack
{
  ASDisplayNode *node = [self yogaNode];
  node.style.flexDirection = ASStackLayoutDirectionHorizontal;
  return node;
}

@end

#pragma mark - Yoga Type Conversion Helpers

YGAlign yogaAlignItems(ASStackLayoutAlignItems alignItems)
{
  switch (alignItems) {
    case ASStackLayoutAlignItemsNotSet:         return YGAlignAuto;
    case ASStackLayoutAlignItemsStart:          return YGAlignFlexStart;
    case ASStackLayoutAlignItemsEnd:            return YGAlignFlexEnd;
    case ASStackLayoutAlignItemsCenter:         return YGAlignCenter;
    case ASStackLayoutAlignItemsStretch:        return YGAlignStretch;
    case ASStackLayoutAlignItemsBaselineFirst:  return YGAlignBaseline;
      // FIXME: WARNING, Yoga does not currently support last-baseline item alignment.
    case ASStackLayoutAlignItemsBaselineLast:   return YGAlignBaseline;
  }
}

ASStackLayoutAlignItems stackAlignItems(YGAlign alignItems, bool baseline_is_last)
{
  switch (alignItems) {
    case YGAlignAuto:       return ASStackLayoutAlignItemsNotSet;
    case YGAlignFlexStart:  return ASStackLayoutAlignItemsStart;
    case YGAlignFlexEnd:    return ASStackLayoutAlignItemsEnd;
    case YGAlignCenter:     return ASStackLayoutAlignItemsCenter;
    case YGAlignStretch:    return ASStackLayoutAlignItemsStretch;
    case YGAlignBaseline:
      return (baseline_is_last ? ASStackLayoutAlignItemsBaselineLast
                               : ASStackLayoutAlignItemsBaselineFirst);
    case YGAlignSpaceAround:
    case YGAlignSpaceBetween: {
      NSCAssert(NO, @"Align items value not supported.");
      return ASStackLayoutAlignItemsNotSet;
    }
  }
}

YGJustify yogaJustifyContent(ASStackLayoutJustifyContent justifyContent)
{
  switch (justifyContent) {
    case ASStackLayoutJustifyContentStart:        return YGJustifyFlexStart;
    case ASStackLayoutJustifyContentCenter:       return YGJustifyCenter;
    case ASStackLayoutJustifyContentEnd:          return YGJustifyFlexEnd;
    case ASStackLayoutJustifyContentSpaceBetween: return YGJustifySpaceBetween;
    case ASStackLayoutJustifyContentSpaceAround:  return YGJustifySpaceAround;
    case ASStackLayoutJustifyContentSpaceEvenly:  return YGJustifySpaceEvenly;
  }
}

ASStackLayoutJustifyContent stackJustifyContent(YGJustify justifyContent)
{
  switch (justifyContent) {
    case YGJustifyFlexStart:    return ASStackLayoutJustifyContentStart;
    case YGJustifyCenter:       return ASStackLayoutJustifyContentCenter;
    case YGJustifyFlexEnd:      return ASStackLayoutJustifyContentEnd;
    case YGJustifySpaceBetween: return ASStackLayoutJustifyContentSpaceBetween;
    case YGJustifySpaceAround:  return ASStackLayoutJustifyContentSpaceAround;
    case YGJustifySpaceEvenly: {
      NSCAssert(NO, @"Justify content value not supported.");
      return ASStackLayoutJustifyContentStart;
    }
  }
}

YGAlign yogaAlignSelf(ASStackLayoutAlignSelf alignSelf)
{
  switch (alignSelf) {
    case ASStackLayoutAlignSelfStart:   return YGAlignFlexStart;
    case ASStackLayoutAlignSelfCenter:  return YGAlignCenter;
    case ASStackLayoutAlignSelfEnd:     return YGAlignFlexEnd;
    case ASStackLayoutAlignSelfStretch: return YGAlignStretch;
    case ASStackLayoutAlignSelfAuto:    return YGAlignAuto;
  }
}

ASStackLayoutAlignSelf stackAlignSelf(YGAlign alignSelf)
{
  switch (alignSelf) {
    case YGAlignFlexStart:  return ASStackLayoutAlignSelfStart;
    case YGAlignCenter:     return ASStackLayoutAlignSelfCenter;
    case YGAlignFlexEnd:    return ASStackLayoutAlignSelfEnd;
    case YGAlignStretch:    return ASStackLayoutAlignSelfStretch;
    case YGAlignAuto:       return ASStackLayoutAlignSelfAuto;
    case YGAlignBaseline:
    case YGAlignSpaceBetween:
    case YGAlignSpaceAround: {
      NSCAssert(NO, @"Align self value not supported.");
      return ASStackLayoutAlignSelfStart;
    }
  }
}

YGFlexDirection yogaFlexDirection(ASStackLayoutDirection direction)
{
  switch (direction) {
    case ASStackLayoutDirectionVertical:
      return YGFlexDirectionColumn;
    case ASStackLayoutDirectionVerticalReverse:
      return YGFlexDirectionColumnReverse;
    case ASStackLayoutDirectionHorizontal:
      return YGFlexDirectionRow;
    case ASStackLayoutDirectionHorizontalReverse:
      return YGFlexDirectionRowReverse;
  }
}

ASStackLayoutDirection stackFlexDirection(YGFlexDirection direction)
{
  switch (direction) {
    case YGFlexDirectionColumn:
      return ASStackLayoutDirectionVertical;
    case YGFlexDirectionColumnReverse:
      return ASStackLayoutDirectionVerticalReverse;
    case YGFlexDirectionRow:
      return ASStackLayoutDirectionHorizontal;
    case YGFlexDirectionRowReverse:
      return ASStackLayoutDirectionHorizontalReverse;
  }
}

float yogaFloatForCGFloat(CGFloat value)
{
  if (value < CGFLOAT_MAX / 2) {
    return value;
  } else {
    return YGUndefined;
  }
}

CGFloat cgFloatForYogaFloat(float yogaFloat, CGFloat undefinedDefault)
{
  return YGFloatIsUndefined(yogaFloat) ? undefinedDefault : yogaFloat;
}

float yogaDimensionToPoints(ASDimension dimension)
{
  ASDisplayNodeCAssert(dimension.unit == ASDimensionUnitPoints,
                       @"Dimensions should not be type Fraction for this method: %f", dimension.value);
  return yogaFloatForCGFloat(dimension.value);
}

float yogaDimensionToPercent(ASDimension dimension)
{
  ASDisplayNodeCAssert(dimension.unit == ASDimensionUnitFraction,
                       @"Dimensions should not be type Points for this method: %f", dimension.value);
  return 100.0 * yogaFloatForCGFloat(dimension.value);

}

YGValue yogaValueForDimension(ASDimension dimension)
{
  switch (dimension.unit) {
    case ASDimensionUnitFraction: {
      return (YGValue){yogaFloatForCGFloat(dimension.value), YGUnitPercent};
    }
    case ASDimensionUnitPoints: {
      return (YGValue){yogaFloatForCGFloat(dimension.value), YGUnitPoint};
    }
    case ASDimensionUnitAuto: {
      return (YGValue){yogaFloatForCGFloat(dimension.value), YGUnitAuto};
    }
  }
}

ASDimension dimensionForYogaValue(YGValue value)
{
  switch (value.unit) {
    case YGUnitPercent: {
      return ASDimensionMake(ASDimensionUnitFraction, cgFloatForYogaFloat(value.value, 0) / 100.0);
    }
    case YGUnitPoint: {
      return ASDimensionMake(ASDimensionUnitPoints, cgFloatForYogaFloat(value.value, 0));
    }
    case YGUnitAuto: {
      return ASDimensionMake(ASDimensionUnitAuto, cgFloatForYogaFloat(value.value, 0));
    }
    case YGUnitUndefined: {
      // YGUnitUndefined maps over to Auto, the default value within Texture
      return ASDimensionMake(ASDimensionUnitAuto, cgFloatForYogaFloat(value.value, 0));
    }
  }
}

ASDimension dimensionForEdgeWithEdgeInsets(YGEdge edge, ASEdgeInsets insets)
{
  switch (edge) {
    case YGEdgeLeft:          return insets.left;
    case YGEdgeTop:           return insets.top;
    case YGEdgeRight:         return insets.right;
    case YGEdgeBottom:        return insets.bottom;
    case YGEdgeStart:         return insets.start;
    case YGEdgeEnd:           return insets.end;
    case YGEdgeHorizontal:    return insets.horizontal;
    case YGEdgeVertical:      return insets.vertical;
    case YGEdgeAll:           return insets.all;
    default: ASDisplayNodeCAssert(NO, @"YGEdge other than ASEdgeInsets is not supported.");
      return ASDimensionAuto;
  }
}

AS_ASSUME_NORETAIN_END

#endif /* YOGA */
