//
//  ASDisplayNodeInternal.h
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

#import <atomic>
#import <AsyncDisplayKit/ASDisplayNode.h>
#import <AsyncDisplayKit/ASDisplayNode+Beta.h>
#import <AsyncDisplayKit/ASDisplayNode+FrameworkPrivate.h>
#import <AsyncDisplayKit/ASLayoutElement.h>
#import <AsyncDisplayKit/ASLayoutTransition.h>
#import <AsyncDisplayKit/ASNodeContext+Private.h>
#import <AsyncDisplayKit/ASThread.h>
#import <AsyncDisplayKit/_ASTransitionContext.h>
#import <AsyncDisplayKit/ASWeakSet.h>

NS_ASSUME_NONNULL_BEGIN

@protocol _ASDisplayLayerDelegate;
@class _ASDisplayLayer;
@class _ASPendingState;
@class ASNodeController;
struct ASDisplayNodeFlags;

BOOL ASDisplayNodeSubclassOverridesSelector(Class subclass, SEL selector);
BOOL ASDisplayNodeNeedsSpecialPropertiesHandling(BOOL isSynchronous, BOOL isLayerBacked);

/// Get the pending view state for the node, creating one if needed.
_ASPendingState * ASDisplayNodeGetPendingState(ASDisplayNode * node);

typedef NS_OPTIONS(unsigned short, ASDisplayNodeMethodOverrides)
{
  ASDisplayNodeMethodOverrideNone                   = 0,
  ASDisplayNodeMethodOverrideTouchesBegan           = 1 << 0,
  ASDisplayNodeMethodOverrideTouchesCancelled       = 1 << 1,
  ASDisplayNodeMethodOverrideTouchesEnded           = 1 << 2,
  ASDisplayNodeMethodOverrideTouchesMoved           = 1 << 3,
  ASDisplayNodeMethodOverrideLayoutSpecThatFits     = 1 << 4,
  ASDisplayNodeMethodOverrideCalcLayoutThatFits     = 1 << 5,
  ASDisplayNodeMethodOverrideCalcSizeThatFits       = 1 << 6,
  ASDisplayNodeMethodOverrideYogaBaseline           = 1 << 7,
};

typedef NS_OPTIONS(uint_least32_t, ASDisplayNodeAtomicFlags)
{
  Synchronous = 1 << 0,
};

// Can be called without the node's lock. Client is responsible for thread safety.
#define _loaded(node) (node->_layer != nil)

#define checkFlag(flag) ((_atomicFlags.load() & flag) != 0)
// Returns the old value of the flag as a BOOL.
#define setFlag(flag, x) (((x ? _atomicFlags.fetch_or(flag) \
                              : _atomicFlags.fetch_and(~flag)) & flag) != 0)

#define ASDisplayNodeGetController(obj) (obj->_strongNodeController ?: obj->_weakNodeController)

ASDK_EXTERN NSString * const ASRenderingEngineDidDisplayScheduledNodesNotification;
ASDK_EXTERN NSString * const ASRenderingEngineDidDisplayNodesScheduledBeforeTimestamp;

// Allow 2^n increments of begin disabling hierarchy notifications
#define VISIBILITY_NOTIFICATIONS_DISABLED_BITS 4

#define TIME_DISPLAYNODE_OPS 0 // If you're using this information frequently, try: (DEBUG || PROFILE)
static constexpr CACornerMask kASCACornerAllCorners =
    kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner | kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;

#define NUM_CLIP_CORNER_LAYERS 4

@interface ASDisplayNode () <_ASTransitionContextCompletionDelegate, CALayerDelegate>
{
@package
  AS::MutexOrPointer __instanceLock__;
  __weak ASDisplayNode *_weakSelf;

  ASNodeContext *_nodeContext;
  _ASPendingState *_pendingViewState;

  UIView *_view;
  CALayer *_layer;

  std::atomic<ASDisplayNodeAtomicFlags> _atomicFlags;

  struct ASDisplayNodeFlags {
    // public properties
    unsigned viewEverHadAGestureRecognizerAttached:1;
    unsigned layerBacked:1;
    unsigned displaysAsynchronously:1;
    unsigned rasterizesSubtree:1;
    unsigned shouldBypassEnsureDisplay:1;
    unsigned displaySuspended:1;
    unsigned shouldAnimateSizeChanges:1;
    
    // Wrapped view handling
    
    // The layer contents should not be cleared in case the node is wrapping a UIImageView.UIImageView is specifically
    // optimized for performance and does not use the usual way to provide the contents of the CALayer via the
    // CALayerDelegate method that backs the UIImageView.
    unsigned canClearContentsOfLayer:1;
    
