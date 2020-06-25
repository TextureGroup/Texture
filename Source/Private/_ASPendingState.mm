//
//  _ASPendingState.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/_ASPendingState.h>

#import <AsyncDisplayKit/_ASCoreAnimationExtras.h>
#import <AsyncDisplayKit/ASEqualityHelpers.h>
#import <AsyncDisplayKit/ASInternalHelpers.h>

#define __shouldSetNeedsDisplayForView(view) (flags.needsDisplay \
  || (flags.setOpaque && _flags.opaque != (view).opaque)\
  || (flags.setBackgroundColor && ![backgroundColor isEqual:(view).backgroundColor])\
  || (flags.setTintColor && ![tintColor isEqual:(view).tintColor]))

#define __shouldSetNeedsDisplayForLayer(layer) (flags.needsDisplay \
  || (flags.setOpaque && _flags.opaque != (layer).opaque)\
  || (flags.setBackgroundColor && ![backgroundColor isEqual:[UIColor colorWithCGColor:(layer).backgroundColor]]))

typedef struct {
  // Properties
  int needsDisplay:1;
  int needsLayout:1;
  int layoutIfNeeded:1;
  
  // Flags indicating that a given property should be applied to the view at creation
  int setClipsToBounds:1;
  int setOpaque:1;
  int setNeedsDisplayOnBoundsChange:1;
  int setAutoresizesSubviews:1;
  int setAutoresizingMask:1;
  int setFrame:1;
  int setBounds:1;
  int setBackgroundColor:1;
  int setTintColor:1;
  int setHidden:1;
  int setAlpha:1;
  int setCornerRadius:1;
  int setContentMode:1;
  int setNeedsDisplay:1;
  int setAnchorPoint:1;
  int setPosition:1;
  int setZPosition:1;
  int setTransform:1;
  int setSublayerTransform:1;
  int setContents:1;
  int setContentsGravity:1;
  int setContentsRect:1;
  int setContentsCenter:1;
  int setContentsScale:1;
  int setRasterizationScale:1;
  int setUserInteractionEnabled:1;
  int setExclusiveTouch:1;
  int setShadowColor:1;
  int setShadowOpacity:1;
  int setShadowOffset:1;
  int setShadowRadius:1;
  int setBorderWidth:1;
  int setBorderColor:1;
  int setAsyncTransactionContainer:1;
  int setAllowsGroupOpacity:1;
  int setAllowsEdgeAntialiasing:1;
  int setEdgeAntialiasingMask:1;
  int setIsAccessibilityElement:1;
  int setAccessibilityLabel:1;
  int setAccessibilityAttributedLabel:1;
  int setAccessibilityHint:1;
  int setAccessibilityAttributedHint:1;
  int setAccessibilityValue:1;
  int setAccessibilityAttributedValue:1;
  int setAccessibilityTraits:1;
  int setAccessibilityFrame:1;
  int setAccessibilityLanguage:1;
  int setAccessibilityElementsHidden:1;
  int setAccessibilityViewIsModal:1;
  int setShouldGroupAccessibilityChildren:1;
  int setAccessibilityIdentifier:1;
  int setAccessibilityNavigationStyle:1;
  int setAccessibilityCustomActions:1;
  int setAccessibilityHeaderElements:1;
  int setAccessibilityActivationPoint:1;
  int setAccessibilityPath:1;
  int setSemanticContentAttribute:1;
  int setLayoutMargins:1;
  int setPreservesSuperviewLayoutMargins:1;
  int setInsetsLayoutMarginsFromSafeArea:1;
  int setActions:1;
  int setMaskedCorners : 1;
} ASPendingStateFlags;


static constexpr ASPendingStateFlags kZeroFlags = {0};

@implementation _ASPendingState
{
  @package //Expose all ivars for ASDisplayNode to bypass getters for efficiency

  UIViewAutoresizing autoresizingMask;
  CAEdgeAntialiasingMask edgeAntialiasingMask;
  CGRect frame;   // Frame is only to be used for synchronous views wrapped by nodes (see setFrame:)
  CGRect bounds;
  UIColor *backgroundColor;
  UIColor *tintColor;
  CGFloat alpha;
  CGFloat cornerRadius;
  UIViewContentMode contentMode;
  CGPoint anchorPoint;
  CGPoint position;
  CGFloat zPosition;
  CATransform3D transform;
  CATransform3D sublayerTransform;
  id contents;
  NSString *contentsGravity;
  CGRect contentsRect;
  CGRect contentsCenter;
  CGFloat contentsScale;
  CGFloat rasterizationScale;
  CGColorRef shadowColor;
  CGFloat shadowOpacity;
  CGSize shadowOffset;
  CGFloat shadowRadius;
  CGFloat borderWidth;
  CGColorRef borderColor;
  UIEdgeInsets layoutMargins;
  NSString *accessibilityLabel;
  NSAttributedString *accessibilityAttributedLabel;
  NSString *accessibilityHint;
  NSAttributedString *accessibilityAttributedHint;
  NSString *accessibilityValue;
  NSAttributedString *accessibilityAttributedValue;
  UIAccessibilityTraits accessibilityTraits;
  CGRect accessibilityFrame;
  NSString *accessibilityLanguage;
  NSString *accessibilityIdentifier;
  UIAccessibilityNavigationStyle accessibilityNavigationStyle;
  NSArray *accessibilityCustomActions;
  NSArray *accessibilityHeaderElements;
  CGPoint accessibilityActivationPoint;
  UIBezierPath *accessibilityPath;
  UISemanticContentAttribute semanticContentAttribute API_AVAILABLE(ios(9.0), tvos(9.0));
  NSDictionary<NSString *, id<CAAction>> *actions;

  ASPendingStateFlags _stateToApplyFlags;
  struct {
    unsigned int asyncTransactionContainer:1;
    unsigned int preservesSuperviewLayoutMargins:1;
    unsigned int insetsLayoutMarginsFromSafeArea:1;
    unsigned int isAccessibilityElement:1;
    unsigned int accessibilityElementsHidden:1;
    unsigned int accessibilityViewIsModal:1;
    unsigned int shouldGroupAccessibilityChildren:1;
    unsigned int clipsToBounds:1;
    unsigned int opaque:1;
    unsigned int hidden:1;
    unsigned int needsDisplayOnBoundsChange:1;
    unsigned int allowsGroupOpacity:1;
    unsigned int allowsEdgeAntialiasing:1;
    unsigned int autoresizesSubviews:1;
    unsigned int userInteractionEnabled:1;
    unsigned int exclusiveTouch:1;
  } _flags;
}

