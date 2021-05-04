//
//  ASLayoutElement.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASAvailability.h>
#import <AsyncDisplayKit/ASDisplayNode+FrameworkPrivate.h>
#import <AsyncDisplayKit/ASDisplayNodeInternal.h>
#import <AsyncDisplayKit/ASInternalHelpers.h>
#import <AsyncDisplayKit/ASLayout.h>
#import <AsyncDisplayKit/ASLayoutElement.h>
#import <AsyncDisplayKit/ASObjectDescriptionHelpers.h>
#import <AsyncDisplayKit/ASThread.h>

using AS::MutexLocker;

using namespace AS;

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

static _Thread_local unowned ASLayoutElementContext *tls_context;

void ASLayoutElementPushContext(ASLayoutElementContext *context)
{
  // NOTE: It would be easy to support nested contexts – just use an NSMutableArray here.
  ASDisplayNodeCAssertNil(tls_context, @"Nested ASLayoutElementContexts aren't supported.");
  
  tls_context = (__bridge ASLayoutElementContext *)(__bridge_retained CFTypeRef)context;
}

ASLayoutElementContext *ASLayoutElementGetCurrentContext()
{
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

@implementation ASLayoutElementStyle {
  AS::RecursiveMutex __instanceLock__;
  ASLayoutElementStyleExtensions _extensions;
  std::atomic<ASLayoutElementSize> _size;
  std::atomic<CGFloat> _spacingBefore;
  std::atomic<CGFloat> _spacingAfter;
  std::atomic<CGFloat> _flexGrow;
  std::atomic<CGFloat> _flexShrink;
  std::atomic<ASDimension> _flexBasis;
  std::atomic<ASStackLayoutAlignSelf> _alignSelf;
  std::atomic<CGFloat> _ascender;
  std::atomic<CGFloat> _descender;
  std::atomic<CGPoint> _layoutPosition;
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
    std::atomic_init(&_size, ASLayoutElementSizeMake());
    std::atomic_init(&_flexBasis, ASDimensionAuto);
  }
  return self;
}

ASSynthesizeLockingMethodsWithMutex(__instanceLock__)

#pragma mark - ASLayoutElementStyleSize

- (ASLayoutElementSize)size
{
  return _size.load();
}

- (void)setSize:(ASLayoutElementSize)size
{
  ASLayoutElementStyleSetSizeWithScope({
    newSize = size;
  });
  // No CallDelegate method as ASLayoutElementSize is currently internal.
}

#pragma mark - ASLayoutElementStyleSizeForwarding

- (ASDimension)width
{
  return _size.load().width;
}

- (void)setWidth:(ASDimension)width
{
  BOOL changed = ASLayoutElementStyleSetSizeWithScope({ newSize.width = width; });
  if (changed) {
    [self propertyDidChange:ASLayoutElementStyleWidthProperty];
  }
}

- (ASDimension)height
{
  return _size.load().height;
}

- (void)setHeight:(ASDimension)height
{
  BOOL changed = ASLayoutElementStyleSetSizeWithScope({ newSize.height = height; });
  if (changed) {
    [self propertyDidChange:ASLayoutElementStyleHeightProperty];
  }
}

- (ASDimension)minWidth
{
  return _size.load().minWidth;
}

- (void)setMinWidth:(ASDimension)minWidth
{
  BOOL changed = ASLayoutElementStyleSetSizeWithScope({ newSize.minWidth = minWidth; });
  if (changed) {
    [self propertyDidChange:ASLayoutElementStyleMinWidthProperty];
  }
}

- (ASDimension)maxWidth
{
  return _size.load().maxWidth;
}

- (void)setMaxWidth:(ASDimension)maxWidth
{
  BOOL changed = ASLayoutElementStyleSetSizeWithScope({ newSize.maxWidth = maxWidth; });
  if (changed) {
    [self propertyDidChange:ASLayoutElementStyleMaxWidthProperty];
  }
}

- (ASDimension)minHeight
{
  return _size.load().minHeight;
}

- (void)setMinHeight:(ASDimension)minHeight
{
  BOOL changed = ASLayoutElementStyleSetSizeWithScope({ newSize.minHeight = minHeight; });
  if (changed) {
    [self propertyDidChange:ASLayoutElementStyleMinHeightProperty];
  }
}

- (ASDimension)maxHeight
{
  return _size.load().maxHeight;
}

- (void)setMaxHeight:(ASDimension)maxHeight
{
  BOOL changed = ASLayoutElementStyleSetSizeWithScope({ newSize.maxHeight = maxHeight; });
  if (changed) {
    [self propertyDidChange:ASLayoutElementStyleMaxHeightProperty];
  }
}


#pragma mark - ASLayoutElementStyleSizeHelpers

- (void)setPreferredSize:(CGSize)preferredSize
{
  BOOL changed = ASLayoutElementStyleSetSizeWithScope({
    newSize.width = ASDimensionMakeWithPoints(preferredSize.width);
    newSize.height = ASDimensionMakeWithPoints(preferredSize.height);
  });
  if (changed) {
    [self propertyDidChange:ASLayoutElementStyleWidthProperty];
    [self propertyDidChange:ASLayoutElementStyleHeightProperty];
  }
}

