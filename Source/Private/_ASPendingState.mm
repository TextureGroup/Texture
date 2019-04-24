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

#include <forward_list>

BOOL __shouldSetNeedsDisplay(CALayer *layer, BOOL needsDisplay, BOOL setOpaque, BOOL opaque, BOOL setBackgroundColor, CGColorRef backgroundColor) {
    return needsDisplay || (setOpaque && opaque != layer.opaque) || (setBackgroundColor && !CGColorEqualToColor(backgroundColor, layer.backgroundColor));
}

#define validate_bounds(newBounds)                                                                                                                              \
ASDisplayNodeAssert(!isnan(newBounds.size.width) && !isnan(newBounds.size.height), @"Invalid bounds %@ provided to %@", NSStringFromCGRect(newBounds), self);   \
if (isnan(newBounds.size.width))                                                                                                                                \
  newBounds.size.width = 0.0;                                                                                                                                   \
if (isnan(newBounds.size.height))                                                                                                                               \
  newBounds.size.height = 0.0;                                                                                                                                  \

#define validate_position(newPosition)                                                                                                              \
ASDisplayNodeAssert(!isnan(newPosition.x) && !isnan(newPosition.y), @"Invalid position %@ provided to %@", NSStringFromCGPoint(newPosition), self); \
if (isnan(newPosition.x))                                                                                                                           \
  newPosition.x = 0.0;                                                                                                                              \
if (isnan(newPosition.y))                                                                                                                           \
  newPosition.y = 0.0;                                                                                                                              \

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

