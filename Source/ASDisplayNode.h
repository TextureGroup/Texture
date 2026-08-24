//
//  ASDisplayNode.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#pragma once

#import <UIKit/UIKit.h>

#import <AsyncDisplayKit/_ASAsyncTransactionContainer.h>
#import <AsyncDisplayKit/ASBaseDefines.h>
#import <AsyncDisplayKit/ASDimension.h>
#import <AsyncDisplayKit/ASDisplayNode+InterfaceState.h>
#import <AsyncDisplayKit/ASAsciiArtBoxCreator.h>
#import <AsyncDisplayKit/ASObjectDescriptionHelpers.h>
#import <AsyncDisplayKit/ASLayoutElement.h>
#import <AsyncDisplayKit/ASLocking.h>

NS_ASSUME_NONNULL_BEGIN

#define ASDisplayNodeLoggingEnabled 0

#ifndef AS_MAX_INTERFACE_STATE_DELEGATES
#define AS_MAX_INTERFACE_STATE_DELEGATES 4
#endif

@class ASDisplayNode;
@protocol ASContextTransitioning;

/**
 * UIView creation block. Used to create the backing view of a new display node.
 */
typedef UIView * _Nonnull(^ASDisplayNodeViewBlock)(void);

/**
 * UIView creation block. Used to create the backing view of a new display node.
 */
typedef UIViewController * _Nonnull(^ASDisplayNodeViewControllerBlock)(void);

/**
 * CALayer creation block. Used to create the backing layer of a new display node.
 */
typedef CALayer * _Nonnull(^ASDisplayNodeLayerBlock)(void);

/**
 * ASDisplayNode loaded callback block. This block is called BEFORE the -didLoad method and is always called on the main thread.
 */
typedef void (^ASDisplayNodeDidLoadBlock)(__kindof ASDisplayNode * node);

/**
 * ASDisplayNode will / did render node content in context.
 */
typedef void (^ASDisplayNodeContextModifier)(CGContextRef context, id _Nullable drawParameters);

/**
 * ASDisplayNode layout spec block. This block can be used instead of implementing layoutSpecThatFits: in subclass
 */
typedef ASLayoutSpec * _Nonnull(^ASLayoutSpecBlock)(__kindof ASDisplayNode *node, ASSizeRange constrainedSize);

/**
 * AsyncDisplayKit non-fatal error block. This block can be used for handling non-fatal errors. Useful for reporting
 * errors that happens in production.
 */
typedef void (^ASDisplayNodeNonFatalErrorBlock)(NSError *error);

typedef NS_ENUM(unsigned char, ASCornerRoundingType) {
  ASCornerRoundingTypeDefaultSlowCALayer,
  ASCornerRoundingTypePrecomposited,
  ASCornerRoundingTypeClipping
};

/**
 * Default drawing priority for display node
 */
ASDK_EXTERN NSInteger const ASDefaultDrawingPriority;

/**
 * An `ASDisplayNode` is an abstraction over `UIView` and `CALayer` that allows you to perform calculations about a view
 * hierarchy off the main thread, and could do rendering off the main thread as well.
 *
 * The node API is designed to be as similar as possible to `UIView`. See the README for examples.
 *
 * ## Subclassing
 *
 * `ASDisplayNode` can be subclassed to create a new UI element. The subclass header `ASDisplayNode+Subclasses` provides
 * necessary declarations and conveniences.
 *
 * Commons reasons to subclass includes making a `UIView` property available and receiving a callback after async
 * display.
 */

@interface ASDisplayNode : NSObject <ASLocking> {
@public
  /**
   * The `_displayNodeContext` ivar is unused by `Texture`, but provided to enable advanced clients to make powerful extensions to base class functionality.
   * For example, `_displayNodeContext` can be used to implement category methods on `ASDisplayNode` that add functionality to all node subclass types.
   * Code demonstrating this technique can be found in the `CatDealsCollectionView` example.
   */
  void *_displayNodeContext;
}


/** # Initializing a node object */


/** 
 * Designated initializer.
 *
 * - Returns: An `ASDisplayNode` instance whose view will be a subclass that enables asynchronous rendering, and passes
 * through `-layout` and touch handling methods.
 */
- (instancetype)init NS_DESIGNATED_INITIALIZER;


/**
 * Alternative initializer with a block to create the backing view.
 *
 * - Parameter viewBlock: The block that will be used to create the backing view.
 *
 * - Returns: An `ASDisplayNode` instance that loads its view with the given block that is guaranteed to run on the main
 * queue. The view will render synchronously and `-layout` and touch handling methods on the node will not be called.
 */
- (instancetype)initWithViewBlock:(NS_SWIFT_UI_ACTOR ASDisplayNodeViewBlock)viewBlock;

/**
 * Alternative initializer with a block to create the backing view.
 *
 * - Parameter viewBlock: The block that will be used to create the backing view.
 * - Parameter didLoadBlock: The block that will be called after the view created by the viewBlock is loaded
 *
 * - Returns: An `ASDisplayNode` instance that loads its view with the given block that is guaranteed to run on the main
 * queue. The view will render synchronously and `-layout` and touch handling methods on the node will not be called.
 */
- (instancetype)initWithViewBlock:(NS_SWIFT_UI_ACTOR ASDisplayNodeViewBlock)viewBlock
                     didLoadBlock:(nullable NS_SWIFT_UI_ACTOR ASDisplayNodeDidLoadBlock)didLoadBlock;

/**
 * Alternative initializer with a block to create the backing layer.
 *
 * - Parameter layerBlock: The block that will be used to create the backing layer.
 *
 * - Returns: An `ASDisplayNode` instance that loads its layer with the given block that is guaranteed to run on the main
 * queue. The layer will render synchronously and `-layout` and touch handling methods on the node will not be called.
 */