/**
 * Apply the state's frame, bounds, and position to layer. This will not
 * be called on synchronous view-backed nodes which require we directly
 * call [view setFrame:].
 *
 * FIXME: How should we reconcile order-of-operations between setting frame, bounds, position?
 * Note we can't read bounds and position in the background, so we have to keep the frame
 * value intact until application time (now).
 */
ASDISPLAYNODE_INLINE void ASPendingStateApplyMetricsToLayer(_ASPendingState *state, CALayer *layer) {
  ASPendingStateFlags flags = state->_stateToApplyFlags;
  if (flags.setFrame) {
    CGRect _bounds = CGRectZero;
    CGPoint _position = CGPointZero;
    ASBoundsAndPositionForFrame(state->frame, layer.bounds.origin, layer.anchorPoint, &_bounds, &_position);
    layer.bounds = _bounds;
    layer.position = _position;
  } else {
    if (flags.setBounds)
      layer.bounds = state->bounds;
    if (flags.setPosition)
      layer.position = state->position;
  }
}

@synthesize frame=frame;
@synthesize bounds=bounds;
@synthesize backgroundColor=backgroundColor;
@synthesize edgeAntialiasingMask=edgeAntialiasingMask;
@synthesize autoresizingMask=autoresizingMask;
@synthesize tintColor=tintColor;
@synthesize alpha=alpha;
@synthesize cornerRadius=cornerRadius;
@synthesize contentMode=contentMode;
@synthesize anchorPoint=anchorPoint;
@synthesize position=position;
@synthesize zPosition=zPosition;
@synthesize transform=transform;
@synthesize sublayerTransform=sublayerTransform;
@synthesize contents=contents;
@synthesize contentsGravity=contentsGravity;
@synthesize contentsRect=contentsRect;
@synthesize contentsCenter=contentsCenter;
@synthesize contentsScale=contentsScale;
@synthesize rasterizationScale=rasterizationScale;
@synthesize userInteractionEnabled=userInteractionEnabled;
@synthesize exclusiveTouch=exclusiveTouch;
@synthesize shadowColor=shadowColor;
@synthesize shadowOpacity=shadowOpacity;
@synthesize shadowOffset=shadowOffset;
@synthesize shadowRadius=shadowRadius;
@synthesize borderWidth=borderWidth;
@synthesize borderColor=borderColor;
@synthesize asyncdisplaykit_asyncTransactionContainer=asyncTransactionContainer;
@synthesize semanticContentAttribute=semanticContentAttribute;
@synthesize layoutMargins=layoutMargins;
@synthesize preservesSuperviewLayoutMargins=preservesSuperviewLayoutMargins;
@synthesize insetsLayoutMarginsFromSafeArea=insetsLayoutMarginsFromSafeArea;
@synthesize actions=actions;
@synthesize maskedCorners = maskedCorners;

static CGColorRef blackColorRef = NULL;

- (instancetype)init
{
  if (!(self = [super init]))
    return nil;


  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    // Default UIKit color is an RGB color
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    blackColorRef = CGColorCreate(colorSpace, (CGFloat[]){0,0,0,1} );
    CFRetain(blackColorRef);
    CGColorSpaceRelease(colorSpace);
  });

  // Set defaults, these come from the defaults specified in CALayer and UIView
  _flags.clipsToBounds = NO;
  _flags.opaque = YES;
  frame = CGRectZero;
  bounds = CGRectZero;
  backgroundColor = nil;
  tintColor = nil;
  _flags.hidden = NO;
  _flags.needsDisplayOnBoundsChange = NO;
  _flags.allowsGroupOpacity = ASDefaultAllowsGroupOpacity();
  _flags.allowsEdgeAntialiasing = ASDefaultAllowsEdgeAntialiasing();
  _flags.autoresizesSubviews = YES;
  alpha = 1.0f;
  cornerRadius = 0.0f;
  contentMode = UIViewContentModeScaleToFill;
  _stateToApplyFlags.needsDisplay = NO;
  anchorPoint = CGPointMake(0.5, 0.5);
  position = CGPointZero;
  zPosition = 0.0;
  transform = CATransform3DIdentity;
  sublayerTransform = CATransform3DIdentity;
  contents = nil;
  contentsGravity = kCAGravityResize;
  contentsRect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
  contentsCenter = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
  contentsScale = 1.0f;
  rasterizationScale = 1.0f;
  _flags.userInteractionEnabled = YES;
  shadowColor = blackColorRef;
  shadowOpacity = 0.0;
  shadowOffset = CGSizeMake(0, -3);
  shadowRadius = 3;
  borderWidth = 0;
  borderColor = blackColorRef;
  layoutMargins = UIEdgeInsetsMake(8, 8, 8, 8);
  _flags.preservesSuperviewLayoutMargins = NO;
  _flags.insetsLayoutMarginsFromSafeArea = YES;
  _flags.isAccessibilityElement = NO;
  accessibilityLabel = nil;
  accessibilityAttributedLabel = nil;
  accessibilityHint = nil;
  accessibilityAttributedHint = nil;
  accessibilityValue = nil;
  accessibilityAttributedValue = nil;
  accessibilityTraits = UIAccessibilityTraitNone;
  accessibilityFrame = CGRectZero;
  accessibilityLanguage = nil;
  _flags.accessibilityElementsHidden = NO;
  _flags.accessibilityViewIsModal = NO;
  _flags.shouldGroupAccessibilityChildren = NO;
  accessibilityIdentifier = nil;
  accessibilityNavigationStyle = UIAccessibilityNavigationStyleAutomatic;
  accessibilityCustomActions = nil;
  accessibilityHeaderElements = nil;
  accessibilityActivationPoint = CGPointZero;
  accessibilityPath = nil;
  edgeAntialiasingMask = (kCALayerLeftEdge | kCALayerRightEdge | kCALayerTopEdge | kCALayerBottomEdge);
  semanticContentAttribute = UISemanticContentAttributeUnspecified;

  return self;
}

