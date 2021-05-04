//
//  ASLayoutElementStyleYoga.mm
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASAvailability.h>
#import <AsyncDisplayKit/ASLayoutElementStyleYoga.h>
#import <AsyncDisplayKit/ASDisplayNode+FrameworkPrivate.h>
#import <AsyncDisplayKit/ASDisplayNode+Yoga2.h>
#import <AsyncDisplayKit/ASDisplayNodeInternal.h>
#import <AsyncDisplayKit/ASInternalHelpers.h>
#import <AsyncDisplayKit/ASLayout.h>
#import <AsyncDisplayKit/ASObjectDescriptionHelpers.h>
#import <AsyncDisplayKit/ASThread.h>

#if YOGA

#import YOGA_HEADER_PATH
#import <AsyncDisplayKit/ASYogaUtilities.h>

using AS::MutexLocker;

@implementation ASLayoutElementStyleYoga {
  AS::MutexOrPointer __instanceLock__;

  YGNodeRef _yogaNode;
  struct {
    /**
     * Will move to node when style is removed for Yoga.
     * Indicates whether "YGAlignBaseline" means first or last.
     */
    BOOL alignItemsBaselineIsLast:1;
  } _flags;
}
@dynamic width, height, minWidth, maxWidth, minHeight, maxHeight;
@dynamic preferredSize, minSize, maxSize, preferredLayoutSize, minLayoutSize, maxLayoutSize;
@dynamic layoutPosition;

#pragma mark - Lifecycle

- (instancetype)init
{
  self = [super init];
  if (self) {
    _yogaNode = YGNodeNew();

    // Set default values that differ between Yoga and Texture
    // Default YGUnitAuto, this set's it to YGUnitUndefined as ASDimensionAuto maps to YGUnitUndefined
    YGNODE_STYLE_SET_DIMENSION(_yogaNode, FlexBasis, ASDimensionAuto);

    ASNodeContext *nodeContext = ASNodeContextGet();
    __instanceLock__.Configure(nodeContext ? &nodeContext->_mutex : nullptr);
  }
  return self;
}

ASSynthesizeLockingMethodsWithMutex(__instanceLock__)

#pragma mark - ASLayoutElementStyleSize

- (ASLayoutElementSize)size
{
  NSAssert(NO, @"Method unavailable in Yoga.");
  return {};
}

- (void)setSize:(ASLayoutElementSize)size
{
  NSAssert(NO, @"Method unavailable in Yoga.");
}

#pragma mark - ASLayoutElementStyleSizeForwarding

- (ASDimension)width
{
  MutexLocker l(__instanceLock__);
  return dimensionForYogaValue(YGNodeStyleGetWidth(_yogaNode));
}

- (void)setWidth:(ASDimension)width
{
  MutexLocker l(__instanceLock__);
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, Width, width);
}

- (ASDimension)height
{
  MutexLocker l(__instanceLock__);
  return dimensionForYogaValue(YGNodeStyleGetHeight(_yogaNode));
}

- (void)setHeight:(ASDimension)height
{
  MutexLocker l(__instanceLock__);
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, Height, height);
}

- (ASDimension)minWidth
{
  MutexLocker l(__instanceLock__);
  return dimensionForYogaValue(YGNodeStyleGetMinWidth(_yogaNode));
}

- (void)setMinWidth:(ASDimension)minWidth
{
  MutexLocker l(__instanceLock__);
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, MinWidth, minWidth);
}

- (ASDimension)maxWidth
{
  MutexLocker l(__instanceLock__);
  return dimensionForYogaValue(YGNodeStyleGetMaxWidth(_yogaNode));
}

- (void)setMaxWidth:(ASDimension)maxWidth
{
  MutexLocker l(__instanceLock__);
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, MaxWidth, maxWidth);
}

- (ASDimension)minHeight
{
  MutexLocker l(__instanceLock__);
  return dimensionForYogaValue(YGNodeStyleGetMinHeight(_yogaNode));
}