    // Prevent calling setNeedsDisplay on a layer that backs a UIImageView. Usually calling setNeedsDisplay on a CALayer
    // triggers a recreation of the contents of layer unfortunately calling it on a CALayer that backs a UIImageView
    // it goes through the normal flow to assign the contents to a layer via the CALayerDelegate methods. Unfortunately
    // UIImageView does not do recreate the layer contents the usual way, it actually does not implement some of the
    // methods at all instead it throws away the contents of the layer and nothing will show up.
    unsigned canCallSetNeedsDisplayOfLayer:1;

    unsigned implementsDrawRect:1;
    unsigned implementsImageDisplay:1;
    unsigned implementsDrawParameters:1;

    // internal state
    unsigned isEnteringHierarchy:1;
    unsigned isExitingHierarchy:1;
    unsigned isInHierarchy:1;
    unsigned visibilityNotificationsDisabled:VISIBILITY_NOTIFICATIONS_DISABLED_BITS;
    unsigned isDeallocating:1;

#if YOGA
      unsigned yoga:1;
      unsigned shouldSuppressYogaCustomMeasure:1;
      unsigned yogaIsApplyingLayout:1;
      unsigned yogaRequestedNestedLayout:1;
#endif
      // Automatically manages subnodes
      unsigned automaticallyManagesSubnodes:1; // Main thread only
      unsigned placeholderEnabled:1;

      // Flattening support
      unsigned viewFlattening:1;
      unsigned haveCachedIsFlattenable:1;
      unsigned cachedIsFlattenable:1;

      // Accessibility support
      unsigned isAccessibilityElement:1;
      unsigned accessibilityElementsHidden:1;
      unsigned accessibilityViewIsModal:1;
      unsigned shouldGroupAccessibilityChildren:1;
      unsigned isAccessibilityContainer:1;
      unsigned fallbackInsetsLayoutMarginsFromSafeArea:1;
      unsigned automaticallyRelayoutOnSafeAreaChanges:1;
      unsigned automaticallyRelayoutOnLayoutMarginsChanges:1;
      unsigned isViewControllerRoot:1;
      unsigned hasHadInterfaceStateDelegates:1;
      unsigned isDisappearing:1;
  } _flags;

  ASInterfaceState _interfaceState;
  ASHierarchyState _hierarchyState;
  ASInterfaceState _pendingInterfaceState;
  ASInterfaceState _preExitingInterfaceState;
  ASCornerRoundingType _cornerRoundingType;
  ASDisplayNodePerformanceMeasurementOptions _measurementOptions;
  ASDisplayNodeMethodOverrides _methodOverrides;
  // Tinting support
  UIColor *_tintColor;

  // Dynamic colors support
  UIColor *_backgroundColor;

  ASDisplayNode * __weak _supernode;
  NSMutableArray<ASDisplayNode *> *_subnodes;

  ASNodeController *_strongNodeController;
  __weak ASNodeController *_weakNodeController;

  std::atomic_uint _displaySentinel;

  // This is the desired contentsScale, not the scale at which the layer's contents should be displayed
  CGFloat _contentsScaleForDisplay;

  UIEdgeInsets _hitTestSlop;

  // Layout support
  ASLayoutElementStyle *_style;
  ASPrimitiveTraitCollection _primitiveTraitCollection;

  // Layout Spec
  ASLayoutSpecBlock _layoutSpecBlock;
  NSString *_debugName;

#if YOGA
  // !!! Only use if !exp_unified_yoga_tree. Use ASAssertNotExperiment if you're not sure.
  NSMutableArray<ASDisplayNode *> *_yogaChildren;
  // Unfortunately this weak pointer has to stay around because even with shared
  // locking, there is no way to avoid racing against the final release of a
  // parent node when ascending.
  __weak ASDisplayNode *_yogaParent;
  CGSize _yogaCalculatedLayoutMaxSize;
#endif

  // Layout Transition
  _ASTransitionContext *_pendingLayoutTransitionContext;
  NSTimeInterval _defaultLayoutTransitionDuration;
  NSTimeInterval _defaultLayoutTransitionDelay;
  UIViewAnimationOptions _defaultLayoutTransitionOptions;

  std::atomic<int32_t> _transitionID;
  std::atomic<int32_t> _pendingTransitionID;
  ASLayoutTransition *_pendingLayoutTransition;
  ASDisplayNodeLayout _calculatedDisplayNodeLayout;
  ASDisplayNodeLayout _pendingDisplayNodeLayout;
  
  /// Sentinel for layout data. Incremented when we get -setNeedsLayout / -invalidateCalculatedLayout.
  /// Starts at 1.
  std::atomic<NSUInteger> _layoutVersion;


