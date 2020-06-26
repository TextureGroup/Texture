//
//  ASDisplayNode+FrameworkPrivate.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

//
// The following methods are ONLY for use by _ASDisplayLayer, _ASDisplayView, and ASDisplayNode.
// These methods must never be called or overridden by other classes.
//

#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/ASDisplayNode.h>
#import <AsyncDisplayKit/ASObjectDescriptionHelpers.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ASInterfaceStateDelegate;

/**
 Hierarchy state is propagated from nodes to all of their children when certain behaviors are required from the subtree.
 Examples include rasterization and external driving of the .interfaceState property.
 By passing this information explicitly, performance is optimized by avoiding iteration up the supernode chain.
 Lastly, this avoidance of supernode traversal protects against the possibility of deadlocks when a supernode is
 simultaneously attempting to materialize views / layers for its subtree (as many related methods require property locking)
 
 Note: as the hierarchy deepens, more state properties may be enabled.  However, state properties may never be disabled /
 cancelled below the point they are enabled.  They continue to the leaves of the hierarchy.
 */

typedef NS_OPTIONS(unsigned char, ASHierarchyState)
{
  /** The node may or may not have a supernode, but no supernode has a special hierarchy-influencing option enabled. */
  ASHierarchyStateNormal                  = 0,
  /** The node has a supernode with .rasterizesSubtree = YES.
      Note: the root node of the rasterized subtree (the one with the property set on it) will NOT have this state set. */
  ASHierarchyStateRasterized              = 1 << 0,
  /** The node or one of its supernodes is managed by a class like ASRangeController.  Most commonly, these nodes are
      ASCellNode objects or a subnode of one, and are used in ASTableView or ASCollectionView.
      These nodes also receive regular updates to the .interfaceState property with more detailed status information. */
  ASHierarchyStateRangeManaged            = 1 << 1,
  /** Down-propagated version of _flags.visibilityNotificationsDisabled.  This flag is very rarely set, but by having it
      locally available to nodes, they do not have to walk up supernodes at the critical points it is checked. */
  ASHierarchyStateTransitioningSupernodes = 1 << 2,
  /** One of the supernodes of this node is performing a transition.
      Any layout calculated during this state should not be applied immediately, but pending until later. */
  ASHierarchyStateLayoutPending           = 1 << 3,
};

ASDISPLAYNODE_INLINE BOOL ASHierarchyStateIncludesLayoutPending(ASHierarchyState hierarchyState)
{
  return ((hierarchyState & ASHierarchyStateLayoutPending) == ASHierarchyStateLayoutPending);
}

ASDISPLAYNODE_INLINE BOOL ASHierarchyStateIncludesRangeManaged(ASHierarchyState hierarchyState)
{
  return ((hierarchyState & ASHierarchyStateRangeManaged) == ASHierarchyStateRangeManaged);
}

ASDISPLAYNODE_INLINE BOOL ASHierarchyStateIncludesRasterized(ASHierarchyState hierarchyState)
{
	return ((hierarchyState & ASHierarchyStateRasterized) == ASHierarchyStateRasterized);
}

ASDISPLAYNODE_INLINE BOOL ASHierarchyStateIncludesTransitioningSupernodes(ASHierarchyState hierarchyState)
{
	return ((hierarchyState & ASHierarchyStateTransitioningSupernodes) == ASHierarchyStateTransitioningSupernodes);
}

__unused static NSString * _Nonnull NSStringFromASHierarchyState(ASHierarchyState hierarchyState)
{
	NSMutableArray *states = [NSMutableArray array];
	if (hierarchyState == ASHierarchyStateNormal) {
		[states addObject:@"Normal"];
	}
	if (ASHierarchyStateIncludesRangeManaged(hierarchyState)) {
		[states addObject:@"RangeManaged"];
	}
	if (ASHierarchyStateIncludesLayoutPending(hierarchyState)) {
		[states addObject:@"LayoutPending"];
	}
	if (ASHierarchyStateIncludesRasterized(hierarchyState)) {
		[states addObject:@"Rasterized"];
	}
	if (ASHierarchyStateIncludesTransitioningSupernodes(hierarchyState)) {
		[states addObject:@"TransitioningSupernodes"];
	}
	return [NSString stringWithFormat:@"{ %@ }", [states componentsJoinedByString:@" | "]];
}

