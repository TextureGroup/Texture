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
#import <AsyncDisplayKit/ASDisplayNodeInternal.h>
#import <AsyncDisplayKit/ASInternalHelpers.h>
#import <AsyncDisplayKit/ASLayout.h>
#import <AsyncDisplayKit/ASLayoutElement.h>
#import <AsyncDisplayKit/ASObjectDescriptionHelpers.h>
#import <AsyncDisplayKit/ASThread.h>

#if YOGA

#import YOGA_HEADER_PATH
#import <AsyncDisplayKit/ASYogaUtilities.h>

NSString * const ASYogaFlexWrapProperty = @"ASLayoutElementStyleLayoutFlexWrapProperty";
NSString * const ASYogaFlexDirectionProperty = @"ASYogaFlexDirectionProperty";
NSString * const ASYogaDirectionProperty = @"ASYogaDirectionProperty";
NSString * const ASYogaSpacingProperty = @"ASYogaSpacingProperty";
NSString * const ASYogaJustifyContentProperty = @"ASYogaJustifyContentProperty";
NSString * const ASYogaAlignItemsProperty = @"ASYogaAlignItemsProperty";
NSString * const ASYogaPositionTypeProperty = @"ASYogaPositionTypeProperty";
NSString * const ASYogaPositionProperty = @"ASYogaPositionProperty";
NSString * const ASYogaMarginProperty = @"ASYogaMarginProperty";
NSString * const ASYogaPaddingProperty = @"ASYogaPaddingProperty";
NSString * const ASYogaBorderProperty = @"ASYogaBorderProperty";
NSString * const ASYogaAspectRatioProperty = @"ASYogaAspectRatioProperty";
NSString * const ASYogaOverflowProperty = @"ASYogaOverflowProperty";
NSString * const ASLayoutElementStyleParentAlignStyle = @"ASLayoutElementStyleParentAlignStyle";

using AS::MutexLocker;

#define ASLayoutElementStyleCallDelegate(propertyName)\
do {\
  [_delegate style:(ASLayoutElementStyle *)self propertyDidChange:propertyName];\
} while(0)

@implementation ASLayoutElementStyleYoga {
  AS::RecursiveMutex __instanceLock__;
  YGNodeRef _yogaNode;

  std::atomic<CGFloat> _spacingBefore;
  std::atomic<CGFloat> _spacingAfter;
  std::atomic<CGFloat> _ascender;
  std::atomic<CGFloat> _descender;

  std::atomic<ASStackLayoutAlignItems> _parentAlignStyle;
}

@dynamic width, height, minWidth, maxWidth, minHeight, maxHeight;
@dynamic preferredSize, minSize, maxSize, preferredLayoutSize, minLayoutSize, maxLayoutSize;
@dynamic layoutPosition;

#pragma mark - Lifecycle

- (instancetype)initWithDelegate:(id<ASLayoutElementStyleDelegate>)delegate
{
  self = [self init];
  if (self) {
    _delegate = delegate;
  }
  return self;
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    // If we use the Yoga node as backing store  we have to create a yoga node for
    // every ASDisplayNode
    [self yogaNodeCreateIfNeeded];

    std::atomic_init(&_parentAlignStyle, ASStackLayoutAlignItemsNotSet);

    // Set default values that differ between Yoga and Texture
    YGNODE_STYLE_SET_DIMENSION(_yogaNode, FlexBasis, ASDimensionAuto);
    YGNodeStyleSetFlexDirection(_yogaNode, yogaFlexDirection(ASStackLayoutDirectionVertical));
    YGNodeStyleSetAlignItems(_yogaNode, yogaAlignItems(ASStackLayoutAlignItemsStretch));
    YGNodeStyleSetAspectRatio(_yogaNode, YGUndefined);
  }
  return self;
}

ASSynthesizeLockingMethodsWithMutex(__instanceLock__)

#pragma mark - ASLayoutElementStyleSize

