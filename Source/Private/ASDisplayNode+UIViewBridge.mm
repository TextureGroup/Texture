//
//  ASDisplayNode+UIViewBridge.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASDisplayNode+FrameworkPrivate.h>
#import <AsyncDisplayKit/_ASCoreAnimationExtras.h>
#import <AsyncDisplayKit/_ASPendingState.h>
#import <AsyncDisplayKit/ASInternalHelpers.h>
#import <AsyncDisplayKit/ASDisplayNodeInternal.h>
#import <AsyncDisplayKit/ASDisplayNode+Subclasses.h>
#import <AsyncDisplayKit/ASPendingStateController.h>

/**
 * The following macros are conveniences to help in the common tasks related to the bridging that ASDisplayNode does to UIView and CALayer.
 * In general, a property can either be:
 *   - Always sent to the layer or view's layer
 *       use _getFromLayer / _setToLayer
 *   - Bridged to the view if view-backed or the layer if layer-backed
 *       use _getFromViewOrLayer / _setToViewOrLayer / _messageToViewOrLayer
 *   - Only applicable if view-backed
 *       use _setToViewOnly / _getFromViewOnly
 *   - Has differing types on views and layers, or custom ASDisplayNode-specific behavior is desired
 *       manually implement
 *
 *  _bridge_prologue_write is defined to take the node's property lock. Add it at the beginning of any bridged property setters.
 *  _bridge_prologue_read is defined to take the node's property lock and enforce thread affinity. Add it at the beginning of any bridged property getters.
 */

#define DISPLAYNODE_USE_LOCKS 1

#if DISPLAYNODE_USE_LOCKS
#define _bridge_prologue_read AS::MutexLocker l(__instanceLock__); ASDisplayNodeAssertThreadAffinity(self)
#define _bridge_prologue_write AS::MutexLocker l(__instanceLock__)
#else
#define _bridge_prologue_read ASDisplayNodeAssertThreadAffinity(self)
#define _bridge_prologue_write
#endif

/// Returns YES if the property set should be applied to view/layer immediately.
/// Side Effect: Registers the node with the shared ASPendingStateController if
/// the property cannot be immediately applied and the node does not already have pending changes.
/// This function must be called with the node's lock already held (after _bridge_prologue_write).
/// *warning* the lock should *not* be released until the pending state is updated if this method
/// returns NO. Otherwise, the pending state can be scheduled and flushed *before* you get a chance
/// to apply it.
ASDISPLAYNODE_INLINE BOOL ASDisplayNodeShouldApplyBridgedWriteToView(ASDisplayNode *node) {
  BOOL loaded = _loaded(node);
  if (ASDisplayNodeThreadIsMain()) {
    return loaded;
  } else {
    if (loaded && !ASDisplayNodeGetPendingState(node).hasChanges) {
      [[ASPendingStateController sharedInstance] registerNode:node];
    }
    return NO;
  }
};

#define _getFromViewOrLayer(layerProperty, viewAndPendingViewStateProperty) _loaded(self) ? \
  (_view ? _view.viewAndPendingViewStateProperty : _layer.layerProperty )\
 : ASDisplayNodeGetPendingState(self).viewAndPendingViewStateProperty

#define _setToViewOrLayer(layerProperty, layerValueExpr, viewAndPendingViewStateProperty, viewAndPendingViewStateExpr) BOOL shouldApply = ASDisplayNodeShouldApplyBridgedWriteToView(self); \
  if (shouldApply) { (_view ? _view.viewAndPendingViewStateProperty = (viewAndPendingViewStateExpr) : _layer.layerProperty = (layerValueExpr)); } else { ASDisplayNodeGetPendingState(self).viewAndPendingViewStateProperty = (viewAndPendingViewStateExpr); }

#define _setToViewOnly(viewAndPendingViewStateProperty, viewAndPendingViewStateExpr) BOOL shouldApply = ASDisplayNodeShouldApplyBridgedWriteToView(self); \
if (shouldApply) { _view.viewAndPendingViewStateProperty = (viewAndPendingViewStateExpr); } else { ASDisplayNodeGetPendingState(self).viewAndPendingViewStateProperty = (viewAndPendingViewStateExpr); }

#define _getFromViewOnly(viewAndPendingViewStateProperty) _loaded(self) ? _view.viewAndPendingViewStateProperty : ASDisplayNodeGetPendingState(self).viewAndPendingViewStateProperty

#define _getFromLayer(layerProperty) _loaded(self) ? _layer.layerProperty : ASDisplayNodeGetPendingState(self).layerProperty

#define _setToLayer(layerProperty, layerValueExpr) BOOL shouldApply = ASDisplayNodeShouldApplyBridgedWriteToView(self); \
if (shouldApply) { _layer.layerProperty = (layerValueExpr); } else { ASDisplayNodeGetPendingState(self).layerProperty = (layerValueExpr); }

/**
 * This category implements certain frequently-used properties and methods of UIView and CALayer so that ASDisplayNode clients can just call the view/layer methods on the node,
 * with minimal loss in performance.  Unlike UIView and CALayer methods, these can be called from a non-main thread until the view or layer is created.
 * This allows text sizing in -calculateSizeThatFits: (essentially a simplified layout) to happen off the main thread
 * without any CALayer or UIView actually existing while still being able to set and read properties from ASDisplayNode instances.
 */
@implementation ASDisplayNode (UIViewBridge)

#if TARGET_OS_TV
// Focus Engine
- (BOOL)canBecomeFocused
{
  return NO;
}

- (void)setNeedsFocusUpdate
{
  ASDisplayNodeAssertMainThread();
  [_view setNeedsFocusUpdate];
}

- (void)updateFocusIfNeeded
{
  ASDisplayNodeAssertMainThread();
  [_view updateFocusIfNeeded];
}

- (BOOL)shouldUpdateFocusInContext:(UIFocusUpdateContext *)context
{
  return NO;
}

- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
  
}

- (UIView *)preferredFocusedView
{
  if (self.nodeLoaded) {
    return _view;
  }
  else {
    return nil;
  }
}
#endif

- (BOOL)canBecomeFirstResponder
{
  if (_view == nil) {
    // By default we return NO if not view is created yet
    return NO;
  }
  return [_view canBecomeFirstResponder];
}

- (BOOL)becomeFirstResponder
{
  ASDisplayNodeAssertMainThread();

  // Note: This implicitly loads the view if it hasn't been loaded yet.
  [self view];

  if (![self canBecomeFirstResponder]) {
    return NO;
  }
  return [_view becomeFirstResponder];
}