- (instancetype)initWithLayerBlock:(NS_SWIFT_UI_ACTOR ASDisplayNodeLayerBlock)layerBlock;

/**
 * Alternative initializer with a block to create the backing layer.
 *
 * - Parameter layerBlock: The block that will be used to create the backing layer.
 * - Parameter didLoadBlock: The block that will be called after the layer created by the layerBlock is loaded
 *
 * - Returns: An `ASDisplayNode` instance that loads its layer with the given block that is guaranteed to run on the main
 * queue. The layer will render synchronously and `-layout` and touch handling methods on the node will not be called.
 */
- (instancetype)initWithLayerBlock:(NS_SWIFT_UI_ACTOR ASDisplayNodeLayerBlock)layerBlock
                      didLoadBlock:(nullable NS_SWIFT_UI_ACTOR  ASDisplayNodeDidLoadBlock)didLoadBlock;

/**
 * Add a block of work to be performed on the main thread when the node's view or layer is loaded. Thread safe.
 * - Warning: Be careful not to retain self in `body`. Change the block parameter list to `^(MYCustomNode *self) {}` if you
 *   want to shadow self (e.g. if calling this during `init`).
 *
 * - Parameter body: The work to be performed when the node is loaded.
 *
 * - Precondition: The node is not already loaded.
 */
- (void)onDidLoad:(NS_SWIFT_UI_ACTOR ASDisplayNodeDidLoadBlock)body;

/**
 * Set the block that should be used to load this node's view.
 *
 * - Parameter viewBlock: The block that creates a view for this node.
 *
 * - Precondition: The node is not yet loaded.
 *
 * - Note: You will usually NOT call this. See the limitations documented in `initWithViewBlock:`
 */
- (void)setViewBlock:(NS_SWIFT_UI_ACTOR ASDisplayNodeViewBlock)viewBlock;

/**
 * Set the block that should be used to load this node's layer.
 *
 * - Parameter layerBlock: The block that creates a layer for this node.
 *
 * - Precondition: The node is not yet loaded.
 *
 * - Note: You will usually NOT call this. See the limitations documented in `initWithLayerBlock:`
 */
- (void)setLayerBlock:(NS_SWIFT_UI_ACTOR ASDisplayNodeLayerBlock)layerBlock;

/** 
 * Returns whether the node is synchronous.
 *
 * - Returns: `NO` if the node wraps a `_ASDisplayView`, `YES` otherwise.
 */
@property (readonly, getter=isSynchronous) BOOL synchronous;


/** # Getting view and layer */


/** 
 * Returns a view.
 *
 * The view property is lazily initialized, similar to `UIViewController`.
 * To go the other direction, use `ASViewToDisplayNode()` in `ASDisplayNodeExtras.h`.
 *
 * - Warning: The first access to it must be on the main thread, and should only be used on the main thread thereafter as 
 * well.
 */
@property (readonly) UIView *view;

/** 
 * Returns whether a node's backing view or layer is loaded.
 *
 * - Returns: `YES` if a view is loaded, or if `layerBacked` is `YES` and layer is not `nil`; `NO` otherwise.
 */
@property (readonly, getter=isNodeLoaded) BOOL nodeLoaded;

/** 
 * Returns whether the node rely on a layer instead of a view.
 *
 * - Returns: `YES` if the node rely on a layer, `NO` otherwise.
 */
@property (getter=isLayerBacked) BOOL layerBacked;

/** 
 * Returns a layer.
 *
 * The layer property is lazily initialized, similar to the view property.
 * To go the other direction, use `ASLayerToDisplayNode()` in `ASDisplayNodeExtras.h`.
 *
 * - Warning: The first access to it must be on the main thread, and should only be used on the main thread thereafter as 
 * well.
 */
@property (readonly) CALayer * layer;

/**
 * Indicates whether the node is currently visible within a window or not.
 *
 * When a node is considered visible, it means that it is at least partially within the visible area of a window.
 *
 * - Returns: `YES` if the node is currently visible within a window, otherwise, `NO`.
 *
 * - SeeAlso: `didEnterVisibleState` and `didExitVisibleState`
 */
@property (readonly, getter=isVisible) BOOL visible;

/**
 * Indicates whether the node is currently in the preloading interface state.
 *
 * - Returns: `YES` if the node is in the preloading interface state.
 *
 * - SeeAlso: `didEnterPreloadState` and `didExitPreloadState`
 */
@property (readonly, getter=isInPreloadState) BOOL inPreloadState;

/**
 * Indicates whether the node is currently in the displaying interface state.
 *
 * - Returns: `YES` if the node is in the displaying interface state.
 *
 * - SeeAlso: `didEnterDisplayState` and `didExitDisplayState`
 */
@property (readonly, getter=isInDisplayState) BOOL inDisplayState;

/**
 * Returns the Interface State of the node.
 *
 * - Returns: The current `ASInterfaceState` of the node, indicating whether it is visible and other situational properties.
 *
 * - SeeAlso: `ASInterfaceState`
 */
@property (readonly) ASInterfaceState interfaceState;

/**
 * Adds a delegate to receive notifications on interfaceState changes.
 *
 * - Warning: This must be called from the main thread.
 * There is a hard limit on the number of delegates a node can have; see
 * `AS_MAX_INTERFACE_STATE_DELEGATES` above.
 *
 * - SeeAlso: `ASInterfaceState`
 */
- (void)addInterfaceStateDelegate:(id <ASInterfaceStateDelegate>)interfaceStateDelegate NS_SWIFT_UI_ACTOR;

/**
 * Removes a delegate from receiving notifications on interfaceState changes.
 *
 * - Warning: This must be called from the main thread.
 *
 * - SeeAlso: `ASInterfaceState`
 */