- (void)setNeedsDisplay
{
  _stateToApplyFlags.needsDisplay = YES;
}

- (void)setNeedsLayout
{
  _stateToApplyFlags.needsLayout = YES;
}

- (void)layoutIfNeeded
{
  _stateToApplyFlags.layoutIfNeeded = YES;
}

- (void)setClipsToBounds:(BOOL)flag
{
  _flags.clipsToBounds = flag;
  _stateToApplyFlags.setClipsToBounds = YES;
}

- (BOOL)clipsToBounds
{
    return _flags.clipsToBounds;
}

- (void)setOpaque:(BOOL)flag
{
  _flags.opaque = flag;
  _stateToApplyFlags.setOpaque = YES;
}

- (BOOL)isOpaque
{
    return _flags.opaque;
}

- (void)setNeedsDisplayOnBoundsChange:(BOOL)flag
{
  _flags.needsDisplayOnBoundsChange = flag;
  _stateToApplyFlags.setNeedsDisplayOnBoundsChange = YES;
}

- (BOOL)needsDisplayOnBoundsChange
{
    return _flags.needsDisplayOnBoundsChange;
}

- (void)setAllowsGroupOpacity:(BOOL)flag
{
  _flags.allowsGroupOpacity = flag;
  _stateToApplyFlags.setAllowsGroupOpacity = YES;
}

- (BOOL)allowsGroupOpacity
{
    return _flags.allowsGroupOpacity;
}

- (void)setAllowsEdgeAntialiasing:(BOOL)flag
{
  _flags.allowsEdgeAntialiasing = flag;
  _stateToApplyFlags.setAllowsEdgeAntialiasing = YES;
}

- (BOOL)allowsEdgeAntialiasing
{
    return _flags.allowsEdgeAntialiasing;
}

- (void)setEdgeAntialiasingMask:(CAEdgeAntialiasingMask)mask
{
  edgeAntialiasingMask = mask;
  _stateToApplyFlags.setEdgeAntialiasingMask = YES;
}

- (void)setAutoresizesSubviews:(BOOL)flag
{
  _flags.autoresizesSubviews = flag;
  _stateToApplyFlags.setAutoresizesSubviews = YES;
}

- (BOOL)autoresizesSubviews
{
    return _flags.autoresizesSubviews;
}

- (void)setAutoresizingMask:(UIViewAutoresizing)mask
{
  autoresizingMask = mask;
  _stateToApplyFlags.setAutoresizingMask = YES;
}

- (void)setFrame:(CGRect)newFrame
{
  frame = newFrame;
  _stateToApplyFlags.setFrame = YES;
}

- (void)setBounds:(CGRect)newBounds
{
  ASDisplayNodeAssert(!isnan(newBounds.size.width) && !isnan(newBounds.size.height), @"Invalid bounds %@ provided to %@", NSStringFromCGRect(newBounds), self);
  if (isnan(newBounds.size.width))
    newBounds.size.width = 0.0;
  if (isnan(newBounds.size.height))
    newBounds.size.height = 0.0;
  bounds = newBounds;
  _stateToApplyFlags.setBounds = YES;
}

- (UIColor *)backgroundColor
{
  return backgroundColor;
}

- (void)setBackgroundColor:(UIColor *)color
{
  if ([color isEqual:backgroundColor]) {
    return;
  }
  backgroundColor = color;
  _stateToApplyFlags.setBackgroundColor = YES;
}

- (UIColor *)tintColor
{
  return tintColor;
}

- (void)setTintColor:(UIColor *)newTintColor
{
  if ([newTintColor isEqual:tintColor]) {
    return;
  }
  tintColor = newTintColor;
  _stateToApplyFlags.setTintColor = YES;
}

- (void)setHidden:(BOOL)flag
{
  _flags.hidden = flag;
  _stateToApplyFlags.setHidden = YES;
}

- (BOOL)isHidden
{
    return _flags.hidden;
}

- (void)setAlpha:(CGFloat)newAlpha
{
  alpha = newAlpha;
  _stateToApplyFlags.setAlpha = YES;
}

- (void)setCornerRadius:(CGFloat)newCornerRadius
{
  cornerRadius = newCornerRadius;
  _stateToApplyFlags.setCornerRadius = YES;
}

- (void)setMaskedCorners:(CACornerMask)newMaskedCorners
{
  maskedCorners = newMaskedCorners;
  _stateToApplyFlags.setMaskedCorners = YES;
}

- (void)setContentMode:(UIViewContentMode)newContentMode
{
  contentMode = newContentMode;
  _stateToApplyFlags.setContentMode = YES;
}

- (void)setAnchorPoint:(CGPoint)newAnchorPoint
{
  anchorPoint = newAnchorPoint;
  _stateToApplyFlags.setAnchorPoint = YES;
}

- (void)setPosition:(CGPoint)newPosition
{
  ASDisplayNodeAssert(!isnan(newPosition.x) && !isnan(newPosition.y), @"Invalid position %@ provided to %@", NSStringFromCGPoint(newPosition), self);
  if (isnan(newPosition.x))
    newPosition.x = 0.0;
  if (isnan(newPosition.y))
    newPosition.y = 0.0;
  position = newPosition;
  _stateToApplyFlags.setPosition = YES;
}

- (void)setZPosition:(CGFloat)newPosition
{
  zPosition = newPosition;
  _stateToApplyFlags.setZPosition = YES;
}

- (void)setTransform:(CATransform3D)newTransform
{
  transform = newTransform;
  _stateToApplyFlags.setTransform = YES;
}

- (void)setSublayerTransform:(CATransform3D)newSublayerTransform
{
  sublayerTransform = newSublayerTransform;
  _stateToApplyFlags.setSublayerTransform = YES;
}

- (void)setContents:(id)newContents
{
  if (contents == newContents) {
    return;
  }

  contents = newContents;
  _stateToApplyFlags.setContents = YES;
}

- (void)setContentsGravity:(NSString *)newContentsGravity
{
  contentsGravity = newContentsGravity;
  _stateToApplyFlags.setContentsGravity = YES;
}

- (void)setContentsRect:(CGRect)newContentsRect
{
  contentsRect = newContentsRect;
  _stateToApplyFlags.setContentsRect = YES;
}