- (BOOL)canResignFirstResponder
{
  ASDisplayNodeAssertMainThread();

  if (_view == nil) {
    // By default we return YES if no view is created yet
    return YES;
  }
  return [_view canResignFirstResponder];
}

- (BOOL)resignFirstResponder
{
  ASDisplayNodeAssertMainThread();

  // Note: This implicitly loads the view if it hasn't been loaded yet.
  [self view];

  if (![self canResignFirstResponder]) {
    return NO;
  }
  return [_view resignFirstResponder];
}

- (BOOL)isFirstResponder
{
  ASDisplayNodeAssertMainThread();
  if (_view == nil) {
    // If no view is created yet we can just return NO as it's unlikely it's the first responder
    return NO;
  }
  return [_view isFirstResponder];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
  ASDisplayNodeAssertMainThread();
  return !self.layerBacked && [self.view canPerformAction:action withSender:sender];
}

- (CGFloat)alpha
{
  _bridge_prologue_read;
  return _getFromViewOrLayer(opacity, alpha);
}

- (void)setAlpha:(CGFloat)newAlpha
{
  _bridge_prologue_write;
  _setToViewOrLayer(opacity, newAlpha, alpha, newAlpha);
}

- (CGFloat)cornerRadius
{
  AS::MutexLocker l(__instanceLock__);
  return _cornerRadius;
}

- (void)setCornerRadius:(CGFloat)newCornerRadius
{
  [self updateCornerRoundingWithType:self.cornerRoundingType
                        cornerRadius:newCornerRadius
                       maskedCorners:self.maskedCorners];
}

- (ASCornerRoundingType)cornerRoundingType
{
  AS::MutexLocker l(__instanceLock__);
  return _cornerRoundingType;
}

- (void)setCornerRoundingType:(ASCornerRoundingType)newRoundingType
{
  [self updateCornerRoundingWithType:newRoundingType cornerRadius:self.cornerRadius maskedCorners:self.maskedCorners];
}

- (CACornerMask)maskedCorners
{
  AS::MutexLocker l(__instanceLock__);
  return _maskedCorners;
}

- (void)setMaskedCorners:(CACornerMask)newMaskedCorners
{
  [self updateCornerRoundingWithType:self.cornerRoundingType
                        cornerRadius:self.cornerRadius
                       maskedCorners:newMaskedCorners];
}

- (NSString *)contentsGravity
{
  _bridge_prologue_read;
  return _getFromLayer(contentsGravity);
}

- (void)setContentsGravity:(NSString *)newContentsGravity
{
  _bridge_prologue_write;
  _setToLayer(contentsGravity, newContentsGravity);
}

- (CGRect)contentsRect
{
  _bridge_prologue_read;
  return _getFromLayer(contentsRect);
}

- (void)setContentsRect:(CGRect)newContentsRect
{
  _bridge_prologue_write;
  _setToLayer(contentsRect, newContentsRect);
}

- (CGRect)contentsCenter
{
  _bridge_prologue_read;
  return _getFromLayer(contentsCenter);
}

- (void)setContentsCenter:(CGRect)newContentsCenter
{
  _bridge_prologue_write;
  _setToLayer(contentsCenter, newContentsCenter);
}

- (CGFloat)contentsScale
{
  _bridge_prologue_read;
  return _getFromLayer(contentsScale);
}

- (void)setContentsScale:(CGFloat)newContentsScale
{
  _bridge_prologue_write;
  _setToLayer(contentsScale, newContentsScale);
}

- (CGFloat)rasterizationScale
{
  _bridge_prologue_read;
  return _getFromLayer(rasterizationScale);
}

- (void)setRasterizationScale:(CGFloat)newRasterizationScale
{
  _bridge_prologue_write;
  _setToLayer(rasterizationScale, newRasterizationScale);
}

- (CGRect)bounds
{
  _bridge_prologue_read;
  return _getFromViewOrLayer(bounds, bounds);
}

- (void)setBounds:(CGRect)newBounds
{
  _bridge_prologue_write;
  _setToViewOrLayer(bounds, newBounds, bounds, newBounds);
  self.threadSafeBounds = newBounds;
}

- (CGRect)frame
{
  _bridge_prologue_read;

  // Frame is only defined when transform is identity.
//#if DEBUG
//  // Checking if the transform is identity is expensive, so disable when unnecessary. We have assertions on in Release, so DEBUG is the only way I know of.
//  ASDisplayNodeAssert(CATransform3DIsIdentity(self.transform), @"-[ASDisplayNode frame] - self.transform must be identity in order to use the frame property.  (From Apple's UIView documentation: If the transform property is not the identity transform, the value of this property is undefined and therefore should be ignored.)");
//#endif

  CGPoint position = self.position;
  CGRect bounds = self.bounds;
  CGPoint anchorPoint = self.anchorPoint;
  CGPoint origin = CGPointMake(position.x - bounds.size.width * anchorPoint.x,
                               position.y - bounds.size.height * anchorPoint.y);
  return CGRectMake(origin.x, origin.y, bounds.size.width, bounds.size.height);
}