- (void)removeInterfaceStateDelegate:(id <ASInterfaceStateDelegate>)interfaceStateDelegate NS_SWIFT_UI_ACTOR;

/**
 * Class property that allows to set a block that can be called on non-fatal errors. This
 * property can be useful for cases when Async Display Kit can recover from an abnormal behavior, but
 * still gives the opportunity to use a reporting mechanism to catch occurrences in production. In
 * development, Async Display Kit will assert instead of calling this block.
 *
 * - Warning: This method is not thread-safe.
 */
@property (class, nonatomic) ASDisplayNodeNonFatalErrorBlock nonFatalErrorBlock;


/** # Managing the nodes hierarchy */


/** 
 * Add a node as a subnode to this node.
 *
 * - Parameter subnode: The node to be added.
 *
 * The subnode's view will automatically be added to this node's view, lazily if the views are not created 
 * yet.
 */
- (void)addSubnode:(ASDisplayNode *)subnode;

/** 
 * Insert a subnode before a given subnode in the list.
 *
 * - Parameter subnode: The node to insert below another node.
 * - Parameter  below: The sibling node that will be above the inserted node.
 *
 * If the views are loaded, the subnode's view will be inserted below the given node's view in the hierarchy
 * even if there are other non-displaynode views.
 */
- (void)insertSubnode:(ASDisplayNode *)subnode belowSubnode:(ASDisplayNode *)below;

/** 
 * Insert a subnode after a given subnode in the list.
 *
 * - Parameter subnode: The node to insert below another node.
 * - Parameter above: The sibling node that will be behind the inserted node.
 *
 * If the views are loaded, the subnode's view will be inserted above the given node's view in the hierarchy
 * even if there are other non-displaynode views.
 */
- (void)insertSubnode:(ASDisplayNode *)subnode aboveSubnode:(ASDisplayNode *)above;

/** 
 * Insert a subnode at a given index in subnodes.
 *
 * - Parameter subnode: The node to insert.
 * - Parameter idx: The index in the array of the subnodes property at which to insert the node. Subnodes indices start at 0
 * and cannot be greater than the number of subnodes.
 *
 * If this node's view is loaded, `ASDisplayNode` insert the subnode's view after the subnode at index - 1's
 * view even if there are other non-displaynode views.
 */
- (void)insertSubnode:(ASDisplayNode *)subnode atIndex:(NSInteger)idx;

/** 
 * Replace subnode with replacementSubnode.
 *
 * - Parameter subnode: A subnode of self.
 * - Parameter replacementSubnode: A node with which to replace subnode.
 *
 * Should both subnode and replacementSubnode already be subnodes of self, subnode is removed and 
 * replacementSubnode inserted in its place.
 * - Note: If subnode is not a subnode of self, this method will throw an exception.
 * If replacementSubnode is nil, this method will throw an exception
 */
- (void)replaceSubnode:(ASDisplayNode *)subnode withSubnode:(ASDisplayNode *)replacementSubnode;

/** 
 * Remove this node from its supernode.
 *
 * The node's view will be automatically removed from the supernode's view.
 */
- (void)removeFromSupernode;

/** 
 * The receiver's immediate subnodes.
 */
@property (nullable, readonly, copy) NSArray<ASDisplayNode *> *subnodes;

/** 
 * The receiver's supernode.
 */
@property (nullable, readonly, weak) ASDisplayNode *supernode;


/** # Drawing and Updating the View */


/** 
 * Whether this node's view performs asynchronous rendering.
 *
 * - Returns: `YES`, except for synchronous views (ie, those created with `-initWithViewBlock:` /
 * `-initWithLayerBlock:`), which are always `NO`.
 *
 * If this flag is set, then the node will participate in the current `asyncdisplaykit_async_transaction` and
 * do its rendering on the displayQueue instead of the main thread.
 *
 * Asynchronous rendering proceeds as follows:
 *
 * When the view is initially added to the hierarchy, it has `-needsDisplay` true.
 * After layout, Core Animation will call `-display` on the `_ASDisplayLayer`
 * `-display` enqueues a rendering operation on the displayQueue
 * When the render block executes, it calls the delegate display method (`-drawRect:...` or `-display`)
 * The delegate provides contents via this method and an operation is added to the `asyncdisplaykit_async_transaction`
 * Once all rendering is complete for the current `asyncdisplaykit_async_transaction`,
 * the completion for the block sets the contents on all of the layers in the same frame
 *
 * If asynchronous rendering is disabled:
 *
 * When the view is initially added to the hierarchy, it has `-needsDisplay` true.
 * After layout, Core Animation will call `-display` on the `_ASDisplayLayer`
 * `-display` calls  delegate display method (`-drawRect:...` or `-display`) immediately
 * `-display` sets the layer contents immediately with the result
 *
 * - Note: this has nothing to do with `-[CALayer drawsAsynchronously]`.
 */
@property BOOL displaysAsynchronously;

/** 
 * Prevent the node's layer from displaying.
 *
 * A subclass may check this flag during `-display` or `-drawInContext:` to cancel a display that is already in
 * progress.
 *
 * - Default: `NO`.
 *
 * - Note: Does not control display for any child or descendant nodes; for that, use
 * `-recursivelySetDisplaySuspended:`.
 * If a `setNeedsDisplay` occurs while `displaySuspended` is `YES`, and `displaySuspended` is set to `NO`, then the
 * layer will be automatically displayed.
 */
@property BOOL displaySuspended;

/**
 * Whether size changes should be animated.
 *
 * - Default: `YES`.
 */
@property BOOL shouldAnimateSizeChanges;

/** 
 * Prevent the node and its descendants' layer from displaying.
 *
 * - Parameter flag: `YES` if display should be prevented or cancelled; `NO` otherwise.
 *
 * - SeeAlso: `displaySuspended`
 */