- (ASLayoutElementSize)size
{
  MutexLocker l(__instanceLock__);
  return (ASLayoutElementSize){
    dimensionForYogaValue(YGNodeStyleGetWidth(_yogaNode)),
    dimensionForYogaValue(YGNodeStyleGetHeight(_yogaNode)),
    dimensionForYogaValue(YGNodeStyleGetMinWidth(_yogaNode)),
    dimensionForYogaValue(YGNodeStyleGetMaxWidth(_yogaNode)),
    dimensionForYogaValue(YGNodeStyleGetMinHeight(_yogaNode)),
    dimensionForYogaValue(YGNodeStyleGetMaxHeight(_yogaNode)),
  };
}

- (void)setSize:(ASLayoutElementSize)size
{
  MutexLocker l(__instanceLock__);
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, Width, size.width);
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, Height, size.height);
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, MinWidth, size.minWidth);
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, MaxWidth, size.maxWidth);
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, MinHeight, size.minHeight);
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, MaxHeight, size.maxHeight);
}

#pragma mark - ASLayoutElementStyleSizeForwarding

- (ASDimension)width
{
  MutexLocker l(__instanceLock__);
  return dimensionForYogaValue(YGNodeStyleGetWidth(_yogaNode));
}

- (void)setWidth:(ASDimension)width
{
  {
    MutexLocker l(__instanceLock__);
    YGNODE_STYLE_SET_DIMENSION(_yogaNode, Width, width);
  }
  ASLayoutElementStyleCallDelegate(ASLayoutElementStyleWidthProperty);
}

- (ASDimension)height
{
  MutexLocker l(__instanceLock__);
  return dimensionForYogaValue(YGNodeStyleGetHeight(_yogaNode));
}

- (void)setHeight:(ASDimension)height
{
  {
    MutexLocker l(__instanceLock__);
    YGNODE_STYLE_SET_DIMENSION(_yogaNode, Height, height);
  }
  ASLayoutElementStyleCallDelegate(ASLayoutElementStyleHeightProperty);
}

- (ASDimension)minWidth
{
  MutexLocker l(__instanceLock__);
  return dimensionForYogaValue(YGNodeStyleGetMinWidth(_yogaNode));
}

- (void)setMinWidth:(ASDimension)minWidth
{
  {
    MutexLocker l(__instanceLock__);
    YGNODE_STYLE_SET_DIMENSION(_yogaNode, MinWidth, minWidth);
  }
  ASLayoutElementStyleCallDelegate(ASLayoutElementStyleMinWidthProperty);
}

- (ASDimension)maxWidth
{
  MutexLocker l(__instanceLock__);
  return dimensionForYogaValue(YGNodeStyleGetMaxWidth(_yogaNode));
}

- (void)setMaxWidth:(ASDimension)maxWidth
{
  {
    MutexLocker l(__instanceLock__);
    YGNODE_STYLE_SET_DIMENSION(_yogaNode, MaxWidth, maxWidth);
  }
  ASLayoutElementStyleCallDelegate(ASLayoutElementStyleMaxWidthProperty);
}

- (ASDimension)minHeight
{
  MutexLocker l(__instanceLock__);
  return dimensionForYogaValue(YGNodeStyleGetMinWidth(_yogaNode));
}

- (void)setMinHeight:(ASDimension)minHeight
{
  {
    MutexLocker l(__instanceLock__);
    YGNODE_STYLE_SET_DIMENSION(_yogaNode, MinHeight, minHeight);
  }
  ASLayoutElementStyleCallDelegate(ASLayoutElementStyleMinHeightProperty);
}

- (ASDimension)maxHeight
{
  MutexLocker l(__instanceLock__);
  return dimensionForYogaValue(YGNodeStyleGetMaxHeight(_yogaNode));
}