- (void)setFrame:(CGRect)rect
{
  BOOL setToView = NO;
  BOOL setToLayer = NO;
  CGRect newBounds = CGRectZero;
  CGPoint newPosition = CGPointZero;
  BOOL nodeLoaded = NO;
  BOOL isMainThread = ASDisplayNodeThreadIsMain();
  {
    _bridge_prologue_write;

    // For classes like ASTableNode, ASCollectionNode, ASScrollNode and similar - make sure UIView gets setFrame:
    struct ASDisplayNodeFlags flags = _flags;
    BOOL specialPropertiesHandling = ASDisplayNodeNeedsSpecialPropertiesHandling(checkFlag(Synchronous), flags.layerBacked);

    nodeLoaded = _loaded(self);
    if (!specialPropertiesHandling) {
      BOOL canReadProperties = isMainThread || !nodeLoaded;
      if (canReadProperties) {
        // We don't have to set frame directly, and we can read current properties.
        // Compute a new bounds and position and set them on self.
        CALayer *layer = _layer;
        CGPoint origin = (nodeLoaded ? layer.bounds.origin : self.bounds.origin);
        CGPoint anchorPoint = (nodeLoaded ? layer.anchorPoint : self.anchorPoint);

        ASBoundsAndPositionForFrame(rect, origin, anchorPoint, &newBounds, &newPosition);

        if (ASIsCGRectValidForLayout(newBounds) == NO || ASIsCGPositionValidForLayout(newPosition) == NO) {
          ASDisplayNodeAssertNonFatal(NO, @"-[ASDisplayNode setFrame:] - The new frame (%@) is invalid and unsafe to be set.", NSStringFromCGRect(rect));
          return;
        }

        if (nodeLoaded) {
          setToLayer = YES;
        } else {
          self.bounds = newBounds;
          self.position = newPosition;
        }
      } else {
        // We don't have to set frame directly, but we can't read properties.
        // Store the frame in our pending state, and it'll get decomposed into
        // bounds and position when the pending state is applied.
        _ASPendingState *pendingState = ASDisplayNodeGetPendingState(self);
        if (nodeLoaded && !pendingState.hasChanges) {
          [[ASPendingStateController sharedInstance] registerNode:self];
        }
        pendingState.frame = rect;
      }
    } else {
      if (nodeLoaded && isMainThread) {
        // We do have to set frame directly, and we're on main thread with a loaded node.
        // Just set the frame on the view.
        // NOTE: Frame is only defined when transform is identity because we explicitly diverge from CALayer behavior and define frame without transform.
        setToView = YES;
      } else {
        // We do have to set frame directly, but either the node isn't loaded or we're on a non-main thread.
        // Set the frame on the pending state, and it'll call setFrame: when applied.
        _ASPendingState *pendingState = ASDisplayNodeGetPendingState(self);
        if (nodeLoaded && !pendingState.hasChanges) {
          [[ASPendingStateController sharedInstance] registerNode:self];
        }
        pendingState.frame = rect;
      }
    }
  }

  if (setToView) {
    ASDisplayNodeAssertTrue(nodeLoaded && isMainThread);
    _view.frame = rect;
  } else if (setToLayer) {
    ASDisplayNodeAssertTrue(nodeLoaded && isMainThread);
    _layer.bounds = newBounds;
    _layer.position = newPosition;
  }
}

- (void)setNeedsDisplay
{
  BOOL isRasterized = NO;
  BOOL shouldApply = NO;
  id viewOrLayer = nil;
  {
    _bridge_prologue_write;
    isRasterized = _hierarchyState & ASHierarchyStateRasterized;
    shouldApply = ASDisplayNodeShouldApplyBridgedWriteToView(self);
    viewOrLayer = _view ?: _layer;
    
    if (isRasterized == NO && shouldApply == NO) {
      // We can't release the lock before applying to pending state, or it may be flushed before it can be applied.
      [ASDisplayNodeGetPendingState(self) setNeedsDisplay];
    }
  }
  
  if (isRasterized) {
    ASPerformBlockOnMainThread(^{
      // The below operation must be performed on the main thread to ensure against an extremely rare deadlock, where a parent node
      // begins materializing the view / layer hierarchy (locking itself or a descendant) while this node walks up
      // the tree and requires locking that node to access .rasterizesSubtree.
      // For this reason, this method should be avoided when possible.  Use _hierarchyState & ASHierarchyStateRasterized.
      ASDisplayNodeAssertMainThread();
      ASDisplayNode *rasterizedContainerNode = self.supernode;
      while (rasterizedContainerNode) {
        if (rasterizedContainerNode.rasterizesSubtree) {
          break;
        }
        rasterizedContainerNode = rasterizedContainerNode.supernode;
      }
      [rasterizedContainerNode setNeedsDisplay];
    });
  } else {
    if (shouldApply) {
      // If not rasterized, and the node is loaded (meaning we certainly have a view or layer), send a
      // message to the view/layer first. This is because __setNeedsDisplay calls as scheduleNodeForDisplay,
      // which may call -displayIfNeeded. We want to ensure the needsDisplay flag is set now, and then cleared.
      [viewOrLayer setNeedsDisplay];
    }
    [self __setNeedsDisplay];
  }
}

- (void)setNeedsLayout
{
  BOOL shouldApply = NO;
  BOOL loaded = NO;
  id viewOrLayer = nil;
  {
    _bridge_prologue_write;
    shouldApply = ASDisplayNodeShouldApplyBridgedWriteToView(self);
    loaded = _loaded(self);
    viewOrLayer = _view ?: _layer;
    if (shouldApply == NO && loaded) {
      // The node is loaded but we're not on main.
      // We will call [self __setNeedsLayout] when we apply the pending state.
      // We need to call it on main if the node is loaded to support automatic subnode management.
      // We can't release the lock before applying to pending state, or it may be flushed before it can be applied.
      [ASDisplayNodeGetPendingState(self) setNeedsLayout];
    }
  }
  
  if (shouldApply) {
    // The node is loaded and we're on main.
    // Quite the opposite of setNeedsDisplay, we must call __setNeedsLayout before messaging
    // the view or layer to ensure that measurement and implicitly added subnodes have been handled.
    [self __setNeedsLayout];
    [viewOrLayer setNeedsLayout];
  } else if (loaded == NO) {
    // The node is not loaded and we're not on main.
    [self __setNeedsLayout];
  }
}

- (void)layoutIfNeeded
{
  BOOL shouldApply = NO;
  BOOL loaded = NO;
  id viewOrLayer = nil;
  {
    _bridge_prologue_write;
    shouldApply = ASDisplayNodeShouldApplyBridgedWriteToView(self);
    loaded = _loaded(self);
    viewOrLayer = _view ?: _layer;
    if (shouldApply == NO && loaded) {
      // The node is loaded but we're not on main.
      // We will call layoutIfNeeded on the view or layer when we apply the pending state. __layout will in turn be called on us (see -[_ASDisplayLayer layoutSublayers]).
      // We need to call it on main if the node is loaded to support automatic subnode management.
      // We can't release the lock before applying to pending state, or it may be flushed before it can be applied.
      [ASDisplayNodeGetPendingState(self) layoutIfNeeded];
    }
  }
  
  if (shouldApply) {
    // The node is loaded and we're on main.
    // Message the view or layer which in turn will call __layout on us (see -[_ASDisplayLayer layoutSublayers]).
    [viewOrLayer layoutIfNeeded];
  } else if (loaded == NO) {
    // The node is not loaded and we're not on main.
    [self __layout];
  }
}

- (BOOL)isOpaque
{
  _bridge_prologue_read;
  return _getFromViewOrLayer(opaque, opaque);
}


