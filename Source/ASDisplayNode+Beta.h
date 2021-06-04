//
//  ASDisplayNode+Beta.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASAvailability.h"
#import "ASDisplayNode.h"
#import "ASLayoutRangeType.h"

#if YOGA
  #import YOGA_HEADER_PATH
  #import "ASYogaUtilities.h"
  #import "ASDisplayNode+Yoga.h"
#endif

NS_ASSUME_NONNULL_BEGIN

ASDK_EXTERN void ASPerformBlockOnMainThread(void (^block)(void));
ASDK_EXTERN void ASPerformBlockOnBackgroundThread(void (^block)(void)); // DISPATCH_QUEUE_PRIORITY_DEFAULT

/**
 * Bitmask to indicate what performance measurements the cell should record.
 */
typedef NS_OPTIONS(unsigned char, ASDisplayNodePerformanceMeasurementOptions) {
  ASDisplayNodePerformanceMeasurementOptionLayoutSpec = 1 << 0,
  ASDisplayNodePerformanceMeasurementOptionLayoutComputation = 1 << 1
};

typedef struct {
  CFTimeInterval layoutSpecTotalTime;
  NSInteger layoutSpecNumberOfPasses;
  CFTimeInterval layoutComputationTotalTime;
  NSInteger layoutComputationNumberOfPasses;
} ASDisplayNodePerformanceMeasurements;

@interface ASDisplayNode (Beta)

/**
 * ASTableView and ASCollectionView now throw exceptions on invalid updates
 * like their UIKit counterparts. If YES, these classes will log messages
 * on invalid updates rather than throwing exceptions.
 *
 * Note that even if AsyncDisplayKit's exception is suppressed, the app may still crash
 * as it proceeds with an invalid update.
 *
 * This property defaults to NO. It will be removed in a future release.
 */
+ (BOOL)suppressesInvalidCollectionUpdateExceptions AS_WARN_UNUSED_RESULT ASDISPLAYNODE_DEPRECATED_MSG("Collection update exceptions are thrown if assertions are enabled.");
+ (void)setSuppressesInvalidCollectionUpdateExceptions:(BOOL)suppresses;

/**
 * @abstract Recursively ensures node and all subnodes are displayed.
 * @see Full documentation in ASDisplayNode+FrameworkPrivate.h
 */
- (void)recursivelyEnsureDisplaySynchronously:(BOOL)synchronously;

/**
 * @abstract allow modification of a context before the node's content is drawn
 *
 * @discussion Set the block to be called after the context has been created and before the node's content is drawn.
 * You can override this to modify the context before the content is drawn. You are responsible for saving and
 * restoring context if necessary. Restoring can be done in contextDidDisplayNodeContent
 * This block can be called from *any* thread and it is unsafe to access any UIKit main thread properties from it.
 */
@property (nullable) ASDisplayNodeContextModifier willDisplayNodeContentWithRenderingContext;

/**
 * @abstract allow modification of a context after the node's content is drawn
 */
@property (nullable) ASDisplayNodeContextModifier didDisplayNodeContentWithRenderingContext;

/**
 * @abstract A bitmask representing which actions (layout spec, layout generation) should be measured.
 */
@property ASDisplayNodePerformanceMeasurementOptions measurementOptions;

/**
 * @abstract A simple struct representing performance measurements collected.
 */
@property (readonly) ASDisplayNodePerformanceMeasurements performanceMeasurements;

/**
 * @abstract Whether this node acts as an accessibility container. If set to YES, then this node's accessibility label will represent
 * an aggregation of all child nodes' accessibility labels. Nodes in this node's subtree that are also accessibility containers will
 * not be included in this aggregation, and will be exposed as separate accessibility elements to UIKit.
 */
@property BOOL isAccessibilityContainer;

/**
 * @abstract Returns the default accessibility property values set by Texture on this node. For
 * example, the default accessibility label for a text node may be its text content, while most
 * other nodes would have nil default labels.
 */
