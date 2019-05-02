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
#import <AsyncDisplayKit/_ASAsyncTransactionContainer.h>
#import <AsyncDisplayKit/ASAssert.h>
#import <AsyncDisplayKit/ASEqualityHelpers.h>
#import <AsyncDisplayKit/ASDisplayNodeInternal.h>
#import <AsyncDisplayKit/ASInternalHelpers.h>

#define __shouldSetNeedsDisplay(layer) (flags.needsDisplay \
  || (flags.setOpaque && flags.opaque != (layer).opaque)\
  || (flags.setBackgroundColor && !CGColorEqualToColor(backgroundColor, (layer).backgroundColor)))

typedef struct {
  // Properties
  unsigned int needsDisplay:1;
  unsigned int needsLayout:1;
  unsigned int layoutIfNeeded:1;
  
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

  // Flags indicating that a given property should be applied to the view at creation
  unsigned int setClipsToBounds:1;
  unsigned int setOpaque:1;
  unsigned int setNeedsDisplayOnBoundsChange:1;
  unsigned int setAutoresizesSubviews:1;
  unsigned int setAutoresizingMask:1;
  unsigned int setFrame:1;
  unsigned int setBounds:1;
  unsigned int setBackgroundColor:1;
  unsigned int setTintColor:1;
  unsigned int setHidden:1;
  unsigned int setAlpha:1;
  unsigned int setCornerRadius:1;
  unsigned int setContentMode:1;
  unsigned int setNeedsDisplay:1;
  unsigned int setAnchorPoint:1;
  unsigned int setPosition:1;
  unsigned int setZPosition:1;
  unsigned int setTransform:1;
  unsigned int setSublayerTransform:1;
  unsigned int setContents:1;
  unsigned int setContentsGravity:1;
  unsigned int setContentsRect:1;
  unsigned int setContentsCenter:1;
  unsigned int setContentsScale:1;
  unsigned int setRasterizationScale:1;
  unsigned int setUserInteractionEnabled:1;
  unsigned int setExclusiveTouch:1;
  unsigned int setShadowColor:1;
  unsigned int setShadowOpacity:1;
  unsigned int setShadowOffset:1;
  unsigned int setShadowRadius:1;
  unsigned int setBorderWidth:1;
  unsigned int setBorderColor:1;
  unsigned int setAsyncTransactionContainer:1;
  unsigned int setAllowsGroupOpacity:1;
  unsigned int setAllowsEdgeAntialiasing:1;
  unsigned int setEdgeAntialiasingMask:1;
  unsigned int setIsAccessibilityElement:1;
  unsigned int setAccessibilityLabel:1;
  unsigned int setAccessibilityAttributedLabel:1;
  unsigned int setAccessibilityHint:1;
  unsigned int setAccessibilityAttributedHint:1;
  unsigned int setAccessibilityValue:1;
  unsigned int setAccessibilityAttributedValue:1;
  unsigned int setAccessibilityTraits:1;
  unsigned int setAccessibilityFrame:1;
  unsigned int setAccessibilityLanguage:1;
  unsigned int setAccessibilityElementsHidden:1;
  unsigned int setAccessibilityViewIsModal:1;
  unsigned int setShouldGroupAccessibilityChildren:1;
  unsigned int setAccessibilityIdentifier:1;
  unsigned int setAccessibilityNavigationStyle:1;
  unsigned int setAccessibilityCustomActions:1;
  unsigned int setAccessibilityHeaderElements:1;
  unsigned int setAccessibilityActivationPoint:1;
  unsigned int setAccessibilityPath:1;
  unsigned int setSemanticContentAttribute:1;
  unsigned int setLayoutMargins:1;
  unsigned int setPreservesSuperviewLayoutMargins:1;
  unsigned int setInsetsLayoutMarginsFromSafeArea:1;
  unsigned int setActions:1;
  unsigned int setMaskedCorners : 1;
} ASPendingStateFlags;


static constexpr ASPendingStateFlags kZeroFlags = {0};