- (void)setOpaque:(BOOL)newOpaque
{
  _bridge_prologue_write;
  BOOL shouldApply = ASDisplayNodeShouldApplyBridgedWriteToView(self);
  
  if (shouldApply) {
    /*
     NOTE: The values of `opaque` can be different between a view and layer.

     In debugging on Xcode 11 I saw the following in lldb:
     - Initially for a new ASDisplayNode layer.isOpaque and _view.isOpaque are true
     - Set the backgroundColor of the node to a valid UIColor
     Expected: layer.isOpaque and view.isOpaque would be equal and true
     Actual: view.isOpaque is true and layer.isOpaque is now false

     This broke some unit tests for view-backed nodes so I think we need to read directly from the view and can't rely on the layers value at this point.
     */
    BOOL oldOpaque = _layer.opaque;
    if (!_flags.layerBacked) {
      oldOpaque = _view.opaque;
      _view.opaque = newOpaque;
    }
    _layer.opaque = newOpaque;
    if (oldOpaque != newOpaque) {
      [self setNeedsDisplay];
    }
  } else {
    // NOTE: If we're in the background, we cannot read the current value of self.opaque (if loaded).
    // When the pending state is applied to the view on main, we will call `setNeedsDisplay` if
    // the new opaque value doesn't match the one on the layer.
    ASDisplayNodeGetPendingState(self).opaque = newOpaque;
  }
}

- (BOOL)isUserInteractionEnabled
{
  _bridge_prologue_read;
  if (_flags.layerBacked) return NO;
  return _getFromViewOnly(userInteractionEnabled);
}

- (void)setUserInteractionEnabled:(BOOL)enabled
{
  _bridge_prologue_write;
  _setToViewOnly(userInteractionEnabled, enabled);
}
#if TARGET_OS_IOS
- (BOOL)isExclusiveTouch
{
  _bridge_prologue_read;
  return _getFromViewOnly(exclusiveTouch);
}

- (void)setExclusiveTouch:(BOOL)exclusiveTouch
{
  _bridge_prologue_write;
  _setToViewOnly(exclusiveTouch, exclusiveTouch);
}
#endif
- (BOOL)clipsToBounds
{
  _bridge_prologue_read;
  return _getFromViewOrLayer(masksToBounds, clipsToBounds);
}

- (void)setClipsToBounds:(BOOL)clips
{
  _bridge_prologue_write;
  _setToViewOrLayer(masksToBounds, clips, clipsToBounds, clips);
}

- (CGPoint)anchorPoint
{
  _bridge_prologue_read;
  return _getFromLayer(anchorPoint);
}

- (void)setAnchorPoint:(CGPoint)newAnchorPoint
{
  _bridge_prologue_write;
  _setToLayer(anchorPoint, newAnchorPoint);
}

- (CGPoint)position
{
  _bridge_prologue_read;
  return _getFromLayer(position);
}

- (void)setPosition:(CGPoint)newPosition
{
  _bridge_prologue_write;
  _setToLayer(position, newPosition);
}

- (CGFloat)zPosition
{
  _bridge_prologue_read;
  return _getFromLayer(zPosition);
}

- (void)setZPosition:(CGFloat)newPosition
{
  _bridge_prologue_write;
  _setToLayer(zPosition, newPosition);
}

- (CATransform3D)transform
{
  _bridge_prologue_read;
  return _getFromLayer(transform);
}

- (void)setTransform:(CATransform3D)newTransform
{
  _bridge_prologue_write;
  _setToLayer(transform, newTransform);
}

- (CATransform3D)subnodeTransform
{
  _bridge_prologue_read;
  return _getFromLayer(sublayerTransform);
}

- (void)setSubnodeTransform:(CATransform3D)newSubnodeTransform
{
  _bridge_prologue_write;
  _setToLayer(sublayerTransform, newSubnodeTransform);
}

- (id)contents
{
  _bridge_prologue_read;
  return _getFromLayer(contents);
}

- (void)setContents:(id)newContents
{
  _bridge_prologue_write;
  _setToLayer(contents, newContents);
}

- (BOOL)isHidden
{
  _bridge_prologue_read;
  return _getFromViewOrLayer(hidden, hidden);
}

- (void)setHidden:(BOOL)flag
{
  _bridge_prologue_write;
  _setToViewOrLayer(hidden, flag, hidden, flag);
}

- (BOOL)needsDisplayOnBoundsChange
{
  _bridge_prologue_read;
  return _getFromLayer(needsDisplayOnBoundsChange);
}

- (void)setNeedsDisplayOnBoundsChange:(BOOL)flag
{
  _bridge_prologue_write;
  _setToLayer(needsDisplayOnBoundsChange, flag);
}

- (BOOL)autoresizesSubviews
{
  _bridge_prologue_read;
  ASDisplayNodeAssert(!_flags.layerBacked, @"Danger: this property is undefined on layer-backed nodes.");
  return _getFromViewOnly(autoresizesSubviews);
}

- (void)setAutoresizesSubviews:(BOOL)flag
{
  _bridge_prologue_write;
  ASDisplayNodeAssert(!_flags.layerBacked, @"Danger: this property is undefined on layer-backed nodes.");
  _setToViewOnly(autoresizesSubviews, flag);
}

- (UIViewAutoresizing)autoresizingMask
{
  _bridge_prologue_read;
  ASDisplayNodeAssert(!_flags.layerBacked, @"Danger: this property is undefined on layer-backed nodes.");
  return _getFromViewOnly(autoresizingMask);
}

- (void)setAutoresizingMask:(UIViewAutoresizing)mask
{
  _bridge_prologue_write;
  ASDisplayNodeAssert(!_flags.layerBacked, @"Danger: this property is undefined on layer-backed nodes.");
  _setToViewOnly(autoresizingMask, mask);
}

- (UIViewContentMode)contentMode
{
  _bridge_prologue_read;
  if (_loaded(self)) {
    if (_flags.layerBacked) {
      return ASDisplayNodeUIContentModeFromCAContentsGravity(_layer.contentsGravity);
    } else {
      return _view.contentMode;
    }
  } else {
    return ASDisplayNodeGetPendingState(self).contentMode;
  }
}

- (void)setContentMode:(UIViewContentMode)contentMode
{
  _bridge_prologue_write;
  BOOL shouldApply = ASDisplayNodeShouldApplyBridgedWriteToView(self);
  if (shouldApply) {
    if (_flags.layerBacked) {
      _layer.contentsGravity = ASDisplayNodeCAContentsGravityFromUIContentMode(contentMode);
    } else {
      _view.contentMode = contentMode;
    }
  } else {
    ASDisplayNodeGetPendingState(self).contentMode = contentMode;
  }
}

- (UIColor *)backgroundColor
{
  _bridge_prologue_read;
  if (_loaded(self)) {
    /*
     Note: We can no longer rely simply on the layers backgroundColor value if the color is set directly on `_view`
     There is no longer a 1:1 mapping between _view.backgroundColor and _layer.backgroundColor after testing in iOS 13 / Xcode 11 so we should prefer one or the other depending on the backing type for the node (view or layer)
     */
    if (_flags.layerBacked) {
      return _backgroundColor;
    } else {
      return _view.backgroundColor;
    }
  }
  return ASDisplayNodeGetPendingState(self).backgroundColor;
}