@property (nullable, readonly, copy) NSString *defaultAccessibilityLabel;
@property (nullable, readonly, copy) NSString *defaultAccessibilityHint;
@property (nullable, readonly, copy) NSString *defaultAccessibilityValue;
@property (nullable, readonly, copy) NSString *defaultAccessibilityIdentifier;
@property (readonly) UIAccessibilityTraits defaultAccessibilityTraits;

/**
 * @abstract Invoked when a user performs a custom action on an accessible node. Nodes that are children of accessibility containers, have
 * an accessibity label and have an interactive UIAccessibilityTrait will automatically receive custom-action handling.
 *
 * @return Return a boolean value that determine whether to propagate through the responder chain.
 * To halt propagation, return YES; otherwise, return NO.
 */
- (BOOL)performAccessibilityCustomAction:(UIAccessibilityCustomAction *)action;

/**
 * @abstract Currently used by ASNetworkImageNode and ASMultiplexImageNode to allow their placeholders to stay if they are loading an image from the network.
 * Otherwise, a display pass is scheduled and completes, but does not actually draw anything - and ASDisplayNode considers the element finished.
 */
- (BOOL)placeholderShouldPersist AS_WARN_UNUSED_RESULT;

/**
 * @abstract Indicates that the receiver and all subnodes have finished displaying. May be called more than once, for example if the receiver has
 * a network image node. This is called after the first display pass even if network image nodes have not downloaded anything (text would be done,
 * and other nodes that are ready to do their final display). Each render of every progressive jpeg network node would cause this to be called, so
 * this hook could be called up to 1 + (pJPEGcount * pJPEGrenderCount) times. The render count depends on how many times the downloader calls the
 * progressImage block.
 */
AS_CATEGORY_IMPLEMENTABLE
- (void)hierarchyDisplayDidFinish NS_REQUIRES_SUPER;

/**
 * Only called on the root during yoga layout.
 */
AS_CATEGORY_IMPLEMENTABLE
- (void)willCalculateLayout:(ASSizeRange)constrainedSize NS_REQUIRES_SUPER;

/**
 * Only ASLayoutRangeModeVisibleOnly or ASLayoutRangeModeLowMemory are recommended.  Default is ASLayoutRangeModeVisibleOnly,
 * because this is the only way to ensure an application will not have blank / flashing views as the user navigates back after
 * a memory warning.  Apps that wish to use the more effective / aggressive ASLayoutRangeModeLowMemory may need to take steps
 * to mitigate this behavior, including: restoring a larger range mode to the next controller before the user navigates there,
 * enabling .neverShowPlaceholders on ASCellNodes so that the navigation operation is blocked on redisplay completing, etc.
 */
+ (void)setRangeModeForMemoryWarnings:(ASLayoutRangeMode)rangeMode;

/**
 * @abstract Whether to draw all descendent nodes' contents into this node's layer's backing store.
 *
 * @discussion
 * When called, causes all descendent nodes' contents to be drawn directly into this node's layer's backing
 * store.
 *
 * If a node's descendants are static (never animated or never change attributes after creation) then that node is a
 * good candidate for rasterization.  Rasterizing descendants has two main benefits:
 * 1) Backing stores for descendant layers are not created.  Instead the layers are drawn directly into the rasterized
 * container.  This can save a great deal of memory.
 * 2) Since the entire subtree is drawn into one backing store, compositing and blending are eliminated in that subtree
 * which can help improve animation/scrolling/etc performance.
 *
 * Rasterization does not currently support descendants with transform, sublayerTransform, or alpha. Those properties
 * will be ignored when rasterizing descendants.
 *
 * Note: this has nothing to do with -[CALayer shouldRasterize], which doesn't work with ASDisplayNode's asynchronous
 * rendering model.
 *
 * Note: You cannot add subnodes whose layers/views are already loaded to a rasterized node.
 * Note: You cannot call this method after the receiver's layer/view is loaded.
 */
- (void)enableSubtreeRasterization;

@end

NS_ASSUME_NONNULL_END