- (void)setContentsCenter:(CGRect)newContentsCenter
{
  contentsCenter = newContentsCenter;
  _stateToApplyFlags.setContentsCenter = YES;
}

- (void)setContentsScale:(CGFloat)newContentsScale
{
  contentsScale = newContentsScale;
  _stateToApplyFlags.setContentsScale = YES;
}

- (void)setRasterizationScale:(CGFloat)newRasterizationScale
{
  rasterizationScale = newRasterizationScale;
  _stateToApplyFlags.setRasterizationScale = YES;
}

- (void)setUserInteractionEnabled:(BOOL)flag
{
  _flags.userInteractionEnabled = flag;
  _stateToApplyFlags.setUserInteractionEnabled = YES;
}

- (BOOL)isUserInteractionEnabled
{
    return _flags.userInteractionEnabled;
}

- (void)setExclusiveTouch:(BOOL)flag
{
  _flags.exclusiveTouch = flag;
  _stateToApplyFlags.setExclusiveTouch = YES;
}

- (BOOL)isExclusiveTouch
{
    return _flags.exclusiveTouch;
}

- (void)setShadowColor:(CGColorRef)color
{
  if (shadowColor == color) {
    return;
  }

  if (shadowColor != blackColorRef) {
    CGColorRelease(shadowColor);
  }
  shadowColor = color;
  CGColorRetain(shadowColor);

  _stateToApplyFlags.setShadowColor = YES;
}

- (void)setShadowOpacity:(CGFloat)newOpacity
{
  shadowOpacity = newOpacity;
  _stateToApplyFlags.setShadowOpacity = YES;
}

- (void)setShadowOffset:(CGSize)newOffset
{
  shadowOffset = newOffset;
  _stateToApplyFlags.setShadowOffset = YES;
}

- (void)setShadowRadius:(CGFloat)newRadius
{
  shadowRadius = newRadius;
  _stateToApplyFlags.setShadowRadius = YES;
}

- (void)setBorderWidth:(CGFloat)newWidth
{
  borderWidth = newWidth;
  _stateToApplyFlags.setBorderWidth = YES;
}

- (void)setBorderColor:(CGColorRef)color
{
  if (borderColor == color) {
    return;
  }

  if (borderColor != blackColorRef) {
    CGColorRelease(borderColor);
  }
  borderColor = color;
  CGColorRetain(borderColor);

  _stateToApplyFlags.setBorderColor = YES;
}

- (void)asyncdisplaykit_setAsyncTransactionContainer:(BOOL)flag
{
  _flags.asyncTransactionContainer = flag;
  _stateToApplyFlags.setAsyncTransactionContainer = YES;
}

- (BOOL)asyncdisplaykit_isAsyncTransactionContainer
{
    return _flags.asyncTransactionContainer;
}

- (void)setLayoutMargins:(UIEdgeInsets)margins
{
  layoutMargins = margins;
  _stateToApplyFlags.setLayoutMargins = YES;
}

- (void)setPreservesSuperviewLayoutMargins:(BOOL)flag
{
  _flags.preservesSuperviewLayoutMargins = flag;
  _stateToApplyFlags.setPreservesSuperviewLayoutMargins = YES;
}

- (BOOL)preservesSuperviewLayoutMargins
{
    return _flags.preservesSuperviewLayoutMargins;
}

- (void)setInsetsLayoutMarginsFromSafeArea:(BOOL)flag
{
  _flags.insetsLayoutMarginsFromSafeArea = flag;
  _stateToApplyFlags.setInsetsLayoutMarginsFromSafeArea = YES;
}

- (BOOL)insetsLayoutMarginsFromSafeArea
{
    return _flags.insetsLayoutMarginsFromSafeArea;
}

- (void)setSemanticContentAttribute:(UISemanticContentAttribute)attribute API_AVAILABLE(ios(9.0), tvos(9.0)) {
  semanticContentAttribute = attribute;
  _stateToApplyFlags.setSemanticContentAttribute = YES;
}

- (void)setActions:(NSDictionary<NSString *,id<CAAction>> *)actionsArg
{
  actions = [actionsArg copy];
  _stateToApplyFlags.setActions = YES;
}

- (BOOL)isAccessibilityElement
{
  return _flags.isAccessibilityElement;
}

- (void)setIsAccessibilityElement:(BOOL)newIsAccessibilityElement
{
  _flags.isAccessibilityElement = newIsAccessibilityElement;
  _stateToApplyFlags.setIsAccessibilityElement = YES;
}

- (NSString *)accessibilityLabel
{
  if (_stateToApplyFlags.setAccessibilityAttributedLabel) {
    return accessibilityAttributedLabel.string;
  }
  return accessibilityLabel;
}

- (void)setAccessibilityLabel:(NSString *)newAccessibilityLabel
{
  ASCompareAssignCopy(accessibilityLabel, newAccessibilityLabel);
  _stateToApplyFlags.setAccessibilityLabel = YES;
  _stateToApplyFlags.setAccessibilityAttributedLabel = NO;
}

- (NSAttributedString *)accessibilityAttributedLabel
{
  if (_stateToApplyFlags.setAccessibilityLabel) {
    return [[NSAttributedString alloc] initWithString:accessibilityLabel];
  }
  return accessibilityAttributedLabel;
}

- (void)setAccessibilityAttributedLabel:(NSAttributedString *)newAccessibilityAttributedLabel
{
  ASCompareAssignCopy(accessibilityAttributedLabel, newAccessibilityAttributedLabel);
  _stateToApplyFlags.setAccessibilityAttributedLabel = YES;
  _stateToApplyFlags.setAccessibilityLabel = NO;
}

- (NSString *)accessibilityHint
{
  if (_stateToApplyFlags.setAccessibilityAttributedHint) {
    return accessibilityAttributedHint.string;
  }
  return accessibilityHint;
}

- (void)setAccessibilityHint:(NSString *)newAccessibilityHint
{
  ASCompareAssignCopy(accessibilityHint, newAccessibilityHint);
  _stateToApplyFlags.setAccessibilityHint = YES;
  _stateToApplyFlags.setAccessibilityAttributedHint = NO;
}

- (NSAttributedString *)accessibilityAttributedHint
{
  if (_stateToApplyFlags.setAccessibilityHint) {
    return [[NSAttributedString alloc] initWithString:accessibilityHint];
  }
  return accessibilityAttributedHint;
}