- (void)setMinHeight:(ASDimension)minHeight
{
  MutexLocker l(__instanceLock__);
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, MinHeight, minHeight);
}

- (ASDimension)maxHeight
{
  MutexLocker l(__instanceLock__);
  return dimensionForYogaValue(YGNodeStyleGetMaxHeight(_yogaNode));
}

- (void)setMaxHeight:(ASDimension)maxHeight
{
  MutexLocker l(__instanceLock__);
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, MaxHeight, maxHeight);
}


#pragma mark - ASLayoutElementStyleSizeHelpers

- (void)setPreferredSize:(CGSize)preferredSize
{
  NSAssert(NO, @"Method unavailable in Yoga.");
}

- (CGSize)preferredSize
{
  NSAssert(NO, @"Method unavailable in Yoga.");
  return CGSizeZero;
}

- (void)setMinSize:(CGSize)minSize
{
  NSAssert(NO, @"Method unavailable in Yoga.");
}

- (void)setMaxSize:(CGSize)maxSize
{
  NSAssert(NO, @"Method unavailable in Yoga.");
}

- (ASLayoutSize)preferredLayoutSize
{
  NSAssert(NO, @"Method unavailable in Yoga.");
  return {};
}

- (void)setPreferredLayoutSize:(ASLayoutSize)preferredLayoutSize
{
  NSAssert(NO, @"Method unavailable in Yoga.");
}

- (ASLayoutSize)minLayoutSize
{
  NSAssert(NO, @"Method unavailable in Yoga.");
  return {};
}

- (void)setMinLayoutSize:(ASLayoutSize)minLayoutSize
{
  NSAssert(NO, @"Method unavailable in Yoga.");
}

- (ASLayoutSize)maxLayoutSize
{
  NSAssert(NO, @"Method unavailable in Yoga.");
  return {};
}

- (void)setMaxLayoutSize:(ASLayoutSize)maxLayoutSize
{
  NSAssert(NO, @"Method unavailable in Yoga.");
}

#pragma mark - ASStackLayoutElement

- (void)setSpacingBefore:(CGFloat)spacingBefore
{
  NSAssert(NO, @"Method unavailable in Yoga.");
}

- (CGFloat)spacingBefore
{
  NSAssert(NO, @"Method unavailable in Yoga.");
  return 0;
}

- (void)setSpacingAfter:(CGFloat)spacingAfter
{
  NSAssert(NO, @"Method unavailable in Yoga.");
}

- (CGFloat)spacingAfter
{
  NSAssert(NO, @"Method unavailable in Yoga.");
  return 0;
}

- (void)setFlexGrow:(CGFloat)flexGrow
{
  MutexLocker l(__instanceLock__);
  YGNodeStyleSetFlexGrow(_yogaNode, flexGrow);
}

- (CGFloat)flexGrow
{
  MutexLocker l(__instanceLock__);
  return YGNodeStyleGetFlexGrow(_yogaNode);
}

- (void)setFlexShrink:(CGFloat)flexShrink
{
  MutexLocker l(__instanceLock__);
  YGNodeStyleSetFlexShrink(_yogaNode, flexShrink);
}

- (CGFloat)flexShrink
{
  MutexLocker l(__instanceLock__);
  return YGNodeStyleGetFlexShrink(_yogaNode);
}

- (void)setFlexBasis:(ASDimension)flexBasis
{
  MutexLocker l(__instanceLock__);
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, FlexBasis, flexBasis);
}

- (ASDimension)flexBasis
{
  MutexLocker l(__instanceLock__);
  return dimensionForYogaValue(YGNodeStyleGetFlexBasis(_yogaNode));
}

- (void)setAlignSelf:(ASStackLayoutAlignSelf)alignSelf
{
  MutexLocker l(__instanceLock__);
  YGNodeStyleSetAlignSelf(_yogaNode, yogaAlignSelf(alignSelf));
}