- (void)setBackgroundColor:(UIColor *)newBackgroundColor
{
  _bridge_prologue_write;
  BOOL shouldApply = ASDisplayNodeShouldApplyBridgedWriteToView(self);
  if (shouldApply) {
    UIColor *oldBackgroundColor = _backgroundColor;
    _backgroundColor = newBackgroundColor;
    if (_flags.layerBacked) {
      _layer.backgroundColor = _backgroundColor.CGColor;
    } else {
      /*
       NOTE: Setting to the view and layer individually is necessary.

       As observed in lldb, the view does not appear to immediately propagate background color to the layer and actually clears it's value (`nil`) initially. This was caught by our snapshot tests.

       Given that UIColor / UIView has dynamic capabilties now, we should set directly to the view and make sure that the layers value is consistent here.

       */
      _view.backgroundColor = _backgroundColor;
      // Gather the CGColorRef from the view incase there are any changes it might apply to which CGColorRef is returned for dynamic colors
      _layer.backgroundColor = _view.backgroundColor.CGColor;
    }

    if (![oldBackgroundColor isEqual:newBackgroundColor]) {
      [self setNeedsDisplay];
    }
  } else {
    // NOTE: If we're in the background, we cannot read the current value of bgcolor (if loaded).
    // When the pending state is applied to the view on main, we will call `setNeedsDisplay` if
    // the new background color doesn't match the one on the layer.
    _backgroundColor = newBackgroundColor;
    ASDisplayNodeGetPendingState(self).backgroundColor = newBackgroundColor;
  }
}

- (UIColor *)tintColor
{
  __instanceLock__.lock();
  UIColor *retVal = nil;
  BOOL shouldAscend = NO;
  if (_flags.layerBacked) {
    retVal = _tintColor;
    // The first nondefault tint color value in the node’s hierarchy, ascending from and starting with the node itself.
    shouldAscend = (retVal == nil);
  } else {
    ASDisplayNodeAssertThreadAffinity(self);
    retVal = _getFromViewOnly(tintColor);
  }
  __instanceLock__.unlock();
  return shouldAscend ? self.supernode.tintColor : retVal;
}

- (void)setTintColor:(UIColor *)color
{
  // Handle locking manually since we unlock to notify subclasses when tint color changes
  __instanceLock__.lock();
  if (_flags.layerBacked) {
    if (![_tintColor isEqual:color]) {
      _tintColor = color;

      if (_loaded(self)) {
        // Tint color has changed. Unlock here before calling subclasses and exit-early
        __instanceLock__.unlock();
        [self tintColorDidChange];
        return;
      }
    }
  } else {
    _tintColor = color;
    _setToViewOnly(tintColor, color);
  }
  __instanceLock__.unlock();
}

- (void)tintColorDidChange
{
    // ignore this, allow subclasses to be notified
}

- (CGColorRef)shadowColor
{
  _bridge_prologue_read;
  return _getFromLayer(shadowColor);
}

- (void)setShadowColor:(CGColorRef)colorValue
{
  _bridge_prologue_write;
  _setToLayer(shadowColor, colorValue);
}

- (CGFloat)shadowOpacity
{
  _bridge_prologue_read;
  return _getFromLayer(shadowOpacity);
}

- (void)setShadowOpacity:(CGFloat)opacity
{
  _bridge_prologue_write;
  _setToLayer(shadowOpacity, opacity);
}

- (CGSize)shadowOffset
{
  _bridge_prologue_read;
  return _getFromLayer(shadowOffset);
}

- (void)setShadowOffset:(CGSize)offset
{
  _bridge_prologue_write;
  _setToLayer(shadowOffset, offset);
}

- (CGFloat)shadowRadius
{
  _bridge_prologue_read;
  return _getFromLayer(shadowRadius);
}

- (void)setShadowRadius:(CGFloat)radius
{
  _bridge_prologue_write;
  _setToLayer(shadowRadius, radius);
}

- (CGFloat)borderWidth
{
  _bridge_prologue_read;
  return _getFromLayer(borderWidth);
}

- (void)setBorderWidth:(CGFloat)width
{
  _bridge_prologue_write;
  _setToLayer(borderWidth, width);
}

- (CGColorRef)borderColor
{
  _bridge_prologue_read;
  return _getFromLayer(borderColor);
}

- (void)setBorderColor:(CGColorRef)colorValue
{
  _bridge_prologue_write;
  _setToLayer(borderColor, colorValue);
}

- (BOOL)allowsGroupOpacity
{
  _bridge_prologue_read;
  return _getFromLayer(allowsGroupOpacity);
}

- (void)setAllowsGroupOpacity:(BOOL)allowsGroupOpacity
{
  _bridge_prologue_write;
  _setToLayer(allowsGroupOpacity, allowsGroupOpacity);
}

- (BOOL)allowsEdgeAntialiasing
{
  _bridge_prologue_read;
  return _getFromLayer(allowsEdgeAntialiasing);
}

- (void)setAllowsEdgeAntialiasing:(BOOL)allowsEdgeAntialiasing
{
  _bridge_prologue_write;
  _setToLayer(allowsEdgeAntialiasing, allowsEdgeAntialiasing);
}

- (CAEdgeAntialiasingMask)edgeAntialiasingMask
{
  _bridge_prologue_read;
  return _getFromLayer(edgeAntialiasingMask);
}

- (void)setEdgeAntialiasingMask:(CAEdgeAntialiasingMask)edgeAntialiasingMask
{
  _bridge_prologue_write;
  _setToLayer(edgeAntialiasingMask, edgeAntialiasingMask);
}

- (UISemanticContentAttribute)semanticContentAttribute
{
  _bridge_prologue_read;
  return _getFromViewOnly(semanticContentAttribute);
}

- (void)setSemanticContentAttribute:(UISemanticContentAttribute)semanticContentAttribute
{
  _bridge_prologue_write;
  _setToViewOnly(semanticContentAttribute, semanticContentAttribute);
#if YOGA
  [self semanticContentAttributeDidChange:semanticContentAttribute];
#endif
}

- (UIEdgeInsets)layoutMargins
{
  _bridge_prologue_read;
  ASDisplayNodeAssert(!_flags.layerBacked, @"Danger: this property is undefined on layer-backed nodes.");
  UIEdgeInsets margins = _getFromViewOnly(layoutMargins);

  if (!AS_AT_LEAST_IOS11 && self.insetsLayoutMarginsFromSafeArea) {
    UIEdgeInsets safeArea = self.safeAreaInsets;
    margins = ASConcatInsets(margins, safeArea);
  }

  return margins;
}