#define HIERARCHY_STATE_DELTA(Name) ({ \
  if ((oldState & ASHierarchyState##Name) != (newState & ASHierarchyState##Name)) { \
    [changes appendFormat:@"%c%s ", (newState & ASHierarchyState##Name ? '+' : '-'), #Name]; \
  } \
})

__unused static NSString * _Nonnull NSStringFromASHierarchyStateChange(ASHierarchyState oldState, ASHierarchyState newState)
{
  if (oldState == newState) {
    return @"{ }";
  }

  NSMutableString *changes = [NSMutableString stringWithString:@"{ "];
  HIERARCHY_STATE_DELTA(Rasterized);
  HIERARCHY_STATE_DELTA(RangeManaged);
  HIERARCHY_STATE_DELTA(TransitioningSupernodes);
  HIERARCHY_STATE_DELTA(LayoutPending);
  [changes appendString:@"}"];
  return changes;
}

#undef HIERARCHY_STATE_DELTA

@interface ASDisplayNode () <ASDescriptionProvider, ASDebugDescriptionProvider>

// The view class to use when creating a new display node instance. Defaults to _ASDisplayView.
+ (Class)viewClass;

// Thread safe way to access the bounds of the node
@property (nonatomic) CGRect threadSafeBounds;

// Returns the bounds of the node without reaching the view or layer
- (CGRect)_locked_threadSafeBounds;

// The -pendingInterfaceState holds the value that will be applied to -interfaceState by the
// ASCATransactionQueue. If already applied, it matches -interfaceState. Thread-safe access.
@property (nonatomic, readonly) ASInterfaceState pendingInterfaceState;

// These methods are recursive, and either union or remove the provided interfaceState to all sub-elements.
- (void)enterInterfaceState:(ASInterfaceState)interfaceState;
- (void)exitInterfaceState:(ASInterfaceState)interfaceState;
- (void)recursivelySetInterfaceState:(ASInterfaceState)interfaceState;

// These methods are recursive, and either union or remove the provided hierarchyState to all sub-elements.
- (void)enterHierarchyState:(ASHierarchyState)hierarchyState;
- (void)exitHierarchyState:(ASHierarchyState)hierarchyState;

// Changed before calling willEnterHierarchy / didExitHierarchy.
@property (readonly, getter = isInHierarchy) BOOL inHierarchy;
// Call willEnterHierarchy if necessary and set inHierarchy = YES if visibility notifications are enabled on all of its parents
- (void)__enterHierarchy;
// Call didExitHierarchy if necessary and set inHierarchy = NO if visibility notifications are enabled on all of its parents
- (void)__exitHierarchy;

/**
 * @abstract Returns the Hierarchy State of the node.
 *
 * @return The current ASHierarchyState of the node, indicating whether it is rasterized or managed by a range controller.
 *
 * @see ASInterfaceState
 */
@property (nonatomic) ASHierarchyState hierarchyState;

/**
 * Represent the current custom action in representation for the node
 */
@property (nonatomic, weak) UIAccessibilityCustomAction *accessibilityCustomAction;

/**
 * @abstract Return if the node is range managed or not
 *
 * @discussion Currently only set interface state on nodes in table and collection views. For other nodes, if they are
 * in the hierarchy we enable all ASInterfaceState types with `ASInterfaceStateInHierarchy`, otherwise `None`.
 */
- (BOOL)supportsRangeManagedInterfaceState;

- (BOOL)_locked_displaysAsynchronously;

// The two methods below will eventually be exposed, but their names are subject to change.
/**
 * @abstract Ensure that all rendering is complete for this node and its descendants.
 *
 * @discussion Calling this method on the main thread after a node is added to the view hierarchy will ensure that
 * placeholder states are never visible to the user.  It is used by ASTableView, ASCollectionView, and ASDKViewController
 * to implement their respective ".neverShowPlaceholders" option.
 *
 * If all nodes have layer.contents set and/or their layer does not have -needsDisplay set, the method will return immediately.
 *
 * This method is capable of handling a mixed set of nodes, with some not having started display, some in progress on an
 * asynchronous display operation, and some already finished.
 *
 * In order to guarantee against deadlocks, this method should only be called on the main thread.
 * It may block on the private queue, [_ASDisplayLayer displayQueue]
 */
- (void)recursivelyEnsureDisplaySynchronously:(BOOL)synchronously;

/**
 * @abstract Calls -didExitPreloadState on the receiver and its subnode hierarchy.
 *
 * @discussion Clears any memory-intensive preloaded content.
 * This method is used to notify the node that it should purge any content that is both expensive to fetch and to
 * retain in memory.
 *
 * @see [ASDisplayNode(Subclassing) didExitPreloadState] and [ASDisplayNode(Subclassing) didEnterPreloadState]
 */
- (void)recursivelyClearPreloadedData;

/**
 * @abstract Calls -didEnterPreloadState on the receiver and its subnode hierarchy.
 *
 * @discussion Fetches content from remote sources for the current node and all subnodes.
 *
 * @see [ASDisplayNode(Subclassing) didEnterPreloadState] and [ASDisplayNode(Subclassing) didExitPreloadState]
 */
- (void)recursivelyPreload;

/**
 * @abstract Triggers a recursive call to -didEnterPreloadState when the node has an interfaceState of ASInterfaceStatePreload
 */
- (void)setNeedsPreload;

/**
 * @abstract Allows a node to bypass all ensureDisplay passes.  Defaults to NO.
 *
 * @discussion Nodes that are expensive to draw and expected to have placeholder even with
 * .neverShowPlaceholders enabled should set this to YES.
 *
 * ASImageNode uses the default of NO, as it is often used for UI images that are expected to synchronize with ensureDisplay.
 *
 * ASNetworkImageNode and ASMultiplexImageNode set this to YES, because they load data from a database or server,
 * and are expected to support a placeholder state given that display is often blocked on slow data fetching.
 */
@property BOOL shouldBypassEnsureDisplay;

/**
 * @abstract Checks whether a node should be scheduled for display, considering its current and new interface states.
 */
- (BOOL)shouldScheduleDisplayWithNewInterfaceState:(ASInterfaceState)newInterfaceState;

/**
 * @abstract safeAreaInsets will fallback to this value if the corresponding UIKit property is not available
 * (due to an old iOS version).
 *
 * @discussion This should be set by the owning view controller based on it's layout guides.
 * If this is not a view controllet's node the value will be calculated automatically by the parent node.
 */
@property (nonatomic) UIEdgeInsets fallbackSafeAreaInsets;

/**
 * @abstract Indicates if this node is a view controller's root node. Defaults to NO.
 *
 * @discussion Set to YES in -[ASDKViewController initWithNode:].
 *
 * YES here only means that this node is used as an ASDKViewController node. It doesn't mean that this node is a root of
 * ASDisplayNode hierarchy, e.g. when its view controller is parented by another ASDKViewController.
 */
@property (nonatomic, getter=isViewControllerRoot) BOOL viewControllerRoot;

@end


@interface ASDisplayNode (ASLayoutInternal)

/**
 * @abstract Informs the root node that the intrinsic size of the receiver is no longer valid.
 *
 * @discussion The size of a root node is determined by each subnode. Calling invalidateSize will let the root node know
 * that the intrinsic size of the receiver node is no longer valid and a resizing of the root node needs to happen.
 */
- (void)_u_setNeedsLayoutFromAbove;

/**
 * @abstract Subclass hook for nodes that are acting as root nodes. This method is called if one of the subnodes
 * size is invalidated and may need to result in a different size as the current calculated size.
 */
- (void)_rootNodeDidInvalidateSize;

/**
 * This method will confirm that the layout is up to date (and update if needed).
 * Importantly, it will also APPLY the layout to all of our subnodes if (unless parent is transitioning).
 */
- (void)_u_measureNodeWithBoundsIfNecessary:(CGRect)bounds;

/**
 * Layout all of the subnodes based on the sublayouts
 */
- (void)_layoutSublayouts;

@end

@interface ASDisplayNode (ASLayoutTransitionInternal)

/**
 * If one or multiple layout transitions are in flight this methods returns if the current layout transition that
 * happens in in this particular thread was invalidated through another thread is starting a transition for this node
 */
- (BOOL)_isLayoutTransitionInvalid;

/**
 * Same as @c -_isLayoutTransitionInvalid but must be called with the node's instance lock held.
 */
- (BOOL)_locked_isLayoutTransitionInvalid;

/**
 * Internal method that can be overriden by subclasses to add specific behavior after the measurement of a layout
 * transition did finish.
 */
- (void)_layoutTransitionMeasurementDidFinish;

/**
 * Informs the node that the pending layout transition did complete
 */
- (void)_completePendingLayoutTransition;

/**
 * Called if the pending layout transition did complete
 */
- (void)_pendingLayoutTransitionDidComplete;

@end

/**
 * Defines interactive accessibility traits which will be exposed as UIAccessibilityCustomActions
 * for nodes within nodes that have isAccessibilityContainer is YES
 */
NS_INLINE UIAccessibilityTraits ASInteractiveAccessibilityTraitsMask() {
  return UIAccessibilityTraitLink | UIAccessibilityTraitKeyboardKey | UIAccessibilityTraitButton;
}

@interface ASDisplayNode (AccessibilityInternal)
- (NSArray *)accessibilityElements;
@end;

@interface UIView (ASDisplayNodeInternal)
@property (nullable, weak) ASDisplayNode *asyncdisplaykit_node;
@end

@interface CALayer (ASDisplayNodeInternal)
@property (nullable, weak) ASDisplayNode *asyncdisplaykit_node;
@end

NS_ASSUME_NONNULL_END
