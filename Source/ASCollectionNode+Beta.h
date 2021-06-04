//
//  ASCollectionNode+Beta.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASCollectionNode.h>

@protocol ASCollectionViewLayoutFacilitatorProtocol, ASCollectionLayoutDelegate, ASBatchFetchingDelegate;
@class ASElementMap;

NS_ASSUME_NONNULL_BEGIN

@interface ASCollectionNode (Beta)

/**
 * Allows providing a custom subclass of ASCollectionView to be managed by ASCollectionNode.
 *
 * @default [ASCollectionView class] is used whenever this property is unset or nil.
 */
@property (nullable, nonatomic) Class collectionViewClass;

/**
 * The elements that are currently displayed. The "UIKit index space". Must be accessed on main thread.
 */
@property (nonatomic, readonly) ASElementMap *visibleElements;

@property (nullable, readonly) id<ASCollectionLayoutDelegate> layoutDelegate;

@property (nullable, nonatomic, weak) id<ASBatchFetchingDelegate> batchFetchingDelegate;

/**
 * When this mode is enabled, ASCollectionView matches the timing of UICollectionView as closely as
 * possible, ensuring that all reload and edit operations are performed on the main thread as
 * blocking calls.
 *
 * This mode is useful for applications that are debugging issues with their collection view
 * implementation. In particular, some applications do not properly conform to the API requirement
 * of UICollectionView, and these applications may experience difficulties with ASCollectionView.
 * Providing this mode allows for developers to work towards resolving technical debt in their
 * collection view data source, while ramping up asynchronous collection layout.
 *
 * NOTE: Because this mode results in expensive operations like cell layout being performed on the
 * main thread, it should be used as a tool to resolve data source conformance issues with Apple
 * collection view API.
 *
 * @default defaults to ASCellLayoutModeNone.
 */
@property (nonatomic) ASCellLayoutMode cellLayoutMode;

/**
 *  Returns YES if the ASCollectionNode contents are completely synchronized with the underlying collection-view layout.
 */
@property (nonatomic, readonly, getter=isSynchronized) BOOL synchronized;

/**
 * When bounds change in non-scrollable direction, we remeasure all cells against the new bounds. If
 * this property is YES (the default, for historical reasons,) this remeasurement takes place within
 * the setBounds: call on the collection view's layer. Otherwise, the remeasurement occurs inside of
 * the collection view's layoutSubviews call.
 * 
 * Setting this to NO can avoid duplicated work for example during rotation, where collection view content
 * is reloaded or updated in the time between the setBounds: and the layout pass. Having it be YES
 * we may remeasure nodes that will be immediately discarded and replaced.
 * 
 * Leaving this as YES will retain historical behavior on which existing application-side collection view
 * machinery may depend.
 */
@property (nonatomic) BOOL remeasuresBeforeLayoutPassOnBoundsChange;

/**
 *  Schedules a block to be performed (on the main thread) as soon as the completion block is called
 *  on performBatchUpdates:.
 *
 *  When isSynchronized == YES, the block is run block immediately (before the method returns).
 */
- (void)onDidFinishSynchronizing:(void (^)(void))didFinishSynchronizing;

/**
 * Whether to immediately apply layouts that are generated in the background (if nodes aren't
 * loaded).
 *
 * This feature is considered experimental; please report any issues you encounter.
 *
 * Defaults to NO. The default may change to YES in the future.
 */
@property(nonatomic) BOOL immediatelyApplyComputedLayouts;

/**
 * The maximum number of elements to insert in each chunk of a collection view update.
 *
 * 0 means all items will be inserted in one chunk. Default is 0.
 */
@property (nonatomic) NSUInteger updateBatchSize;

/**
 * Whether cell nodes should be temporarily stored in, and pulled from, a global cache
 * during updates. The nodeModel will be used as the key. This is useful to reduce the
 * cost of operations such as reloading content due to iPad rotation, or moving content
 * from one collection node to another, or calling reloadData. Default is NO.
 */
@property (nonatomic) BOOL useNodeCache;

/**
 * A way to override the default ASCellLayoutModeNone behavior of forcing all initial updates to be
 * synchronous. Defaults to NO, will eventually flip to YES.
 */
@property(nonatomic) BOOL allowAsyncUpdatesForInitialContent;

/**
 * Whether to defer each layout pass to the next run loop. Useful when, for example, the collection
 * node is fully obscured by another view and you want to break up large layout operations such as
 * rotations into multiple run loop iterations.
 *
 * Defaults to NO.
 */
@property (nonatomic) BOOL shouldDelayLayout;


- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout layoutFacilitator:(nullable id<ASCollectionViewLayoutFacilitatorProtocol>)layoutFacilitator;

- (instancetype)initWithLayoutDelegate:(id<ASCollectionLayoutDelegate>)layoutDelegate layoutFacilitator:(nullable id<ASCollectionViewLayoutFacilitatorProtocol>)layoutFacilitator;

- (void)beginUpdates ASDISPLAYNODE_DEPRECATED_MSG("Use -performBatchUpdates:completion: instead.");

- (void)endUpdatesAnimated:(BOOL)animated ASDISPLAYNODE_DEPRECATED_MSG("Use -performBatchUpdates:completion: instead.");

- (void)endUpdatesAnimated:(BOOL)animated completion:(nullable void (^)(BOOL))completion ASDISPLAYNODE_DEPRECATED_MSG("Use -performBatchUpdates:completion: instead.");

@end

NS_ASSUME_NONNULL_END