- (void)recursivelySetDisplaySuspended:(BOOL)flag;

/**
 * Calls `-clearContents` on the receiver and its subnode hierarchy.
 *
 * Clears backing stores and other memory-intensive intermediates.
 * If the node is removed from a visible hierarchy and then re-added, it will automatically trigger a new asynchronous display,
 * as long as `displaySuspended` is not set.
 * If the node remains in the hierarchy throughout, `-setNeedsDisplay` is required to trigger a new asynchronous display.
 *
 * - SeeAlso: `displaySuspended` and `setNeedsDisplay`
 */
- (void)recursivelyClearContents;

/**
 * Toggle displaying a placeholder over the node that covers content until the node and all subnodes are
 * displayed.
 *
 * - Default: `NO`.
 */
@property BOOL placeholderEnabled;

/**
 * Set the time it takes to fade out the placeholder when a node's contents are finished displaying.
 *
 * - Default: `0.0`.
 */
@property NSTimeInterval placeholderFadeDuration;

/**
 * Determines drawing priority of the node. Nodes with higher priority will be drawn earlier.
 *
 * - Default: `ASDefaultDrawingPriority`.
 *
 * - Note: There may be multiple drawing threads, and some of them may
 * decide to perform operations in queued order (regardless of `drawingPriority`)
 */
@property NSInteger drawingPriority;


/** # Hit Testing */


/** 
 * Bounds insets for hit testing.
 *
 * When set to a non-zero inset, increases the bounds for hit testing to make it easier to tap or perform
 * gestures on this node.
 *
 * - Default: `UIEdgeInsetsZero`.
 *
 * - Note: This affects the default implementation of `-hitTest` and `-pointInside`, so subclasses should call super if you override
 * it and want `hitTestSlop` applied.
 */
@property UIEdgeInsets hitTestSlop;

/** 
 * Returns a Boolean value indicating whether the receiver contains the specified point.
 *
 * Includes the "slop" factor specified with `hitTestSlop`.
 *
 * - Parameter point: A point that is in the receiver's local coordinate system (bounds).
 * - Parameter event: The event that warranted a call to this method.
 *
 * - Returns: `YES` if point is inside the receiver's bounds; otherwise, `NO`.
 */
- (BOOL)pointInside:(CGPoint)point withEvent:(nullable UIEvent *)event AS_WARN_UNUSED_RESULT;


/** # Converting Between View Coordinate Systems */


/** 
 * Converts a point from the receiver's coordinate system to that of the specified node.
 *
 * - Parameter point: A point specified in the local coordinate system (bounds) of the receiver.
 * - Parameter node: The node into whose coordinate system point is to be converted.
 *
 * - Returns: The point converted to the coordinate system of node.
 */
- (CGPoint)convertPoint:(CGPoint)point toNode:(nullable ASDisplayNode *)node AS_WARN_UNUSED_RESULT;

/** 
 * Converts a point from the coordinate system of a given node to that of the receiver.
 *
 * - Parameter point: A point specified in the local coordinate system (bounds) of node.
 * - Parameter node: The node with point in its coordinate system.
 *
 * - Returns: The point converted to the local coordinate system (bounds) of the receiver.
 */
- (CGPoint)convertPoint:(CGPoint)point fromNode:(nullable ASDisplayNode *)node AS_WARN_UNUSED_RESULT;

/** 
 * Converts a rectangle from the receiver's coordinate system to that of another view.
 *
 * - Parameter rect: A rectangle specified in the local coordinate system (bounds) of the receiver.
 * - Parameter node: The node that is the target of the conversion operation.
 *
 * - Returns: The converted rectangle.
 */
- (CGRect)convertRect:(CGRect)rect toNode:(nullable ASDisplayNode *)node AS_WARN_UNUSED_RESULT;

/** 
 * Converts a rectangle from the coordinate system of another node to that of the receiver.
 *
 * - Parameter rect: A rectangle specified in the local coordinate system (bounds) of node.
 * - Parameter node: The node with rect in its coordinate system.
 *
 * - Returns: The converted rectangle.
 */
- (CGRect)convertRect:(CGRect)rect fromNode:(nullable ASDisplayNode *)node AS_WARN_UNUSED_RESULT;

/**
 * Whether or not the node would support having `.layerBacked = YES`.
 */
@property (readonly) BOOL supportsLayerBacking;

/**
 * Whether or not the node layout should be automatically updated when it receives `safeAreaInsetsDidChange`.
 *
 * - Default: `NO`.
 */
@property BOOL automaticallyRelayoutOnSafeAreaChanges;

/**
 * Whether or not the node layout should be automatically updated when it receives `layoutMarginsDidChange`.
 *
 * - Default: `NO`.
 */
@property BOOL automaticallyRelayoutOnLayoutMarginsChanges;

@end

/**
 * Convenience methods for debugging.
 */
@interface ASDisplayNode (Debugging) <ASDebugNameProvider>

/**
 * Whether or not `ASDisplayNode` instances should store their unflattened layouts.
 *
 * The layout can be accessed via `-unflattenedCalculatedLayout`.
 *
 * Flattened layouts use less memory and are faster to lookup. On the other hand, unflattened layouts are useful for debugging
 * because they preserve original information.
 *
 * - Default: `NO`.
 */
@property (class) BOOL shouldStoreUnflattenedLayouts;

@property (nullable, readonly) ASLayout *unflattenedCalculatedLayout;

/**
 * Return a description of the node hierarchy.
 *
 * For debugging: (lldb) po `[node displayNodeRecursiveDescription]`
 */
- (NSString *)displayNodeRecursiveDescription AS_WARN_UNUSED_RESULT;

/**
 * A detailed description of this node's layout state. This is useful when debugging.
 */
@property (copy, readonly) NSString *detailedLayoutDescription;