- (void)setAccessibilityAttributedHint:(NSAttributedString *)newAccessibilityAttributedHint
{
  ASCompareAssignCopy(accessibilityAttributedHint, newAccessibilityAttributedHint);
  _stateToApplyFlags.setAccessibilityAttributedHint = YES;
  _stateToApplyFlags.setAccessibilityHint = NO;
}

- (NSString *)accessibilityValue
{
  if (_stateToApplyFlags.setAccessibilityAttributedValue) {
    return accessibilityAttributedValue.string;
  }
  return accessibilityValue;
}

- (void)setAccessibilityValue:(NSString *)newAccessibilityValue
{
  ASCompareAssignCopy(accessibilityValue, newAccessibilityValue);
  _stateToApplyFlags.setAccessibilityValue = YES;
  _stateToApplyFlags.setAccessibilityAttributedValue = NO;
}

- (NSAttributedString *)accessibilityAttributedValue
{
  if (_stateToApplyFlags.setAccessibilityValue) {
    return [[NSAttributedString alloc] initWithString:accessibilityValue];
  }
  return accessibilityAttributedValue;
}

- (void)setAccessibilityAttributedValue:(NSAttributedString *)newAccessibilityAttributedValue
{
  ASCompareAssignCopy(accessibilityAttributedValue, newAccessibilityAttributedValue);
  _stateToApplyFlags.setAccessibilityAttributedValue = YES;
  _stateToApplyFlags.setAccessibilityValue = NO;
}

- (UIAccessibilityTraits)accessibilityTraits
{
  return accessibilityTraits;
}

- (void)setAccessibilityTraits:(UIAccessibilityTraits)newAccessibilityTraits
{
  accessibilityTraits = newAccessibilityTraits;
  _stateToApplyFlags.setAccessibilityTraits = YES;
}

- (CGRect)accessibilityFrame
{
  return accessibilityFrame;
}

- (void)setAccessibilityFrame:(CGRect)newAccessibilityFrame
{
  accessibilityFrame = newAccessibilityFrame;
  _stateToApplyFlags.setAccessibilityFrame = YES;
}

- (NSString *)accessibilityLanguage
{
  return accessibilityLanguage;
}

- (void)setAccessibilityLanguage:(NSString *)newAccessibilityLanguage
{
  _stateToApplyFlags.setAccessibilityLanguage = YES;
  accessibilityLanguage = newAccessibilityLanguage;
}

- (BOOL)accessibilityElementsHidden
{
  return _flags.accessibilityElementsHidden;
}

- (void)setAccessibilityElementsHidden:(BOOL)newAccessibilityElementsHidden
{
  _flags.accessibilityElementsHidden = newAccessibilityElementsHidden;
  _stateToApplyFlags.setAccessibilityElementsHidden = YES;
}

- (BOOL)accessibilityViewIsModal
{
  return _flags.accessibilityViewIsModal;
}

- (void)setAccessibilityViewIsModal:(BOOL)newAccessibilityViewIsModal
{
  _flags.accessibilityViewIsModal = newAccessibilityViewIsModal;
  _stateToApplyFlags.setAccessibilityViewIsModal = YES;
}

- (BOOL)shouldGroupAccessibilityChildren
{
  return _flags.shouldGroupAccessibilityChildren;
}

- (void)setShouldGroupAccessibilityChildren:(BOOL)newShouldGroupAccessibilityChildren
{
  _flags.shouldGroupAccessibilityChildren = newShouldGroupAccessibilityChildren;
  _stateToApplyFlags.setShouldGroupAccessibilityChildren = YES;
}

- (NSString *)accessibilityIdentifier
{
  return accessibilityIdentifier;
}

- (void)setAccessibilityIdentifier:(NSString *)newAccessibilityIdentifier
{
  _stateToApplyFlags.setAccessibilityIdentifier = YES;
  if (accessibilityIdentifier != newAccessibilityIdentifier) {
    accessibilityIdentifier = [newAccessibilityIdentifier copy];
  }
}

- (UIAccessibilityNavigationStyle)accessibilityNavigationStyle
{
  return accessibilityNavigationStyle;
}

- (void)setAccessibilityNavigationStyle:(UIAccessibilityNavigationStyle)newAccessibilityNavigationStyle
{
  _stateToApplyFlags.setAccessibilityNavigationStyle = YES;
  accessibilityNavigationStyle = newAccessibilityNavigationStyle;
}

- (NSArray *)accessibilityCustomActions
{
  return accessibilityCustomActions;
}