- (void)setLayoutMargins:(UIEdgeInsets)layoutMargins
{
  _bridge_prologue_write;
  ASDisplayNodeAssert(!_flags.layerBacked, @"Danger: this property is undefined on layer-backed nodes.");
  _setToViewOnly(layoutMargins, layoutMargins);
}

- (BOOL)preservesSuperviewLayoutMargins
{
  _bridge_prologue_read;
  ASDisplayNodeAssert(!_flags.layerBacked, @"Danger: this property is undefined on layer-backed nodes.");
  return _getFromViewOnly(preservesSuperviewLayoutMargins);
}

- (void)setPreservesSuperviewLayoutMargins:(BOOL)preservesSuperviewLayoutMargins
{
  _bridge_prologue_write;
  ASDisplayNodeAssert(!_flags.layerBacked, @"Danger: this property is undefined on layer-backed nodes.");
  _setToViewOnly(preservesSuperviewLayoutMargins, preservesSuperviewLayoutMargins);
}

- (void)layoutMarginsDidChange
{
  ASDisplayNodeAssertMainThread();

  if (self.automaticallyRelayoutOnLayoutMarginsChanges) {
    [self setNeedsLayout];
  }
}

- (UIEdgeInsets)safeAreaInsets
{
  _bridge_prologue_read;

  if (AS_AVAILABLE_IOS_TVOS(11.0, 11.0)) {
    if (!_flags.layerBacked && _loaded(self)) {
      return self.view.safeAreaInsets;
    }
  }
  return _fallbackSafeAreaInsets;
}

- (BOOL)insetsLayoutMarginsFromSafeArea
{
  _bridge_prologue_read;

  return [self _locked_insetsLayoutMarginsFromSafeArea];
}

- (void)setInsetsLayoutMarginsFromSafeArea:(BOOL)insetsLayoutMarginsFromSafeArea
{
  ASDisplayNodeAssertThreadAffinity(self);
  BOOL shouldNotifyAboutUpdate;
  {
    _bridge_prologue_write;

    _flags.fallbackInsetsLayoutMarginsFromSafeArea = insetsLayoutMarginsFromSafeArea;

    if (AS_AVAILABLE_IOS_TVOS(11.0, 11.0)) {
      if (!_flags.layerBacked) {
        _setToViewOnly(insetsLayoutMarginsFromSafeArea, insetsLayoutMarginsFromSafeArea);
      }
    }

    shouldNotifyAboutUpdate = _loaded(self) && (!AS_AT_LEAST_IOS11 || _flags.layerBacked);
  }

  if (shouldNotifyAboutUpdate) {
    [self layoutMarginsDidChange];
  }
}

- (NSDictionary<NSString *,id<CAAction>> *)actions
{
  _bridge_prologue_read;
  return _getFromLayer(actions);
}

- (void)setActions:(NSDictionary<NSString *,id<CAAction>> *)actions
{
  _bridge_prologue_write;
  _setToLayer(actions, actions);
}

- (void)safeAreaInsetsDidChange
{
  ASDisplayNodeAssertMainThread();

  if (self.automaticallyRelayoutOnSafeAreaChanges) {
    [self setNeedsLayout];
  }

  [self _fallbackUpdateSafeAreaOnChildren];
}

@end

@implementation ASDisplayNode (InternalPropertyBridge)

- (CGFloat)layerCornerRadius
{
  _bridge_prologue_read;
  return _getFromLayer(cornerRadius);
}

- (void)setLayerCornerRadius:(CGFloat)newLayerCornerRadius
{
  _bridge_prologue_write;
  _setToLayer(cornerRadius, newLayerCornerRadius);
}

- (CACornerMask)layerMaskedCorners
{
  _bridge_prologue_read;
  if (AS_AVAILABLE_IOS_TVOS(11, 11)) {
    return _getFromLayer(maskedCorners);
  } else {
    return kASCACornerAllCorners;
  }
}

- (void)setLayerMaskedCorners:(CACornerMask)newLayerMaskedCorners
{
  _bridge_prologue_write;
  if (AS_AVAILABLE_IOS_TVOS(11, 11)) {
    _setToLayer(maskedCorners, newLayerMaskedCorners);
  } else {
    ASDisplayNodeAssert(newLayerMaskedCorners == kASCACornerAllCorners,
                        @"Cannot change maskedCorners property in iOS < 11 while using DefaultSlowCALayer rounding.");
  }
}

- (BOOL)_locked_insetsLayoutMarginsFromSafeArea
{
  DISABLED_ASAssertLocked(__instanceLock__);
  if (AS_AVAILABLE_IOS_TVOS(11.0, 11.0)) {
    if (!_flags.layerBacked) {
      return _getFromViewOnly(insetsLayoutMarginsFromSafeArea);
    }
  }
  return _flags.fallbackInsetsLayoutMarginsFromSafeArea;
}

@end

#pragma mark - UIViewBridgeAccessibility

// ASDK supports accessibility for view or layer backed nodes. To be able to provide support for layer backed
// nodes, properties for all of the UIAccessibility protocol defined properties need to be provided an held in sync
// between node and view

// Helper function with following logic:
// - If the node is not loaded yet use the property from the pending state
// - In case the node is loaded
//  - Check if the node has a view and get the value from the view if loaded or from the pending state
//  - If view is not available, e.g. the node is layer backed return the property value
#define _getAccessibilityFromViewOrProperty(nodeProperty, viewAndPendingViewStateProperty) _loaded(self) ? \
(_view ? _view.viewAndPendingViewStateProperty : nodeProperty )\
: ASDisplayNodeGetPendingState(self).viewAndPendingViewStateProperty

// Helper function to set property values on pending state or view and property if loaded
#define _setAccessibilityToViewAndProperty(nodeProperty, nodeValueExpr, viewAndPendingViewStateProperty, viewAndPendingViewStateExpr) \
nodeProperty = nodeValueExpr; _setToViewOnly(viewAndPendingViewStateProperty, viewAndPendingViewStateExpr)

@implementation ASDisplayNode (UIViewBridgeAccessibility)

- (BOOL)isAccessibilityElement
{
  _bridge_prologue_read;
  return _getAccessibilityFromViewOrProperty(_flags.isAccessibilityElement, isAccessibilityElement);
}

- (void)setIsAccessibilityElement:(BOOL)isAccessibilityElement
{
  _bridge_prologue_write;
  _setAccessibilityToViewAndProperty(_flags.isAccessibilityElement, isAccessibilityElement, isAccessibilityElement, isAccessibilityElement);
}