- (ASStackLayoutAlignSelf)alignSelf
{
  MutexLocker l(__instanceLock__);
  return stackAlignSelf(YGNodeStyleGetAlignSelf(_yogaNode));
}

- (void)setAscender:(CGFloat)ascender
{
  NSAssert(NO, @"Method unavailable in Yoga.");
}

- (CGFloat)ascender
{
  NSAssert(NO, @"Method unavailable in Yoga.");
  return 0;
}

- (void)setDescender:(CGFloat)descender
{
  NSAssert(NO, @"Method unavailable in Yoga.");
}

- (CGFloat)descender
{
  NSAssert(NO, @"Method unavailable in Yoga.");
  return 0;
}

#pragma mark - ASAbsoluteLayoutElement

- (void)setLayoutPosition:(CGPoint)layoutPosition
{
  // NSCAssert(NO, @"layoutPosition not supported in Yoga");
}

- (CGPoint)layoutPosition
{
  // NSCAssert(NO, @"layoutPosition not supported in Yoga");
  return CGPointZero;
}

#pragma mark - Extensibility

- (void)setLayoutOptionExtensionBool:(BOOL)value atIndex:(int)idx
{
  NSCAssert(NO, @"Layout option extensions not supported in Yoga");
}

- (BOOL)layoutOptionExtensionBoolAtIndex:(int)idx
{
  NSCAssert(NO, @"Layout option extensions not supported in Yoga");
  return NO;
}

- (void)setLayoutOptionExtensionInteger:(NSInteger)value atIndex:(int)idx
{
  NSCAssert(NO, @"Layout option extensions not supported in Yoga");
}

- (NSInteger)layoutOptionExtensionIntegerAtIndex:(int)idx
{
  NSCAssert(NO, @"Layout option extensions not supported in Yoga");
  return 0;
}

- (void)setLayoutOptionExtensionEdgeInsets:(UIEdgeInsets)value atIndex:(int)idx
{
  NSCAssert(NO, @"Layout option extensions not supported in Yoga");
}

- (UIEdgeInsets)layoutOptionExtensionEdgeInsetsAtIndex:(int)idx
{
  NSCAssert(NO, @"Layout option extensions not supported in Yoga");
  return UIEdgeInsetsZero;
}

#pragma mark - Debugging

- (NSString *)description
{
  return ASObjectDescriptionMake(self, [self propertiesForDescription]);
}

- (NSMutableArray<NSDictionary *> *)propertiesForDescription
{
  NSMutableArray<NSDictionary *> *result = [NSMutableArray array];

  if ((self.minLayoutSize.width.unit != ASDimensionUnitAuto ||
    self.minLayoutSize.height.unit != ASDimensionUnitAuto)) {
    [result addObject:@{ @"minLayoutSize" : NSStringFromASLayoutSize(self.minLayoutSize) }];
  }

  if ((self.preferredLayoutSize.width.unit != ASDimensionUnitAuto ||
    self.preferredLayoutSize.height.unit != ASDimensionUnitAuto)) {
    [result addObject:@{ @"preferredSize" : NSStringFromASLayoutSize(self.preferredLayoutSize) }];
  }

  if ((self.maxLayoutSize.width.unit != ASDimensionUnitAuto ||
    self.maxLayoutSize.height.unit != ASDimensionUnitAuto)) {
    [result addObject:@{ @"maxLayoutSize" : NSStringFromASLayoutSize(self.maxLayoutSize) }];
  }

  if (self.alignSelf != ASStackLayoutAlignSelfAuto) {
    [result addObject:@{ @"alignSelf" : [@[@"ASStackLayoutAlignSelfAuto",
                                          @"ASStackLayoutAlignSelfStart",
                                          @"ASStackLayoutAlignSelfEnd",
                                          @"ASStackLayoutAlignSelfCenter",
                                          @"ASStackLayoutAlignSelfStretch"] objectAtIndex:self.alignSelf] }];
  }

  if (self.ascender != 0) {
    [result addObject:@{ @"ascender" : @(self.ascender) }];
  }

  if (self.descender != 0) {
    [result addObject:@{ @"descender" : @(self.descender) }];
  }

  if (ASDimensionEqualToDimension(self.flexBasis, ASDimensionAuto) == NO) {
    [result addObject:@{ @"flexBasis" : NSStringFromASDimension(self.flexBasis) }];
  }

  if (self.flexGrow != 0) {
    [result addObject:@{ @"flexGrow" : @(self.flexGrow) }];
  }

  if (self.flexShrink != 0) {
    [result addObject:@{ @"flexShrink" : @(self.flexShrink) }];
  }

  if (self.spacingAfter != 0) {
    [result addObject:@{ @"spacingAfter" : @(self.spacingAfter) }];
  }

  if (self.spacingBefore != 0) {
    [result addObject:@{ @"spacingBefore" : @(self.spacingBefore) }];
  }

  return result;
}