@implementation _ASPendingState
{
  @package //Expose all ivars for ASDisplayNode to bypass getters for efficiency

  UIViewAutoresizing autoresizingMask;
  unsigned int edgeAntialiasingMask;
  CGRect frame;   // Frame is only to be used for synchronous views wrapped by nodes (see setFrame:)
  CGRect bounds;
  CGColorRef backgroundColor;
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

  ASPendingStateFlags _flags;
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
  ASPendingStateFlags flags = state->_flags;
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
static UIColor *defaultTintColor = nil;

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
    defaultTintColor = [UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0];
  });

  // Set defaults, these come from the defaults specified in CALayer and UIView
  _flags.clipsToBounds = NO;
  _flags.opaque = YES;
  frame = CGRectZero;
  bounds = CGRectZero;
  backgroundColor = nil;
  tintColor = defaultTintColor;
  _flags.hidden = NO;
  _flags.needsDisplayOnBoundsChange = NO;
  _flags.allowsGroupOpacity = ASDefaultAllowsGroupOpacity();
  _flags.allowsEdgeAntialiasing = ASDefaultAllowsEdgeAntialiasing();
  _flags.autoresizesSubviews = YES;
  alpha = 1.0f;
  cornerRadius = 0.0f;
  contentMode = UIViewContentModeScaleToFill;
  _flags.needsDisplay = NO;
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
  _flags.needsDisplay = YES;
}

- (void)setNeedsLayout
{
  _flags.needsLayout = YES;
}

- (void)layoutIfNeeded
{
  _flags.layoutIfNeeded = YES;
}

- (void)setClipsToBounds:(BOOL)flag
{
  _flags.clipsToBounds = flag;
  _flags.setClipsToBounds = YES;
}

- (BOOL)clipsToBounds
{
    return _flags.clipsToBounds;
}

- (void)setOpaque:(BOOL)flag
{
  _flags.opaque = flag;
  _flags.setOpaque = YES;
}

- (BOOL)isOpaque
{
    return _flags.opaque;
}

- (void)setNeedsDisplayOnBoundsChange:(BOOL)flag
{
  _flags.needsDisplayOnBoundsChange = flag;
  _flags.setNeedsDisplayOnBoundsChange = YES;
}

- (BOOL)needsDisplayOnBoundsChange
{
    return _flags.needsDisplayOnBoundsChange;
}

- (void)setAllowsGroupOpacity:(BOOL)flag
{
  _flags.allowsGroupOpacity = flag;
  _flags.setAllowsGroupOpacity = YES;
}

- (BOOL)allowsGroupOpacity
{
    return _flags.allowsGroupOpacity;
}

- (void)setAllowsEdgeAntialiasing:(BOOL)flag
{
  _flags.allowsEdgeAntialiasing = flag;
  _flags.setAllowsEdgeAntialiasing = YES;
}

- (BOOL)allowsEdgeAntialiasing
{
    return _flags.allowsEdgeAntialiasing;
}

- (void)setEdgeAntialiasingMask:(unsigned int)mask
{
  edgeAntialiasingMask = mask;
  _flags.setEdgeAntialiasingMask = YES;
}

- (void)setAutoresizesSubviews:(BOOL)flag
{
  _flags.autoresizesSubviews = flag;
  _flags.setAutoresizesSubviews = YES;
}

- (BOOL)autoresizesSubviews
{
    return _flags.autoresizesSubviews;
}

- (void)setAutoresizingMask:(UIViewAutoresizing)mask
{
  autoresizingMask = mask;
  _flags.setAutoresizingMask = YES;
}

- (void)setFrame:(CGRect)newFrame
{
  frame = newFrame;
  _flags.setFrame = YES;
}

- (void)setBounds:(CGRect)newBounds
{
  ASDisplayNodeAssert(!isnan(newBounds.size.width) && !isnan(newBounds.size.height), @"Invalid bounds %@ provided to %@", NSStringFromCGRect(newBounds), self);
  if (isnan(newBounds.size.width))
    newBounds.size.width = 0.0;
  if (isnan(newBounds.size.height))
    newBounds.size.height = 0.0;
  bounds = newBounds;
  _flags.setBounds = YES;
}

- (CGColorRef)backgroundColor
{
  return backgroundColor;
}

- (void)setBackgroundColor:(CGColorRef)color
{
  if (color == backgroundColor) {
    return;
  }

  CGColorRelease(backgroundColor);
  backgroundColor = CGColorRetain(color);
  _flags.setBackgroundColor = YES;
}

- (void)setTintColor:(UIColor *)newTintColor
{
  tintColor = newTintColor;
  _flags.setTintColor = YES;
}

- (void)setHidden:(BOOL)flag
{
  _flags.hidden = flag;
  _flags.setHidden = YES;
}

- (BOOL)isHidden
{
    return _flags.hidden;
}

- (void)setAlpha:(CGFloat)newAlpha
{
  alpha = newAlpha;
  _flags.setAlpha = YES;
}

- (void)setCornerRadius:(CGFloat)newCornerRadius
{
  cornerRadius = newCornerRadius;
  _flags.setCornerRadius = YES;
}

- (void)setMaskedCorners:(CACornerMask)newMaskedCorners
{
  maskedCorners = newMaskedCorners;
  _flags.setMaskedCorners = YES;
}