- (CGSize)preferredSize
{
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
}

- (void)setMinSize:(CGSize)minSize
{
  BOOL changed = ASLayoutElementStyleSetSizeWithScope({
    newSize.minWidth = ASDimensionMakeWithPoints(minSize.width);
    newSize.minHeight = ASDimensionMakeWithPoints(minSize.height);
  });
  if (changed) {
    [self propertyDidChange:ASLayoutElementStyleMinWidthProperty];
    [self propertyDidChange:ASLayoutElementStyleMinHeightProperty];
  }
}

- (void)setMaxSize:(CGSize)maxSize
{
  BOOL changed = ASLayoutElementStyleSetSizeWithScope({
    newSize.maxWidth = ASDimensionMakeWithPoints(maxSize.width);
    newSize.maxHeight = ASDimensionMakeWithPoints(maxSize.height);
  });
  if (changed) {
    [self propertyDidChange:ASLayoutElementStyleMaxWidthProperty];
    [self propertyDidChange:ASLayoutElementStyleMaxHeightProperty];
  }
}

- (ASLayoutSize)preferredLayoutSize
{
  ASLayoutElementSize size = _size.load();
  return ASLayoutSizeMake(size.width, size.height);
}

- (void)setPreferredLayoutSize:(ASLayoutSize)preferredLayoutSize
{
  BOOL changed = ASLayoutElementStyleSetSizeWithScope({
    newSize.width = preferredLayoutSize.width;
    newSize.height = preferredLayoutSize.height;
  });
  if (changed) {
    [self propertyDidChange:ASLayoutElementStyleWidthProperty];
    [self propertyDidChange:ASLayoutElementStyleHeightProperty];
  }
}

- (ASLayoutSize)minLayoutSize
{
  ASLayoutElementSize size = _size.load();
  return ASLayoutSizeMake(size.minWidth, size.minHeight);
}

- (void)setMinLayoutSize:(ASLayoutSize)minLayoutSize
{
  BOOL changed = ASLayoutElementStyleSetSizeWithScope({
    newSize.minWidth = minLayoutSize.width;
    newSize.minHeight = minLayoutSize.height;
  });
  if (changed) {
    [self propertyDidChange:ASLayoutElementStyleMinWidthProperty];
    [self propertyDidChange:ASLayoutElementStyleMinHeightProperty];
  }
}

- (ASLayoutSize)maxLayoutSize
{
  ASLayoutElementSize size = _size.load();
  return ASLayoutSizeMake(size.maxWidth, size.maxHeight);
}

- (void)setMaxLayoutSize:(ASLayoutSize)maxLayoutSize
{
  BOOL changed = ASLayoutElementStyleSetSizeWithScope({
    newSize.maxWidth = maxLayoutSize.width;
    newSize.maxHeight = maxLayoutSize.height;
  });
  if (changed) {
    [self propertyDidChange:ASLayoutElementStyleMaxWidthProperty];
    [self propertyDidChange:ASLayoutElementStyleMaxHeightProperty];
  }
}

#pragma mark - ASStackLayoutElement

- (void)setSpacingBefore:(CGFloat)spacingBefore
{
  if (_spacingBefore.exchange(spacingBefore) != spacingBefore) {
    [self propertyDidChange:ASLayoutElementStyleSpacingBeforeProperty];
  }
}

- (CGFloat)spacingBefore
{
  return _spacingBefore.load();
}

- (void)setSpacingAfter:(CGFloat)spacingAfter
{
  if (_spacingAfter.exchange(spacingAfter) != spacingAfter) {
    [self propertyDidChange:ASLayoutElementStyleSpacingAfterProperty];
  }
}

- (CGFloat)spacingAfter
{
  return _spacingAfter.load();
}

- (void)setFlexGrow:(CGFloat)flexGrow
{
  if (_flexGrow.exchange(flexGrow) != flexGrow) {
    [self propertyDidChange:ASLayoutElementStyleFlexGrowProperty];
  }
}

- (CGFloat)flexGrow
{
  return _flexGrow.load();
}

- (void)setFlexShrink:(CGFloat)flexShrink
{
  if (_flexShrink.exchange(flexShrink) != flexShrink) {
    [self propertyDidChange:ASLayoutElementStyleFlexShrinkProperty];
  }
}

- (CGFloat)flexShrink
{
  return _flexShrink.load();
}

- (void)setFlexBasis:(ASDimension)flexBasis
{
  if (!ASDimensionEqualToDimension(_flexBasis.exchange(flexBasis), flexBasis)) {
    [self propertyDidChange:ASLayoutElementStyleFlexBasisProperty];
  }
}

- (ASDimension)flexBasis
{
  return _flexBasis.load();
}

- (void)setAlignSelf:(ASStackLayoutAlignSelf)alignSelf
{
  if (_alignSelf.exchange(alignSelf) != alignSelf) {
    [self propertyDidChange:ASLayoutElementStyleAlignSelfProperty];
  }
}