- (void)setMaxHeight:(ASDimension)maxHeight
{
  {
    MutexLocker l(__instanceLock__);
    YGNODE_STYLE_SET_DIMENSION(_yogaNode, MaxHeight, maxHeight);
  }
  ASLayoutElementStyleCallDelegate(ASLayoutElementStyleMaxHeightProperty);
}


#pragma mark - ASLayoutElementStyleSizeHelpers

- (void)setPreferredSize:(CGSize)preferredSize
{
  {
    MutexLocker l(__instanceLock__);
    YGNODE_STYLE_SET_DIMENSION(_yogaNode, Width, ASDimensionMakeWithPoints(preferredSize.width));
    YGNODE_STYLE_SET_DIMENSION(_yogaNode, Height, ASDimensionMakeWithPoints(preferredSize.height));
  }
  ASLayoutElementStyleCallDelegate(ASLayoutElementStyleWidthProperty);
  ASLayoutElementStyleCallDelegate(ASLayoutElementStyleHeightProperty);
}

- (CGSize)preferredSize
{
  MutexLocker l(__instanceLock__);
  YGValue width = YGNodeStyleGetWidth(_yogaNode);
  YGValue height = YGNodeStyleGetHeight(_yogaNode);
  if (width.unit != YGUnitPoint) {
    NSCAssert(NO, @"Cannot get preferredSize of element with fractional width. Width: %f.",  width.value);
    return CGSizeZero;
  }

  if (height.unit != YGUnitPoint) {
    NSCAssert(height.unit != YGUnitPoint, @"Cannot get preferredSize of element with fractional height. Height: %f.", height.value);
    return CGSizeZero;
  }

  return (CGSize){cgFloatForYogaFloat(width.value, 0), cgFloatForYogaFloat(height.value, 0)};
}

- (void)setMinSize:(CGSize)minSize
{
  {
    MutexLocker l(__instanceLock__);
    YGNodeStyleSetMinWidth(_yogaNode, minSize.width);
    YGNodeStyleSetMinHeight(_yogaNode, minSize.height);
  }
  ASLayoutElementStyleCallDelegate(ASLayoutElementStyleMinWidthProperty);
  ASLayoutElementStyleCallDelegate(ASLayoutElementStyleMinHeightProperty);
}

- (void)setMaxSize:(CGSize)maxSize
{
  {
    MutexLocker l(__instanceLock__);
    YGNodeStyleSetMaxWidth(_yogaNode, maxSize.width);
    YGNodeStyleSetMaxHeight(_yogaNode, maxSize.height);
  }
  ASLayoutElementStyleCallDelegate(ASLayoutElementStyleMaxWidthProperty);
  ASLayoutElementStyleCallDelegate(ASLayoutElementStyleMaxHeightProperty);
}

- (ASLayoutSize)preferredLayoutSize
{
  return ASLayoutSizeMake(
    dimensionForYogaValue(YGNodeStyleGetWidth(_yogaNode)),
    dimensionForYogaValue(YGNodeStyleGetHeight(_yogaNode))
  );
}

- (void)setPreferredLayoutSize:(ASLayoutSize)preferredLayoutSize
{
  {
    MutexLocker l(__instanceLock__);
    YGNODE_STYLE_SET_DIMENSION(_yogaNode, Width, preferredLayoutSize.width);
    YGNODE_STYLE_SET_DIMENSION(_yogaNode, Width, preferredLayoutSize.height);
  }
  ASLayoutElementStyleCallDelegate(ASLayoutElementStyleWidthProperty);
  ASLayoutElementStyleCallDelegate(ASLayoutElementStyleHeightProperty);
}

- (ASLayoutSize)minLayoutSize
{
  return ASLayoutSizeMake(
    dimensionForYogaValue(YGNodeStyleGetMinWidth(_yogaNode)),
    dimensionForYogaValue(YGNodeStyleGetMinHeight(_yogaNode))
  );
}