  // Layout Spec performance measurement
  NSTimeInterval _layoutSpecTotalTime;
  NSInteger _layoutSpecNumberOfPasses;
  NSTimeInterval _layoutComputationTotalTime;
  NSInteger _layoutComputationNumberOfPasses;


  // View Loading
  ASDisplayNodeViewBlock _viewBlock;
  ASDisplayNodeLayerBlock _layerBlock;
  std::vector<ASDisplayNodeDidLoadBlock> _onDidLoadBlocks;
  Class _viewClass; // nil -> _ASDisplayView
  Class _layerClass; // nil -> _ASDisplayLayer


  // Placeholder support
  UIImage *_placeholderImage;
  CALayer *_placeholderLayer;

  // keeps track of nodes/subnodes that have not finished display, used with placeholders
  ASWeakSet *_pendingDisplayNodes;


  // Corner Radius support
  CGFloat _cornerRadius;
@protected
  CALayer *_clipCornerLayers[NUM_CLIP_CORNER_LAYERS];
@package
  CACornerMask _maskedCorners;

  ASDisplayNodeContextModifier _willDisplayNodeContentWithRenderingContext;
  ASDisplayNodeContextModifier _didDisplayNodeContentWithRenderingContext;


  // Accessibility support
  NSString *_accessibilityLabel;
  NSAttributedString *_accessibilityAttributedLabel;
  NSString *_accessibilityHint;
  NSAttributedString *_accessibilityAttributedHint;
  NSString *_accessibilityValue;
  NSAttributedString *_accessibilityAttributedValue;
  UIAccessibilityTraits _accessibilityTraits;
  CGRect _accessibilityFrame;
  NSString *_accessibilityLanguage;
  NSString *_accessibilityIdentifier;
  UIAccessibilityNavigationStyle _accessibilityNavigationStyle;
  NSArray *_accessibilityCustomActions;
  NSArray *_accessibilityHeaderElements;
  CGPoint _accessibilityActivationPoint;
  UIBezierPath *_accessibilityPath;

  ASDisplayNodeAccessibilityElementsBlock _accessibilityElementsBlock;

  // Safe Area support
  // These properties are used on iOS 10 and lower, where safe area is not supported by UIKit.
  UIEdgeInsets _fallbackSafeAreaInsets;

  // Right-to-Left layout support
  UISemanticContentAttribute _semanticContentAttribute;

#pragma mark - ASDisplayNode (Debugging)
  ASLayout *_unflattenedLayout;

#if TIME_DISPLAYNODE_OPS
@public
  NSTimeInterval _debugTimeToCreateView;
  NSTimeInterval _debugTimeToApplyPendingState;
  NSTimeInterval _debugTimeToAddSubnodeViews;
  NSTimeInterval _debugTimeForDidLoad;
#endif

  /// Fast path: tells whether we've ever had an interface state delegate before.
  __weak id<ASInterfaceStateDelegate> _interfaceStateDelegates[AS_MAX_INTERFACE_STATE_DELEGATES];

  NSDictionary<NSString *, id<CAAction>> *_disappearanceActions;
}

+ (void)scheduleNodeForRecursiveDisplay:(ASDisplayNode *)node;

// When a table/collection view reload during a transaction, cell will reconfigure which might
// involves visible -> reload(hide show) and in this case we want to merge hide show pair by
// delaying the process until later.
+ (BOOL)shouldCoalesceInterfaceStateDuringTransaction;

/// The _ASDisplayLayer backing the node, if any.
@property (nullable, nonatomic, readonly) _ASDisplayLayer *asyncLayer;

/// Bitmask to check which methods an object overrides.
- (ASDisplayNodeMethodOverrides)methodOverrides;

/**
 * In edge cases _assign_ pointers to ASDisplayNode can be invalid, even when properly cleaned up
 * in dealloc. This occurs when dealloc has begun, but not completed, and another thread tries to
 * retain the _assign_ pointer. It cannot be successfully retained, the dealloc will complete,
 * and a crash is likely. There's no obvious way to know when this is this case. _weak_ pointers, on
 * the other hand, will have already been zeroed. Therefore ASDisplayNode will initialize a _weak_
 * self pointer, and `tryRetain` will return a safely strongified copy of it if it is not nil.
 *
 * This method should be used in all cases where _assign_ pointers are stored with the expectation
 * that the ASDisplayNode or a subclass will clean them up (this can be the only reasonable way to
 * interop with non-objC third-party libraries, notably Yoga).
 */
- (nullable instancetype)tryRetain;

/**
 * Invoked before a call to setNeedsLayout to the underlying view
 */
- (void)__setNeedsLayout;

/**
 * Invoked after a call to setNeedsDisplay to the underlying view
 */
- (void)__setNeedsDisplay;