- (ASStackLayoutAlignSelf)alignSelf
{
  return _alignSelf.load();
}

- (void)setAscender:(CGFloat)ascender
{
  if (_ascender.exchange(ascender) != ascender) {
    [self propertyDidChange:ASLayoutElementStyleAscenderProperty];
  }
}

- (CGFloat)ascender
{
  return _ascender.load();
}

- (void)setDescender:(CGFloat)descender
{
  if (_descender.exchange(descender) != descender) {
    [self propertyDidChange:ASLayoutElementStyleDescenderProperty];
  }
}

- (CGFloat)descender
{
  return _descender.load();
}

#pragma mark - ASAbsoluteLayoutElement

- (void)setLayoutPosition:(CGPoint)layoutPosition
{
  if (!CGPointEqualToPoint(_layoutPosition.exchange(layoutPosition), layoutPosition)) {
    [self propertyDidChange:ASLayoutElementStyleLayoutPositionProperty];
  }
}

- (CGPoint)layoutPosition
{
  return _layoutPosition.load();
}

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


- (void)propertyDidChange:(NSString *)propertyName
{
  [_delegate style:self propertyDidChange:propertyName];
}

#if YOGA

#define ASSERT_USE_STYLE_NODE_YOGA() NSCAssert(NO, @"ASLayoutElementStyleYoga needs to be used.");

- (YGNodeRef)yogaNode {
  ASSERT_USE_STYLE_NODE_YOGA()
  return NULL;
}
- (YGWrap)flexWrap {
  ASSERT_USE_STYLE_NODE_YOGA()
  return YGWrapNoWrap;
}
- (ASStackLayoutDirection)flexDirection {
  ASSERT_USE_STYLE_NODE_YOGA()
  return ASStackLayoutDirectionVertical;
}
- (YGDirection)direction {
  ASSERT_USE_STYLE_NODE_YOGA()
  return YGDirectionInherit;
}
- (ASStackLayoutJustifyContent)justifyContent {
  ASSERT_USE_STYLE_NODE_YOGA()
  return ASStackLayoutJustifyContentStart;
}
- (ASStackLayoutAlignItems)alignItems {
  ASSERT_USE_STYLE_NODE_YOGA()
  return ASStackLayoutAlignItemsStretch;
}
- (YGPositionType)positionType {
  ASSERT_USE_STYLE_NODE_YOGA()
  return YGPositionTypeRelative;
}
- (ASEdgeInsets)position {
  ASSERT_USE_STYLE_NODE_YOGA()
  return ASEdgeInsetsMake(UIEdgeInsetsZero);
}
- (ASEdgeInsets)margin {
  ASSERT_USE_STYLE_NODE_YOGA()
  return ASEdgeInsetsMake(UIEdgeInsetsZero);
}
- (ASEdgeInsets)padding {
  ASSERT_USE_STYLE_NODE_YOGA()
  return ASEdgeInsetsMake(UIEdgeInsetsZero);
}
- (ASEdgeInsets)border {
  ASSERT_USE_STYLE_NODE_YOGA()
  return ASEdgeInsetsMake(UIEdgeInsetsZero);
}
- (CGFloat)aspectRatio {
  ASSERT_USE_STYLE_NODE_YOGA()
  return 0;
}
- (YGOverflow)overflow {
  ASSERT_USE_STYLE_NODE_YOGA()
  return YGOverflowVisible;
}
- (void)setFlexWrap:(YGWrap)flexWrap { ASSERT_USE_STYLE_NODE_YOGA() }
- (void)setFlexDirection:(ASStackLayoutDirection)flexDirection { ASSERT_USE_STYLE_NODE_YOGA() }
- (void)setDirection:(YGDirection)direction { ASSERT_USE_STYLE_NODE_YOGA() }
- (void)setJustifyContent:(ASStackLayoutJustifyContent)justify { ASSERT_USE_STYLE_NODE_YOGA() }
- (void)setAlignItems:(ASStackLayoutAlignItems)alignItems { ASSERT_USE_STYLE_NODE_YOGA() }
- (void)setPositionType:(YGPositionType)positionType { ASSERT_USE_STYLE_NODE_YOGA() }
- (void)setPosition:(ASEdgeInsets)position { ASSERT_USE_STYLE_NODE_YOGA() }
- (void)setMargin:(ASEdgeInsets)margin { ASSERT_USE_STYLE_NODE_YOGA() }
- (void)setPadding:(ASEdgeInsets)padding { ASSERT_USE_STYLE_NODE_YOGA() }
- (void)setBorder:(ASEdgeInsets)border { ASSERT_USE_STYLE_NODE_YOGA() }
- (void)setAspectRatio:(CGFloat)aspectRatio { ASSERT_USE_STYLE_NODE_YOGA() }
- (void)setOverflow:(YGOverflow)overflow { ASSERT_USE_STYLE_NODE_YOGA() }

#endif /* YOGA */

@end