- (void)setMinLayoutSize:(ASLayoutSize)minLayoutSize
{
  {
    MutexLocker l(__instanceLock__);
    YGNODE_STYLE_SET_DIMENSION(_yogaNode, MinWidth, minLayoutSize.width);
    YGNODE_STYLE_SET_DIMENSION(_yogaNode, MinHeight, minLayoutSize.height);
  }
  ASLayoutElementStyleCallDelegate(ASLayoutElementStyleMinWidthProperty);
  ASLayoutElementStyleCallDelegate(ASLayoutElementStyleMinHeightProperty);
}

- (ASLayoutSize)maxLayoutSize
{
  MutexLocker l(__instanceLock__);
  return ASLayoutSizeMake(
    dimensionForYogaValue(YGNodeStyleGetMaxWidth(_yogaNode)),
    dimensionForYogaValue(YGNodeStyleGetMaxHeight(_yogaNode))
  );
}

- (void)setMaxLayoutSize:(ASLayoutSize)maxLayoutSize
{
  {
    MutexLocker l(__instanceLock__);
    YGNODE_STYLE_SET_DIMENSION(_yogaNode, MaxWidth, maxLayoutSize.width);
    YGNODE_STYLE_SET_DIMENSION(_yogaNode, MaxHeight, maxLayoutSize.height);
  }
  ASLayoutElementStyleCallDelegate(ASLayoutElementStyleMaxWidthProperty);
  ASLayoutElementStyleCallDelegate(ASLayoutElementStyleMaxHeightProperty);
}

#pragma mark - ASStackLayoutElement

- (void)setSpacingBefore:(CGFloat)spacingBefore
{
  // Not an equivalent on _yogaNode
  if (_spacingBefore.exchange(spacingBefore) != spacingBefore) {
    ASLayoutElementStyleCallDelegate(ASLayoutElementStyleSpacingBeforeProperty);
  }
}

- (CGFloat)spacingBefore
{
  // Not an equivalent on _yogaNode
  return _spacingBefore.load();
}

- (void)setSpacingAfter:(CGFloat)spacingAfter
{
  // Not an equivalent on _yogaNode
  if (_spacingAfter.exchange(spacingAfter) != spacingAfter) {
    ASLayoutElementStyleCallDelegate(ASLayoutElementStyleSpacingAfterProperty);
  }
}

- (CGFloat)spacingAfter
{
  // Not an equivalent on _yogaNode
  return _spacingAfter.load();
}

- (void)setFlexGrow:(CGFloat)flexGrow
{
  {
    MutexLocker l(__instanceLock__);
    YGNodeStyleSetFlexGrow(_yogaNode, flexGrow);
  }
  ASLayoutElementStyleCallDelegate(ASLayoutElementStyleFlexGrowProperty);
}

- (CGFloat)flexGrow
{
  MutexLocker l(__instanceLock__);
  return YGNodeStyleGetFlexGrow(_yogaNode);
}

- (void)setFlexShrink:(CGFloat)flexShrink
{
  {
    MutexLocker l(__instanceLock__);
    YGNodeStyleSetFlexShrink(_yogaNode, flexShrink);
  }
  ASLayoutElementStyleCallDelegate(ASLayoutElementStyleFlexShrinkProperty);
}

- (CGFloat)flexShrink
{
  MutexLocker l(__instanceLock__);
  return YGNodeStyleGetFlexShrink(_yogaNode);
}

- (void)setFlexBasis:(ASDimension)flexBasis
{
  {
    MutexLocker l(__instanceLock__);
    YGNODE_STYLE_SET_DIMENSION(_yogaNode, FlexBasis, flexBasis);
  }
  ASLayoutElementStyleCallDelegate(ASLayoutElementStyleFlexBasisProperty);
}

- (ASDimension)flexBasis
{
  MutexLocker l(__instanceLock__);
  return dimensionForYogaValue(YGNodeStyleGetFlexBasis(_yogaNode));
}