@end

/**
 * ## UIView bridge
 *
 * `ASDisplayNode` provides thread-safe access to most of `UIView` and `CALayer` properties and methods, traditionally unsafe.
 *
 * Using them will not cause the actual view/layer to be created, and will be applied when it is created (when the view 
 * or layer property is accessed).
 *
 * - NOTE: After the view or layer is created, the properties pass through to the view or layer directly and must be called on the main thread.
 *
 * See [UIView](https://developer.apple.com/documentation/uikit/uiview?language=objc) and [CALayer](https://developer.apple.com/documentation/quartzcore/calayer?language=objc) for documentation on these common properties.
 */
@interface ASDisplayNode (UIViewBridge)

/**
 * Marks the view as needing display. Convenience for use whether the view / layer is loaded or not. Safe to call from a background thread.
 */
- (void)setNeedsDisplay;

/**
 * Marks the node as needing layout. Convenience for use whether the view / layer is loaded or not. Safe to call from a background thread.
 *
 * If the node determines its own desired layout size will change in the next layout pass, it will propagate this
 * information up the tree so its parents can have a chance to consider and apply if necessary the new size onto the node.
 *
 * - Note: `ASCellNode` has special behavior in that calling this method will automatically notify
 * the containing `ASTableView` / `ASCollectionView` that the cell should be resized, if necessary.
 */
- (void)setNeedsLayout;

/**
 * Performs a layout pass on the node. Convenience for use whether the view / layer is loaded or not. Safe to call from a background thread.
 */
- (void)layoutIfNeeded;

/**
 * The frame rectangle, which describes the node’s location and size in its supernode’s coordinate system.
 *
 * - Default: `CGRectZero`.
 */
@property CGRect frame;

/**
 * The bounds rectangle, which describes the node’s location and size in its own coordinate system.
 *
 * - Default: `CGRectZero`.
 */
@property CGRect bounds;

/**
 * The node’s position in its supernode’s coordinate space.
 *
 * - Default: `CGPointZero`.
 *
 * - Note: Updated with layout update.
 */
@property CGPoint position;

/**
 * The node’s alpha value.
 *
 * - Default: `1.0`.
 */
@property CGFloat alpha;

/**
 * Sets the corner rounding method to use on the `ASDisplayNode`.
 * There are three types of corner rounding provided by `Texture`: `CALayer`, `Precomposited`, and `Clipping`.
 *
 * - `ASCornerRoundingTypeDefaultSlowCALayer`: uses `CALayer`'s inefficient `.cornerRadius` property. Use
 * this type of corner in situations in which there is both movement through and movement underneath
 * the corner (very rare). This uses only `.cornerRadius`.
 *
 * - `ASCornerRoundingTypePrecomposited`: corners are drawn using bezier paths to clip the content in a
 * `CGContext` / `UIGraphicsContext`. This requires `.backgroundColor` and `.cornerRadius` to be set. Use opaque
 * background colors when possible for optimal efficiency, but transparent colors are supported and much
 * more efficient than `CALayer`. The only limitation of this approach is that it cannot clip children, and
 * thus works best for `ASImageNodes` or containers showing a background around their children.
 *
 * - `ASCornerRoundingTypeClipping`: overlays 4 separate opaque corners on top of the content that needs
 * corner rounding. Requires `.backgroundColor` and `.cornerRadius` to be set. Use clip corners in situations
 * where there is movement through the corner, with an opaque background (no movement underneath the corner).
 * Clipped corners are ideal for animating / resizing views, and still outperform `CALayer`.
 *
 * For more information and examples, see [http://texturegroup.org/docs/corner-rounding.html](http://texturegroup.org/docs/corner-rounding.html)
 *
 * - Default: `ASCornerRoundingTypeDefaultSlowCALayer`.
 */
@property ASCornerRoundingType cornerRoundingType;

/**
 * The radius to use when rounding corners of the `ASDisplayNode`.
 *
 * This property is thread-safe and should always be preferred over `CALayer`'s `cornerRadius` property,
 * even if corner rounding type is `ASCornerRoundingTypeDefaultSlowCALayer`.
 *
 * - Default: `0.0`.
 */
@property CGFloat cornerRadius;

/**
 * Which corners to mask when rounding corners.
 *
 * This option cannot be changed when using `iOS < 11`
 * and using `ASCornerRoundingTypeDefaultSlowCALayer`. Use a different corner rounding type to implement not-all-corners
 * rounding in prior versions of iOS.
 *
 * - Default: `all four corners`.
 */
@property CACornerMask maskedCorners;

/**
 * A Boolean value that determines whether subnodes are confined to the bounds of the node.
 *
 * - Default: `NO`.
 */
@property BOOL clipsToBounds;

/**
 * A Boolean value that determines whether the node is hidden.
 *
 * - Default: `NO`.
 */
@property (getter=isHidden) BOOL hidden;

/**
 * A Boolean value that determines whether the node is opaque.
 *
 * - Default: `YES`.
 */
@property (getter=isOpaque) BOOL opaque;

/**
 * An object that provides the contents of the layer.
 *
 * - Default: `nil`.
 */
@property (nullable) id contents;

/**
 * The rectangle, in the unit coordinate space, that defines the portion of the layer’s contents that should be used.
 *
 * - Default: the unit rectangle `[0 0 1 1]`.
 *
 * See [CALayer.h](https://developer.apple.com/documentation/quartzcore/calayer/1410866-contentsrect?language=objc) for details.
 */
@property CGRect contentsRect;

/**
 * The rectangle that defines how the layer contents are scaled if the layer’s contents are resized.
 *
 * - Default: the unit rectangle `[0 0 1 1]`.
 *
 * See [CALayer.h](https://developer.apple.com/documentation/quartzcore/calayer/1410740-contentscenter?language=objc) for details.
 */