/**
 * Setup the node -> controller reference. Strong or weak is based on
 * the "shouldInvertStrongReference" property of the controller.
 *
 * Note: To prevent lock-ordering deadlocks, this method does not take the node's lock.
 * In practice, changing the node controller of a node multiple times is not
 * supported behavior.
 */
- (void)__setNodeController:(ASNodeController *)controller;

/**
 * Called whenever the node needs to layout its subnodes and, if it's already loaded, its subviews.
 * Executes the layout pass for the node
 *
 * This method is thread-safe but requires thread affinity. At the same time, this method currently
 * requires to be called without the lock held. This means that a race condition is unavoidable when
 * calling this method from a background thread.
 */
- (void)__layout;

/**
 * Internal tree modification methods.
 */
- (void)_removeFromSupernodeIfEqualTo:(ASDisplayNode *)supernode;

// Private API for helper functions / unit tests.  Use ASDisplayNodeDisableHierarchyNotifications() to control this.
- (BOOL)__visibilityNotificationsDisabled;
- (BOOL)__selfOrParentHasVisibilityNotificationsDisabled;
- (void)__incrementVisibilityNotificationsDisabled;
- (void)__decrementVisibilityNotificationsDisabled;

/// Helper method to summarize whether or not the node run through the display process
- (BOOL)_implementsDisplay;

/// Display the node's view/layer immediately on the current thread, bypassing the background thread rendering. Will be deprecated.
- (void)displayImmediately;

/// Refreshes any precomposited or drawn clip corners, setting up state as required to transition corner config.
- (void)updateCornerRoundingWithType:(ASCornerRoundingType)newRoundingType
                        cornerRadius:(CGFloat)newCornerRadius
                       maskedCorners:(CACornerMask)newMaskedCorners;

/// Update the Semantic Content Attribute. Trigger layout if this value has changed.
- (void)updateSemanticContentAttributeWithAttribute:(UISemanticContentAttribute)attribute;

/// Alternative initialiser for backing with a custom view class.  Supports asynchronous display with _ASDisplayView subclasses.
- (instancetype)initWithViewClass:(Class)viewClass;

/// Alternative initialiser for backing with a custom layer class.  Supports asynchronous display with _ASDisplayLayer subclasses.
- (instancetype)initWithLayerClass:(Class)layerClass;

@property (nonatomic) CGFloat contentsScaleForDisplay;

- (void)applyPendingViewState;

/**
 * Makes a local copy of the interface state delegates then calls the block on each.
 *
 * Lock is not held during block invocation. Method must not be called with the lock held.
 */
- (void)enumerateInterfaceStateDelegates:(void(NS_NOESCAPE ^)(id<ASInterfaceStateDelegate> delegate))block;

/**
 * This method has proven helpful in a few rare scenarios, similar to a category extension on UIView,
 * but it's considered private API for now and its use should not be encouraged.
 * @param checkViewHierarchy If YES, and no supernode can be found, method will walk up from `self.view` to find a supernode.
 * If YES, this method must be called on the main thread and the node must not be layer-backed.
 */
- (nullable ASDisplayNode *)_supernodeWithClass:(Class)supernodeClass checkViewHierarchy:(BOOL)checkViewHierarchy;

/**
 * Whether this node rasterizes its descendants. See -enableSubtreeRasterization.
 */
@property (readonly) BOOL rasterizesSubtree;

/**
 * Called during layout pass to determine if the node should be flattened
 */
- (BOOL)isFlattenable;

/**
 * Called if a gesture recognizer was attached to an _ASDisplayView
 */
- (void)nodeViewDidAddGestureRecognizer;

// Recalculates fallbackSafeAreaInsets for the subnodes
- (void)_fallbackUpdateSafeAreaOnChildren;

// Apply pending interface to interface state recursively for node and all subnodes.
- (void)recursivelyApplyPendingInterfaceState;

@end

@interface ASDisplayNode (InternalPropertyBridge)

@property (nonatomic) CGFloat layerCornerRadius;

/// NOTE: Changing this to non-default under iOS < 11 will make an assertion (for the end user to see.)
@property (nonatomic) CACornerMask layerMaskedCorners;

- (BOOL)_locked_insetsLayoutMarginsFromSafeArea;

@end

@interface ASDisplayNode (ASLayoutElementPrivate)

/**
 * Returns the internal style object or creates a new if no exists. Need to be called with lock held.
 */
- (ASLayoutElementStyle *)_locked_style;

/**
 * Returns the current layout element. Need to be called with lock held.
 */
- (id<ASLayoutElement>)_locked_layoutElementThatFits:(ASSizeRange)constrainedSize;

@end

NS_ASSUME_NONNULL_END