- (void)setAlignSelf:(ASStackLayoutAlignSelf)alignSelf
{
  {
    MutexLocker l(__instanceLock__);
    YGNodeStyleSetAlignSelf(_yogaNode, yogaAlignSelf(alignSelf));
  }
  ASLayoutElementStyleCallDelegate(ASLayoutElementStyleAlignSelfProperty);
}

- (ASStackLayoutAlignSelf)alignSelf
{
  MutexLocker l(__instanceLock__);
  return stackAlignSelf(YGNodeStyleGetAlignSelf(_yogaNode));
}

- (void)setAscender:(CGFloat)ascender
{
  // Not an equivalent on _yogaNode
  if (_ascender.exchange(ascender) != ascender) {
    ASLayoutElementStyleCallDelegate(ASLayoutElementStyleAscenderProperty);
  }
}

- (CGFloat)ascender
{
  // Not an equivalent on _yogaNode
  return _ascender.load();
}

- (void)setDescender:(CGFloat)descender
{
  // Not an equivalent on _yogaNode
  if (_descender.exchange(descender) != descender) {
    ASLayoutElementStyleCallDelegate(ASLayoutElementStyleDescenderProperty);
  }
}

- (CGFloat)descender
{
  // Not an equivalent on _yogaNode
  return _descender.load();
}

#pragma mark - ASAbsoluteLayoutElement

- (void)setLayoutPosition:(CGPoint)layoutPosition
{
  NSCAssert(NO, @"layoutPosition not supported in Yoga");
}

