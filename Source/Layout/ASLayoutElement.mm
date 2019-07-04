//
//  ASLayoutElement.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASDisplayNode+FrameworkPrivate.h>
#import <AsyncDisplayKit/ASAvailability.h>
#import <AsyncDisplayKit/ASLayout.h>
#import <AsyncDisplayKit/ASLayoutElement.h>
#import <AsyncDisplayKit/ASThread.h>
#import <AsyncDisplayKit/ASObjectDescriptionHelpers.h>
#import <AsyncDisplayKit/ASInternalHelpers.h>

#import <atomic>

using AS::MutexLocker;

#if YOGA
  #import YOGA_HEADER_PATH
  #import <AsyncDisplayKit/ASYogaUtilities.h>
#endif

#pragma mark - ASLayoutElementContext

@implementation ASLayoutElementContext

- (instancetype)init
{
  if (self = [super init]) {
    _transitionID = ASLayoutElementContextDefaultTransitionID;
  }
  return self;
}

@end

CGFloat const ASLayoutElementParentDimensionUndefined = NAN;
CGSize const ASLayoutElementParentSizeUndefined = {ASLayoutElementParentDimensionUndefined, ASLayoutElementParentDimensionUndefined};

int32_t const ASLayoutElementContextInvalidTransitionID = 0;
int32_t const ASLayoutElementContextDefaultTransitionID = ASLayoutElementContextInvalidTransitionID + 1;

#if AS_TLS_AVAILABLE

static _Thread_local __unsafe_unretained ASLayoutElementContext *tls_context;

void ASLayoutElementPushContext(ASLayoutElementContext *context)
{
  // NOTE: It would be easy to support nested contexts – just use an NSMutableArray here.
  ASDisplayNodeCAssertNil(tls_context, @"Nested ASLayoutElementContexts aren't supported.");
  
  tls_context = (__bridge ASLayoutElementContext *)(__bridge_retained CFTypeRef)context;
}

ASLayoutElementContext *ASLayoutElementGetCurrentContext()
{
  // Don't retain here. Caller will retain if it wants to!
  return tls_context;
}

void ASLayoutElementPopContext()
{
  ASDisplayNodeCAssertNotNil(tls_context, @"Attempt to pop context when there wasn't a context!");
  CFRelease((__bridge CFTypeRef)tls_context);
  tls_context = nil;
}

#else

static pthread_key_t ASLayoutElementContextKey() {
  static pthread_key_t k;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    pthread_key_create(&k, NULL);
  });
  return k;
}
void ASLayoutElementPushContext(ASLayoutElementContext *context)
{
  // NOTE: It would be easy to support nested contexts – just use an NSMutableArray here.
  ASDisplayNodeCAssertNil(pthread_getspecific(ASLayoutElementContextKey()), @"Nested ASLayoutElementContexts aren't supported.");
  
  const auto cfCtx = (__bridge_retained CFTypeRef)context;
  pthread_setspecific(ASLayoutElementContextKey(), cfCtx);
}

ASLayoutElementContext *ASLayoutElementGetCurrentContext()
{
  // Don't retain here. Caller will retain if it wants to!
  const auto ctxPtr = pthread_getspecific(ASLayoutElementContextKey());
  return (__bridge ASLayoutElementContext *)ctxPtr;
}

void ASLayoutElementPopContext()
{
  const auto ctx = (CFTypeRef)pthread_getspecific(ASLayoutElementContextKey());
  ASDisplayNodeCAssertNotNil(ctx, @"Attempt to pop context when there wasn't a context!");
  CFRelease(ctx);
  pthread_setspecific(ASLayoutElementContextKey(), NULL);
}

#endif // AS_TLS_AVAILABLE

#pragma mark - ASLayoutElementStyle

NSString * const ASLayoutElementStyleWidthProperty = @"ASLayoutElementStyleWidthProperty";
NSString * const ASLayoutElementStyleMinWidthProperty = @"ASLayoutElementStyleMinWidthProperty";
NSString * const ASLayoutElementStyleMaxWidthProperty = @"ASLayoutElementStyleMaxWidthProperty";

NSString * const ASLayoutElementStyleHeightProperty = @"ASLayoutElementStyleHeightProperty";
NSString * const ASLayoutElementStyleMinHeightProperty = @"ASLayoutElementStyleMinHeightProperty";
NSString * const ASLayoutElementStyleMaxHeightProperty = @"ASLayoutElementStyleMaxHeightProperty";

NSString * const ASLayoutElementStyleSpacingBeforeProperty = @"ASLayoutElementStyleSpacingBeforeProperty";
NSString * const ASLayoutElementStyleSpacingAfterProperty = @"ASLayoutElementStyleSpacingAfterProperty";
NSString * const ASLayoutElementStyleFlexGrowProperty = @"ASLayoutElementStyleFlexGrowProperty";
NSString * const ASLayoutElementStyleFlexShrinkProperty = @"ASLayoutElementStyleFlexShrinkProperty";
NSString * const ASLayoutElementStyleFlexBasisProperty = @"ASLayoutElementStyleFlexBasisProperty";
NSString * const ASLayoutElementStyleAlignSelfProperty = @"ASLayoutElementStyleAlignSelfProperty";
NSString * const ASLayoutElementStyleAscenderProperty = @"ASLayoutElementStyleAscenderProperty";
NSString * const ASLayoutElementStyleDescenderProperty = @"ASLayoutElementStyleDescenderProperty";