- (NSString *)accessibilityLabel
{
  _bridge_prologue_read;
  return _getAccessibilityFromViewOrProperty(_accessibilityLabel, accessibilityLabel);
}

- (void)setAccessibilityLabel:(NSString *)accessibilityLabel
{
  _bridge_prologue_write;
  NSString *oldAccessibilityLabel = _getFromViewOnly(accessibilityLabel);
  _setAccessibilityToViewAndProperty(_accessibilityLabel, accessibilityLabel, accessibilityLabel, accessibilityLabel);
  if (AS_AVAILABLE_IOS_TVOS(11, 11)) {
    NSAttributedString *accessibilityAttributedLabel = accessibilityLabel ? [[NSAttributedString alloc] initWithString:accessibilityLabel] : nil;
    _setAccessibilityToViewAndProperty(_accessibilityAttributedLabel, accessibilityAttributedLabel, accessibilityAttributedLabel, accessibilityAttributedLabel);
  }

  // We need to update action name when it's changed to reflect the latest state.
  // Note: Update the custom action itself won't work when a11y is inside a list of custom actions
  // in which one action results in a name change in the next action. In that case the UIAccessibility
  // will hold the old action strongly until a11y jumps out of the list of custom actions.
  // Thus we can only update name in place to have the change take effect.
  BOOL needsUpdateActionName = self.isNodeLoaded && ![oldAccessibilityLabel isEqualToString:accessibilityLabel] && (0 != (_accessibilityTraits & ASInteractiveAccessibilityTraitsMask()));
  if (needsUpdateActionName) {
    self.accessibilityCustomAction.name = accessibilityLabel;
  }
}


- (NSAttributedString *)accessibilityAttributedLabel
{
  _bridge_prologue_read;
  return _getAccessibilityFromViewOrProperty(_accessibilityAttributedLabel, accessibilityAttributedLabel);
}

- (void)setAccessibilityAttributedLabel:(NSAttributedString *)accessibilityAttributedLabel
{
  _bridge_prologue_write;
  { _setAccessibilityToViewAndProperty(_accessibilityAttributedLabel, accessibilityAttributedLabel, accessibilityAttributedLabel, accessibilityAttributedLabel); }
  { _setAccessibilityToViewAndProperty(_accessibilityLabel, accessibilityAttributedLabel.string, accessibilityLabel, accessibilityAttributedLabel.string); }
}

- (NSString *)accessibilityHint
{
  _bridge_prologue_read;
  return _getAccessibilityFromViewOrProperty(_accessibilityHint, accessibilityHint);
}

- (void)setAccessibilityHint:(NSString *)accessibilityHint
{
  _bridge_prologue_write;
  _setAccessibilityToViewAndProperty(_accessibilityHint, accessibilityHint, accessibilityHint, accessibilityHint);
  if (AS_AVAILABLE_IOS_TVOS(11, 11)) {
    NSAttributedString *accessibilityAttributedHint = accessibilityHint ? [[NSAttributedString alloc] initWithString:accessibilityHint] : nil;
    _setAccessibilityToViewAndProperty(_accessibilityAttributedHint, accessibilityAttributedHint, accessibilityAttributedHint, accessibilityAttributedHint);
  }
}

- (NSAttributedString *)accessibilityAttributedHint
{
  _bridge_prologue_read;
  return _getAccessibilityFromViewOrProperty(_accessibilityAttributedHint, accessibilityAttributedHint);
}

- (void)setAccessibilityAttributedHint:(NSAttributedString *)accessibilityAttributedHint
{
  _bridge_prologue_write;
  { _setAccessibilityToViewAndProperty(_accessibilityAttributedHint, accessibilityAttributedHint, accessibilityAttributedHint, accessibilityAttributedHint); }

  { _setAccessibilityToViewAndProperty(_accessibilityHint, accessibilityAttributedHint.string, accessibilityHint, accessibilityAttributedHint.string); }
}

- (NSString *)accessibilityValue
{
  _bridge_prologue_read;
  return _getAccessibilityFromViewOrProperty(_accessibilityValue, accessibilityValue);
}

- (void)setAccessibilityValue:(NSString *)accessibilityValue
{
  _bridge_prologue_write;
  _setAccessibilityToViewAndProperty(_accessibilityValue, accessibilityValue, accessibilityValue, accessibilityValue);
  if (AS_AVAILABLE_IOS_TVOS(11, 11)) {
    NSAttributedString *accessibilityAttributedValue = accessibilityValue ? [[NSAttributedString alloc] initWithString:accessibilityValue] : nil;
    _setAccessibilityToViewAndProperty(_accessibilityAttributedValue, accessibilityAttributedValue, accessibilityAttributedValue, accessibilityAttributedValue);
  }
}

- (NSAttributedString *)accessibilityAttributedValue
{
  _bridge_prologue_read;
  return _getAccessibilityFromViewOrProperty(_accessibilityAttributedValue, accessibilityAttributedValue);
}

- (void)setAccessibilityAttributedValue:(NSAttributedString *)accessibilityAttributedValue
{
  _bridge_prologue_write;
  { _setAccessibilityToViewAndProperty(_accessibilityAttributedValue, accessibilityAttributedValue, accessibilityAttributedValue, accessibilityAttributedValue); }
  { _setAccessibilityToViewAndProperty(_accessibilityValue, accessibilityAttributedValue.string, accessibilityValue, accessibilityAttributedValue.string); }
}

- (UIAccessibilityTraits)accessibilityTraits
{
  _bridge_prologue_read;
  return _getAccessibilityFromViewOrProperty(_accessibilityTraits, accessibilityTraits);
}

- (void)setAccessibilityTraits:(UIAccessibilityTraits)accessibilityTraits
{
  _bridge_prologue_write;
  _setAccessibilityToViewAndProperty(_accessibilityTraits, accessibilityTraits, accessibilityTraits, accessibilityTraits);
}

- (CGRect)accessibilityFrame
{
  _bridge_prologue_read;
  return _getAccessibilityFromViewOrProperty(_accessibilityFrame, accessibilityFrame);
}

- (void)setAccessibilityFrame:(CGRect)accessibilityFrame
{
  _bridge_prologue_write;
  _setAccessibilityToViewAndProperty(_accessibilityFrame, accessibilityFrame, accessibilityFrame, accessibilityFrame);
}

- (NSString *)accessibilityLanguage
{
  _bridge_prologue_read;
  return _getAccessibilityFromViewOrProperty(_accessibilityLanguage, accessibilityLanguage);
}