- (CGPoint)layoutPosition
{
  NSCAssert(NO, @"layoutPosition not supported in Yoga");
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

- (YGNodeRef)yogaNodeCreateIfNeeded
{
  if (_yogaNode == NULL) {
    _yogaNode = YGNodeNew();
  }
  return _yogaNode;
}

- (void)destroyYogaNode
{
  if (_yogaNode != NULL) {
    if (ASDisplayNode *delegateAsNode = ASDynamicCast(_delegate, ASDisplayNode)) {
      MutexLocker l(delegateAsNode->__instanceLock__);
      ASLayoutElementYogaUpdateMeasureFunc(_yogaNode, nil);
    }
    YGNodeFree(_yogaNode);
    _yogaNode = NULL;
  }
}

- (void)dealloc
{
  [self destroyYogaNode];
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
  return stackAlignItems(YGNodeStyleGetAlignItems(_yogaNode));
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

// private (ASLayoutElementStylePrivate.h)
- (ASStackLayoutAlignItems)parentAlignStyle
{
  // Not an equivalent on _yogaNode
  return _parentAlignStyle.load();
}

- (YGOverflow)overflow
{
  MutexLocker l(__instanceLock__);
  return YGNodeStyleGetOverflow(_yogaNode);
}

- (void)setFlexWrap:(YGWrap)flexWrap
{
  {
    MutexLocker l(__instanceLock__);
    YGNodeStyleSetFlexWrap(_yogaNode, flexWrap);
  }
  ASLayoutElementStyleCallDelegate(ASYogaFlexWrapProperty);
}

- (void)setFlexDirection:(ASStackLayoutDirection)flexDirection
{
  {
    MutexLocker l(__instanceLock__);
    YGNodeStyleSetFlexDirection(_yogaNode, yogaFlexDirection(flexDirection));
  }
  ASLayoutElementStyleCallDelegate(ASYogaFlexDirectionProperty);
}

- (void)setDirection:(YGDirection)direction
{
  {
    MutexLocker l(__instanceLock__);
    YGNodeStyleSetDirection(_yogaNode, direction);
  }
  ASLayoutElementStyleCallDelegate(ASYogaDirectionProperty);
}

- (void)setJustifyContent:(ASStackLayoutJustifyContent)justify
{
  {
    MutexLocker l(__instanceLock__);
    YGNodeStyleSetJustifyContent(_yogaNode, yogaJustifyContent(justify));
  }
  ASLayoutElementStyleCallDelegate(ASYogaJustifyContentProperty);
}

- (void)setAlignItems:(ASStackLayoutAlignItems)alignItems
{
  {
    MutexLocker l(__instanceLock__);
    YGNodeStyleSetAlignItems(_yogaNode, yogaAlignItems(alignItems));
  }
  ASLayoutElementStyleCallDelegate(ASYogaAlignItemsProperty);
}

- (void)setPositionType:(YGPositionType)positionType
{
  {
    MutexLocker l(__instanceLock__);
    YGNodeStyleSetPositionType(_yogaNode, positionType);
  }
  ASLayoutElementStyleCallDelegate(ASYogaPositionTypeProperty);
}

- (void)setPosition:(ASEdgeInsets)position
{
  {
  MutexLocker l(__instanceLock__);
    YGEdge edge = YGEdgeLeft;
    for (int i = 0; i < YGEdgeAll + 1; ++i) {
      YGNODE_STYLE_SET_DIMENSION_WITH_EDGE(_yogaNode, Position, dimensionForEdgeWithEdgeInsets(edge, position), edge);
      edge = (YGEdge)(edge + 1);
    }
  }
  ASLayoutElementStyleCallDelegate(ASYogaPositionProperty);
}

- (void)setMargin:(ASEdgeInsets)margin
{
  {
    MutexLocker l(__instanceLock__);
    YGEdge edge = YGEdgeLeft;
    for (int i = 0; i < YGEdgeAll + 1; ++i) {
      YGNODE_STYLE_SET_DIMENSION_WITH_EDGE(_yogaNode, Margin, dimensionForEdgeWithEdgeInsets(edge, margin), edge);
      edge = (YGEdge)(edge + 1);
    }
  }
  ASLayoutElementStyleCallDelegate(ASYogaMarginProperty);
}

- (void)setPadding:(ASEdgeInsets)padding
{
  {
    MutexLocker l(__instanceLock__);
    YGEdge edge = YGEdgeLeft;
    for (int i = 0; i < YGEdgeAll + 1; ++i) {
      YGNODE_STYLE_SET_DIMENSION_WITH_EDGE(_yogaNode, Padding, dimensionForEdgeWithEdgeInsets(edge, padding), edge);
      edge = (YGEdge)(edge + 1);
    }
  }
  ASLayoutElementStyleCallDelegate(ASYogaPaddingProperty);
}

- (void)setBorder:(ASEdgeInsets)border
{
  {
    MutexLocker l(__instanceLock__);
    YGEdge edge = YGEdgeLeft;
    for (int i = 0; i < YGEdgeAll + 1; ++i) {
      YGNODE_STYLE_SET_FLOAT_WITH_EDGE(_yogaNode, Border, dimensionForEdgeWithEdgeInsets(edge, border), edge);
      edge = (YGEdge)(edge + 1);
    }
  }
  ASLayoutElementStyleCallDelegate(ASYogaBorderProperty);
}

- (void)setAspectRatio:(CGFloat)aspectRatio
{
  {
    MutexLocker l(__instanceLock__);
    if (aspectRatio > FLT_EPSILON && aspectRatio < CGFLOAT_MAX / 2.0) {
      YGNodeStyleSetAspectRatio(_yogaNode, aspectRatio);
    }
  }
  ASLayoutElementStyleCallDelegate(ASYogaAspectRatioProperty);
}

// private (ASLayoutElementStylePrivate.h)
- (void)setParentAlignStyle:(ASStackLayoutAlignItems)style
{
  // Not an equivalent on _yogaNode
  if (_parentAlignStyle.exchange(style) != style) {
    ASLayoutElementStyleCallDelegate(ASLayoutElementStyleParentAlignStyle);
  }
}

- (void)setOverflow:(YGOverflow)overflow
{
  {
    MutexLocker l(__instanceLock__);
    YGNodeStyleSetOverflow(_yogaNode, overflow);
  }
  ASLayoutElementStyleCallDelegate(ASYogaOverflowProperty);
}

@end

#endif /* YOGA */