NSString * const ASLayoutElementStyleLayoutPositionProperty = @"ASLayoutElementStyleLayoutPositionProperty";

#if YOGA
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
#endif

#define ASLayoutElementStyleSetSizeWithScope(x)                                    \
  ({                                                                               \
    __instanceLock__.lock();                                                       \
    const ASLayoutElementSize oldSize = _size.load();                              \
    ASLayoutElementSize newSize = oldSize;                                         \
    {x};                                                                           \
    BOOL changed = !ASLayoutElementSizeEqualToLayoutElementSize(oldSize, newSize); \
    if (changed) {                                                                 \
      _size.store(newSize);                                                        \
    }                                                                              \
    __instanceLock__.unlock();                                                     \
    changed;                                                                       \
  })

#define ASLayoutElementStyleCallDelegate(propertyName)\
do {\
  [self propertyDidChange:propertyName];\
  [_delegate style:self propertyDidChange:propertyName];\
} while(0)

@implementation ASLayoutElementStyle {
  AS::RecursiveMutex __instanceLock__;

#if AS_USE_LAYOUT_EXTENSIBILITY
  ASLayoutElementStyleExtensions _extensions;
#endif

  // Used by Texture and Yoga
  std::atomic<CGFloat> _spacingBefore;
  std::atomic<CGFloat> _spacingAfter;
  std::atomic<CGFloat> _ascender;
  std::atomic<CGFloat> _descender;

#if !USE_YOGA_NODE
  std::atomic<ASLayoutElementSize> _size;
  std::atomic<CGFloat> _flexGrow;
  std::atomic<CGFloat> _flexShrink;
  std::atomic<ASDimension> _flexBasis;
  std::atomic<ASStackLayoutAlignSelf> _alignSelf;
#endif // !USE_YOGA_NODE


#if YOGA
  YGNodeRef _yogaNode;
#if !USE_YOGA_NODE
  std::atomic<YGWrap> _flexWrap;
  std::atomic<ASStackLayoutDirection> _flexDirection;
  std::atomic<YGDirection> _direction;
  std::atomic<ASStackLayoutJustifyContent> _justifyContent;
  std::atomic<ASStackLayoutAlignItems> _alignItems;
  std::atomic<YGPositionType> _positionType;
  std::atomic<ASEdgeInsets> _position;
  std::atomic<ASEdgeInsets> _margin;
  std::atomic<ASEdgeInsets> _padding;
  std::atomic<ASEdgeInsets> _border;
  std::atomic<CGFloat> _aspectRatio;
#endif // !USE_YOGA_NODE
  std::atomic<ASStackLayoutAlignItems> _parentAlignStyle;
#else // YOGA
  std::atomic<CGPoint> _layoutPosition;
#endif // YOGA
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
#if !USE_YOGA_NODE
    std::atomic_init(&_size, ASLayoutElementSizeMake());
    std::atomic_init(&_flexBasis, ASDimensionAuto);
#endif // !USE_YOGA_NODE

#if YOGA
    std::atomic_init(&_parentAlignStyle, ASStackLayoutAlignItemsNotSet);
#if !USE_YOGA_NODE
    std::atomic_init(&_flexDirection, ASStackLayoutDirectionVertical);
    std::atomic_init(&_alignItems, ASStackLayoutAlignItemsStretch);
    std::atomic_init(&_aspectRatio, static_cast<CGFloat>(YGUndefined));
#else
    // If we use the Yoga node as backing store  we have to create a yoga node for
    // every ASDisplayNode
    [self yogaNodeCreateIfNeeded];

    // Set default values that differ between Yoga and Texture
    YGNODE_STYLE_SET_DIMENSION(_yogaNode, FlexBasis, ASDimensionAuto);
    YGNodeStyleSetFlexDirection(_yogaNode, yogaFlexDirection(ASStackLayoutDirectionVertical));
    YGNodeStyleSetAlignItems(_yogaNode, yogaAlignItems(ASStackLayoutAlignItemsStretch));
    YGNodeStyleSetAspectRatio(_yogaNode, YGUndefined);
#endif // !USE_YOGA_NODE
#endif // YOGA
  }
  return self;
}

ASSynthesizeLockingMethodsWithMutex(__instanceLock__)

#pragma mark - ASLayoutElementStyleSize