@property CGRect contentsCenter;

/**
 * The scale factor applied to the layer.
 *
 * - Default: `1.0`.
 *
 * See [CALayer.h](https://developer.apple.com/documentation/quartzcore/calayer/1410746-contentsscale?language=objc) for details.
 */
@property CGFloat contentsScale;

/**
 * The scale at which to rasterize content, relative to the coordinate space of the layer.
 *
 * - Default: `1.0`.
 *
 * See [CALayer.h](https://developer.apple.com/documentation/quartzcore/calayer/1410801-rasterizationscale?language=objc) for details.
 */
@property CGFloat rasterizationScale;

/**
 * Defines the anchor point of the node’s bounds rectangle.
 *
 * - Default: `(0.5, 0.5)`.
 * 
 * See [CALayer.h](https://developer.apple.com/documentation/quartzcore/calayer/1410817-anchorpoint?language=objc) for details.
 */
@property CGPoint anchorPoint;

/**
 * The layer’s position on the z axis.
 *
 * - Default: `0.0`.
 *
 * See [CALayer.h](https://developer.apple.com/documentation/quartzcore/calayer/1410884-zposition?language=objc) for details.
 */
@property CGFloat zPosition;

/**
 * The transform applied to the layer’s contents.
 *
 * - Default: `CATransform3DIdentity`.
 *
 * See [CALayer.h](https://developer.apple.com/documentation/quartzcore/calayer/1410836-transform?language=objc) for details.
 */
@property CATransform3D transform;

/**
 * Specifies the transform to apply to sublayers when rendering.
 *
 * - Default: `CATransform3DIdentity`.
 */
@property CATransform3D subnodeTransform;

/**
 * A Boolean value that determines whether user events are ignored and removed from the event queue.
 *
 * - Default: `YES` (`NO` for layer-backed nodes).
 */
@property (getter=isUserInteractionEnabled) BOOL userInteractionEnabled;

#if TARGET_OS_IOS
/**
 * A Boolean value that indicates whether the receiver handles touch events exclusively.
 *
 * Setting this property to `YES` causes the receiver to block the delivery of touch events to other views in the same window.
 *
 * - Default: `NO`.
 */
@property (getter=isExclusiveTouch) BOOL exclusiveTouch;      
#endif

/**
 * A dictionary containing layer actions.
 *
 * - Default: `nil`.
 */
@property (nullable, copy) NSDictionary<NSString *, id<CAAction>> *actions;

/**
 * The node view's background color.
 *
 * In contrast to `UIView`, setting a transparent color will not set `opaque = NO`.
 * This only affects nodes that implement `+drawRect` like `ASTextNode`.
 *
 * - Default: `nil`.
*/
@property (nullable, copy) UIColor *backgroundColor;

/**
 * The first nondefault tint color value in the node’s hierarchy, ascending from and starting with the node itself.
 *
 * - Default: `Blue`.
 */
@property (null_resettable, copy) UIColor *tintColor;

/**
 * Notifies the node when the `tintColor` has changed.
 *
 * - Note: This method is guaranteed to be called if the `tintColor` is changed after the node loaded.
 */
- (void)tintColorDidChange;

/**
 * A flag used to determine how a node lays out its content when its bounds change.
 *
 * This is like `UIView`'s contentMode property, but better. We do our own mapping to layer.contentsGravity in
 * `_ASDisplayView`. You can set `needsDisplayOnBoundsChange` independently.
 * Thus, `UIViewContentModeRedraw` is not allowed; use `needsDisplayOnBoundsChange = YES` instead, and pick an appropriate
 * contentMode for your content while it's being re-rendered.
 *
 * - Default: `UIViewContentModeScaleToFill`.
 */
@property UIViewContentMode contentMode;

/**
 * A constant that specifies how the layer's contents are positioned or scaled within its bounds.
 *
 * - Note: Use `.contentMode` in preference when possible.
 */
@property (copy) NSString *contentsGravity;

/**
 * A semantic description of the view’s contents, used to determine whether the view should be flipped when switching between left-to-right and right-to-left layouts.
 */
@property UISemanticContentAttribute semanticContentAttribute;

/**
 * The color of the layer’s shadow.
 *
 * - Default: `opaque rgb black`.
 */
@property (nullable) CGColorRef shadowColor;

/**
 * The opacity of the layer’s shadow.
 *
 * The value in this property must be in the range 0.0 (transparent) to 1.0 (opaque).
 *
 * - Default: `0.0`.
 */
@property CGFloat shadowOpacity;

/**
 * The offset (in points) of the layer’s shadow.
 *
 * - Default: `(0.0, -3.0)`.
 */
@property CGSize shadowOffset;

/**
 * The blur radius (in points) used to render the layer’s shadow
 *
 * - Default: `3.0`.
 */
@property CGFloat shadowRadius;

/**
 * The width of the layer’s border.
 *
 * - Default: `0.0`.
 */
@property CGFloat borderWidth;

/**
 * The color of the layer’s border.
 *
 * - Default: `opaque rgb black`.
 */
@property (nullable) CGColorRef borderColor;

/**
 * A Boolean indicating whether the layer is allowed to composite itself as a group separate from its parent.
 */
@property BOOL allowsGroupOpacity;

/**
 * A Boolean indicating whether the layer is allowed to perform edge antialiasing.
 */
@property BOOL allowsEdgeAntialiasing;

/**
 * A bitmask defining how the edges of the receiver are rasterized.
 *
 * - Default: `all values from CAEdgeAntialiasingMask`.
 */
@property CAEdgeAntialiasingMask edgeAntialiasingMask;

/**
 * A Boolean indicating whether the layer contents must be updated when its bounds rectangle changes.
 *
 * - Default: `NO`.
 */
