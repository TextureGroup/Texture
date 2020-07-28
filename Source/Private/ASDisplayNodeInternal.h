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
};

typedef NS_OPTIONS(uint_least32_t, ASDisplayNodeAtomicFlags)
{
  Synchronous = 1 << 0,
  YogaLayoutInProgress = 1 << 1,
};

// Can be called without the node's lock. Client is responsible for thread safety.
#define _loaded(node) (node->_layer != nil)

#define checkFlag(flag) ((_atomicFlags.load() & flag) != 0)
// Returns the old value of the flag as a BOOL.
#define setFlag(flag, x) (((x ? _atomicFlags.fetch_or(flag) \
                              : _atomicFlags.fetch_and(~flag)) & flag) != 0)

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
  AS::RecursiveMutex __instanceLock__;

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
      unsigned willApplyNextYogaCalculatedLayout:1;
#endif
      // Automatically manages subnodes
      unsigned automaticallyManagesSubnodes:1; // Main thread only
      unsigned placeholderEnabled:1;
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

@protected
  ASDisplayNode * __weak _supernode;
  NSMutableArray<ASDisplayNode *> *_subnodes;

  ASNodeController *_strongNodeController;
  __weak ASNodeController *_weakNodeController;

  // Set this to nil whenever you modify _subnodes
  NSArray<ASDisplayNode *> *_cachedSubnodes;

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
  // Only ASDisplayNodes are supported in _yogaChildren currently. This means that it is necessary to
  // create ASDisplayNodes to make a stack layout when using Yoga.
  // However, the implementation is mostly ready for id <ASLayoutElement>, with a few areas requiring updates.
  NSMutableArray<ASDisplayNode *> *_yogaChildren;
  __weak ASDisplayNode *_yogaParent;
  ASLayout *_yogaCalculatedLayout;
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
  NSMutableArray<ASDisplayNodeDidLoadBlock> *_onDidLoadBlocks;
  Class _viewClass; // nil -> _ASDisplayView
  Class _layerClass; // nil -> _ASDisplayLayer


  // Placeholder support
  UIImage *_placeholderImage;
  CALayer *_placeholderLayer;

  // keeps track of nodes/subnodes that have not finished display, used with placeholders
  ASWeakSet *_pendingDisplayNodes;


  // Corner Radius support
  CGFloat _cornerRadius;
  CALayer *_clipCornerLayers[NUM_CLIP_CORNER_LAYERS];
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


  // Safe Area support
  // These properties are used on iOS 10 and lower, where safe area is not supported by UIKit.
  UIEdgeInsets _fallbackSafeAreaInsets;



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
}

+ (void)scheduleNodeForRecursiveDisplay:(ASDisplayNode *)node;

/// The _ASDisplayLayer backing the node, if any.
@property (nullable, nonatomic, readonly) _ASDisplayLayer *asyncLayer;

/// Bitmask to check which methods an object overrides.
- (ASDisplayNodeMethodOverrides)methodOverrides;

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
 * Called whenever the node needs to layout its subnodes and, if it's already loaded, its subviews. Executes the layout pass for the node
 *
 * This method is thread-safe but asserts thread affinity.
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
 * Called if a gesture recognizer was attached to an _ASDisplayView
 */
- (void)nodeViewDidAddGestureRecognizer;

// Recalculates fallbackSafeAreaInsets for the subnodes
- (void)_fallbackUpdateSafeAreaOnChildren;

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