- (ASLayoutElementSize)size
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  return (ASLayoutElementSize){
    dimensionForYogaValue(YGNodeStyleGetWidth(_yogaNode)),
    dimensionForYogaValue(YGNodeStyleGetHeight(_yogaNode)),
    dimensionForYogaValue(YGNodeStyleGetMinWidth(_yogaNode)),
    dimensionForYogaValue(YGNodeStyleGetMaxWidth(_yogaNode)),
    dimensionForYogaValue(YGNodeStyleGetMinHeight(_yogaNode)),
    dimensionForYogaValue(YGNodeStyleGetMaxHeight(_yogaNode)),
  };
#else
  return _size.load();
#endif
}

- (void)setSize:(ASLayoutElementSize)size
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, Width, size.width);
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, Height, size.height);
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, MinWidth, size.minWidth);
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, MaxWidth, size.maxWidth);
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, MinHeight, size.minHeight);
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, MaxHeight, size.maxHeight);
#else
  ASLayoutElementStyleSetSizeWithScope({
    newSize = size;
  });
  // No CallDelegate method as ASLayoutElementSize is currently internal.
#endif
}

#pragma mark - ASLayoutElementStyleSizeForwarding

- (ASDimension)width
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  return dimensionForYogaValue(YGNodeStyleGetWidth(_yogaNode));
#else
  return _size.load().width;
#endif
}

- (void)setWidth:(ASDimension)width
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, Width, width);
#else
  BOOL changed = ASLayoutElementStyleSetSizeWithScope({ newSize.width = width; });
  if (changed) {
    ASLayoutElementStyleCallDelegate(ASLayoutElementStyleWidthProperty);
  }
#endif
}

- (ASDimension)height
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  return dimensionForYogaValue(YGNodeStyleGetHeight(_yogaNode));
#else
  return _size.load().height;
#endif
}

- (void)setHeight:(ASDimension)height
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, Height, height);
#else
  BOOL changed = ASLayoutElementStyleSetSizeWithScope({ newSize.height = height; });
  if (changed) {
    ASLayoutElementStyleCallDelegate(ASLayoutElementStyleHeightProperty);
  }
#endif
}

- (ASDimension)minWidth
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  return dimensionForYogaValue(YGNodeStyleGetMinWidth(_yogaNode));
#else
  return _size.load().minWidth;
#endif
}

- (void)setMinWidth:(ASDimension)minWidth
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, MinWidth, minWidth);
#else
  BOOL changed = ASLayoutElementStyleSetSizeWithScope({ newSize.minWidth = minWidth; });
  if (changed) {
    ASLayoutElementStyleCallDelegate(ASLayoutElementStyleMinWidthProperty);
  }
#endif
}

- (ASDimension)maxWidth
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  return dimensionForYogaValue(YGNodeStyleGetMaxWidth(_yogaNode));
#else
  return _size.load().maxWidth;
#endif
}

- (void)setMaxWidth:(ASDimension)maxWidth
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, MaxWidth, maxWidth);
#else
  BOOL changed = ASLayoutElementStyleSetSizeWithScope({ newSize.maxWidth = maxWidth; });
  if (changed) {
    ASLayoutElementStyleCallDelegate(ASLayoutElementStyleMaxWidthProperty);
  }
#endif
}

- (ASDimension)minHeight
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  return dimensionForYogaValue(YGNodeStyleGetMinWidth(_yogaNode));
#else
  return _size.load().minHeight;
#endif
}

- (void)setMinHeight:(ASDimension)minHeight
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, MinHeight, minHeight);
#else
  BOOL changed = ASLayoutElementStyleSetSizeWithScope({ newSize.minHeight = minHeight; });
  if (changed) {
    ASLayoutElementStyleCallDelegate(ASLayoutElementStyleMinHeightProperty);
  }
#endif
}

- (ASDimension)maxHeight
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  return dimensionForYogaValue(YGNodeStyleGetMaxHeight(_yogaNode));
#else
  return _size.load().maxHeight;
#endif
}

- (void)setMaxHeight:(ASDimension)maxHeight
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, MaxHeight, maxHeight);
#else
  BOOL changed = ASLayoutElementStyleSetSizeWithScope({ newSize.maxHeight = maxHeight; });
  if (changed) {
    ASLayoutElementStyleCallDelegate(ASLayoutElementStyleMaxHeightProperty);
  }
#endif
}


#pragma mark - ASLayoutElementStyleSizeHelpers

- (void)setPreferredSize:(CGSize)preferredSize
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, Width, ASDimensionMakeWithPoints(preferredSize.width));
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, Height, ASDimensionMakeWithPoints(preferredSize.height));
#else
  BOOL changed = ASLayoutElementStyleSetSizeWithScope({
    newSize.width = ASDimensionMakeWithPoints(preferredSize.width);
    newSize.height = ASDimensionMakeWithPoints(preferredSize.height);
  });
  if (changed) {
    ASLayoutElementStyleCallDelegate(ASLayoutElementStyleWidthProperty);
    ASLayoutElementStyleCallDelegate(ASLayoutElementStyleHeightProperty);
  }
#endif
}