@property BOOL needsDisplayOnBoundsChange;

/**
 * A Boolean value that determines whether the receiver automatically resizes its subviews when its bounds change.
 *
 * - Default: `YES` (undefined for layer-backed nodes).
 */
@property BOOL autoresizesSubviews;

/**
 * An integer bit mask that determines how the receiver resizes itself when its superview’s bounds change.
 *
 * - Default: `UIViewAutoresizingNone` (undefined for layer-backed nodes).
 */
@property UIViewAutoresizing autoresizingMask;

/**
 * Content margins
 *
 * This property is bridged to its `UIView` counterpart.
 *
 * If your layout depends on this property, you should probably enable `automaticallyRelayoutOnLayoutMarginsChanges` to ensure
 * that the layout gets automatically updated when the value of this property changes. Or you can override `layoutMarginsDidChange`
 * and make all the necessary updates manually.
 */
@property UIEdgeInsets layoutMargins;

/**
 * A Boolean value indicating whether the current view also respects the margins of its superview.
 *
 * - Default: `NO`
 *
 * - Note: Set to enable pass-through or cascading behavior of margins from this view’s parent to its children.
 */
@property BOOL preservesSuperviewLayoutMargins;

/**
 * Notifies the node that the layout margins changed.
 */
- (void)layoutMarginsDidChange;

/**
 * Safe area insets
 *
 * This property is bridged to its `UIVIew` counterpart.
 *
 * If your layout depends on this property, you should probably enable `automaticallyRelayoutOnSafeAreaChanges` to ensure
 * that the layout gets automatically updated when the value of this property changes. Or you can override `safeAreaInsetsDidChange`
 * and make all the necessary updates manually.
 */
@property (readonly) UIEdgeInsets safeAreaInsets;

/**
 * A Boolean value indicating whether the view's layout margins are updated automatically to reflect the safe area.
 *
 * - Default: `YES`.
 */
@property BOOL insetsLayoutMarginsFromSafeArea;

/**
 * Called when the safe area of the node changes.
 */
- (void)safeAreaInsetsDidChange;


// UIResponder methods
// By default these fall through to the underlying view, but can be overridden.
- (BOOL)canBecomeFirstResponder;                                            // default==NO
- (BOOL)becomeFirstResponder;                                               // default==NO (no-op)
- (BOOL)canResignFirstResponder;                                            // default==YES
- (BOOL)resignFirstResponder;                                               // default==NO (no-op)
- (BOOL)isFirstResponder;
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender;

#if TARGET_OS_TV
//Focus Engine
- (void)setNeedsFocusUpdate;
- (BOOL)canBecomeFocused;
- (void)updateFocusIfNeeded;
- (void)didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator;
- (BOOL)shouldUpdateFocusInContext:(UIFocusUpdateContext *)context;
- (nullable UIView *)preferredFocusedView;
#endif

@end

@interface ASDisplayNode (UIViewBridgeAccessibility)

// Accessibility support
@property           BOOL isAccessibilityElement;
@property (nullable, copy)   NSString *accessibilityLabel;
@property (nullable, copy)   NSAttributedString *accessibilityAttributedLabel API_AVAILABLE(ios(11.0),tvos(11.0));
@property (nullable, copy)   NSString *accessibilityHint;
@property (nullable, copy)   NSAttributedString *accessibilityAttributedHint API_AVAILABLE(ios(11.0),tvos(11.0));
@property (nullable, copy)   NSString *accessibilityValue;
@property (nullable, copy)   NSAttributedString *accessibilityAttributedValue API_AVAILABLE(ios(11.0),tvos(11.0));
@property           UIAccessibilityTraits accessibilityTraits;
@property           CGRect accessibilityFrame;
@property (nullable, copy)   UIBezierPath *accessibilityPath;
@property           CGPoint accessibilityActivationPoint;
@property (nullable, copy)   NSString *accessibilityLanguage;
@property           BOOL accessibilityElementsHidden;
@property           BOOL accessibilityViewIsModal;
@property           BOOL shouldGroupAccessibilityChildren;
@property           UIAccessibilityNavigationStyle accessibilityNavigationStyle;
@property (nullable, copy)   NSArray *accessibilityCustomActions API_AVAILABLE(ios(8.0),tvos(9.0));
#if TARGET_OS_TV
@property (nullable, copy) 	NSArray *accessibilityHeaderElements;
#endif

// Accessibility identification support
@property (nullable, copy)   NSString *accessibilityIdentifier;

@end

@interface ASDisplayNode (ASLayoutElement) <ASLayoutElement>

/**
 * Asks the node to return a layout based on given size range.
 *
 * - Parameter constrainedSize: The minimum and maximum sizes the receiver should fit in.
 *
 * - Returns: An `ASLayout` instance defining the layout of the receiver (and its children, if the box layout model is used).
 *
 * Though this method does not set the bounds of the view, it does have side effects--caching both the
 * constraint and the result.
 *
 * - Warning: Subclasses must not override this; it caches results from `-calculateLayoutThatFits:`. Calling this method may
 * be expensive if result is not cached.
 *
 * - SeeAlso: `[ASDisplayNode(Subclassing) calculateLayoutThatFits:]`
 */
- (ASLayout *)layoutThatFits:(ASSizeRange)constrainedSize;

@end

@interface ASDisplayNode (ASLayoutElementStylability) <ASLayoutElementStylability>

@end

typedef NS_ENUM(NSInteger, ASLayoutEngineType) {
  ASLayoutEngineTypeLayoutSpec,
  ASLayoutEngineTypeYoga
};

@interface ASDisplayNode (ASLayout)

/**
 * Returns the current layout type the node uses for layout the subtree.
 */
@property (readonly) ASLayoutEngineType layoutEngineType;