- (void)setAccessibilityCustomActions:(NSArray *)newAccessibilityCustomActions
{
  _stateToApplyFlags.setAccessibilityCustomActions = YES;
  if (accessibilityCustomActions != newAccessibilityCustomActions) {
    accessibilityCustomActions = [newAccessibilityCustomActions copy];
  }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (NSArray *)accessibilityHeaderElements
{
  return accessibilityHeaderElements;
}

- (void)setAccessibilityHeaderElements:(NSArray *)newAccessibilityHeaderElements
{
  _stateToApplyFlags.setAccessibilityHeaderElements = YES;
  if (accessibilityHeaderElements != newAccessibilityHeaderElements) {
    accessibilityHeaderElements = [newAccessibilityHeaderElements copy];
  }
}
#pragma clang diagnostic pop

- (CGPoint)accessibilityActivationPoint
{
  if (_stateToApplyFlags.setAccessibilityActivationPoint) {
    return accessibilityActivationPoint;
  }
  
  // Default == Mid-point of the accessibilityFrame
  return CGPointMake(CGRectGetMidX(accessibilityFrame), CGRectGetMidY(accessibilityFrame));
}

- (void)setAccessibilityActivationPoint:(CGPoint)newAccessibilityActivationPoint
{
  _stateToApplyFlags.setAccessibilityActivationPoint = YES;
  accessibilityActivationPoint = newAccessibilityActivationPoint;
}

- (UIBezierPath *)accessibilityPath
{
  return accessibilityPath;
}

- (void)setAccessibilityPath:(UIBezierPath *)newAccessibilityPath
{
  _stateToApplyFlags.setAccessibilityPath = YES;
  if (accessibilityPath != newAccessibilityPath) {
    accessibilityPath = newAccessibilityPath;
  }
}

- (void)applyToLayer:(CALayer *)layer
{
  ASPendingStateFlags flags = _stateToApplyFlags;

  if (__shouldSetNeedsDisplayForLayer(layer)) {
    [layer setNeedsDisplay];
  }

  if (flags.setAnchorPoint)
    layer.anchorPoint = anchorPoint;

  if (flags.setZPosition)
    layer.zPosition = zPosition;

  if (flags.setTransform)
    layer.transform = transform;

  if (flags.setSublayerTransform)
    layer.sublayerTransform = sublayerTransform;

  if (flags.setContents)
    layer.contents = contents;

  if (flags.setContentsGravity)
    layer.contentsGravity = contentsGravity;

  if (flags.setContentsRect)
    layer.contentsRect = contentsRect;

  if (flags.setContentsCenter)
    layer.contentsCenter = contentsCenter;

  if (flags.setContentsScale)
    layer.contentsScale = contentsScale;

  if (flags.setRasterizationScale)
    layer.rasterizationScale = rasterizationScale;

  if (flags.setClipsToBounds)
    layer.masksToBounds = _flags.clipsToBounds;

  if (flags.setBackgroundColor)
    layer.backgroundColor = backgroundColor.CGColor;

  if (flags.setOpaque)
    layer.opaque = _flags.opaque;

  if (flags.setHidden)
    layer.hidden = _flags.hidden;

  if (flags.setAlpha)
    layer.opacity = alpha;

  if (flags.setCornerRadius)
    layer.cornerRadius = cornerRadius;

  if (AS_AVAILABLE_IOS_TVOS(11, 11)) {
    if (flags.setMaskedCorners) {
      layer.maskedCorners = maskedCorners;
    }
  }

  if (flags.setContentMode)
    layer.contentsGravity = ASDisplayNodeCAContentsGravityFromUIContentMode(contentMode);

  if (flags.setShadowColor)
    layer.shadowColor = shadowColor;

  if (flags.setShadowOpacity)
    layer.shadowOpacity = shadowOpacity;

  if (flags.setShadowOffset)
    layer.shadowOffset = shadowOffset;

  if (flags.setShadowRadius)
    layer.shadowRadius = shadowRadius;

  if (flags.setBorderWidth)
    layer.borderWidth = borderWidth;

  if (flags.setBorderColor)
    layer.borderColor = borderColor;

  if (flags.setNeedsDisplayOnBoundsChange)
    layer.needsDisplayOnBoundsChange = _flags.needsDisplayOnBoundsChange;
  
  if (flags.setAllowsGroupOpacity)
    layer.allowsGroupOpacity = _flags.allowsGroupOpacity;

  if (flags.setAllowsEdgeAntialiasing)
    layer.allowsEdgeAntialiasing = _flags.allowsEdgeAntialiasing;

  if (flags.setEdgeAntialiasingMask)
    layer.edgeAntialiasingMask = edgeAntialiasingMask;

  if (flags.setAsyncTransactionContainer)
    layer.asyncdisplaykit_asyncTransactionContainer = _flags.asyncTransactionContainer;

  if (flags.setOpaque)
    ASDisplayNodeAssert(layer.opaque == _flags.opaque, @"Didn't set opaque as desired");

  if (flags.setActions)
    layer.actions = actions;

  ASPendingStateApplyMetricsToLayer(self, layer);
  
  if (flags.needsLayout)
    [layer setNeedsLayout];
  
  if (flags.layoutIfNeeded)
    [layer layoutIfNeeded];
}

- (void)applyToView:(UIView *)view withSpecialPropertiesHandling:(BOOL)specialPropertiesHandling
{
  /*
   Use our convenience setters blah here instead of layer.blah
   We were accidentally setting some properties on layer here, but view in UIViewBridgeOptimizations.

   That could easily cause bugs where it mattered whether you set something up on a bg thread on in -didLoad
   because a different setter would be called.
   */

  unowned CALayer *layer = view.layer;

  ASPendingStateFlags flags = _stateToApplyFlags;
  if (__shouldSetNeedsDisplayForView(view)) {
    [view setNeedsDisplay];
  }

  if (flags.setAnchorPoint)
    layer.anchorPoint = anchorPoint;

  if (flags.setPosition)
    layer.position = position;

  if (flags.setZPosition)
    layer.zPosition = zPosition;

  if (flags.setBounds)
    view.bounds = bounds;

  if (flags.setTransform)
    layer.transform = transform;

  if (flags.setSublayerTransform)
    layer.sublayerTransform = sublayerTransform;

  if (flags.setContents)
    layer.contents = contents;

  if (flags.setContentsGravity)
    layer.contentsGravity = contentsGravity;

  if (flags.setContentsRect)
    layer.contentsRect = contentsRect;

  if (flags.setContentsCenter)
    layer.contentsCenter = contentsCenter;

  if (flags.setContentsScale)
    layer.contentsScale = contentsScale;

  if (flags.setRasterizationScale)
    layer.rasterizationScale = rasterizationScale;

  if (flags.setActions)
    layer.actions = actions;

  if (flags.setClipsToBounds)
    view.clipsToBounds = _flags.clipsToBounds;

  if (flags.setBackgroundColor) {
    view.backgroundColor = backgroundColor;
    layer.backgroundColor = backgroundColor.CGColor;
  }

  if (flags.setTintColor)
    view.tintColor = tintColor;

  if (flags.setOpaque) {
    view.opaque = _flags.opaque;
    layer.opaque = _flags.opaque;
  }

  if (flags.setHidden)
    view.hidden = _flags.hidden;

  if (flags.setAlpha)
    view.alpha = alpha;

  if (flags.setCornerRadius)
    layer.cornerRadius = cornerRadius;

  if (flags.setContentMode)
    view.contentMode = contentMode;

  if (flags.setUserInteractionEnabled)
    view.userInteractionEnabled = _flags.userInteractionEnabled;

  #if TARGET_OS_IOS
  if (flags.setExclusiveTouch)
    view.exclusiveTouch = _flags.exclusiveTouch;
  #endif
    
  if (flags.setShadowColor)
    layer.shadowColor = shadowColor;

  if (flags.setShadowOpacity)
    layer.shadowOpacity = shadowOpacity;

  if (flags.setShadowOffset)
    layer.shadowOffset = shadowOffset;

  if (flags.setShadowRadius)
    layer.shadowRadius = shadowRadius;

  if (flags.setBorderWidth)
    layer.borderWidth = borderWidth;

  if (flags.setBorderColor)
    layer.borderColor = borderColor;

  if (flags.setAutoresizingMask)
    view.autoresizingMask = autoresizingMask;

  if (flags.setAutoresizesSubviews)
    view.autoresizesSubviews = _flags.autoresizesSubviews;

  if (flags.setNeedsDisplayOnBoundsChange)
    layer.needsDisplayOnBoundsChange = _flags.needsDisplayOnBoundsChange;
  
  if (flags.setAllowsGroupOpacity)
    layer.allowsGroupOpacity = _flags.allowsGroupOpacity;

  if (flags.setAllowsEdgeAntialiasing)
    layer.allowsEdgeAntialiasing = _flags.allowsEdgeAntialiasing;

  if (flags.setEdgeAntialiasingMask)
    layer.edgeAntialiasingMask = edgeAntialiasingMask;

  if (flags.setAsyncTransactionContainer)
    view.asyncdisplaykit_asyncTransactionContainer = _flags.asyncTransactionContainer;

  if (flags.setOpaque)
    ASDisplayNodeAssert(layer.opaque == _flags.opaque, @"Didn't set opaque as desired");

  if (flags.setLayoutMargins)
    view.layoutMargins = layoutMargins;

  if (flags.setPreservesSuperviewLayoutMargins)
    view.preservesSuperviewLayoutMargins = _flags.preservesSuperviewLayoutMargins;

  if (AS_AVAILABLE_IOS_TVOS(11.0, 11.0)) {
    if (flags.setInsetsLayoutMarginsFromSafeArea) {
      view.insetsLayoutMarginsFromSafeArea = _flags.insetsLayoutMarginsFromSafeArea;
    }
  }

  if (flags.setSemanticContentAttribute) {
    view.semanticContentAttribute = semanticContentAttribute;
  }

  if (flags.setIsAccessibilityElement)
    view.isAccessibilityElement = _flags.isAccessibilityElement;

  if (flags.setAccessibilityLabel)
    view.accessibilityLabel = accessibilityLabel;

  if (flags.setAccessibilityHint)
    view.accessibilityHint = accessibilityHint;

  if (flags.setAccessibilityValue)
    view.accessibilityValue = accessibilityValue;

  if (AS_AVAILABLE_IOS_TVOS(11, 11)) {
    if (flags.setAccessibilityAttributedLabel) {
      view.accessibilityAttributedLabel = accessibilityAttributedLabel;
    }
    if (flags.setAccessibilityAttributedHint) {
      view.accessibilityAttributedHint = accessibilityAttributedHint;
    }
    if (flags.setAccessibilityAttributedValue) {
      view.accessibilityAttributedValue = accessibilityAttributedValue;
    }
  }

  if (flags.setAccessibilityTraits)
    view.accessibilityTraits = accessibilityTraits;

  if (flags.setAccessibilityFrame)
    view.accessibilityFrame = accessibilityFrame;

  if (flags.setAccessibilityLanguage)
    view.accessibilityLanguage = accessibilityLanguage;

  if (flags.setAccessibilityElementsHidden)
    view.accessibilityElementsHidden = _flags.accessibilityElementsHidden;

  if (flags.setAccessibilityViewIsModal)
    view.accessibilityViewIsModal = _flags.accessibilityViewIsModal;

  if (flags.setShouldGroupAccessibilityChildren)
    view.shouldGroupAccessibilityChildren = _flags.shouldGroupAccessibilityChildren;

  if (flags.setAccessibilityIdentifier)
    view.accessibilityIdentifier = accessibilityIdentifier;
  
  if (flags.setAccessibilityNavigationStyle)
    view.accessibilityNavigationStyle = accessibilityNavigationStyle;

  if (flags.setAccessibilityCustomActions) {
    view.accessibilityCustomActions = accessibilityCustomActions;
  }

#if TARGET_OS_TV
  if (flags.setAccessibilityHeaderElements)
    view.accessibilityHeaderElements = accessibilityHeaderElements;
#endif
  
  if (flags.setAccessibilityActivationPoint)
    view.accessibilityActivationPoint = accessibilityActivationPoint;
  
  if (flags.setAccessibilityPath)
    view.accessibilityPath = accessibilityPath;

  if (flags.setFrame && specialPropertiesHandling) {
    // Frame is only defined when transform is identity because we explicitly diverge from CALayer behavior and define frame without transform
//#if DEBUG
//    // Checking if the transform is identity is expensive, so disable when unnecessary. We have assertions on in Release, so DEBUG is the only way I know of.
//    ASDisplayNodeAssert(CATransform3DIsIdentity(layer.transform), @"-[ASDisplayNode setFrame:] - self.transform must be identity in order to set the frame property.  (From Apple's UIView documentation: If the transform property is not the identity transform, the value of this property is undefined and therefore should be ignored.)");
//#endif
    view.frame = frame;
  } else {
    ASPendingStateApplyMetricsToLayer(self, layer);
  }
  
  if (flags.needsLayout)
    [view setNeedsLayout];
  
  if (flags.layoutIfNeeded)
    [view layoutIfNeeded];
}

// FIXME: Make this more efficient by tracking which properties are set rather than reading everything.
+ (_ASPendingState *)pendingViewStateFromLayer:(CALayer *)layer
{
  if (!layer) {
    return nil;
  }
  _ASPendingState *pendingState = [[_ASPendingState alloc] init];
  pendingState.anchorPoint = layer.anchorPoint;
  pendingState.position = layer.position;
  pendingState.zPosition = layer.zPosition;
  pendingState.bounds = layer.bounds;
  pendingState.transform = layer.transform;
  pendingState.sublayerTransform = layer.sublayerTransform;
  pendingState.contents = layer.contents;
  pendingState.contentsGravity = layer.contentsGravity;
  pendingState.contentsRect = layer.contentsRect;
  pendingState.contentsCenter = layer.contentsCenter;
  pendingState.contentsScale = layer.contentsScale;
  pendingState.rasterizationScale = layer.rasterizationScale;
  pendingState.clipsToBounds = layer.masksToBounds;
  pendingState.backgroundColor = [UIColor colorWithCGColor:layer.backgroundColor];
  pendingState.opaque = layer.opaque;
  pendingState.hidden = layer.hidden;
  pendingState.alpha = layer.opacity;
  pendingState.cornerRadius = layer.cornerRadius;
  pendingState.contentMode = ASDisplayNodeUIContentModeFromCAContentsGravity(layer.contentsGravity);
  pendingState.shadowColor = layer.shadowColor;
  pendingState.shadowOpacity = layer.shadowOpacity;
  pendingState.shadowOffset = layer.shadowOffset;
  pendingState.shadowRadius = layer.shadowRadius;
  pendingState.borderWidth = layer.borderWidth;
  pendingState.borderColor = layer.borderColor;
  pendingState.needsDisplayOnBoundsChange = layer.needsDisplayOnBoundsChange;
  pendingState.allowsGroupOpacity = layer.allowsGroupOpacity;
  pendingState.allowsEdgeAntialiasing = layer.allowsEdgeAntialiasing;
  pendingState.edgeAntialiasingMask = layer.edgeAntialiasingMask;
  return pendingState;
}

// FIXME: Make this more efficient by tracking which properties are set rather than reading everything.
+ (_ASPendingState *)pendingViewStateFromView:(UIView *)view
{
  if (!view) {
    return nil;
  }
  _ASPendingState *pendingState = [[_ASPendingState alloc] init];

  CALayer *layer = view.layer;
  pendingState.anchorPoint = layer.anchorPoint;
  pendingState.position = layer.position;
  pendingState.zPosition = layer.zPosition;
  pendingState.bounds = view.bounds;
  pendingState.transform = layer.transform;
  pendingState.sublayerTransform = layer.sublayerTransform;
  pendingState.contents = layer.contents;
  pendingState.contentsGravity = layer.contentsGravity;
  pendingState.contentsRect = layer.contentsRect;
  pendingState.contentsCenter = layer.contentsCenter;
  pendingState.contentsScale = layer.contentsScale;
  pendingState.rasterizationScale = layer.rasterizationScale;
  pendingState.clipsToBounds = view.clipsToBounds;
  pendingState.backgroundColor = view.backgroundColor;
  pendingState.tintColor = view.tintColor;
  pendingState.opaque = layer.opaque;
  pendingState.hidden = view.hidden;
  pendingState.alpha = view.alpha;
  pendingState.cornerRadius = layer.cornerRadius;
  pendingState.contentMode = view.contentMode;
  pendingState.userInteractionEnabled = view.userInteractionEnabled;
#if TARGET_OS_IOS
  pendingState.exclusiveTouch = view.exclusiveTouch;
#endif
  pendingState.shadowColor = layer.shadowColor;
  pendingState.shadowOpacity = layer.shadowOpacity;
  pendingState.shadowOffset = layer.shadowOffset;
  pendingState.shadowRadius = layer.shadowRadius;
  pendingState.borderWidth = layer.borderWidth;
  pendingState.borderColor = layer.borderColor;
  pendingState.autoresizingMask = view.autoresizingMask;
  pendingState.autoresizesSubviews = view.autoresizesSubviews;
  pendingState.needsDisplayOnBoundsChange = layer.needsDisplayOnBoundsChange;
  pendingState.allowsGroupOpacity = layer.allowsGroupOpacity;
  pendingState.allowsEdgeAntialiasing = layer.allowsEdgeAntialiasing;
  pendingState.edgeAntialiasingMask = layer.edgeAntialiasingMask;
  pendingState.semanticContentAttribute = view.semanticContentAttribute;
  pendingState.layoutMargins = view.layoutMargins;
  pendingState.preservesSuperviewLayoutMargins = view.preservesSuperviewLayoutMargins;
  if (AS_AVAILABLE_IOS_TVOS(11, 11)) {
    pendingState.insetsLayoutMarginsFromSafeArea = view.insetsLayoutMarginsFromSafeArea;
  }
  pendingState.isAccessibilityElement = view.isAccessibilityElement;
  pendingState.accessibilityLabel = view.accessibilityLabel;
  pendingState.accessibilityHint = view.accessibilityHint;
  pendingState.accessibilityValue = view.accessibilityValue;
  if (AS_AVAILABLE_IOS_TVOS(11, 11)) {
    pendingState.accessibilityAttributedLabel = view.accessibilityAttributedLabel;
    pendingState.accessibilityAttributedHint = view.accessibilityAttributedHint;
    pendingState.accessibilityAttributedValue = view.accessibilityAttributedValue;
  }
  pendingState.accessibilityTraits = view.accessibilityTraits;
  pendingState.accessibilityFrame = view.accessibilityFrame;
  pendingState.accessibilityLanguage = view.accessibilityLanguage;
  pendingState.accessibilityElementsHidden = view.accessibilityElementsHidden;
  pendingState.accessibilityViewIsModal = view.accessibilityViewIsModal;
  pendingState.shouldGroupAccessibilityChildren = view.shouldGroupAccessibilityChildren;
  pendingState.accessibilityIdentifier = view.accessibilityIdentifier;
  pendingState.accessibilityNavigationStyle = view.accessibilityNavigationStyle;
  pendingState.accessibilityCustomActions = view.accessibilityCustomActions;
#if TARGET_OS_TV
  pendingState.accessibilityHeaderElements = view.accessibilityHeaderElements;
#endif
  pendingState.accessibilityActivationPoint = view.accessibilityActivationPoint;
  pendingState.accessibilityPath = view.accessibilityPath;
  return pendingState;
}

- (void)clearChanges
{
  _stateToApplyFlags = kZeroFlags;
}

- (BOOL)hasSetNeedsLayout
{
  return _stateToApplyFlags.needsLayout;
}

- (BOOL)hasSetNeedsDisplay
{
  return _stateToApplyFlags.needsDisplay;
}

- (BOOL)hasChanges
{
  return memcmp(&_stateToApplyFlags, &kZeroFlags, sizeof(ASPendingStateFlags));
}

- (void)dealloc
{
  if (shadowColor != blackColorRef) {
    CGColorRelease(shadowColor);
  }
  
  if (borderColor != blackColorRef) {
    CGColorRelease(borderColor);
  }
}

@end