- (CGSize)preferredSize
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  YGValue width = YGNodeStyleGetWidth(_yogaNode);
  YGValue height = YGNodeStyleGetHeight(_yogaNode);
  NSCAssert(width.unit != YGUnitPoint, @"Cannot get preferredSize of element with fractional width. Width: %f.", width.value);
  NSCAssert(height.unit != YGUnitPoint, @"Cannot get preferredSize of element with fractional height. Height: %f.", height.value);

  return (CGSize){cgFloatForYogaFloat(width.value, 0), cgFloatForYogaFloat(height.value, 0)};
#else
  ASLayoutElementSize size = _size.load();
  if (size.width.unit == ASDimensionUnitFraction) {
    NSCAssert(NO, @"Cannot get preferredSize of element with fractional width. Width: %@.", NSStringFromASDimension(size.width));
    return CGSizeZero;
  }
  
  if (size.height.unit == ASDimensionUnitFraction) {
    NSCAssert(NO, @"Cannot get preferredSize of element with fractional height. Height: %@.", NSStringFromASDimension(size.height));
    return CGSizeZero;
  }
  
  return CGSizeMake(size.width.value, size.height.value);
#endif
}

- (void)setMinSize:(CGSize)minSize
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  YGNodeStyleSetMinWidth(_yogaNode, minSize.width);
  YGNodeStyleSetMinHeight(_yogaNode, minSize.height);
#else
  BOOL changed = ASLayoutElementStyleSetSizeWithScope({
    newSize.minWidth = ASDimensionMakeWithPoints(minSize.width);
    newSize.minHeight = ASDimensionMakeWithPoints(minSize.height);
  });
  if (changed) {
    ASLayoutElementStyleCallDelegate(ASLayoutElementStyleMinWidthProperty);
    ASLayoutElementStyleCallDelegate(ASLayoutElementStyleMinHeightProperty);
  }
#endif
}

- (void)setMaxSize:(CGSize)maxSize
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  YGNodeStyleSetMaxWidth(_yogaNode, maxSize.width);
  YGNodeStyleSetMaxHeight(_yogaNode, maxSize.height);
#else
  BOOL changed = ASLayoutElementStyleSetSizeWithScope({
    newSize.maxWidth = ASDimensionMakeWithPoints(maxSize.width);
    newSize.maxHeight = ASDimensionMakeWithPoints(maxSize.height);
  });
  if (changed) {
    ASLayoutElementStyleCallDelegate(ASLayoutElementStyleMaxWidthProperty);
    ASLayoutElementStyleCallDelegate(ASLayoutElementStyleMaxHeightProperty);
  }
#endif
}

- (ASLayoutSize)preferredLayoutSize
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  return ASLayoutSizeMake(
    dimensionForYogaValue(YGNodeStyleGetWidth(_yogaNode)),
    dimensionForYogaValue(YGNodeStyleGetHeight(_yogaNode))
  );
#else
  ASLayoutElementSize size = _size.load();
  return ASLayoutSizeMake(size.width, size.height);
#endif
}

- (void)setPreferredLayoutSize:(ASLayoutSize)preferredLayoutSize
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, Width, preferredLayoutSize.width);
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, Width, preferredLayoutSize.height);
#else
  BOOL changed = ASLayoutElementStyleSetSizeWithScope({
    newSize.width = preferredLayoutSize.width;
    newSize.height = preferredLayoutSize.height;
  });
  if (changed) {
    ASLayoutElementStyleCallDelegate(ASLayoutElementStyleWidthProperty);
    ASLayoutElementStyleCallDelegate(ASLayoutElementStyleHeightProperty);
  }
#endif
}

- (ASLayoutSize)minLayoutSize
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  return ASLayoutSizeMake(
    dimensionForYogaValue(YGNodeStyleGetMinWidth(_yogaNode)),
    dimensionForYogaValue(YGNodeStyleGetMinHeight(_yogaNode))
  );
#else
  ASLayoutElementSize size = _size.load();
  return ASLayoutSizeMake(size.minWidth, size.minHeight);
#endif
}

- (void)setMinLayoutSize:(ASLayoutSize)minLayoutSize
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, MinWidth, minLayoutSize.width);
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, MinHeight, minLayoutSize.height);
#else
  BOOL changed = ASLayoutElementStyleSetSizeWithScope({
    newSize.minWidth = minLayoutSize.width;
    newSize.minHeight = minLayoutSize.height;
  });
  if (changed) {
    ASLayoutElementStyleCallDelegate(ASLayoutElementStyleMinWidthProperty);
    ASLayoutElementStyleCallDelegate(ASLayoutElementStyleMinHeightProperty);
  }
#endif
}

- (ASLayoutSize)maxLayoutSize
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  return ASLayoutSizeMake(
    dimensionForYogaValue(YGNodeStyleGetMaxWidth(_yogaNode)),
    dimensionForYogaValue(YGNodeStyleGetMaxHeight(_yogaNode))
  );
#else
  ASLayoutElementSize size = _size.load();
  return ASLayoutSizeMake(size.maxWidth, size.maxHeight);