@implementation _ASPendingStateInflated
{
  @package
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
  BOOL asyncTransactionContainer;
  UIEdgeInsets layoutMargins;
  BOOL preservesSuperviewLayoutMargins;
  BOOL insetsLayoutMarginsFromSafeArea;
  BOOL isAccessibilityElement;
  NSString *accessibilityLabel;
  NSAttributedString *accessibilityAttributedLabel;
  NSString *accessibilityHint;
  NSAttributedString *accessibilityAttributedHint;
  NSString *accessibilityValue;
  NSAttributedString *accessibilityAttributedValue;
  UIAccessibilityTraits accessibilityTraits;
  CGRect accessibilityFrame;
  NSString *accessibilityLanguage;
  BOOL accessibilityElementsHidden;
  BOOL accessibilityViewIsModal;
  BOOL shouldGroupAccessibilityChildren;
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
ASDISPLAYNODE_INLINE void ASPendingStateApplyMetricsToLayer(_ASPendingStateInflated *state, CALayer *layer) {
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

@synthesize clipsToBounds=clipsToBounds;
@synthesize opaque=opaque;
@synthesize frame=frame;
@synthesize bounds=bounds;
@synthesize backgroundColor=backgroundColor;
@synthesize hidden=isHidden;
@synthesize needsDisplayOnBoundsChange=needsDisplayOnBoundsChange;
@synthesize allowsGroupOpacity=allowsGroupOpacity;
@synthesize allowsEdgeAntialiasing=allowsEdgeAntialiasing;
@synthesize edgeAntialiasingMask=edgeAntialiasingMask;
@synthesize autoresizesSubviews=autoresizesSubviews;
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
  clipsToBounds = NO;
  opaque = YES;
  frame = CGRectZero;
  bounds = CGRectZero;
  backgroundColor = nil;
  tintColor = defaultTintColor;
  isHidden = NO;
  needsDisplayOnBoundsChange = NO;
  allowsGroupOpacity = ASDefaultAllowsGroupOpacity();
  allowsEdgeAntialiasing = ASDefaultAllowsEdgeAntialiasing();
  autoresizesSubviews = YES;
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
  userInteractionEnabled = YES;
  shadowColor = blackColorRef;
  shadowOpacity = 0.0;
  shadowOffset = CGSizeMake(0, -3);
  shadowRadius = 3;
  borderWidth = 0;
  borderColor = blackColorRef;
  layoutMargins = UIEdgeInsetsMake(8, 8, 8, 8);
  preservesSuperviewLayoutMargins = NO;
  insetsLayoutMarginsFromSafeArea = YES;
  isAccessibilityElement = NO;
  accessibilityLabel = nil;
  accessibilityAttributedLabel = nil;
  accessibilityHint = nil;
  accessibilityAttributedHint = nil;
  accessibilityValue = nil;
  accessibilityAttributedValue = nil;
  accessibilityTraits = UIAccessibilityTraitNone;
  accessibilityFrame = CGRectZero;
  accessibilityLanguage = nil;
  accessibilityElementsHidden = NO;
  accessibilityViewIsModal = NO;
  shouldGroupAccessibilityChildren = NO;
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

- (BOOL)hasLayoutIfNeeded
{
  return _flags.layoutIfNeeded;
}

- (void)setClipsToBounds:(BOOL)flag
{
  clipsToBounds = flag;
  _flags.setClipsToBounds = YES;
}

- (void)setOpaque:(BOOL)flag
{
  opaque = flag;
  _flags.setOpaque = YES;
}

- (void)setNeedsDisplayOnBoundsChange:(BOOL)flag
{
  needsDisplayOnBoundsChange = flag;
  _flags.setNeedsDisplayOnBoundsChange = YES;
}

- (void)setAllowsGroupOpacity:(BOOL)flag
{
  allowsGroupOpacity = flag;
  _flags.setAllowsGroupOpacity = YES;
}

- (void)setAllowsEdgeAntialiasing:(BOOL)flag
{
  allowsEdgeAntialiasing = flag;
  _flags.setAllowsEdgeAntialiasing = YES;
}

- (void)setEdgeAntialiasingMask:(unsigned int)mask
{
  edgeAntialiasingMask = mask;
  _flags.setEdgeAntialiasingMask = YES;
}

- (void)setAutoresizesSubviews:(BOOL)flag
{
  autoresizesSubviews = flag;
  _flags.setAutoresizesSubviews = YES;
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
  validate_bounds(newBounds);
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
  isHidden = flag;
  _flags.setHidden = YES;
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
  validate_position(newPosition);
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
  userInteractionEnabled = flag;
  _flags.setUserInteractionEnabled = YES;
}

- (void)setExclusiveTouch:(BOOL)flag
{
  exclusiveTouch = flag;
  _flags.setExclusiveTouch = YES;
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
  asyncTransactionContainer = flag;
  _flags.setAsyncTransactionContainer = YES;
}

- (void)setLayoutMargins:(UIEdgeInsets)margins
{
  layoutMargins = margins;
  _flags.setLayoutMargins = YES;
}

- (void)setPreservesSuperviewLayoutMargins:(BOOL)flag
{
  preservesSuperviewLayoutMargins = flag;
  _flags.setPreservesSuperviewLayoutMargins = YES;
}

- (void)setInsetsLayoutMarginsFromSafeArea:(BOOL)flag
{
  insetsLayoutMarginsFromSafeArea = flag;
  _flags.setInsetsLayoutMarginsFromSafeArea = YES;
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
  return isAccessibilityElement;
}

- (void)setIsAccessibilityElement:(BOOL)newIsAccessibilityElement
{
  isAccessibilityElement = newIsAccessibilityElement;
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
  return accessibilityElementsHidden;
}

- (void)setAccessibilityElementsHidden:(BOOL)newAccessibilityElementsHidden
{
  accessibilityElementsHidden = newAccessibilityElementsHidden;
  _flags.setAccessibilityElementsHidden = YES;
}

- (BOOL)accessibilityViewIsModal
{
  return accessibilityViewIsModal;
}

- (void)setAccessibilityViewIsModal:(BOOL)newAccessibilityViewIsModal
{
  accessibilityViewIsModal = newAccessibilityViewIsModal;
  _flags.setAccessibilityViewIsModal = YES;
}

- (BOOL)shouldGroupAccessibilityChildren
{
  return shouldGroupAccessibilityChildren;
}

- (void)setShouldGroupAccessibilityChildren:(BOOL)newShouldGroupAccessibilityChildren
{
  shouldGroupAccessibilityChildren = newShouldGroupAccessibilityChildren;
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

  if (__shouldSetNeedsDisplay(layer, flags.needsDisplay, flags.setOpaque, opaque, flags.setBackgroundColor, backgroundColor)) {
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
    layer.masksToBounds = clipsToBounds;

  if (flags.setBackgroundColor)
    layer.backgroundColor = backgroundColor;

  if (flags.setOpaque)
    layer.opaque = opaque;

  if (flags.setHidden)
    layer.hidden = isHidden;

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
    layer.needsDisplayOnBoundsChange = needsDisplayOnBoundsChange;
  
  if (flags.setAllowsGroupOpacity)
    layer.allowsGroupOpacity = allowsGroupOpacity;

  if (flags.setAllowsEdgeAntialiasing)
    layer.allowsEdgeAntialiasing = allowsEdgeAntialiasing;

  if (flags.setEdgeAntialiasingMask)
    layer.edgeAntialiasingMask = edgeAntialiasingMask;

  if (flags.setAsyncTransactionContainer)
    layer.asyncdisplaykit_asyncTransactionContainer = asyncTransactionContainer;

  if (flags.setOpaque)
    ASDisplayNodeAssert(layer.opaque == opaque, @"Didn't set opaque as desired");

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
  if (__shouldSetNeedsDisplay(layer, flags.needsDisplay, flags.setOpaque, opaque, flags.setBackgroundColor, backgroundColor)) {
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
    view.clipsToBounds = clipsToBounds;

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
    layer.opaque = opaque;

  if (flags.setHidden)
    view.hidden = isHidden;

  if (flags.setAlpha)
    view.alpha = alpha;

  if (flags.setCornerRadius)
    layer.cornerRadius = cornerRadius;

  if (flags.setContentMode)
    view.contentMode = contentMode;

  if (flags.setUserInteractionEnabled)
    view.userInteractionEnabled = userInteractionEnabled;

  #if TARGET_OS_IOS
  if (flags.setExclusiveTouch)
    view.exclusiveTouch = exclusiveTouch;
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
    view.autoresizesSubviews = autoresizesSubviews;

  if (flags.setNeedsDisplayOnBoundsChange)
    layer.needsDisplayOnBoundsChange = needsDisplayOnBoundsChange;
  
  if (flags.setAllowsGroupOpacity)
    layer.allowsGroupOpacity = allowsGroupOpacity;

  if (flags.setAllowsEdgeAntialiasing)
    layer.allowsEdgeAntialiasing = allowsEdgeAntialiasing;

  if (flags.setEdgeAntialiasingMask)
    layer.edgeAntialiasingMask = edgeAntialiasingMask;

  if (flags.setAsyncTransactionContainer)
    view.asyncdisplaykit_asyncTransactionContainer = asyncTransactionContainer;

  if (flags.setOpaque)
    ASDisplayNodeAssert(layer.opaque == opaque, @"Didn't set opaque as desired");

  if (flags.setLayoutMargins)
    view.layoutMargins = layoutMargins;

  if (flags.setPreservesSuperviewLayoutMargins)
    view.preservesSuperviewLayoutMargins = preservesSuperviewLayoutMargins;

  if (AS_AVAILABLE_IOS(11.0)) {
    if (flags.setInsetsLayoutMarginsFromSafeArea) {
      view.insetsLayoutMarginsFromSafeArea = insetsLayoutMarginsFromSafeArea;
    }
  }

  if (flags.setSemanticContentAttribute) {
    view.semanticContentAttribute = semanticContentAttribute;
  }

  if (flags.setIsAccessibilityElement)
    view.isAccessibilityElement = isAccessibilityElement;

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
    view.accessibilityElementsHidden = accessibilityElementsHidden;

  if (flags.setAccessibilityViewIsModal)
    view.accessibilityViewIsModal = accessibilityViewIsModal;

  if (flags.setShouldGroupAccessibilityChildren)
    view.shouldGroupAccessibilityChildren = shouldGroupAccessibilityChildren;

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
+ (id<_ASPendingState>)pendingViewStateFromLayer:(CALayer *)layer
{
  if (!layer) {
    return nil;
  }
  _ASPendingStateInflated *pendingState = [[_ASPendingStateInflated alloc] init];
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
+ (id<_ASPendingState>)pendingViewStateFromView:(UIView *)view
{
  if (!view) {
    return nil;
  }
  _ASPendingStateInflated *pendingState = [[_ASPendingStateInflated alloc] init];

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

- (NSUInteger)cost
{
    ASPendingStateFlags flags = _flags;
    
    NSUInteger total = 0;
    total += flags.setAnchorPoint ? sizeof(self.anchorPoint) + sizeof(void *) : 0;
    total += flags.setPosition ? sizeof(self.position) + sizeof(void *) : 0;
    total += flags.setZPosition ? sizeof(self.zPosition) + sizeof(void *) : 0;
    total += flags.setFrame ? sizeof(self.frame) + sizeof(void *) : 0;
    total += flags.setBounds ? sizeof(self.bounds) + sizeof(void *) : 0;
    total += flags.setTransform ? sizeof(self.transform) + sizeof(void *) : 0;
    total += flags.setSublayerTransform ? sizeof(self.sublayerTransform) + sizeof(void *) : 0;
    total += flags.setContents ? sizeof(self.contents) + sizeof(void *) : 0;
    total += flags.setContentsGravity ? sizeof(self.contentsGravity) + sizeof(void *) : 0;
    total += flags.setContentsRect ? sizeof(self.contentsRect) + sizeof(void *) : 0;
    total += flags.setContentsCenter ? sizeof(self.contentsCenter) + sizeof(void *) : 0;
    total += flags.setContentsScale ? sizeof(self.contentsScale) + sizeof(void *) : 0;
    total += flags.setRasterizationScale ? sizeof(self.rasterizationScale) + sizeof(void *) : 0;
    total += flags.setClipsToBounds ? sizeof(self.clipsToBounds) + sizeof(void *) : 0;
    total += flags.setBackgroundColor ? sizeof(self.backgroundColor) + sizeof(void *) : 0;
    total += flags.setTintColor ? sizeof(self.tintColor) + sizeof(void *) : 0;
    total += flags.setHidden ? sizeof(self.hidden) + sizeof(void *) : 0;
    total += flags.setAlpha ? sizeof(self.alpha) + sizeof(void *) : 0;
    total += flags.setCornerRadius ? sizeof(self.cornerRadius) + sizeof(void *) : 0;
    total += flags.setContentMode ? sizeof(self.contentMode) + sizeof(void *) : 0;
    total += flags.setUserInteractionEnabled ? sizeof(self.userInteractionEnabled) + sizeof(void *) : 0;
    total += flags.setExclusiveTouch ? sizeof(self.exclusiveTouch) + sizeof(void *) : 0;
    total += flags.setShadowOpacity ? sizeof(self.shadowOpacity) + sizeof(void *) : 0;
    total += flags.setShadowOffset ? sizeof(self.shadowOffset) + sizeof(void *) : 0;
    total += flags.setShadowRadius ? sizeof(self.shadowRadius) + sizeof(void *) : 0;
    total += flags.setShadowColor ? sizeof(self.shadowColor) + sizeof(void *) : 0;
    total += flags.setBorderWidth ? sizeof(self.borderWidth) + sizeof(void *) : 0;
    total += flags.setBorderColor ? sizeof(self.borderColor) + sizeof(void *) : 0;
    total += flags.setAutoresizingMask ? sizeof(self.autoresizingMask) + sizeof(void *) : 0;
    total += flags.setAutoresizesSubviews ? sizeof(self.autoresizesSubviews) + sizeof(void *) : 0;
    total += flags.setNeedsDisplayOnBoundsChange ? sizeof(self.needsDisplayOnBoundsChange) + sizeof(void *) : 0;
    total += flags.setAllowsGroupOpacity ? sizeof(self.allowsGroupOpacity) + sizeof(void *) : 0;
    total += flags.setAllowsEdgeAntialiasing ? sizeof(self.allowsEdgeAntialiasing) + sizeof(void *) : 0;
    total += flags.setEdgeAntialiasingMask ? sizeof(self.edgeAntialiasingMask) + sizeof(void *) : 0;
    total += flags.needsDisplay ? sizeof(BOOL) + sizeof(void *) : 0;
    total += flags.needsLayout ? sizeof(BOOL) + sizeof(void *) : 0;
    total += flags.setAsyncTransactionContainer ? sizeof(self->asyncTransactionContainer) + sizeof(void *) : 0;
    total += flags.setOpaque ? sizeof(self.opaque) + sizeof(void *) : 0;
    total += flags.setSemanticContentAttribute ? sizeof(self.semanticContentAttribute) + sizeof(void *) : 0;
    total += flags.setLayoutMargins ? sizeof(self.layoutMargins) + sizeof(void *) : 0;
    total += flags.setPreservesSuperviewLayoutMargins ? sizeof(self.preservesSuperviewLayoutMargins) + sizeof(void *) : 0;
    total += flags.setInsetsLayoutMarginsFromSafeArea ? sizeof(self.insetsLayoutMarginsFromSafeArea) + sizeof(void *) : 0;
    total += flags.setIsAccessibilityElement ? sizeof(self.isAccessibilityElement) + sizeof(void *) : 0;
    total += flags.setAccessibilityLabel ? sizeof(self.accessibilityLabel) + sizeof(void *) : 0;
    total += flags.setAccessibilityAttributedLabel ? sizeof(self.accessibilityAttributedLabel) + sizeof(void *) : 0;
    total += flags.setAccessibilityHint ? sizeof(self.accessibilityHint) + sizeof(void *) : 0;
    total += flags.setAccessibilityAttributedHint ? sizeof(self.accessibilityAttributedHint) + sizeof(void *) : 0;
    total += flags.setAccessibilityValue ? sizeof(self.accessibilityValue) + sizeof(void *) : 0;
    total += flags.setAccessibilityAttributedValue ? sizeof(self.accessibilityAttributedValue) + sizeof(void *) : 0;
    total += flags.setAccessibilityTraits ? sizeof(self.accessibilityTraits) + sizeof(void *) : 0;
    total += flags.setAccessibilityFrame ? sizeof(self.accessibilityFrame) + sizeof(void *) : 0;
    total += flags.setAccessibilityLanguage ? sizeof(self.accessibilityLanguage) + sizeof(void *) : 0;
    total += flags.setAccessibilityElementsHidden ? sizeof(self.accessibilityElementsHidden) + sizeof(void *) : 0;
    total += flags.setAccessibilityViewIsModal ? sizeof(self.accessibilityViewIsModal) + sizeof(void *) : 0;
    total += flags.setShouldGroupAccessibilityChildren ? sizeof(self.shouldGroupAccessibilityChildren) + sizeof(void *) : 0;
    total += flags.setAccessibilityIdentifier ? sizeof(self.accessibilityIdentifier) + sizeof(void *) : 0;
    total += flags.setAccessibilityNavigationStyle ? sizeof(self.accessibilityNavigationStyle) + sizeof(void *) : 0;
    total += flags.setAccessibilityHeaderElements ? sizeof(self->accessibilityHeaderElements) + sizeof(void *) : 0;
    total += flags.setAccessibilityActivationPoint ? sizeof(self.accessibilityActivationPoint) + sizeof(void *) : 0;
    total += flags.setAccessibilityPath ? sizeof(self.accessibilityPath) + sizeof(void *) : 0;
    
    return total;
}

@end

typedef NS_ENUM(NSUInteger, ASPendingStateType) {
  ASPendingStateTypeNone = 0,
  ASPendingStateTypeAnchorPoint,
  ASPendingStateTypePosition,
  ASPendingStateTypeZPosition,
  ASPendingStateTypeFrame,
  ASPendingStateTypeBounds,
  ASPendingStateTypeTransform,
  ASPendingStateTypeSublayerTransform,
  ASPendingStateTypeContents,
  ASPendingStateTypeContentsGravity,
  ASPendingStateTypeContentsRect,
  ASPendingStateTypeContentsCenter,
  ASPendingStateTypeContentsScale,
  ASPendingStateTypeRasterizationScale,
  ASPendingStateTypeClipsToBounds,
  ASPendingStateTypeBackgroundColor,
  ASPendingStateTypeTintColor,
  ASPendingStateTypeHidden,
  ASPendingStateTypeAlpha,
  ASPendingStateTypeCornerRadius,
  ASPendingStateTypeContentMode,
  ASPendingStateTypeUserInteractionEnabled,
  ASPendingStateTypeExclusiveTouch,
  ASPendingStateTypeShadowOpacity,
  ASPendingStateTypeShadowOffset,
  ASPendingStateTypeShadowRadius,
  ASPendingStateTypeShadowColor,
  ASPendingStateTypeBorderWidth,
  ASPendingStateTypeBorderColor,
  ASPendingStateTypeAutoresizingMask,
  ASPendingStateTypeAutoresizesSubviews,
  ASPendingStateTypeNeedsDisplayOnBoundsChange,
  ASPendingStateTypeAllowsGroupOpacity,
  ASPendingStateTypeAllowsEdgeAntialiasing,
  ASPendingStateTypeEdgeAntialiasingMask,
  ASPendingStateTypeNeedsDisplay,
  ASPendingStateTypeLayoutIfNeeded,
  ASPendingStateTypeNeedsLayout,
  ASPendingStateTypeAsyncTransactionContainer,
  ASPendingStateTypeOpaque,
  ASPendingStateTypeSemanticContentAttribute,
  ASPendingStateTypeLayoutMargins,
  ASPendingStateTypePreservesSuperviewLayoutMargins,
  ASPendingStateTypeInsetsLayoutMarginsFromSafeArea,
  ASPendingStateTypeIsAccessibilityElement,
  ASPendingStateTypeAccessibilityLabel,
  ASPendingStateTypeAccessibilityAttributedLabel,
  ASPendingStateTypeAccessibilityHint,
  ASPendingStateTypeAccessibilityAttributedHint,
  ASPendingStateTypeAccessibilityValue,
  ASPendingStateTypeAccessibilityAttributedValue,
  ASPendingStateTypeAccessibilityTraits,
  ASPendingStateTypeAccessibilityFrame,
  ASPendingStateTypeAccessibilityLanguage,
  ASPendingStateTypeAccessibilityElementsHidden,
  ASPendingStateTypeAccessibilityViewIsModal,
  ASPendingStateTypeShouldGroupAccessibilityChildren,
  ASPendingStateTypeAccessibilityIdentifier,
  ASPendingStateTypeAccessibilityNavigationStyle,
  ASPendingStateTypeAccessibilityHeaderElements,
  ASPendingStateTypeAccessibilityActivationPoint,
  ASPendingStateTypeAccessibilityPath,
};

@interface _ASPendingStateCompressedNode : NSObject
{
    @package
    ASPendingStateType _pendingStateType;
}
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithPendingStateType:(ASPendingStateType)pendingStateType NS_DESIGNATED_INITIALIZER;
@end

@implementation _ASPendingStateCompressedNode

- (instancetype)initWithPendingStateType:(ASPendingStateType)pendingStateType
{
  if (self = [super init]) {
    _pendingStateType = pendingStateType;
  }
  return self;
}

- (ASPendingStateType)pendingStateType
{
    return _pendingStateType;
}

@end

#define TYPE_NODE_INTERFACE_AND_IMP_UPPER(type, Type, typeName) \
@interface _ASPendingStateCompressedNode##Type: _ASPendingStateCompressedNode { \
@package \
  type _##typeName; \
} \
\
@end \
\
@implementation _ASPendingStateCompressedNode##Type \
\
- (instancetype)initWithPendingStateType:(ASPendingStateType)pendingStateType typeName:(type)new##typeName { \
  if (self = [super initWithPendingStateType:pendingStateType]) { \
    _##typeName = new##typeName; \
  } \
  return self; \
} \
\
@end \

#define TYPE_NODE_INTERFACE_AND_IMP(type, typeName) \
TYPE_NODE_INTERFACE_AND_IMP_UPPER(type, type, typeName)

TYPE_NODE_INTERFACE_AND_IMP_UPPER(id, Object, object)
TYPE_NODE_INTERFACE_AND_IMP_UPPER(unsigned int, UInt, uInt)
TYPE_NODE_INTERFACE_AND_IMP(UIViewContentMode, uiViewContentMode)
TYPE_NODE_INTERFACE_AND_IMP(BOOL, bool)
TYPE_NODE_INTERFACE_AND_IMP(CGFloat, cgFloat)
TYPE_NODE_INTERFACE_AND_IMP(CGSize, cgSize)
TYPE_NODE_INTERFACE_AND_IMP(CGPoint, cgPoint)
TYPE_NODE_INTERFACE_AND_IMP(CGRect, cgRect)
TYPE_NODE_INTERFACE_AND_IMP(UIViewAutoresizing, uiViewAutoresizing)
TYPE_NODE_INTERFACE_AND_IMP(CATransform3D, caTransform3D)
TYPE_NODE_INTERFACE_AND_IMP(UIAccessibilityTraits, uiAccessibilityTraits)
TYPE_NODE_INTERFACE_AND_IMP(UIAccessibilityNavigationStyle, uiAccessibilityNavigationStyle)
TYPE_NODE_INTERFACE_AND_IMP(UISemanticContentAttribute, uiSemanticContentAttribute)
TYPE_NODE_INTERFACE_AND_IMP(UIEdgeInsets, uiEdgeInsets)

@interface _ASPendingStateCompressed () {
  std::forward_list<_ASPendingStateCompressedNode *> _list;
}
@end

@implementation _ASPendingStateCompressed

- (_ASPendingStateCompressedNode *)nodeOfPendingStateType:(ASPendingStateType)pendingStateType
{
    for (auto node = _list.begin(); node != _list.end(); ++node) {
        if ((*node)->_pendingStateType == pendingStateType) {
            return *node;
        }
    }
    return nil;
}

- (_ASPendingStateInflated *)defaultState
{
    static dispatch_once_t onceToken;
    static _ASPendingStateInflated *defaultState;
    dispatch_once(&onceToken, ^{
        defaultState = [[_ASPendingStateInflated alloc] init];
    });
    return defaultState;
}

- (BOOL)hasChanges
{
    return !_list.empty();
}

- (_ASPendingStateInflated *)inflatedPendingState
{
  _ASPendingStateInflated *inflated = [[_ASPendingStateInflated alloc] init];
  
  // Since this is a forward list we need to keep track of which elements we've set and skip any we already have. This will allow the latest
  for (auto node = _list.begin(); node != _list.end(); ++node) {
    _ASPendingStateCompressedNode *compressedNode = *node;
    switch(compressedNode->_pendingStateType) {
      case ASPendingStateTypeAnchorPoint:
        if (inflated->_flags.setAnchorPoint) continue;
        [inflated setAnchorPoint:((_ASPendingStateCompressedNodeCGPoint *)compressedNode)->_cgPoint];
        break;
      case ASPendingStateTypePosition:
        if (inflated->_flags.setPosition) continue;
        [inflated setPosition:((_ASPendingStateCompressedNodeCGPoint *)compressedNode)->_cgPoint];
        break;
      case ASPendingStateTypeZPosition:
        if (inflated->_flags.setZPosition) continue;
        [inflated setZPosition:((_ASPendingStateCompressedNodeCGFloat *)compressedNode)->_cgFloat];
        break;
      case ASPendingStateTypeFrame:
        if (inflated->_flags.setFrame) continue;
        [inflated setFrame:((_ASPendingStateCompressedNodeCGRect *)compressedNode)->_cgRect];
        break;
      case ASPendingStateTypeBounds:
        if (inflated->_flags.setBounds) continue;
        [inflated setBounds:((_ASPendingStateCompressedNodeCGRect *)compressedNode)->_cgRect];
        break;
      case ASPendingStateTypeTransform:
        if (inflated->_flags.setTransform) continue;
        [inflated setTransform:((_ASPendingStateCompressedNodeCATransform3D *)compressedNode)->_caTransform3D];
        break;
      case ASPendingStateTypeSublayerTransform:
        if (inflated->_flags.setSublayerTransform) continue;
        [inflated setSublayerTransform:((_ASPendingStateCompressedNodeCATransform3D *)compressedNode)->_caTransform3D];
        break;
      case ASPendingStateTypeContents:
        if (inflated->_flags.setContents) continue;
        [inflated setContents:((_ASPendingStateCompressedNodeObject *)compressedNode)->_object];
        break;
      case ASPendingStateTypeContentsGravity:
        if (inflated->_flags.setContentsGravity) continue;
        [inflated setContentsGravity:((_ASPendingStateCompressedNodeObject *)compressedNode)->_object];
        break;
      case ASPendingStateTypeContentsRect:
        if (inflated->_flags.setContentsRect) continue;
        [inflated setContentsRect:((_ASPendingStateCompressedNodeCGRect *)compressedNode)->_cgRect];
        break;
      case ASPendingStateTypeContentsCenter:
        if (inflated->_flags.setContentsCenter) continue;
        [inflated setContentsCenter:((_ASPendingStateCompressedNodeCGRect *)compressedNode)->_cgRect];
        break;
      case ASPendingStateTypeContentsScale:
        if (inflated->_flags.setContentsScale) continue;
        [inflated setContentsScale:((_ASPendingStateCompressedNodeCGFloat *)compressedNode)->_cgFloat];
        break;
      case ASPendingStateTypeRasterizationScale:
        if (inflated->_flags.setRasterizationScale) continue;
        [inflated setRasterizationScale:((_ASPendingStateCompressedNodeCGFloat *)compressedNode)->_cgFloat];
        break;
      case ASPendingStateTypeClipsToBounds:
        if (inflated->_flags.setClipsToBounds) continue;
        [inflated setClipsToBounds:((_ASPendingStateCompressedNodeBOOL *)compressedNode)->_bool];
        break;
      case ASPendingStateTypeBackgroundColor:
        if (inflated->_flags.setBackgroundColor) continue;
        [inflated setBackgroundColor:(__bridge CGColorRef)((_ASPendingStateCompressedNodeObject *)compressedNode)->_object];
        break;
      case ASPendingStateTypeTintColor:
        if (inflated->_flags.setTintColor) continue;
        [inflated setTintColor:((_ASPendingStateCompressedNodeObject *)compressedNode)->_object];
        break;
      case ASPendingStateTypeHidden:
        if (inflated->_flags.setHidden) continue;
        [inflated setHidden:((_ASPendingStateCompressedNodeBOOL *)compressedNode)->_bool];
        break;
      case ASPendingStateTypeAlpha:
        if (inflated->_flags.setAlpha) continue;
        [inflated setAlpha:((_ASPendingStateCompressedNodeCGFloat *)compressedNode)->_cgFloat];
        break;
      case ASPendingStateTypeCornerRadius:
        if (inflated->_flags.setCornerRadius) continue;
        [inflated setCornerRadius:((_ASPendingStateCompressedNodeCGFloat *)compressedNode)->_cgFloat];
        break;
      case ASPendingStateTypeContentMode:
        if (inflated->_flags.setContentMode) continue;
        [inflated setContentMode:((_ASPendingStateCompressedNodeUIViewContentMode *)compressedNode)->_uiViewContentMode];
        break;
      case ASPendingStateTypeUserInteractionEnabled:
        if (inflated->_flags.setUserInteractionEnabled) continue;
        [inflated setUserInteractionEnabled:((_ASPendingStateCompressedNodeBOOL *)compressedNode)->_bool];
        break;
      case ASPendingStateTypeExclusiveTouch:
        if (inflated->_flags.setExclusiveTouch) continue;
        [inflated setExclusiveTouch:((_ASPendingStateCompressedNodeBOOL *)compressedNode)->_bool];
        break;
      case ASPendingStateTypeShadowOpacity:
        if (inflated->_flags.setShadowOpacity) continue;
        [inflated setShadowOpacity:((_ASPendingStateCompressedNodeCGFloat *)compressedNode)->_cgFloat];
        break;
      case ASPendingStateTypeShadowOffset:
        if (inflated->_flags.setShadowOffset) continue;
        [inflated setShadowOpacity:((_ASPendingStateCompressedNodeCGFloat *)compressedNode)->_cgFloat];
        break;
      case ASPendingStateTypeShadowRadius:
        if (inflated->_flags.setShadowRadius) continue;
        [inflated setShadowRadius:((_ASPendingStateCompressedNodeCGFloat *)compressedNode)->_cgFloat];
        break;
      case ASPendingStateTypeShadowColor:
        if (inflated->_flags.setShadowColor) continue;
        [inflated setShadowColor:(__bridge CGColorRef)((_ASPendingStateCompressedNodeObject *)compressedNode)->_object];
        break;
      case ASPendingStateTypeBorderWidth:
        if (inflated->_flags.setBorderWidth) continue;
        [inflated setBorderWidth:((_ASPendingStateCompressedNodeCGFloat *)compressedNode)->_cgFloat];
        break;
      case ASPendingStateTypeBorderColor:
        if (inflated->_flags.setBorderColor) continue;
        [inflated setBorderColor:(__bridge CGColorRef)((_ASPendingStateCompressedNodeObject *)compressedNode)->_object];
        break;
      case ASPendingStateTypeAutoresizingMask:
        if (inflated->_flags.setAutoresizingMask) continue;
        [inflated setAutoresizingMask:((_ASPendingStateCompressedNodeUIViewAutoresizing *)compressedNode)->_uiViewAutoresizing];
        break;
      case ASPendingStateTypeAutoresizesSubviews:
        if (inflated->_flags.setAutoresizesSubviews) continue;
        [inflated setAutoresizesSubviews:((_ASPendingStateCompressedNodeBOOL *)compressedNode)->_bool];
        break;
      case ASPendingStateTypeNeedsDisplayOnBoundsChange:
        if (inflated->_flags.setNeedsDisplayOnBoundsChange) continue;
        [inflated setNeedsDisplayOnBoundsChange:((_ASPendingStateCompressedNodeBOOL *)compressedNode)->_bool];
        break;
      case ASPendingStateTypeAllowsGroupOpacity:
        if (inflated->_flags.setAllowsGroupOpacity) continue;
        [inflated setAllowsGroupOpacity:((_ASPendingStateCompressedNodeBOOL *)compressedNode)->_bool];
        break;
      case ASPendingStateTypeAllowsEdgeAntialiasing:
        if (inflated->_flags.setAllowsEdgeAntialiasing) continue;
        [inflated setAllowsEdgeAntialiasing:((_ASPendingStateCompressedNodeBOOL *)compressedNode)->_bool];
        break;
      case ASPendingStateTypeEdgeAntialiasingMask:
        if (inflated->_flags.setEdgeAntialiasingMask) continue;
        [inflated setEdgeAntialiasingMask:((_ASPendingStateCompressedNodeUInt *)compressedNode)->_uInt];
        break;
      case ASPendingStateTypeNeedsDisplay:
        [inflated setNeedsDisplay];
        break;
      case ASPendingStateTypeNeedsLayout:
        [inflated setNeedsLayout];
        break;
      case ASPendingStateTypeLayoutIfNeeded:
        [inflated layoutIfNeeded];
        break;
      case ASPendingStateTypeAsyncTransactionContainer:
        if (inflated->_flags.setAsyncTransactionContainer) continue;
        [inflated asyncdisplaykit_setAsyncTransactionContainer:((_ASPendingStateCompressedNodeBOOL *)compressedNode)->_bool];
        break;
      case ASPendingStateTypeOpaque:
        if (inflated->_flags.setOpaque) continue;
        [inflated setOpaque:((_ASPendingStateCompressedNodeBOOL *)compressedNode)->_bool];
        break;
      case ASPendingStateTypeSemanticContentAttribute:
        if (inflated->_flags.setSemanticContentAttribute) continue;
        [inflated setSemanticContentAttribute:((_ASPendingStateCompressedNodeUISemanticContentAttribute *)compressedNode)->_uiSemanticContentAttribute];
        break;
      case ASPendingStateTypeLayoutMargins:
        if (inflated->_flags.setLayoutMargins) continue;
        [inflated setLayoutMargins:((_ASPendingStateCompressedNodeUIEdgeInsets *)compressedNode)->_uiEdgeInsets];
        break;
      case ASPendingStateTypePreservesSuperviewLayoutMargins:
        if (inflated->_flags.setPreservesSuperviewLayoutMargins) continue;
        [inflated setPreservesSuperviewLayoutMargins:((_ASPendingStateCompressedNodeBOOL *)compressedNode)->_bool];
        break;
      case ASPendingStateTypeInsetsLayoutMarginsFromSafeArea:
        if (inflated->_flags.setInsetsLayoutMarginsFromSafeArea) continue;
        [inflated setInsetsLayoutMarginsFromSafeArea:((_ASPendingStateCompressedNodeBOOL *)compressedNode)->_bool];
        break;
      case ASPendingStateTypeIsAccessibilityElement:
        if (inflated->_flags.setIsAccessibilityElement) continue;
        [inflated setIsAccessibilityElement:((_ASPendingStateCompressedNodeBOOL *)compressedNode)->_bool];
        break;
      case ASPendingStateTypeAccessibilityLabel:
        if (inflated->_flags.setAccessibilityLabel) continue;
        [inflated setAccessibilityLabel:((_ASPendingStateCompressedNodeObject *)compressedNode)->_object];
        break;
      case ASPendingStateTypeAccessibilityAttributedLabel:
        if (inflated->_flags.setAccessibilityAttributedLabel) continue;
        [inflated setAccessibilityAttributedLabel:((_ASPendingStateCompressedNodeObject *)compressedNode)->_object];
        break;
      case ASPendingStateTypeAccessibilityHint:
        if (inflated->_flags.setAccessibilityHint) continue;
        [inflated setAccessibilityHint:((_ASPendingStateCompressedNodeObject *)compressedNode)->_object];
        break;
      case ASPendingStateTypeAccessibilityAttributedHint:
        if (inflated->_flags.setAccessibilityAttributedHint) continue;
        [inflated setAccessibilityAttributedHint:((_ASPendingStateCompressedNodeObject *)compressedNode)->_object];
        break;
      case ASPendingStateTypeAccessibilityValue:
        if (inflated->_flags.setAccessibilityValue) continue;
        [inflated setAccessibilityValue:((_ASPendingStateCompressedNodeObject *)compressedNode)->_object];
        break;
      case ASPendingStateTypeAccessibilityAttributedValue:
        if (inflated->_flags.setAccessibilityAttributedValue) continue;
        [inflated setAccessibilityAttributedValue:((_ASPendingStateCompressedNodeObject *)compressedNode)->_object];
        break;
      case ASPendingStateTypeAccessibilityTraits:
        if (inflated->_flags.setAccessibilityTraits) continue;
        [inflated setAccessibilityTraits:((_ASPendingStateCompressedNodeUIAccessibilityTraits *)compressedNode)->_uiAccessibilityTraits];
        break;
      case ASPendingStateTypeAccessibilityFrame:
        if (inflated->_flags.setAccessibilityFrame) continue;
        [inflated setAccessibilityFrame:((_ASPendingStateCompressedNodeCGRect *)compressedNode)->_cgRect];
        break;
      case ASPendingStateTypeAccessibilityLanguage:
        if (inflated->_flags.setAccessibilityLanguage) continue;
        [inflated setAccessibilityLanguage:((_ASPendingStateCompressedNodeObject *)compressedNode)->_object];
        break;
      case ASPendingStateTypeAccessibilityElementsHidden:
        if (inflated->_flags.setAccessibilityElementsHidden) continue;
        [inflated setAccessibilityElementsHidden:((_ASPendingStateCompressedNodeBOOL *)compressedNode)->_bool];
        break;
      case ASPendingStateTypeAccessibilityViewIsModal:
        if (inflated->_flags.setAccessibilityViewIsModal) continue;
        [inflated setAccessibilityViewIsModal:((_ASPendingStateCompressedNodeBOOL *)compressedNode)->_bool];
        break;
      case ASPendingStateTypeShouldGroupAccessibilityChildren:
        if (inflated->_flags.setShouldGroupAccessibilityChildren) continue;
        [inflated setShouldGroupAccessibilityChildren:((_ASPendingStateCompressedNodeBOOL *)compressedNode)->_bool];
        break;
      case ASPendingStateTypeAccessibilityIdentifier:
        if (inflated->_flags.setAccessibilityIdentifier) continue;
        [inflated setAccessibilityIdentifier:((_ASPendingStateCompressedNodeObject *)compressedNode)->_object];
        break;
      case ASPendingStateTypeAccessibilityNavigationStyle:
        if (inflated->_flags.setAccessibilityNavigationStyle) continue;
        [inflated setAccessibilityNavigationStyle:((_ASPendingStateCompressedNodeUIAccessibilityNavigationStyle *)compressedNode)->_uiAccessibilityNavigationStyle];
        break;
      case ASPendingStateTypeAccessibilityHeaderElements:
        if (inflated->_flags.setAccessibilityHeaderElements) continue;
        [inflated setAccessibilityElementsHidden:((_ASPendingStateCompressedNodeBOOL *)compressedNode)->_bool];
        break;
      case ASPendingStateTypeAccessibilityActivationPoint:
        if (inflated->_flags.setAccessibilityActivationPoint) continue;
        [inflated setAccessibilityActivationPoint:((_ASPendingStateCompressedNodeCGPoint *)compressedNode)->_cgPoint];
        break;
      case ASPendingStateTypeAccessibilityPath:
        if (inflated->_flags.setAccessibilityPath) continue;
        [inflated setAccessibilityPath:((_ASPendingStateCompressedNodeObject *)compressedNode)->_object];
        break;
      default:
        ASDisplayNodeAssert(YES, @"unhandled pending node state type");
        break;
        
    }
  }
  return inflated;
}

- (void)applyToView:(UIView *)view withSpecialPropertiesHandling:(BOOL)specialPropertiesHandling
{
  [[self inflatedPendingState] applyToView:view withSpecialPropertiesHandling:specialPropertiesHandling];
}

- (void)applyToLayer:(CALayer *)layer
{
  [[self inflatedPendingState] applyToLayer:layer];
}

- (void)clearChanges
{
  _list.clear();
}

+ (NSObject<_ASPendingState> *)pendingViewStateFromLayer:(CALayer *)layer
{
  return [_ASPendingStateInflated pendingViewStateFromLayer:layer];
}


+ (NSObject<_ASPendingState> *)pendingViewStateFromView:(UIView *)view
{
  return [_ASPendingStateInflated pendingViewStateFromView:view];
}


#define SET_PENDING_STATE_GENERAL_BRIDGED(property, pendingStateType, var, nodeType, name, bridged) \
- (void)set##property:(var)property \
{ \
_list.push_front([[_ASPendingStateCompressedNode##nodeType alloc] initWithPendingStateType:pendingStateType name:bridged(property)]); \
} \

#define SET_PENDING_STATE_GENERAL(property, pendingStateType, var, name) \
SET_PENDING_STATE_GENERAL_BRIDGED(property, pendingStateType, var, var, name, ) \

#define GET_PENDING_STATE_GENERAL_BRIDGED(property, pendingStateType, var, nodeType, name, bridged) \
- (var)property \
{ \
if (_ASPendingStateCompressedNode##nodeType *node = (_ASPendingStateCompressedNode##nodeType *)[self nodeOfPendingStateType:pendingStateType]) { \
return bridged(node->_##name); \
} \
return [self defaultState].property; \
} \

#define GET_PENDING_STATE_GENERAL(property, pendingStateType, var, name) \
GET_PENDING_STATE_GENERAL_BRIDGED(property, pendingStateType, var, var, name, ) \

#define GET_AND_SET_PENDING_STATE_CONTENT_MODE(lower, upper, pendingStateType) \
SET_PENDING_STATE_GENERAL(upper, pendingStateType, UIViewContentMode, uiViewContentMode) \
GET_PENDING_STATE_GENERAL(lower, pendingStateType, UIViewContentMode, uiViewContentMode) \

#define GET_AND_SET_PENDING_STATE_FLOAT(lower, upper, pendingStateType) \
SET_PENDING_STATE_GENERAL(upper, pendingStateType, CGFloat, cgFloat) \
GET_PENDING_STATE_GENERAL(lower, pendingStateType, CGFloat, cgFloat) \

#define GET_AND_SET_PENDING_STATE_POINT(lower, upper, pendingStateType) \
SET_PENDING_STATE_GENERAL(upper, pendingStateType, CGPoint, cgPoint) \
GET_PENDING_STATE_GENERAL(lower, pendingStateType, CGPoint, cgPoint) \

#define GET_AND_SET_PENDING_STATE_SIZE(lower, upper, pendingStateType) \
SET_PENDING_STATE_GENERAL(upper, pendingStateType, CGSize, cgSize) \
GET_PENDING_STATE_GENERAL(lower, pendingStateType, CGSize, cgSize) \

#define GET_AND_SET_PENDING_STATE_RECT(lower, upper, pendingStateType) \
SET_PENDING_STATE_GENERAL(upper, pendingStateType, CGRect, cgRect) \
GET_PENDING_STATE_GENERAL(lower, pendingStateType, CGRect, cgRect) \

#define GET_AND_SET_PENDING_STATE_BOOL(lower, upper, pendingStateType) \
SET_PENDING_STATE_GENERAL(upper, pendingStateType, BOOL, bool) \
GET_PENDING_STATE_GENERAL(lower, pendingStateType, BOOL, bool) \

#define GET_AND_SET_PENDING_STATE_TRANSFORM_3D(lower, upper, pendingStateType) \
SET_PENDING_STATE_GENERAL(upper, pendingStateType, CATransform3D, caTransform3D) \
GET_PENDING_STATE_GENERAL(lower, pendingStateType, CATransform3D, caTransform3D) \

#define GET_AND_SET_PENDING_STATE_ACCESSIBILITY_TRAITS(lower, upper, pendingStateType) \
SET_PENDING_STATE_GENERAL(upper, pendingStateType, UIAccessibilityTraits, uiAccessibilityTraits) \
GET_PENDING_STATE_GENERAL(lower, pendingStateType, UIAccessibilityTraits, uiAccessibilityTraits) \

#define GET_AND_SET_PENDING_STATE_ACCESSIBILITY_NAVIGATION_STYLE(lower, upper, pendingStateType) \
SET_PENDING_STATE_GENERAL(upper, pendingStateType, UIAccessibilityNavigationStyle, uiAccessibilityNavigationStyle) \
GET_PENDING_STATE_GENERAL(lower, pendingStateType, UIAccessibilityNavigationStyle, uiAccessibilityNavigationStyle) \

#define GET_AND_SET_PENDING_STATE_AUTORESIZING(lower, upper, pendingStateType) \
SET_PENDING_STATE_GENERAL(upper, pendingStateType, UIViewAutoresizing, uiViewAutoresizing) \
GET_PENDING_STATE_GENERAL(lower, pendingStateType, UIViewAutoresizing, uiViewAutoresizing) \

#define GET_AND_SET_PENDING_STATE_UINT(lower, upper, pendingStateType) \
SET_PENDING_STATE_GENERAL_BRIDGED(upper, pendingStateType, unsigned int, UInt, uInt, ) \
GET_PENDING_STATE_GENERAL_BRIDGED(lower, pendingStateType, unsigned int, UInt, uInt, ) \

#define GET_AND_SET_PENDING_STATE_SEMANTIC_CONTENT_ATTRIBUTE(lower, upper, pendingStateType) \
SET_PENDING_STATE_GENERAL(upper, pendingStateType, UISemanticContentAttribute, uiSemanticContentAttribute) \
GET_PENDING_STATE_GENERAL(lower, pendingStateType, UISemanticContentAttribute, uiSemanticContentAttribute) \

#define GET_AND_SET_PENDING_STATE_EDGE_INSETS(lower, upper, pendingStateType) \
SET_PENDING_STATE_GENERAL(upper, pendingStateType, UIEdgeInsets, uiEdgeInsets) \
GET_PENDING_STATE_GENERAL(lower, pendingStateType, UIEdgeInsets, uiEdgeInsets) \

#define GET_AND_SET_PENDING_STATE_OBJECT(lower, upper, pendingStateType, refType) \
SET_PENDING_STATE_GENERAL_BRIDGED(upper, pendingStateType, refType, Object, object, ) \
GET_PENDING_STATE_GENERAL_BRIDGED(lower, pendingStateType, refType, Object, object, ) \

#define GET_AND_SET_PENDING_STATE_BRIDGED_OBJECT(lower, upper, pendingStateType, refType) \
SET_PENDING_STATE_GENERAL_BRIDGED(upper, pendingStateType, refType, Object, object, (__bridge id)) \
GET_PENDING_STATE_GENERAL_BRIDGED(lower, pendingStateType, refType, Object, object, (__bridge refType)) \

GET_AND_SET_PENDING_STATE_POINT(anchorPoint, AnchorPoint, ASPendingStateTypeAnchorPoint)
GET_AND_SET_PENDING_STATE_POINT(position, Position, ASPendingStateTypePosition)
GET_AND_SET_PENDING_STATE_FLOAT(zPosition, ZPosition, ASPendingStateTypeZPosition)
GET_AND_SET_PENDING_STATE_RECT(frame, Frame, ASPendingStateTypeFrame)

GET_PENDING_STATE_GENERAL(bounds, ASPendingStateTypeBounds, CGRect, cgRect)
- (void)setBounds:(CGRect)bounds
{
  validate_bounds(bounds);
  _list.push_front([[_ASPendingStateCompressedNodeCGRect alloc] initWithPendingStateType:ASPendingStateTypeBounds cgRect:bounds]);
}

GET_AND_SET_PENDING_STATE_TRANSFORM_3D(transform, Transform, ASPendingStateTypeTransform)
GET_AND_SET_PENDING_STATE_TRANSFORM_3D(sublayerTransform, SublayerTransform, ASPendingStateTypeSublayerTransform)

GET_PENDING_STATE_GENERAL_BRIDGED(contents, ASPendingStateTypeContents, id, Object, object, )
bool isContentsNode(_ASPendingStateCompressedNode *node) {
  return node->_pendingStateType == ASPendingStateTypeContents;
}
// The thinking is it's worth iterating over the list to clear out any contents objects because they are likely large.
- (void)setContents:(id)contents
{
  _list.remove_if(isContentsNode);
  _list.push_front([[_ASPendingStateCompressedNodeObject alloc] initWithPendingStateType:ASPendingStateTypeContents object:contents]);
}
GET_AND_SET_PENDING_STATE_OBJECT(contentsGravity, ContentsGravity, ASPendingStateTypeContentsGravity, NSString *)
GET_AND_SET_PENDING_STATE_RECT(contentsRect, ContentsRect, ASPendingStateTypeContentsRect)
GET_AND_SET_PENDING_STATE_RECT(contentsCenter, ContentsCenter, ASPendingStateTypeContentsCenter)
GET_AND_SET_PENDING_STATE_FLOAT(contentsScale, ContentsScale, ASPendingStateTypeContentsScale)
GET_AND_SET_PENDING_STATE_FLOAT(rasterizationScale, RasterizationScale, ASPendingStateTypeRasterizationScale)
GET_AND_SET_PENDING_STATE_BOOL(clipsToBounds, ClipsToBounds, ASPendingStateTypeClipsToBounds)
GET_AND_SET_PENDING_STATE_BRIDGED_OBJECT(backgroundColor, BackgroundColor, ASPendingStateTypeBackgroundColor, CGColorRef)
GET_AND_SET_PENDING_STATE_OBJECT(tintColor, TintColor, ASPendingStateTypeTintColor, UIColor *)
GET_AND_SET_PENDING_STATE_BOOL(isHidden, Hidden, ASPendingStateTypeHidden)
GET_AND_SET_PENDING_STATE_FLOAT(alpha, Alpha, ASPendingStateTypeAlpha)
GET_AND_SET_PENDING_STATE_FLOAT(cornerRadius, CornerRadius, ASPendingStateTypeCornerRadius)
GET_AND_SET_PENDING_STATE_CONTENT_MODE(contentMode, ContentMode, ASPendingStateTypeContentMode)
GET_AND_SET_PENDING_STATE_BOOL(isUserInteractionEnabled, UserInteractionEnabled, ASPendingStateTypeUserInteractionEnabled)
GET_AND_SET_PENDING_STATE_BOOL(isExclusiveTouch, ExclusiveTouch, ASPendingStateTypeExclusiveTouch)
GET_AND_SET_PENDING_STATE_FLOAT(shadowOpacity, ShadowOpacity, ASPendingStateTypeShadowOpacity)
GET_AND_SET_PENDING_STATE_SIZE(shadowOffset, ShadowOffset, ASPendingStateTypeShadowOffset)
GET_AND_SET_PENDING_STATE_FLOAT(shadowRadius, ShadowRadius, ASPendingStateTypeShadowRadius)
GET_AND_SET_PENDING_STATE_BRIDGED_OBJECT(shadowColor, ShadowColor, ASPendingStateTypeShadowColor, CGColorRef)
GET_AND_SET_PENDING_STATE_FLOAT(borderWidth, BorderWidth, ASPendingStateTypeBorderWidth)
GET_AND_SET_PENDING_STATE_BRIDGED_OBJECT(borderColor, BorderColor, ASPendingStateTypeBorderColor, CGColorRef)
GET_AND_SET_PENDING_STATE_AUTORESIZING(autoresizingMask, AutoresizingMask, ASPendingStateTypeAutoresizingMask)
GET_AND_SET_PENDING_STATE_BOOL(autoresizesSubviews, AutoresizesSubviews, ASPendingStateTypeAutoresizesSubviews)
GET_AND_SET_PENDING_STATE_BOOL(needsDisplayOnBoundsChange, NeedsDisplayOnBoundsChange, ASPendingStateTypeNeedsDisplayOnBoundsChange)
GET_AND_SET_PENDING_STATE_BOOL(allowsGroupOpacity, AllowsGroupOpacity, ASPendingStateTypeAllowsGroupOpacity)
GET_AND_SET_PENDING_STATE_BOOL(allowsEdgeAntialiasing, AllowsEdgeAntialiasing, ASPendingStateTypeAllowsEdgeAntialiasing)
GET_AND_SET_PENDING_STATE_UINT(edgeAntialiasingMask, EdgeAntialiasingMask, ASPendingStateTypeEdgeAntialiasingMask)

- (BOOL)hasSetNeedsDisplay
{
  if (_ASPendingStateCompressedNode *node = [self nodeOfPendingStateType:ASPendingStateTypeNeedsDisplay]) {
    return YES;
  }
  return NO;
}

- (void)setNeedsDisplay
{
  _list.push_front([[_ASPendingStateCompressedNode alloc] initWithPendingStateType:ASPendingStateTypeNeedsDisplay]);
}

- (BOOL)hasSetNeedsLayout
{
  if (_ASPendingStateCompressedNode *node = [self nodeOfPendingStateType:ASPendingStateTypeNeedsLayout]) {
    return YES;
  }
  return NO;
}

- (void)setNeedsLayout
{
  _list.push_front([[_ASPendingStateCompressedNode alloc] initWithPendingStateType:ASPendingStateTypeNeedsLayout]);
}

- (void)layoutIfNeeded
{
  _list.push_front([[_ASPendingStateCompressedNode alloc] initWithPendingStateType:ASPendingStateTypeLayoutIfNeeded]);
}

- (BOOL)hasLayoutIfNeeded
{
  if (_ASPendingStateCompressedNode *node = [self nodeOfPendingStateType:ASPendingStateTypeLayoutIfNeeded]) {
    return YES;
  }
  return NO;
}


GET_PENDING_STATE_GENERAL_BRIDGED(asyncdisplaykit_isAsyncTransactionContainer, ASPendingStateTypeAsyncTransactionContainer, BOOL, BOOL, bool, )
- (void)asyncdisplaykit_setAsyncTransactionContainer:(BOOL)asyncdisplaykit_asyncTransactionContainer
{
  _list.push_front([[_ASPendingStateCompressedNodeBOOL alloc] initWithPendingStateType:ASPendingStateTypeAsyncTransactionContainer bool:asyncdisplaykit_asyncTransactionContainer]);
}

GET_AND_SET_PENDING_STATE_BOOL(isOpaque, Opaque, ASPendingStateTypeOpaque)
GET_AND_SET_PENDING_STATE_SEMANTIC_CONTENT_ATTRIBUTE(semanticContentAttribute, SemanticContentAttribute, ASPendingStateTypeSemanticContentAttribute)
GET_AND_SET_PENDING_STATE_EDGE_INSETS(layoutMargins, LayoutMargins, ASPendingStateTypeLayoutMargins)
GET_AND_SET_PENDING_STATE_BOOL(preservesSuperviewLayoutMargins, PreservesSuperviewLayoutMargins, ASPendingStateTypePreservesSuperviewLayoutMargins)
GET_AND_SET_PENDING_STATE_BOOL(insetsLayoutMarginsFromSafeArea, InsetsLayoutMarginsFromSafeArea, ASPendingStateTypeInsetsLayoutMarginsFromSafeArea)
GET_AND_SET_PENDING_STATE_BOOL(isAccessibilityElement, IsAccessibilityElement, ASPendingStateTypeIsAccessibilityElement)
GET_AND_SET_PENDING_STATE_OBJECT(accessibilityLabel, AccessibilityLabel, ASPendingStateTypeAccessibilityLabel, NSString *)
GET_AND_SET_PENDING_STATE_OBJECT(accessibilityAttributedLabel, AccessibilityAttributedLabel, ASPendingStateTypeAccessibilityAttributedLabel, NSAttributedString *)
GET_AND_SET_PENDING_STATE_OBJECT(accessibilityHint, AccessibilityHint, ASPendingStateTypeAccessibilityHint, NSString *)
GET_AND_SET_PENDING_STATE_OBJECT(accessibilityAttributedHint, AccessibilityAttributedHint, ASPendingStateTypeAccessibilityAttributedHint, NSAttributedString *)
GET_AND_SET_PENDING_STATE_OBJECT(accessibilityValue, AccessibilityValue, ASPendingStateTypeAccessibilityValue, NSString *)
GET_AND_SET_PENDING_STATE_OBJECT(accessibilityAttributedValue, AccessibilityAttributedValue, ASPendingStateTypeAccessibilityAttributedValue, NSAttributedString *)
GET_AND_SET_PENDING_STATE_ACCESSIBILITY_TRAITS(accessibilityTraits, AccessibilityTraits, ASPendingStateTypeAccessibilityTraits)
GET_AND_SET_PENDING_STATE_RECT(accessibilityFrame, AccessibilityFrame, ASPendingStateTypeAccessibilityFrame)
GET_AND_SET_PENDING_STATE_OBJECT(accessibilityLanguage, AccessibilityLanguage, ASPendingStateTypeAccessibilityLanguage, NSString *)
GET_AND_SET_PENDING_STATE_BOOL(accessibilityElementsHidden, AccessibilityElementsHidden, ASPendingStateTypeAccessibilityElementsHidden)
GET_AND_SET_PENDING_STATE_BOOL(accessibilityViewIsModal, AccessibilityViewIsModal, ASPendingStateTypeAccessibilityViewIsModal)
GET_AND_SET_PENDING_STATE_BOOL(shouldGroupAccessibilityChildren, ShouldGroupAccessibilityChildren, ASPendingStateTypeShouldGroupAccessibilityChildren)
GET_AND_SET_PENDING_STATE_OBJECT(accessibilityIdentifier, AccessibilityIdentifier, ASPendingStateTypeAccessibilityIdentifier, NSString *)
GET_AND_SET_PENDING_STATE_ACCESSIBILITY_NAVIGATION_STYLE(accessibilityNavigationStyle, AccessibilityNavigationStyle, ASPendingStateTypeAccessibilityNavigationStyle)
GET_AND_SET_PENDING_STATE_OBJECT(accessibilityHeaderElements, AccessibilityHeaderElements, ASPendingStateTypeAccessibilityHeaderElements, NSArray *)
GET_AND_SET_PENDING_STATE_POINT(accessibilityActivationPoint, AccessibilityActivationPoint, ASPendingStateTypeAccessibilityActivationPoint)
GET_AND_SET_PENDING_STATE_OBJECT(accessibilityPath, AccessibilityPath, ASPendingStateTypeAccessibilityPath, UIBezierPath *)

@end