- (void)setContentMode:(UIViewContentMode)newContentMode
{
  contentMode = newContentMode;
  _flags.setContentMode = YES;
}

- (void)setAnchorPoint:(CGPoint)newAnchorPoint
{
  anchorPoint = newAnchorPoint;
  _flags.setAnchorPoint = YES;
}

- (void)setPosition:(CGPoint)newPosition
{
  ASDisplayNodeAssert(!isnan(newPosition.x) && !isnan(newPosition.y), @"Invalid position %@ provided to %@", NSStringFromCGPoint(newPosition), self);
  if (isnan(newPosition.x))
    newPosition.x = 0.0;
  if (isnan(newPosition.y))
    newPosition.y = 0.0;
  position = newPosition;
  _flags.setPosition = YES;
}

- (void)setZPosition:(CGFloat)newPosition
{
  zPosition = newPosition;
  _flags.setZPosition = YES;
}

- (void)setTransform:(CATransform3D)newTransform
{
  transform = newTransform;
  _flags.setTransform = YES;
}

- (void)setSublayerTransform:(CATransform3D)newSublayerTransform
{
  sublayerTransform = newSublayerTransform;
  _flags.setSublayerTransform = YES;
}

- (void)setContents:(id)newContents
{
  if (contents == newContents) {
    return;
  }

  contents = newContents;
  _flags.setContents = YES;
}

- (void)setContentsGravity:(NSString *)newContentsGravity
{
  contentsGravity = newContentsGravity;
  _flags.setContentsGravity = YES;
}

- (void)setContentsRect:(CGRect)newContentsRect
{
  contentsRect = newContentsRect;
  _flags.setContentsRect = YES;
}

- (void)setContentsCenter:(CGRect)newContentsCenter
{
  contentsCenter = newContentsCenter;
  _flags.setContentsCenter = YES;
}

- (void)setContentsScale:(CGFloat)newContentsScale
{
  contentsScale = newContentsScale;
  _flags.setContentsScale = YES;
}

- (void)setRasterizationScale:(CGFloat)newRasterizationScale
{
  rasterizationScale = newRasterizationScale;
  _flags.setRasterizationScale = YES;
}

- (void)setUserInteractionEnabled:(BOOL)flag
{
  _flags.userInteractionEnabled = flag;
  _flags.setUserInteractionEnabled = YES;
}

- (BOOL)isUserInteractionEnabled
{
    return _flags.userInteractionEnabled;
}

- (void)setExclusiveTouch:(BOOL)flag
{
  _flags.exclusiveTouch = flag;
  _flags.setExclusiveTouch = YES;
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

  _flags.setShadowColor = YES;
}

- (void)setShadowOpacity:(CGFloat)newOpacity
{
  shadowOpacity = newOpacity;
  _flags.setShadowOpacity = YES;
}

- (void)setShadowOffset:(CGSize)newOffset
{
  shadowOffset = newOffset;
  _flags.setShadowOffset = YES;
}

- (void)setShadowRadius:(CGFloat)newRadius
{
  shadowRadius = newRadius;
  _flags.setShadowRadius = YES;
}

- (void)setBorderWidth:(CGFloat)newWidth
{
  borderWidth = newWidth;
  _flags.setBorderWidth = YES;
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

  _flags.setBorderColor = YES;
}

- (void)asyncdisplaykit_setAsyncTransactionContainer:(BOOL)flag
{
  _flags.asyncTransactionContainer = flag;
  _flags.setAsyncTransactionContainer = YES;
}

- (BOOL)asyncdisplaykit_isAsyncTransactionContainer
{
    return _flags.asyncTransactionContainer;
}

- (void)setLayoutMargins:(UIEdgeInsets)margins
{
  layoutMargins = margins;
  _flags.setLayoutMargins = YES;
}

- (void)setPreservesSuperviewLayoutMargins:(BOOL)flag
{
  _flags.preservesSuperviewLayoutMargins = flag;
  _flags.setPreservesSuperviewLayoutMargins = YES;
}

- (BOOL)preservesSuperviewLayoutMargins
{
    return _flags.preservesSuperviewLayoutMargins;
}

- (void)setInsetsLayoutMarginsFromSafeArea:(BOOL)flag
{
  _flags.insetsLayoutMarginsFromSafeArea = flag;
  _flags.setInsetsLayoutMarginsFromSafeArea = YES;
}

- (BOOL)insetsLayoutMarginsFromSafeArea
{
    return _flags.insetsLayoutMarginsFromSafeArea;
}