#endif
}

- (void)setMaxLayoutSize:(ASLayoutSize)maxLayoutSize
{
#if USE_YOGA_NODE
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, MaxWidth, maxLayoutSize.width);
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, MaxHeight, maxLayoutSize.height);
#else
  BOOL changed = ASLayoutElementStyleSetSizeWithScope({
    newSize.maxWidth = maxLayoutSize.width;
    newSize.maxHeight = maxLayoutSize.height;
  });
  if (changed) {
    ASLayoutElementStyleCallDelegate(ASLayoutElementStyleMaxWidthProperty);
    ASLayoutElementStyleCallDelegate(ASLayoutElementStyleMaxHeightProperty);
  }
#endif
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
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  YGNodeStyleSetFlexGrow(_yogaNode, flexGrow);
#else
  if (_flexGrow.exchange(flexGrow) != flexGrow) {
    ASLayoutElementStyleCallDelegate(ASLayoutElementStyleFlexGrowProperty);
  }
#endif
}

- (CGFloat)flexGrow
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  return YGNodeStyleGetFlexGrow(_yogaNode);
#else
  return _flexGrow.load();
#endif
}

- (void)setFlexShrink:(CGFloat)flexShrink
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  YGNodeStyleSetFlexShrink(_yogaNode, flexShrink);
#else
  if (_flexShrink.exchange(flexShrink) != flexShrink) {
    ASLayoutElementStyleCallDelegate(ASLayoutElementStyleFlexShrinkProperty);
  }
#endif
}

- (CGFloat)flexShrink
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  return YGNodeStyleGetFlexShrink(_yogaNode);
#else
  return _flexShrink.load();
#endif
}

- (void)setFlexBasis:(ASDimension)flexBasis
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  YGNODE_STYLE_SET_DIMENSION(_yogaNode, FlexBasis, flexBasis);
#else
  if (!ASDimensionEqualToDimension(_flexBasis.exchange(flexBasis), flexBasis)) {
    ASLayoutElementStyleCallDelegate(ASLayoutElementStyleFlexBasisProperty);
  }
#endif
}

- (ASDimension)flexBasis
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  return dimensionForYogaValue(YGNodeStyleGetFlexBasis(_yogaNode));
#else
  return _flexBasis.load();
#endif
}

- (void)setAlignSelf:(ASStackLayoutAlignSelf)alignSelf
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  YGNodeStyleSetAlignSelf(_yogaNode, yogaAlignSelf(alignSelf));
#else
  if (_alignSelf.exchange(alignSelf) != alignSelf) {
    ASLayoutElementStyleCallDelegate(ASLayoutElementStyleAlignSelfProperty);
  }
#endif
}

- (ASStackLayoutAlignSelf)alignSelf
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  return stackAlignSelf(YGNodeStyleGetAlignSelf(_yogaNode));
#else
  return _alignSelf.load();
#endif
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

#if !YOGA
- (void)setLayoutPosition:(CGPoint)layoutPosition
{
  // Not an equivalent on _yogaNode
  if (!CGPointEqualToPoint(_layoutPosition.exchange(layoutPosition), layoutPosition)) {
    ASLayoutElementStyleCallDelegate(ASLayoutElementStyleLayoutPositionProperty);
  }
}

- (CGPoint)layoutPosition
{
  // Not an equivalent on _yogaNode
  return _layoutPosition.load();
}
#endif

#if AS_USE_LAYOUT_EXTENSIBILITY
#pragma mark - Extensibility

- (void)setLayoutOptionExtensionBool:(BOOL)value atIndex:(int)idx
{
  NSCAssert(idx < kMaxLayoutElementBoolExtensions, @"Setting index outside of max bool extensions space");
  
  MutexLocker l(__instanceLock__);
  _extensions.boolExtensions[idx] = value;
}

- (BOOL)layoutOptionExtensionBoolAtIndex:(int)idx\
{
  NSCAssert(idx < kMaxLayoutElementBoolExtensions, @"Accessing index outside of max bool extensions space");
  
  MutexLocker l(__instanceLock__);
  return _extensions.boolExtensions[idx];
}

- (void)setLayoutOptionExtensionInteger:(NSInteger)value atIndex:(int)idx
{
  NSCAssert(idx < kMaxLayoutElementStateIntegerExtensions, @"Setting index outside of max integer extensions space");
  
  MutexLocker l(__instanceLock__);
  _extensions.integerExtensions[idx] = value;
}

- (NSInteger)layoutOptionExtensionIntegerAtIndex:(int)idx
{
  NSCAssert(idx < kMaxLayoutElementStateIntegerExtensions, @"Accessing index outside of max integer extensions space");
  
  MutexLocker l(__instanceLock__);
  return _extensions.integerExtensions[idx];
}