- (void)setAccessibilityLanguage:(NSString *)accessibilityLanguage
{
  _bridge_prologue_write;
  _setAccessibilityToViewAndProperty(_accessibilityLanguage, accessibilityLanguage, accessibilityLanguage, accessibilityLanguage);
}

- (BOOL)accessibilityElementsHidden
{
  _bridge_prologue_read;
  return _getAccessibilityFromViewOrProperty(_flags.accessibilityElementsHidden, accessibilityElementsHidden);
}

- (void)setAccessibilityElementsHidden:(BOOL)accessibilityElementsHidden
{
  _bridge_prologue_write;
  _setAccessibilityToViewAndProperty(_flags.accessibilityElementsHidden, accessibilityElementsHidden, accessibilityElementsHidden, accessibilityElementsHidden);
}

- (BOOL)accessibilityViewIsModal
{
  _bridge_prologue_read;
  return _getAccessibilityFromViewOrProperty(_flags.accessibilityViewIsModal, accessibilityViewIsModal);
}

- (void)setAccessibilityViewIsModal:(BOOL)accessibilityViewIsModal
{
  _bridge_prologue_write;
  _setAccessibilityToViewAndProperty(_flags.accessibilityViewIsModal, accessibilityViewIsModal, accessibilityViewIsModal, accessibilityViewIsModal);
}

- (BOOL)shouldGroupAccessibilityChildren
{
  _bridge_prologue_read;
  return _getAccessibilityFromViewOrProperty(_flags.shouldGroupAccessibilityChildren, shouldGroupAccessibilityChildren);
}

- (void)setShouldGroupAccessibilityChildren:(BOOL)shouldGroupAccessibilityChildren
{
  _bridge_prologue_write;
  _setAccessibilityToViewAndProperty(_flags.shouldGroupAccessibilityChildren, shouldGroupAccessibilityChildren, shouldGroupAccessibilityChildren, shouldGroupAccessibilityChildren);
}

- (NSString *)accessibilityIdentifier
{
  _bridge_prologue_read;
  return _getAccessibilityFromViewOrProperty(_accessibilityIdentifier, accessibilityIdentifier);
}

- (void)setAccessibilityIdentifier:(NSString *)accessibilityIdentifier
{
  _bridge_prologue_write;
  _setAccessibilityToViewAndProperty(_accessibilityIdentifier, accessibilityIdentifier, accessibilityIdentifier, accessibilityIdentifier);
}

- (void)setAccessibilityNavigationStyle:(UIAccessibilityNavigationStyle)accessibilityNavigationStyle
{
  _bridge_prologue_write;
  _setAccessibilityToViewAndProperty(_accessibilityNavigationStyle, accessibilityNavigationStyle, accessibilityNavigationStyle, accessibilityNavigationStyle);
}

- (UIAccessibilityNavigationStyle)accessibilityNavigationStyle
{
  _bridge_prologue_read;
  return _getAccessibilityFromViewOrProperty(_accessibilityNavigationStyle, accessibilityNavigationStyle);
}

- (void)setAccessibilityCustomActions:(NSArray *)accessibilityCustomActions
{
  _bridge_prologue_write;
  _setAccessibilityToViewAndProperty(_accessibilityCustomActions, accessibilityCustomActions, accessibilityCustomActions, accessibilityCustomActions);
}

- (NSArray *)accessibilityCustomActions
{
  _bridge_prologue_read;
  return _getAccessibilityFromViewOrProperty(_accessibilityCustomActions, accessibilityCustomActions);
}

#if TARGET_OS_TV
- (void)setAccessibilityHeaderElements:(NSArray *)accessibilityHeaderElements
{
  _bridge_prologue_write;
  _setAccessibilityToViewAndProperty(_accessibilityHeaderElements, accessibilityHeaderElements, accessibilityHeaderElements, accessibilityHeaderElements);
}

- (NSArray *)accessibilityHeaderElements
{
  _bridge_prologue_read;
  return _getAccessibilityFromViewOrProperty(_accessibilityHeaderElements, accessibilityHeaderElements);
}
#endif

- (void)setAccessibilityActivationPoint:(CGPoint)accessibilityActivationPoint
{
  _bridge_prologue_write;
  _setAccessibilityToViewAndProperty(_accessibilityActivationPoint, accessibilityActivationPoint, accessibilityActivationPoint, accessibilityActivationPoint);
}

- (CGPoint)accessibilityActivationPoint
{
  _bridge_prologue_read;
  return _getAccessibilityFromViewOrProperty(_accessibilityActivationPoint, accessibilityActivationPoint);
}

- (void)setAccessibilityPath:(UIBezierPath *)accessibilityPath
{
  _bridge_prologue_write;
  _setAccessibilityToViewAndProperty(_accessibilityPath, accessibilityPath, accessibilityPath, accessibilityPath);
}

- (UIBezierPath *)accessibilityPath
{
  _bridge_prologue_read;
  return _getAccessibilityFromViewOrProperty(_accessibilityPath, accessibilityPath);
}

- (NSInteger)accessibilityElementCount
{
  _bridge_prologue_read;
  return _getFromViewOnly(accessibilityElementCount);
}

@end


#pragma mark - ASAsyncTransactionContainer

@implementation ASDisplayNode (ASAsyncTransactionContainer)

- (BOOL)asyncdisplaykit_isAsyncTransactionContainer
{
  _bridge_prologue_read;
  return _getFromViewOrLayer(asyncdisplaykit_isAsyncTransactionContainer, asyncdisplaykit_isAsyncTransactionContainer);
}

- (void)asyncdisplaykit_setAsyncTransactionContainer:(BOOL)asyncTransactionContainer
{
  _bridge_prologue_write;
  _setToViewOrLayer(asyncdisplaykit_asyncTransactionContainer, asyncTransactionContainer, asyncdisplaykit_asyncTransactionContainer, asyncTransactionContainer);
}

- (ASAsyncTransactionContainerState)asyncdisplaykit_asyncTransactionContainerState
{
  ASDisplayNodeAssertMainThread();
  return [_layer asyncdisplaykit_asyncTransactionContainerState];
}

- (void)asyncdisplaykit_cancelAsyncTransactions
{
  ASDisplayNodeAssertMainThread();
  [_layer asyncdisplaykit_cancelAsyncTransactions];
}

- (void)asyncdisplaykit_setCurrentAsyncTransaction:(_ASAsyncTransaction *)transaction
{
  _layer.asyncdisplaykit_currentAsyncTransaction = transaction;
}

- (_ASAsyncTransaction *)asyncdisplaykit_currentAsyncTransaction
{
  return _layer.asyncdisplaykit_currentAsyncTransaction;
}

@end