- (void)setSemanticContentAttribute:(UISemanticContentAttribute)attribute API_AVAILABLE(ios(9.0), tvos(9.0)) {
  semanticContentAttribute = attribute;
  _flags.setSemanticContentAttribute = YES;
}

- (void)setActions:(NSDictionary<NSString *,id<CAAction>> *)actionsArg
{
  actions = [actionsArg copy];
  _flags.setActions = YES;
}

- (BOOL)isAccessibilityElement
{
  return _flags.isAccessibilityElement;
}

- (void)setIsAccessibilityElement:(BOOL)newIsAccessibilityElement
{
  _flags.isAccessibilityElement = newIsAccessibilityElement;
  _flags.setIsAccessibilityElement = YES;
}

- (NSString *)accessibilityLabel
{
  if (_flags.setAccessibilityAttributedLabel) {
    return accessibilityAttributedLabel.string;
  }
  return accessibilityLabel;
}

- (void)setAccessibilityLabel:(NSString *)newAccessibilityLabel
{
  ASCompareAssignCopy(accessibilityLabel, newAccessibilityLabel);
  _flags.setAccessibilityLabel = YES;
  _flags.setAccessibilityAttributedLabel = NO;
}

- (NSAttributedString *)accessibilityAttributedLabel
{
  if (_flags.setAccessibilityLabel) {
    return [[NSAttributedString alloc] initWithString:accessibilityLabel];
  }
  return accessibilityAttributedLabel;
}

- (void)setAccessibilityAttributedLabel:(NSAttributedString *)newAccessibilityAttributedLabel
{
  ASCompareAssignCopy(accessibilityAttributedLabel, newAccessibilityAttributedLabel);
  _flags.setAccessibilityAttributedLabel = YES;
  _flags.setAccessibilityLabel = NO;
}

- (NSString *)accessibilityHint
{
  if (_flags.setAccessibilityAttributedHint) {
    return accessibilityAttributedHint.string;
  }
  return accessibilityHint;
}

- (void)setAccessibilityHint:(NSString *)newAccessibilityHint
{
  ASCompareAssignCopy(accessibilityHint, newAccessibilityHint);
  _flags.setAccessibilityHint = YES;
  _flags.setAccessibilityAttributedHint = NO;
}

- (NSAttributedString *)accessibilityAttributedHint
{
  if (_flags.setAccessibilityHint) {
    return [[NSAttributedString alloc] initWithString:accessibilityHint];
  }
  return accessibilityAttributedHint;
}

- (void)setAccessibilityAttributedHint:(NSAttributedString *)newAccessibilityAttributedHint
{
  ASCompareAssignCopy(accessibilityAttributedHint, newAccessibilityAttributedHint);
  _flags.setAccessibilityAttributedHint = YES;
  _flags.setAccessibilityHint = NO;
}

- (NSString *)accessibilityValue
{
  if (_flags.setAccessibilityAttributedValue) {
    return accessibilityAttributedValue.string;
  }
  return accessibilityValue;
}

- (void)setAccessibilityValue:(NSString *)newAccessibilityValue
{
  ASCompareAssignCopy(accessibilityValue, newAccessibilityValue);
  _flags.setAccessibilityValue = YES;
  _flags.setAccessibilityAttributedValue = NO;
}

- (NSAttributedString *)accessibilityAttributedValue
{
  if (_flags.setAccessibilityValue) {
    return [[NSAttributedString alloc] initWithString:accessibilityValue];
  }
  return accessibilityAttributedValue;
}

- (void)setAccessibilityAttributedValue:(NSAttributedString *)newAccessibilityAttributedValue
{
  ASCompareAssignCopy(accessibilityAttributedValue, newAccessibilityAttributedValue);
  _flags.setAccessibilityAttributedValue = YES;
  _flags.setAccessibilityValue = NO;
}

- (UIAccessibilityTraits)accessibilityTraits
{
  return accessibilityTraits;
}

- (void)setAccessibilityTraits:(UIAccessibilityTraits)newAccessibilityTraits
{
  accessibilityTraits = newAccessibilityTraits;
  _flags.setAccessibilityTraits = YES;
}

- (CGRect)accessibilityFrame
{
  return accessibilityFrame;
}

- (void)setAccessibilityFrame:(CGRect)newAccessibilityFrame
{
  accessibilityFrame = newAccessibilityFrame;
  _flags.setAccessibilityFrame = YES;
}

- (NSString *)accessibilityLanguage
{
  return accessibilityLanguage;
}

- (void)setAccessibilityLanguage:(NSString *)newAccessibilityLanguage
{
  _flags.setAccessibilityLanguage = YES;
  accessibilityLanguage = newAccessibilityLanguage;
}