- (void)setLayoutOptionExtensionEdgeInsets:(UIEdgeInsets)value atIndex:(int)idx
{
  NSCAssert(idx < kMaxLayoutElementStateEdgeInsetExtensions, @"Setting index outside of max edge insets extensions space");
  
  MutexLocker l(__instanceLock__);
  _extensions.edgeInsetsExtensions[idx] = value;
}

- (UIEdgeInsets)layoutOptionExtensionEdgeInsetsAtIndex:(int)idx
{
  NSCAssert(idx < kMaxLayoutElementStateEdgeInsetExtensions, @"Accessing index outside of max edge insets extensions space");
  
  MutexLocker l(__instanceLock__);
  return _extensions.edgeInsetsExtensions[idx];
}

#endif // AS_USE_LAYOUT_EXTENSIBILITY

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
  
  if (CGPointEqualToPoint(self.layoutPosition, CGPointZero) == NO) {
    [result addObject:@{ @"layoutPosition" : [NSValue valueWithCGPoint:self.layoutPosition] }];
  }

  return result;
}

#pragma mark - Yoga Support

- (void)propertyDidChange:(NSString *)propertyName
{
#if YOGA && !USE_YOGA_NODE
  /* TODO(appleguy): STYLE SETTER METHODS LEFT TO IMPLEMENT
   void YGNodeStyleSetOverflow(YGNodeRef node, YGOverflow overflow);
   void YGNodeStyleSetFlex(YGNodeRef node, float flex);
   */

  if (_yogaNode == NULL) {
    return;
  }
  // Because the NSStrings used to identify each property are const, use efficient pointer comparison.
  if (propertyName == ASLayoutElementStyleWidthProperty) {
    YGNODE_STYLE_SET_DIMENSION(_yogaNode, Width, self.width);
  }
  else if (propertyName == ASLayoutElementStyleMinWidthProperty) {
    YGNODE_STYLE_SET_DIMENSION(_yogaNode, MinWidth, self.minWidth);
  }
  else if (propertyName == ASLayoutElementStyleMaxWidthProperty) {
    YGNODE_STYLE_SET_DIMENSION(_yogaNode, MaxWidth, self.maxWidth);
  }
  else if (propertyName == ASLayoutElementStyleHeightProperty) {
    YGNODE_STYLE_SET_DIMENSION(_yogaNode, Height, self.height);
  }
  else if (propertyName == ASLayoutElementStyleMinHeightProperty) {
    YGNODE_STYLE_SET_DIMENSION(_yogaNode, MinHeight, self.minHeight);
  }
  else if (propertyName == ASLayoutElementStyleMaxHeightProperty) {
    YGNODE_STYLE_SET_DIMENSION(_yogaNode, MaxHeight, self.maxHeight);
  }
  else if (propertyName == ASLayoutElementStyleFlexGrowProperty) {
    YGNodeStyleSetFlexGrow(_yogaNode, self.flexGrow);
  }
  else if (propertyName == ASLayoutElementStyleFlexShrinkProperty) {
    YGNodeStyleSetFlexShrink(_yogaNode, self.flexShrink);
  }
  else if (propertyName == ASLayoutElementStyleFlexBasisProperty) {
    YGNODE_STYLE_SET_DIMENSION(_yogaNode, FlexBasis, self.flexBasis);
  }
  else if (propertyName == ASLayoutElementStyleAlignSelfProperty) {
    YGNodeStyleSetAlignSelf(_yogaNode, yogaAlignSelf(self.alignSelf));
  }
  else if (propertyName == ASYogaFlexWrapProperty) {
    YGNodeStyleSetFlexWrap(_yogaNode, self.flexWrap);
  }
  else if (propertyName == ASYogaFlexDirectionProperty) {
    YGNodeStyleSetFlexDirection(_yogaNode, yogaFlexDirection(self.flexDirection));
  }
  else if (propertyName == ASYogaDirectionProperty) {
    YGNodeStyleSetDirection(_yogaNode, self.direction);
  }
  else if (propertyName == ASYogaJustifyContentProperty) {
    YGNodeStyleSetJustifyContent(_yogaNode, yogaJustifyContent(self.justifyContent));
  }
  else if (propertyName == ASYogaAlignItemsProperty) {
    ASStackLayoutAlignItems alignItems = self.alignItems;
    if (alignItems != ASStackLayoutAlignItemsNotSet) {
      YGNodeStyleSetAlignItems(_yogaNode, yogaAlignItems(alignItems));
    }
  }
  else if (propertyName == ASYogaPositionTypeProperty) {
    YGNodeStyleSetPositionType(_yogaNode, self.positionType);
  }
  else if (propertyName == ASYogaPositionProperty) {
    ASEdgeInsets position = self.position;
    YGEdge edge = YGEdgeLeft;
    for (int i = 0; i < YGEdgeAll + 1; ++i) {
      YGNODE_STYLE_SET_DIMENSION_WITH_EDGE(_yogaNode, Position, dimensionForEdgeWithEdgeInsets(edge, position), edge);
      edge = (YGEdge)(edge + 1);
    }
  }
  else if (propertyName == ASYogaMarginProperty) {
    ASEdgeInsets margin   = self.margin;
    YGEdge edge = YGEdgeLeft;
    for (int i = 0; i < YGEdgeAll + 1; ++i) {
      YGNODE_STYLE_SET_DIMENSION_WITH_EDGE(_yogaNode, Margin, dimensionForEdgeWithEdgeInsets(edge, margin), edge);
      edge = (YGEdge)(edge + 1);
    }
  }
  else if (propertyName == ASYogaPaddingProperty) {
    ASEdgeInsets padding  = self.padding;
    YGEdge edge = YGEdgeLeft;
    for (int i = 0; i < YGEdgeAll + 1; ++i) {
      YGNODE_STYLE_SET_DIMENSION_WITH_EDGE(_yogaNode, Padding, dimensionForEdgeWithEdgeInsets(edge, padding), edge);
      edge = (YGEdge)(edge + 1);
    }
  }
  else if (propertyName == ASYogaBorderProperty) {
    ASEdgeInsets border   = self.border;
    YGEdge edge = YGEdgeLeft;
    for (int i = 0; i < YGEdgeAll + 1; ++i) {
      YGNODE_STYLE_SET_FLOAT_WITH_EDGE(_yogaNode, Border, dimensionForEdgeWithEdgeInsets(edge, border), edge);
      edge = (YGEdge)(edge + 1);
    }
  }
  else if (propertyName == ASYogaAspectRatioProperty) {
    CGFloat aspectRatio = self.aspectRatio;
    if (aspectRatio > FLT_EPSILON && aspectRatio < CGFLOAT_MAX / 2.0) {
      YGNodeStyleSetAspectRatio(_yogaNode, aspectRatio);
    }
  }
#endif
}