/**
 * Return the calculated size.
 *
 * Ideal for use by subclasses in -layout, having already prompted their subnodes to calculate their size by
 * calling `-layoutThatFits:` on them in `-calculateLayoutThatFits`.
 *
 * - Returns: Size already calculated by `-calculateLayoutThatFits:`.
 *
 * - Warning: Subclasses must not override this; it returns the last cached measurement and is never expensive.
 */
@property (readonly) CGSize calculatedSize;

/** 
 * Return the constrained size range used for calculating layout.
 *
 * - Returns: The minimum and maximum constrained sizes used by `calculateLayoutThatFits:`.
 */
@property (readonly) ASSizeRange constrainedSizeForCalculatedLayout;

@end

@interface ASDisplayNode (ASLayoutTransitioning)

/**
 * The amount of time it takes to complete the default transition animation.
 *
 * - Default: `0.2`.
 */
@property NSTimeInterval defaultLayoutTransitionDuration;

/**
 * The amount of time (measured in seconds) to wait before beginning the default transition animation.
 *
 * - Default: `0.0`.
 */
@property NSTimeInterval defaultLayoutTransitionDelay;

/**
 * A mask of options indicating how you want to perform the default transition animations.
 * For a list of valid constants, see `UIViewAnimationOptions`.
 */
@property UIViewAnimationOptions defaultLayoutTransitionOptions;

/**
 * A place to perform your animation. New nodes have been inserted here. You can also use this time to re-order the hierarchy.
 */
- (void)animateLayoutTransition:(nonnull id<ASContextTransitioning>)context;

/**
 * A place to clean up your nodes after the transition.
 */
- (void)didCompleteLayoutTransition:(nonnull id<ASContextTransitioning>)context;

/**
 * Transitions the current layout with a new constrained size. Must be called on main thread.
 *
 * - Parameter animated: Animation is optional, but will still proceed through your `animateLayoutTransition` implementation with `isAnimated == NO`.
 * - Parameter shouldMeasureAsync: Measure the layout asynchronously.
 * - Parameter completion: Optional completion block called only if a new layout is calculated.
 * It is called on main, right after the measurement and before -animateLayoutTransition:.
 *
 * If the passed constrainedSize is the the same as the node's current constrained size, this method is noop. If passed `YES` to `shouldMeasureAsync` it's guaranteed that measurement is happening on a background thread, otherwise measaurement will happen on the thread that the method was called on. The `measurementCompletion` callback is always called on the main thread right after the measurement and before `-animateLayoutTransition:`.
 *
 * - SeeAlso: `animateLayoutTransition:`
 */
- (void)transitionLayoutWithSizeRange:(ASSizeRange)constrainedSize
                             animated:(BOOL)animated
                   shouldMeasureAsync:(BOOL)shouldMeasureAsync
                measurementCompletion:(nullable NS_SWIFT_UI_ACTOR void(^)(void))completion NS_SWIFT_UI_ACTOR;


/**
 * Invalidates the layout and begins a relayout of the node with the current `constrainedSize`. Must be called on main thread.
 *
 * It is called right after the measurement and before `-animateLayoutTransition:`.
 *
 * - Parameter animated: Animation is optional, but will still proceed through your `animateLayoutTransition` implementation with `isAnimated == NO`.
 * - Parameter shouldMeasureAsync: Measure the layout asynchronously.
 * - Parameter completion: Optional completion block called only if a new layout is calculated.
 *
 * - SeeAlso: `animateLayoutTransition:`
 */
- (void)transitionLayoutWithAnimation:(BOOL)animated
                   shouldMeasureAsync:(BOOL)shouldMeasureAsync
                measurementCompletion:(nullable NS_SWIFT_UI_ACTOR void(^)(void))completion NS_SWIFT_UI_ACTOR;

/**
 * Cancels all performing layout transitions. Can be called on any thread.
 */
- (void)cancelLayoutTransition;

@end

/**
 * `ASDisplayNode` support for automatic subnode management.
 */
@interface ASDisplayNode (ASAutomaticSubnodeManagement)

/**
 * A boolean that shows whether the node automatically inserts and removes nodes based on the presence or
 * absence of the node and its subnodes is completely determined in its `layoutSpecThatFits:` method.
 *
 * If flag is `YES` the node no longer require `addSubnode:` or `removeFromSupernode` method calls. The presence
 * or absence of subnodes is completely determined in its `layoutSpecThatFits:` method.
 *
 * - Default: `NO`.
 */
@property BOOL automaticallyManagesSubnodes;

@end

/**
 * `ASDisplayNode` participates in `ASAsyncTransactions`, so you can determine when your subnodes are done rendering.
 * See: `-(void)asyncdisplaykit_asyncTransactionContainerStateDidChange` in `ASDisplayNodeSubclass.h`
 */
@interface ASDisplayNode (ASAsyncTransactionContainer) <ASAsyncTransactionContainer>
@end

/**
 * `UIVIew(AsyncDisplayKit)` defines convenience method for adding `sub-ASDisplayNode` to an `UIView`.
 */
@interface UIView (AsyncDisplayKit)
/**
 * Convenience method, equivalent to `[view addSubview:node.view]` or `[view.layer addSublayer:node.layer]` if layer-backed.
 *
 * - Parameter node: The node to be added.
 */
- (void)addSubnode:(ASDisplayNode *)node;
@end

/**
 * `CALayer(AsyncDisplayKit)` defines convenience method for adding `sub-ASDisplayNode` to a `CALayer`.
 */
@interface CALayer (AsyncDisplayKit)
/**
 * Convenience method, equivalent to `[layer addSublayer:node.layer]`.
 *
 * - Parameter node: The node to be added.
 */
- (void)addSubnode:(ASDisplayNode *)node;
@end

NS_ASSUME_NONNULL_END