+ (void)initialize
{
  [super initialize];
  YGConfigSetPointScaleFactor(YGConfigGetDefault(), ASScreenScale());
  // Yoga recommends using Web Defaults for all new projects. This will be enabled for Texture very soon.
  //YGConfigSetUseWebDefaults(YGConfigGetDefault(), true);
}

- (YGNodeRef)yogaNode
{
  return _yogaNode;
}

- (void)dealloc
{
  YGNodeFree(_yogaNode);
}

- (YGWrap)flexWrap
{
  MutexLocker l(__instanceLock__);
  return YGNodeStyleGetFlexWrap(_yogaNode);
}

- (ASStackLayoutDirection)flexDirection
{
  MutexLocker l(__instanceLock__);
  return stackFlexDirection(YGNodeStyleGetFlexDirection(_yogaNode));
}

- (YGDirection)direction
{
  MutexLocker l(__instanceLock__);
  return YGNodeStyleGetDirection(_yogaNode);
}

- (ASStackLayoutJustifyContent)justifyContent
{
  return stackJustifyContent(YGNodeStyleGetJustifyContent(_yogaNode));
}

- (ASStackLayoutAlignItems)alignItems
{
  return stackAlignItems(YGNodeStyleGetAlignItems(_yogaNode), _flags.alignItemsBaselineIsLast);
}

- (ASStackLayoutAlignItems)alignContent
{
  return stackAlignItems(YGNodeStyleGetAlignContent(_yogaNode), false);
}

- (YGPositionType)positionType
{
  MutexLocker l(__instanceLock__);
  return YGNodeStyleGetPositionType(_yogaNode);
}

- (ASEdgeInsets)position
{
  MutexLocker l(__instanceLock__);
  AS_EDGE_INSETS_FROM_YGNODE_STYLE(_yogaNode, Position, dimensionForYogaValue);
}

- (ASEdgeInsets)margin
{
  MutexLocker l(__instanceLock__);
  AS_EDGE_INSETS_FROM_YGNODE_STYLE(_yogaNode, Margin, dimensionForYogaValue);
}

- (ASEdgeInsets)padding
{
  MutexLocker l(__instanceLock__);
  AS_EDGE_INSETS_FROM_YGNODE_STYLE(_yogaNode, Padding, dimensionForYogaValue);
}

- (ASEdgeInsets)border
{
  MutexLocker l(__instanceLock__);
  AS_EDGE_INSETS_FROM_YGNODE_STYLE(_yogaNode, Border, [](float border) -> ASDimension {
    return ASDimensionMake(ASDimensionUnitPoints, cgFloatForYogaFloat(border, 0));
  });
}

- (CGFloat)aspectRatio
{
  MutexLocker l(__instanceLock__);
  return YGNodeStyleGetAspectRatio(_yogaNode);
}

- (YGOverflow)overflow
{
  MutexLocker l(__instanceLock__);
  return YGNodeStyleGetOverflow(_yogaNode);
}