#pragma mark - Yoga Flexbox Properties

#if YOGA

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
    // Release the __bridge_retained Context object.
    ASLayoutElementYogaUpdateMeasureFunc(_yogaNode, nil);
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
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  return YGNodeStyleGetFlexWrap(_yogaNode);
#else
  return _flexWrap.load();
#endif
}

- (ASStackLayoutDirection)flexDirection
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  return stackFlexDirection(YGNodeStyleGetFlexDirection(_yogaNode));
#else
  return _flexDirection.load();
#endif
}

- (YGDirection)direction
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  return YGNodeStyleGetDirection(_yogaNode);
#else
  return _direction.load();
#endif
}

- (ASStackLayoutJustifyContent)justifyContent
{
#if USE_YOGA_NODE
  return stackJustifyContent(YGNodeStyleGetJustifyContent(_yogaNode));
#else
  return _justifyContent.load();
#endif
}

- (ASStackLayoutAlignItems)alignItems
{
#if USE_YOGA_NODE
  return stackAlignItems(YGNodeStyleGetAlignItems(_yogaNode));
#else
  return _alignItems.load();
#endif
}

- (YGPositionType)positionType
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  return YGNodeStyleGetPositionType(_yogaNode);
#else
  return _positionType.load();
#endif
}

- (ASEdgeInsets)position
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  AS_EDGE_INSETS_FROM_YGNODE_STYLE(_yogaNode, Position, dimensionForYogaValue);
#else
  return _position.load();
#endif
}

- (ASEdgeInsets)margin
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  AS_EDGE_INSETS_FROM_YGNODE_STYLE(_yogaNode, Margin, dimensionForYogaValue);
#else
  return _margin.load();
#endif
}

- (ASEdgeInsets)padding
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  AS_EDGE_INSETS_FROM_YGNODE_STYLE(_yogaNode, Padding, dimensionForYogaValue);
#else
  return _padding.load();
#endif
}

- (ASEdgeInsets)border
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  AS_EDGE_INSETS_FROM_YGNODE_STYLE(_yogaNode, Border, [](float border) -> ASDimension {
    return ASDimensionMake(ASDimensionUnitPoints, cgFloatForYogaFloat(border, 0));
  });
#else
  return _border.load();
#endif
}

- (CGFloat)aspectRatio
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  return YGNodeStyleGetAspectRatio(_yogaNode);
#else
  return _aspectRatio.load();
#endif
}

// private (ASLayoutElementStylePrivate.h)
- (ASStackLayoutAlignItems)parentAlignStyle
{
  // Not an equivalent on _yogaNode
  return _parentAlignStyle.load();
}

- (void)setFlexWrap:(YGWrap)flexWrap
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  YGNodeStyleSetFlexWrap(_yogaNode, flexWrap);
#else
  if (_flexWrap.exchange(flexWrap) != flexWrap) {
    ASLayoutElementStyleCallDelegate(ASYogaFlexWrapProperty);
  }
#endif
}

- (void)setFlexDirection:(ASStackLayoutDirection)flexDirection
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  YGNodeStyleSetFlexDirection(_yogaNode, yogaFlexDirection(flexDirection));
#else
  if (_flexDirection.exchange(flexDirection) != flexDirection) {
    ASLayoutElementStyleCallDelegate(ASYogaFlexDirectionProperty);
  }