- (BOOL)accessibilityElementsHidden
{
  return _flags.accessibilityElementsHidden;
}

- (void)setAccessibilityElementsHidden:(BOOL)newAccessibilityElementsHidden
{
  _flags.accessibilityElementsHidden = newAccessibilityElementsHidden;
  _flags.setAccessibilityElementsHidden = YES;
}

- (BOOL)accessibilityViewIsModal
{
  return _flags.accessibilityViewIsModal;
}

- (void)setAccessibilityViewIsModal:(BOOL)newAccessibilityViewIsModal
{
  _flags.accessibilityViewIsModal = newAccessibilityViewIsModal;
  _flags.setAccessibilityViewIsModal = YES;
}

- (BOOL)shouldGroupAccessibilityChildren
{
  return _flags.shouldGroupAccessibilityChildren;
}

- (void)setShouldGroupAccessibilityChildren:(BOOL)newShouldGroupAccessibilityChildren
{
  _flags.shouldGroupAccessibilityChildren = newShouldGroupAccessibilityChildren;
  _flags.setShouldGroupAccessibilityChildren = YES;
}

- (NSString *)accessibilityIdentifier
{
  return accessibilityIdentifier;
}

- (void)setAccessibilityIdentifier:(NSString *)newAccessibilityIdentifier
{
  _flags.setAccessibilityIdentifier = YES;
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
  _flags.setAccessibilityNavigationStyle = YES;
  accessibilityNavigationStyle = newAccessibilityNavigationStyle;
}

- (NSArray *)accessibilityCustomActions
{
  return accessibilityCustomActions;
}

- (void)setAccessibilityCustomActions:(NSArray *)newAccessibilityCustomActions
{
  _flags.setAccessibilityCustomActions = YES;
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
  _flags.setAccessibilityHeaderElements = YES;
  if (accessibilityHeaderElements != newAccessibilityHeaderElements) {
    accessibilityHeaderElements = [newAccessibilityHeaderElements copy];
  }
}
#pragma clang diagnostic pop

- (CGPoint)accessibilityActivationPoint
{
  if (_flags.setAccessibilityActivationPoint) {
    return accessibilityActivationPoint;
  }
  
  // Default == Mid-point of the accessibilityFrame
  return CGPointMake(CGRectGetMidX(accessibilityFrame), CGRectGetMidY(accessibilityFrame));
}

- (void)setAccessibilityActivationPoint:(CGPoint)newAccessibilityActivationPoint
{
  _flags.setAccessibilityActivationPoint = YES;
  accessibilityActivationPoint = newAccessibilityActivationPoint;
}

- (UIBezierPath *)accessibilityPath
{
  return accessibilityPath;
}

- (void)setAccessibilityPath:(UIBezierPath *)newAccessibilityPath
{
  _flags.setAccessibilityPath = YES;
  if (accessibilityPath != newAccessibilityPath) {
    accessibilityPath = newAccessibilityPath;
  }
}

- (void)applyToLayer:(CALayer *)layer
{
  ASPendingStateFlags flags = _flags;

  if (__shouldSetNeedsDisplay(layer)) {
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
    layer.backgroundColor = backgroundColor;

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

  ASPendingStateFlags flags = _flags;
  if (__shouldSetNeedsDisplay(layer)) {
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
    // We have to make sure certain nodes get the background color call directly set
    if (specialPropertiesHandling) {
      view.backgroundColor = [UIColor colorWithCGColor:backgroundColor];
    } else {
      // Set the background color to the layer as in the UIView bridge we use this value as background color
      layer.backgroundColor = backgroundColor;
    }
  }

  if (flags.setTintColor)
    view.tintColor = self.tintColor;

  if (flags.setOpaque)
    layer.opaque = _flags.opaque;

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

  if (AS_AVAILABLE_IOS(11.0)) {
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
  pendingState.backgroundColor = layer.backgroundColor;
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
  pendingState.backgroundColor = layer.backgroundColor;
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
  _flags = kZeroFlags;
}

- (BOOL)hasSetNeedsLayout
{
  return _flags.needsLayout;
}

- (BOOL)hasSetNeedsDisplay
{
  return _flags.needsDisplay;
}

- (BOOL)hasChanges
{
  return memcmp(&_flags, &kZeroFlags, sizeof(ASPendingStateFlags));
}

- (void)dealloc
{
  CGColorRelease(backgroundColor);
  
  if (shadowColor != blackColorRef) {
    CGColorRelease(shadowColor);
  }
  
  if (borderColor != blackColorRef) {
    CGColorRelease(borderColor);
  }
}

@end

#pragma clang diagnostic pop