- (void)setFlexWrap:(YGWrap)flexWrap
{
  MutexLocker l(__instanceLock__);
  YGNodeStyleSetFlexWrap(_yogaNode, flexWrap);
}

- (void)setFlexDirection:(ASStackLayoutDirection)flexDirection
{
  MutexLocker l(__instanceLock__);
  YGNodeStyleSetFlexDirection(_yogaNode, yogaFlexDirection(flexDirection));
}

- (void)setDirection:(YGDirection)direction
{
  MutexLocker l(__instanceLock__);
  YGNodeStyleSetDirection(_yogaNode, direction);
}

- (void)setJustifyContent:(ASStackLayoutJustifyContent)justify
{
  MutexLocker l(__instanceLock__);
  YGNodeStyleSetJustifyContent(_yogaNode, yogaJustifyContent(justify));
}

- (void)setAlignItems:(ASStackLayoutAlignItems)alignItems
{
  MutexLocker l(__instanceLock__);
  _flags.alignItemsBaselineIsLast = (alignItems == ASStackLayoutAlignItemsBaselineLast);
  YGNodeStyleSetAlignItems(_yogaNode, yogaAlignItems(alignItems));
}

- (void)setAlignContent:(ASStackLayoutAlignItems)alignContent
{
  MutexLocker l(__instanceLock__);
  YGNodeStyleSetAlignContent(_yogaNode, yogaAlignItems(alignContent));
}

- (void)setPositionType:(YGPositionType)positionType
{
  MutexLocker l(__instanceLock__);
  YGNodeStyleSetPositionType(_yogaNode, positionType);
}

- (void)setPosition:(ASEdgeInsets)position
{
  MutexLocker l(__instanceLock__);
  YGEdge edge = YGEdgeLeft;
  for (int i = 0; i < YGEdgeAll + 1; ++i) {
    YGNODE_STYLE_SET_DIMENSION_WITH_EDGE(_yogaNode, Position, dimensionForEdgeWithEdgeInsets(edge, position), edge);
    edge = (YGEdge)(edge + 1);
  }
}

- (void)setMargin:(ASEdgeInsets)margin
{
  MutexLocker l(__instanceLock__);
  YGEdge edge = YGEdgeLeft;
  for (int i = 0; i < YGEdgeAll + 1; ++i) {
    YGNODE_STYLE_SET_DIMENSION_WITH_EDGE(_yogaNode, Margin, dimensionForEdgeWithEdgeInsets(edge, margin), edge);
    edge = (YGEdge)(edge + 1);
  }
}

- (void)setPadding:(ASEdgeInsets)padding
{
  MutexLocker l(__instanceLock__);
  YGEdge edge = YGEdgeLeft;
  for (int i = 0; i < YGEdgeAll + 1; ++i) {
    YGNODE_STYLE_SET_DIMENSION_WITH_EDGE(_yogaNode, Padding, dimensionForEdgeWithEdgeInsets(edge, padding), edge);
    edge = (YGEdge)(edge + 1);
  }
}

- (void)setBorder:(ASEdgeInsets)border
{
  MutexLocker l(__instanceLock__);
  YGEdge edge = YGEdgeLeft;
  for (int i = 0; i < YGEdgeAll + 1; ++i) {
    YGNODE_STYLE_SET_FLOAT_WITH_EDGE(_yogaNode, Border, dimensionForEdgeWithEdgeInsets(edge, border), edge);
    edge = (YGEdge)(edge + 1);
  }
}

- (void)setAspectRatio:(CGFloat)aspectRatio
{
  MutexLocker l(__instanceLock__);
  if (aspectRatio > FLT_EPSILON && aspectRatio < CGFLOAT_MAX / 2.0) {
    YGNodeStyleSetAspectRatio(_yogaNode, aspectRatio);
  }
}

- (void)setOverflow:(YGOverflow)overflow
{
  MutexLocker l(__instanceLock__);
  YGNodeStyleSetOverflow(_yogaNode, overflow);
}

@end

#endif /* YOGA */