#endif
}

- (void)setDirection:(YGDirection)direction
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  YGNodeStyleSetDirection(_yogaNode, direction);
#else
  if (_direction.exchange(direction) != direction) {
    ASLayoutElementStyleCallDelegate(ASYogaDirectionProperty);
  }
#endif
}

- (void)setJustifyContent:(ASStackLayoutJustifyContent)justify
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  YGNodeStyleSetJustifyContent(_yogaNode, yogaJustifyContent(justify));
#else
  if (_justifyContent.exchange(justify) != justify) {
    ASLayoutElementStyleCallDelegate(ASYogaJustifyContentProperty);
  }
#endif
}

- (void)setAlignItems:(ASStackLayoutAlignItems)alignItems
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  YGNodeStyleSetAlignItems(_yogaNode, yogaAlignItems(alignItems));
#else
  if (_alignItems.exchange(alignItems) != alignItems) {
    ASLayoutElementStyleCallDelegate(ASYogaAlignItemsProperty);
  }
#endif
}

- (void)setPositionType:(YGPositionType)positionType
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  YGNodeStyleSetPositionType(_yogaNode, positionType);
#else
  if (_positionType.exchange(positionType) != positionType) {
    ASLayoutElementStyleCallDelegate(ASYogaPositionTypeProperty);
  }
#endif
}

/// TODO: smart compare ASEdgeInsets instead of memory compare.
- (void)setPosition:(ASEdgeInsets)position
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  YGEdge edge = YGEdgeLeft;
  for (int i = 0; i < YGEdgeAll + 1; ++i) {
    YGNODE_STYLE_SET_DIMENSION_WITH_EDGE(_yogaNode, Position, dimensionForEdgeWithEdgeInsets(edge, position), edge);
    edge = (YGEdge)(edge + 1);
  }
#else
  ASEdgeInsets oldValue = _position.exchange(position);
  if (0 != memcmp(&position, &oldValue, sizeof(ASEdgeInsets))) {
    ASLayoutElementStyleCallDelegate(ASYogaPositionProperty);
  }
#endif
}

- (void)setMargin:(ASEdgeInsets)margin
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  YGEdge edge = YGEdgeLeft;
  for (int i = 0; i < YGEdgeAll + 1; ++i) {
    YGNODE_STYLE_SET_DIMENSION_WITH_EDGE(_yogaNode, Margin, dimensionForEdgeWithEdgeInsets(edge, margin), edge);
    edge = (YGEdge)(edge + 1);
  }
#else
  ASEdgeInsets oldValue = _margin.exchange(margin);
  if (0 != memcmp(&margin, &oldValue, sizeof(ASEdgeInsets))) {
    ASLayoutElementStyleCallDelegate(ASYogaMarginProperty);
  }
#endif
}

- (void)setPadding:(ASEdgeInsets)padding
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  YGEdge edge = YGEdgeLeft;
  for (int i = 0; i < YGEdgeAll + 1; ++i) {
    YGNODE_STYLE_SET_DIMENSION_WITH_EDGE(_yogaNode, Padding, dimensionForEdgeWithEdgeInsets(edge, padding), edge);
    edge = (YGEdge)(edge + 1);
  }
#else
  ASEdgeInsets oldValue = _padding.exchange(padding);
  if (0 != memcmp(&padding, &oldValue, sizeof(ASEdgeInsets))) {
    ASLayoutElementStyleCallDelegate(ASYogaPaddingProperty);
  }
#endif
}

- (void)setBorder:(ASEdgeInsets)border
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  YGEdge edge = YGEdgeLeft;
  for (int i = 0; i < YGEdgeAll + 1; ++i) {
    YGNODE_STYLE_SET_FLOAT_WITH_EDGE(_yogaNode, Border, dimensionForEdgeWithEdgeInsets(edge, border), edge);
    edge = (YGEdge)(edge + 1);
  }
#else
  ASEdgeInsets oldValue = _border.exchange(border);
  if (0 != memcmp(&border, &oldValue, sizeof(ASEdgeInsets))) {
    ASLayoutElementStyleCallDelegate(ASYogaBorderProperty);
  }
#endif
}

- (void)setAspectRatio:(CGFloat)aspectRatio
{
#if USE_YOGA_NODE
  MutexLocker l(__instanceLock__);
  if (aspectRatio > FLT_EPSILON && aspectRatio < CGFLOAT_MAX / 2.0) {
    YGNodeStyleSetAspectRatio(_yogaNode, aspectRatio);
  }
#else
  if (_aspectRatio.exchange(aspectRatio) != aspectRatio) {
    ASLayoutElementStyleCallDelegate(ASYogaAspectRatioProperty);
  }
#endif
}

// private (ASLayoutElementStylePrivate.h)
- (void)setParentAlignStyle:(ASStackLayoutAlignItems)style
{
  // Not an equivalent on _yogaNode
  _parentAlignStyle.store(style);
}

#endif /* YOGA */

@end
