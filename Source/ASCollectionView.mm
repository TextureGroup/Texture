//
//  ASCollectionView.mm
//  Texture
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the /ASDK-Licenses directory of this source tree. An additional
//  grant of patent rights can be found in the PATENTS file in the same directory.
//
//  Modifications to this file made after 4/13/2017 are: Copyright (c) 2017-present,
//  Pinterest, Inc.  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASAssert.h>
#import <AsyncDisplayKit/ASBatchFetching.h>
#import <AsyncDisplayKit/ASDelegateProxy.h>
#import <AsyncDisplayKit/ASCellNode+Internal.h>
#import <AsyncDisplayKit/ASCollectionElement.h>
#import <AsyncDisplayKit/ASCollectionInternal.h>
#import <AsyncDisplayKit/ASCollectionLayout.h>
#import <AsyncDisplayKit/ASCollectionNode+Beta.h>
#import <AsyncDisplayKit/ASCollectionViewLayoutController.h>
#import <AsyncDisplayKit/ASCollectionViewLayoutFacilitatorProtocol.h>
#import <AsyncDisplayKit/ASCollectionViewFlowLayoutInspector.h>
#import <AsyncDisplayKit/ASDataController.h>
#import <AsyncDisplayKit/ASDisplayNodeExtras.h>
#import <AsyncDisplayKit/ASDisplayNode+FrameworkPrivate.h>
#import <AsyncDisplayKit/ASDisplayNode+Subclasses.h>
#import <AsyncDisplayKit/ASElementMap.h>
#import <AsyncDisplayKit/ASInternalHelpers.h>
#import <AsyncDisplayKit/UICollectionViewLayout+ASConvenience.h>
#import <AsyncDisplayKit/ASRangeController.h>
#import <AsyncDisplayKit/_ASCollectionViewCell.h>
#import <AsyncDisplayKit/_ASDisplayLayer.h>
#import <AsyncDisplayKit/_ASCollectionReusableView.h>
#import <AsyncDisplayKit/ASPagerNode.h>
#import <AsyncDisplayKit/ASSectionContext.h>
#import <AsyncDisplayKit/ASCollectionView+Undeprecated.h>
#import <AsyncDisplayKit/_ASHierarchyChangeSet.h>
#import <AsyncDisplayKit/CoreGraphics+ASConvenience.h>
#import <AsyncDisplayKit/ASLayout.h>
#import <AsyncDisplayKit/ASThread.h>

/**
 * A macro to get self.collectionNode and assign it to a local variable, or return
 * the given value if nil.
 *
 * Previously we would set ASCollectionNode's dataSource & delegate to nil
 * during dealloc. However, our asyncDelegate & asyncDataSource must be set on the
 * main thread, so if the node is deallocated off-main, we won't learn about the change
 * until later on. Since our @c collectionNode parameter to delegate methods (e.g.
 * collectionNode:didEndDisplayingItemWithNode:) is nonnull, it's important that we never
 * unintentionally pass nil (this will crash in Swift, in production). So we can use
 * this macro to ensure that our node is still alive before calling out to the user
 * on its behalf.
 */
#define GET_COLLECTIONNODE_OR_RETURN(__var, __val) \
  ASCollectionNode *__var = self.collectionNode; \
  if (__var == nil) { \
    return __val; \
  }

#define ASFlowLayoutDefault(layout, property, default)                                        \
({                                                                                            \
  UICollectionViewFlowLayout *flowLayout = ASDynamicCast(layout, UICollectionViewFlowLayout); \
  flowLayout ? flowLayout.property : default;                                                 \
})

/// What, if any, invalidation should we perform during the next -layoutSubviews.
typedef NS_ENUM(NSUInteger, ASCollectionViewInvalidationStyle) {
  /// Perform no invalidation.
  ASCollectionViewInvalidationStyleNone,
  /// Perform invalidation with animation (use an empty batch update).
  ASCollectionViewInvalidationStyleWithoutAnimation,
  /// Perform invalidation without animation (use -invalidateLayout).
  ASCollectionViewInvalidationStyleWithAnimation,
};

static const NSUInteger kASCollectionViewAnimationNone = UITableViewRowAnimationNone;

/// Used for all cells and supplementaries. UICV keys by supp-kind+reuseID so this is plenty.
static NSString * const kReuseIdentifier = @"_ASCollectionReuseIdentifier";

#pragma mark -
#pragma mark ASCollectionView.

@interface ASCollectionView () <ASRangeControllerDataSource, ASRangeControllerDelegate, ASDataControllerSource, ASCellNodeInteractionDelegate, ASDelegateProxyInterceptor, ASBatchFetchingScrollView, ASCALayerExtendedDelegate, UICollectionViewDelegateFlowLayout> {
  ASCollectionViewProxy *_proxyDataSource;
  ASCollectionViewProxy *_proxyDelegate;
  
  ASDataController *_dataController;
  ASRangeController *_rangeController;
  ASCollectionViewLayoutController *_layoutController;
  id<ASCollectionViewLayoutInspecting> _defaultLayoutInspector;
  __weak id<ASCollectionViewLayoutInspecting> _layoutInspector;
  NSHashTable<_ASCollectionViewCell *> *_cellsForVisibilityUpdates;
  NSHashTable<ASCellNode *> *_cellsForLayoutUpdates;
  id<ASCollectionViewLayoutFacilitatorProtocol> _layoutFacilitator;
  CGFloat _leadingScreensForBatching;
  
  // When we update our data controller in response to an interactive move,
  // we don't want to tell the collection view about the change (it knows!)
  BOOL _updatingInResponseToInteractiveMove;
  BOOL _inverted;
  
  NSUInteger _superBatchUpdateCount;
  BOOL _isDeallocating;
  
  ASBatchContext *_batchContext;
  
  CGSize _lastBoundsSizeUsedForMeasuringNodes;
  
  NSMutableSet *_registeredSupplementaryKinds;
  
  // CountedSet because UIKit may display the same element in multiple cells e.g. during animations.
  NSCountedSet<ASCollectionElement *> *_visibleElements;
  
  CGPoint _deceleratingVelocity;

  BOOL _zeroContentInsets;
  
  ASCollectionViewInvalidationStyle _nextLayoutInvalidationStyle;
  
  /**
   * If YES, the `UICollectionView` will reload its data on next layout pass so we should not forward any updates to it.
   
   * Rationale:
   * In `reloadData`, a collection view invalidates its data and marks itself as needing reload, and waits until `layoutSubviews` to requery its data source.
   * This can lead to data inconsistency problems.
   * Say you have an empty collection view. You call `reloadData`, then immediately insert an item into your data source and call `insertItemsAtIndexPaths:[0,0]`.
   * You will get an assertion failure saying `Invalid number of items in section 0.
   * The number of items after the update (1) must be equal to the number of items before the update (1) plus or minus the items added and removed (1 added, 0 removed).`
   * The collection view never queried your data source before the update to see that it actually had 0 items.
   */
  BOOL _superIsPendingDataLoad;

  /**
   * It's important that we always check for batch fetching at least once, but also
   * that we do not check for batch fetching for empty updates (as that may cause an infinite
   * loop of batch fetching, where the batch completes and performBatchUpdates: is called without
   * actually making any changes.) So to handle the case where a collection is completely empty
   * (0 sections) we always check at least once after each update (initial reload is the first update.)
   */
  BOOL _hasEverCheckedForBatchFetchingDueToUpdate;
  
  /**
   * Counter used to keep track of nested batch updates.
   */
  NSInteger _batchUpdateCount;

  /**
   * Keep a strong reference to node till view is ready to release.
   */
  ASCollectionNode *_keepalive_node;

  struct {
    unsigned int scrollViewDidScroll:1;
    unsigned int scrollViewWillBeginDragging:1;
    unsigned int scrollViewDidEndDragging:1;
    unsigned int scrollViewWillEndDragging:1;
    unsigned int scrollViewDidEndDecelerating:1;
    unsigned int collectionViewWillDisplayNodeForItem:1;
    unsigned int collectionViewWillDisplayNodeForItemDeprecated:1;
    unsigned int collectionViewDidEndDisplayingNodeForItem:1;
    unsigned int collectionViewShouldSelectItem:1;
    unsigned int collectionViewDidSelectItem:1;
    unsigned int collectionViewShouldDeselectItem:1;
    unsigned int collectionViewDidDeselectItem:1;
    unsigned int collectionViewShouldHighlightItem:1;
    unsigned int collectionViewDidHighlightItem:1;
    unsigned int collectionViewDidUnhighlightItem:1;
    unsigned int collectionViewShouldShowMenuForItem:1;
    unsigned int collectionViewCanPerformActionForItem:1;
    unsigned int collectionViewPerformActionForItem:1;
    unsigned int collectionViewWillBeginBatchFetch:1;
    unsigned int shouldBatchFetchForCollectionView:1;
    unsigned int collectionNodeWillDisplayItem:1;
    unsigned int collectionNodeDidEndDisplayingItem:1;
    unsigned int collectionNodeShouldSelectItem:1;
    unsigned int collectionNodeDidSelectItem:1;
    unsigned int collectionNodeShouldDeselectItem:1;
    unsigned int collectionNodeDidDeselectItem:1;
    unsigned int collectionNodeShouldHighlightItem:1;
    unsigned int collectionNodeDidHighlightItem:1;
    unsigned int collectionNodeDidUnhighlightItem:1;
    unsigned int collectionNodeShouldShowMenuForItem:1;
    unsigned int collectionNodeCanPerformActionForItem:1;
    unsigned int collectionNodePerformActionForItem:1;
    unsigned int collectionNodeWillBeginBatchFetch:1;
    unsigned int collectionNodeWillDisplaySupplementaryElement:1;
    unsigned int collectionNodeDidEndDisplayingSupplementaryElement:1;
    unsigned int shouldBatchFetchForCollectionNode:1;

    // Interop flags
    unsigned int interop:1;
    unsigned int interopWillDisplayCell:1;
    unsigned int interopDidEndDisplayingCell:1;
    unsigned int interopWillDisplaySupplementaryView:1;
    unsigned int interopdidEndDisplayingSupplementaryView:1;
  } _asyncDelegateFlags;
  
  struct {
    unsigned int collectionViewNodeForItem:1;
    unsigned int collectionViewNodeBlockForItem:1;
    unsigned int collectionViewNodeForSupplementaryElement:1;
    unsigned int numberOfSectionsInCollectionView:1;
    unsigned int collectionViewNumberOfItemsInSection:1;
    unsigned int collectionNodeNodeForItem:1;
    unsigned int collectionNodeNodeBlockForItem:1;
    unsigned int nodeModelForItem:1;
    unsigned int collectionNodeNodeForSupplementaryElement:1;
    unsigned int collectionNodeNodeBlockForSupplementaryElement:1;
    unsigned int collectionNodeSupplementaryElementKindsInSection:1;
    unsigned int numberOfSectionsInCollectionNode:1;
    unsigned int collectionNodeNumberOfItemsInSection:1;
    unsigned int collectionNodeContextForSection:1;
    unsigned int collectionNodeCanMoveItem:1;
    unsigned int collectionNodeMoveItem:1;

    // Whether this data source conforms to ASCollectionDataSourceInterop
    unsigned int interop:1;
    // Whether this interop data source returns YES from +dequeuesCellsForNodeBackedItems
    unsigned int interopAlwaysDequeue:1;
    // Whether this interop data source implements viewForSupplementaryElementOfKind:
    unsigned int interopViewForSupplementaryElement:1;
  } _asyncDataSourceFlags;
  
  struct {
    unsigned int constrainedSizeForSupplementaryNodeOfKindAtIndexPath:1;
    unsigned int supplementaryNodesOfKindInSection:1;
    unsigned int didChangeCollectionViewDataSource:1;
    unsigned int didChangeCollectionViewDelegate:1;
  } _layoutInspectorFlags;
  
  BOOL _hasDataControllerLayoutDelegate;
}

@end

@implementation ASCollectionView
{
  __weak id<ASCollectionDelegate> _asyncDelegate;
  __weak id<ASCollectionDataSource> _asyncDataSource;
}

// Using _ASDisplayLayer ensures things like -layout are properly forwarded to ASCollectionNode.
+ (Class)layerClass
{
  return [_ASDisplayLayer class];
}

#pragma mark -
#pragma mark Lifecycle.

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout
{
  return [self initWithFrame:CGRectZero collectionViewLayout:layout];
}

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout
{
  return [self _initWithFrame:frame collectionViewLayout:layout layoutFacilitator:nil owningNode:nil eventLog:nil];
}

- (instancetype)_initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout layoutFacilitator:(id<ASCollectionViewLayoutFacilitatorProtocol>)layoutFacilitator owningNode:(ASCollectionNode *)owningNode eventLog:(ASEventLog *)eventLog
{
  if (!(self = [super initWithFrame:frame collectionViewLayout:layout]))
    return nil;

  // Disable UICollectionView prefetching. Use super, because self disables this method.
  // Experiments done by Instagram show that this option being YES (default)
  // when unused causes a significant hit to scroll performance.
  // https://github.com/Instagram/IGListKit/issues/318
  if (AS_AVAILABLE_IOS(10)) {
    super.prefetchingEnabled = NO;
  }

  _layoutController = [[ASCollectionViewLayoutController alloc] initWithCollectionView:self];
  
  _rangeController = [[ASRangeController alloc] init];
  _rangeController.dataSource = self;
  _rangeController.delegate = self;
  _rangeController.layoutController = _layoutController;
  
  _dataController = [[ASDataController alloc] initWithDataSource:self node:owningNode eventLog:eventLog];
  _dataController.delegate = _rangeController;
  
  _batchContext = [[ASBatchContext alloc] init];
  
  _leadingScreensForBatching = 2.0;
  
  _lastBoundsSizeUsedForMeasuringNodes = self.bounds.size;
  
  _layoutFacilitator = layoutFacilitator;
  
  _proxyDelegate = [[ASCollectionViewProxy alloc] initWithTarget:nil interceptor:self];
  super.delegate = (id<UICollectionViewDelegate>)_proxyDelegate;
  
  _proxyDataSource = [[ASCollectionViewProxy alloc] initWithTarget:nil interceptor:self];
  super.dataSource = (id<UICollectionViewDataSource>)_proxyDataSource;
  
  _registeredSupplementaryKinds = [NSMutableSet set];
  _visibleElements = [[NSCountedSet alloc] init];
  
  _cellsForVisibilityUpdates = [NSHashTable hashTableWithOptions:NSHashTableObjectPointerPersonality];
  _cellsForLayoutUpdates = [NSHashTable hashTableWithOptions:NSHashTableObjectPointerPersonality];
  self.backgroundColor = [UIColor whiteColor];
  
  [self registerClass:[_ASCollectionViewCell class] forCellWithReuseIdentifier:kReuseIdentifier];
  
  [self _configureCollectionViewLayout:layout];
  
  return self;
}

- (void)dealloc
{
  ASDisplayNodeAssertMainThread();
  ASDisplayNodeCAssert(_batchUpdateCount == 0, @"ASCollectionView deallocated in the middle of a batch update.");
  
  // Sometimes the UIKit classes can call back to their delegate even during deallocation, due to animation completion blocks etc.
  _isDeallocating = YES;
  [self setAsyncDelegate:nil];
  [self setAsyncDataSource:nil];

  // Data controller & range controller may own a ton of nodes, let's deallocate those off-main.
  ASPerformBackgroundDeallocation(&_dataController);
  ASPerformBackgroundDeallocation(&_rangeController);
}

#pragma mark -
#pragma mark Overrides.

/**
 * This method is not available to be called by the public i.e.
 * it should only be called by UICollectionView itself. UICollectionView
 * does this e.g. during the first layout pass, or if you call -numberOfSections
 * before its content is loaded.
 */
- (void)reloadData
{
  [super reloadData];

  // UICollectionView calls -reloadData during first layoutSubviews and when the data source changes.
  // This fires off the first load of cell nodes.
  if (_asyncDataSource != nil && !self.dataController.initialReloadDataHasBeenCalled) {
    [self performBatchUpdates:^{
      [_changeSet reloadData];
    } completion:nil];
  }
}

- (void)scrollToItemAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(UICollectionViewScrollPosition)scrollPosition animated:(BOOL)animated
{
  if ([self validateIndexPath:indexPath]) {
    [super scrollToItemAtIndexPath:indexPath atScrollPosition:scrollPosition animated:animated];
  }
}

- (void)relayoutItems
{
  [_dataController relayoutAllNodesWithInvalidationBlock:^{
    [self.collectionViewLayout invalidateLayout];
    [self invalidateFlowLayoutDelegateMetrics];
  }];
}

- (BOOL)isProcessingUpdates
{
  return [_dataController isProcessingUpdates];
}

- (void)onDidFinishProcessingUpdates:(nullable void (^)())completion
{
  [_dataController onDidFinishProcessingUpdates:completion];
}

- (void)waitUntilAllUpdatesAreCommitted
{
  ASDisplayNodeAssertMainThread();
  if (_batchUpdateCount > 0) {
    // This assertion will be enabled soon.
    //    ASDisplayNodeFailAssert(@"Should not call %@ during batch update", NSStringFromSelector(_cmd));
    return;
  }

  [_dataController waitUntilAllUpdatesAreProcessed];
}

- (void)setDataSource:(id<UICollectionViewDataSource>)dataSource
{
  // UIKit can internally generate a call to this method upon changing the asyncDataSource; only assert for non-nil. We also allow this when we're doing interop.
  ASDisplayNodeAssert(_asyncDelegateFlags.interop || dataSource == nil, @"ASCollectionView uses asyncDataSource, not UICollectionView's dataSource property.");
}

- (void)setDelegate:(id<UICollectionViewDelegate>)delegate
{
  // Our UIScrollView superclass sets its delegate to nil on dealloc. Only assert if we get a non-nil value here. We also allow this when we're doing interop.
  ASDisplayNodeAssert(_asyncDelegateFlags.interop || delegate == nil, @"ASCollectionView uses asyncDelegate, not UICollectionView's delegate property.");
}

- (void)proxyTargetHasDeallocated:(ASDelegateProxy *)proxy
{
  if (proxy == _proxyDelegate) {
    [self setAsyncDelegate:nil];
  } else if (proxy == _proxyDataSource) {
    [self setAsyncDataSource:nil];
  }
}

- (id<ASCollectionDataSource>)asyncDataSource
{
  return _asyncDataSource;
}

- (void)setAsyncDataSource:(id<ASCollectionDataSource>)asyncDataSource
{
  // Changing super.dataSource will trigger a setNeedsLayout, so this must happen on the main thread.
  ASDisplayNodeAssertMainThread();

  // Note: It's common to check if the value hasn't changed and short-circuit but we aren't doing that here to handle
  // the (common) case of nilling the asyncDataSource in the ViewController's dealloc. In this case our _asyncDataSource
  // will return as nil (ARC magic) even though the _proxyDataSource still exists. It's really important to hold a strong
  // reference to the old dataSource in this case because calls to ASCollectionViewProxy will start failing and cause crashes.
  NS_VALID_UNTIL_END_OF_SCOPE id oldDataSource = super.dataSource;
  
  if (asyncDataSource == nil) {
    _asyncDataSource = nil;
    _proxyDataSource = _isDeallocating ? nil : [[ASCollectionViewProxy alloc] initWithTarget:nil interceptor:self];
    _asyncDataSourceFlags = {};

  } else {
    _asyncDataSource = asyncDataSource;
    _proxyDataSource = [[ASCollectionViewProxy alloc] initWithTarget:_asyncDataSource interceptor:self];
    
    _asyncDataSourceFlags.collectionViewNodeForItem = [_asyncDataSource respondsToSelector:@selector(collectionView:nodeForItemAtIndexPath:)];
    _asyncDataSourceFlags.collectionViewNodeBlockForItem = [_asyncDataSource respondsToSelector:@selector(collectionView:nodeBlockForItemAtIndexPath:)];
    _asyncDataSourceFlags.numberOfSectionsInCollectionView = [_asyncDataSource respondsToSelector:@selector(numberOfSectionsInCollectionView:)];
    _asyncDataSourceFlags.collectionViewNumberOfItemsInSection = [_asyncDataSource respondsToSelector:@selector(collectionView:numberOfItemsInSection:)];
    _asyncDataSourceFlags.collectionViewNodeForSupplementaryElement = [_asyncDataSource respondsToSelector:@selector(collectionView:nodeForSupplementaryElementOfKind:atIndexPath:)];

    _asyncDataSourceFlags.collectionNodeNodeForItem = [_asyncDataSource respondsToSelector:@selector(collectionNode:nodeForItemAtIndexPath:)];
    _asyncDataSourceFlags.collectionNodeNodeBlockForItem = [_asyncDataSource respondsToSelector:@selector(collectionNode:nodeBlockForItemAtIndexPath:)];
    _asyncDataSourceFlags.numberOfSectionsInCollectionNode = [_asyncDataSource respondsToSelector:@selector(numberOfSectionsInCollectionNode:)];
    _asyncDataSourceFlags.collectionNodeNumberOfItemsInSection = [_asyncDataSource respondsToSelector:@selector(collectionNode:numberOfItemsInSection:)];
    _asyncDataSourceFlags.collectionNodeContextForSection = [_asyncDataSource respondsToSelector:@selector(collectionNode:contextForSection:)];
    _asyncDataSourceFlags.collectionNodeNodeForSupplementaryElement = [_asyncDataSource respondsToSelector:@selector(collectionNode:nodeForSupplementaryElementOfKind:atIndexPath:)];
    _asyncDataSourceFlags.collectionNodeNodeBlockForSupplementaryElement = [_asyncDataSource respondsToSelector:@selector(collectionNode:nodeBlockForSupplementaryElementOfKind:atIndexPath:)];
    _asyncDataSourceFlags.collectionNodeSupplementaryElementKindsInSection = [_asyncDataSource respondsToSelector:@selector(collectionNode:supplementaryElementKindsInSection:)];
    _asyncDataSourceFlags.nodeModelForItem = [_asyncDataSource respondsToSelector:@selector(collectionNode:nodeModelForItemAtIndexPath:)];
    _asyncDataSourceFlags.collectionNodeCanMoveItem = [_asyncDataSource respondsToSelector:@selector(collectionNode:canMoveItemWithNode:)];
    _asyncDataSourceFlags.collectionNodeMoveItem = [_asyncDataSource respondsToSelector:@selector(collectionNode:moveItemAtIndexPath:toIndexPath:)];

    _asyncDataSourceFlags.interop = [_asyncDataSource conformsToProtocol:@protocol(ASCollectionDataSourceInterop)];
    if (_asyncDataSourceFlags.interop) {
      id<ASCollectionDataSourceInterop> interopDataSource = (id<ASCollectionDataSourceInterop>)_asyncDataSource;
      _asyncDataSourceFlags.interopAlwaysDequeue = [[interopDataSource class] respondsToSelector:@selector(dequeuesCellsForNodeBackedItems)] && [[interopDataSource class] dequeuesCellsForNodeBackedItems];
      _asyncDataSourceFlags.interopViewForSupplementaryElement = [interopDataSource respondsToSelector:@selector(collectionView:viewForSupplementaryElementOfKind:atIndexPath:)];
    }

    ASDisplayNodeAssert(_asyncDataSourceFlags.collectionNodeNumberOfItemsInSection || _asyncDataSourceFlags.collectionViewNumberOfItemsInSection, @"Data source must implement collectionNode:numberOfItemsInSection:");
    ASDisplayNodeAssert(_asyncDataSourceFlags.collectionNodeNodeBlockForItem
                        || _asyncDataSourceFlags.collectionNodeNodeForItem
                        || _asyncDataSourceFlags.collectionViewNodeBlockForItem
                        || _asyncDataSourceFlags.collectionViewNodeForItem, @"Data source must implement collectionNode:nodeBlockForItemAtIndexPath: or collectionNode:nodeForItemAtIndexPath:");
  }
  
  _dataController.validationErrorSource = asyncDataSource;
  super.dataSource = (id<UICollectionViewDataSource>)_proxyDataSource;
  
  //Cache results of layoutInspector to ensure flags are up to date if getter lazily loads a new one.
  id<ASCollectionViewLayoutInspecting> layoutInspector = self.layoutInspector;
  if (_layoutInspectorFlags.didChangeCollectionViewDataSource) {
    [layoutInspector didChangeCollectionViewDataSource:asyncDataSource];
  }
}

- (id<ASCollectionDelegate>)asyncDelegate
{
  return _asyncDelegate;
}

- (void)setAsyncDelegate:(id<ASCollectionDelegate>)asyncDelegate
{
  // Changing super.delegate will trigger a setNeedsLayout, so this must happen on the main thread.
  ASDisplayNodeAssertMainThread();

  // Note: It's common to check if the value hasn't changed and short-circuit but we aren't doing that here to handle
  // the (common) case of nilling the asyncDelegate in the ViewController's dealloc. In this case our _asyncDelegate
  // will return as nil (ARC magic) even though the _proxyDataSource still exists. It's really important to hold a strong
  // reference to the old delegate in this case because calls to ASCollectionViewProxy will start failing and cause crashes.
  NS_VALID_UNTIL_END_OF_SCOPE id oldDelegate = super.delegate;
  
  if (asyncDelegate == nil) {
    _asyncDelegate = nil;
    _proxyDelegate = _isDeallocating ? nil : [[ASCollectionViewProxy alloc] initWithTarget:nil interceptor:self];
    _asyncDelegateFlags = {};
  } else {
    _asyncDelegate = asyncDelegate;
    _proxyDelegate = [[ASCollectionViewProxy alloc] initWithTarget:_asyncDelegate interceptor:self];
    
    _asyncDelegateFlags.scrollViewDidScroll = [_asyncDelegate respondsToSelector:@selector(scrollViewDidScroll:)];
    _asyncDelegateFlags.scrollViewWillEndDragging = [_asyncDelegate respondsToSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)];
    _asyncDelegateFlags.scrollViewDidEndDecelerating = [_asyncDelegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)];
    _asyncDelegateFlags.scrollViewWillBeginDragging = [_asyncDelegate respondsToSelector:@selector(scrollViewWillBeginDragging:)];
    _asyncDelegateFlags.scrollViewDidEndDragging = [_asyncDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)];
    _asyncDelegateFlags.collectionViewWillDisplayNodeForItem = [_asyncDelegate respondsToSelector:@selector(collectionView:willDisplayNode:forItemAtIndexPath:)];
    if (_asyncDelegateFlags.collectionViewWillDisplayNodeForItem == NO) {
      _asyncDelegateFlags.collectionViewWillDisplayNodeForItemDeprecated = [_asyncDelegate respondsToSelector:@selector(collectionView:willDisplayNodeForItemAtIndexPath:)];
    }
    _asyncDelegateFlags.collectionViewDidEndDisplayingNodeForItem = [_asyncDelegate respondsToSelector:@selector(collectionView:didEndDisplayingNode:forItemAtIndexPath:)];
    _asyncDelegateFlags.collectionViewWillBeginBatchFetch = [_asyncDelegate respondsToSelector:@selector(collectionView:willBeginBatchFetchWithContext:)];
    _asyncDelegateFlags.shouldBatchFetchForCollectionView = [_asyncDelegate respondsToSelector:@selector(shouldBatchFetchForCollectionView:)];
    _asyncDelegateFlags.collectionViewShouldSelectItem = [_asyncDelegate respondsToSelector:@selector(collectionView:shouldSelectItemAtIndexPath:)];
    _asyncDelegateFlags.collectionViewDidSelectItem = [_asyncDelegate respondsToSelector:@selector(collectionView:didSelectItemAtIndexPath:)];
    _asyncDelegateFlags.collectionViewShouldDeselectItem = [_asyncDelegate respondsToSelector:@selector(collectionView:shouldDeselectItemAtIndexPath:)];
    _asyncDelegateFlags.collectionViewDidDeselectItem = [_asyncDelegate respondsToSelector:@selector(collectionView:didDeselectItemAtIndexPath:)];
    _asyncDelegateFlags.collectionViewShouldHighlightItem = [_asyncDelegate respondsToSelector:@selector(collectionView:shouldHighlightItemAtIndexPath:)];
    _asyncDelegateFlags.collectionViewDidHighlightItem = [_asyncDelegate respondsToSelector:@selector(collectionView:didHighlightItemAtIndexPath:)];
    _asyncDelegateFlags.collectionViewDidUnhighlightItem = [_asyncDelegate respondsToSelector:@selector(collectionView:didUnhighlightItemAtIndexPath:)];
    _asyncDelegateFlags.collectionViewShouldShowMenuForItem = [_asyncDelegate respondsToSelector:@selector(collectionView:shouldShowMenuForItemAtIndexPath:)];
    _asyncDelegateFlags.collectionViewCanPerformActionForItem = [_asyncDelegate respondsToSelector:@selector(collectionView:canPerformAction:forItemAtIndexPath:withSender:)];
    _asyncDelegateFlags.collectionViewPerformActionForItem = [_asyncDelegate respondsToSelector:@selector(collectionView:performAction:forItemAtIndexPath:withSender:)];
    _asyncDelegateFlags.collectionNodeWillDisplayItem = [_asyncDelegate respondsToSelector:@selector(collectionNode:willDisplayItemWithNode:)];
    _asyncDelegateFlags.collectionNodeDidEndDisplayingItem = [_asyncDelegate respondsToSelector:@selector(collectionNode:didEndDisplayingItemWithNode:)];
    _asyncDelegateFlags.collectionNodeWillBeginBatchFetch = [_asyncDelegate respondsToSelector:@selector(collectionNode:willBeginBatchFetchWithContext:)];
    _asyncDelegateFlags.shouldBatchFetchForCollectionNode = [_asyncDelegate respondsToSelector:@selector(shouldBatchFetchForCollectionNode:)];
    _asyncDelegateFlags.collectionNodeShouldSelectItem = [_asyncDelegate respondsToSelector:@selector(collectionNode:shouldSelectItemAtIndexPath:)];
    _asyncDelegateFlags.collectionNodeDidSelectItem = [_asyncDelegate respondsToSelector:@selector(collectionNode:didSelectItemAtIndexPath:)];
    _asyncDelegateFlags.collectionNodeShouldDeselectItem = [_asyncDelegate respondsToSelector:@selector(collectionNode:shouldDeselectItemAtIndexPath:)];
    _asyncDelegateFlags.collectionNodeDidDeselectItem = [_asyncDelegate respondsToSelector:@selector(collectionNode:didDeselectItemAtIndexPath:)];
    _asyncDelegateFlags.collectionNodeShouldHighlightItem = [_asyncDelegate respondsToSelector:@selector(collectionNode:shouldHighlightItemAtIndexPath:)];
    _asyncDelegateFlags.collectionNodeDidHighlightItem = [_asyncDelegate respondsToSelector:@selector(collectionNode:didHighlightItemAtIndexPath:)];
    _asyncDelegateFlags.collectionNodeDidUnhighlightItem = [_asyncDelegate respondsToSelector:@selector(collectionNode:didUnhighlightItemAtIndexPath:)];
    _asyncDelegateFlags.collectionNodeShouldShowMenuForItem = [_asyncDelegate respondsToSelector:@selector(collectionNode:shouldShowMenuForItemAtIndexPath:)];
    _asyncDelegateFlags.collectionNodeCanPerformActionForItem = [_asyncDelegate respondsToSelector:@selector(collectionNode:canPerformAction:forItemAtIndexPath:sender:)];
    _asyncDelegateFlags.collectionNodePerformActionForItem = [_asyncDelegate respondsToSelector:@selector(collectionNode:performAction:forItemAtIndexPath:sender:)];
    _asyncDelegateFlags.collectionNodeWillDisplaySupplementaryElement = [_asyncDelegate respondsToSelector:@selector(collectionNode:willDisplaySupplementaryElementWithNode:)];
    _asyncDelegateFlags.collectionNodeDidEndDisplayingSupplementaryElement = [_asyncDelegate respondsToSelector:@selector(collectionNode:didEndDisplayingSupplementaryElementWithNode:)];
    _asyncDelegateFlags.interop = [_asyncDelegate conformsToProtocol:@protocol(ASCollectionDelegateInterop)];
    if (_asyncDelegateFlags.interop) {
      id<ASCollectionDelegateInterop> interopDelegate = (id<ASCollectionDelegateInterop>)_asyncDelegate;
      _asyncDelegateFlags.interopWillDisplayCell = [interopDelegate respondsToSelector:@selector(collectionView:willDisplayCell:forItemAtIndexPath:)];
      _asyncDelegateFlags.interopDidEndDisplayingCell = [interopDelegate respondsToSelector:@selector(collectionView:didEndDisplayingCell:forItemAtIndexPath:)];
      _asyncDelegateFlags.interopWillDisplaySupplementaryView = [interopDelegate respondsToSelector:@selector(collectionView:willDisplaySupplementaryView:forElementKind:atIndexPath:)];
      _asyncDelegateFlags.interopdidEndDisplayingSupplementaryView = [interopDelegate respondsToSelector:@selector(collectionView:didEndDisplayingSupplementaryView:forElementOfKind:atIndexPath:)];
    }
  }

  super.delegate = (id<UICollectionViewDelegate>)_proxyDelegate;
  
  //Cache results of layoutInspector to ensure flags are up to date if getter lazily loads a new one.
  id<ASCollectionViewLayoutInspecting> layoutInspector = self.layoutInspector;
  if (_layoutInspectorFlags.didChangeCollectionViewDelegate) {
    [layoutInspector didChangeCollectionViewDelegate:asyncDelegate];
  }
}

- (void)setCollectionViewLayout:(nonnull UICollectionViewLayout *)collectionViewLayout
{
  ASDisplayNodeAssertMainThread();
  [super setCollectionViewLayout:collectionViewLayout];
  
  [self _configureCollectionViewLayout:collectionViewLayout];
  
  // Trigger recreation of layout inspector with new collection view layout
  if (_layoutInspector != nil) {
    _layoutInspector = nil;
    [self layoutInspector];
  }
}

- (id<ASCollectionViewLayoutInspecting>)layoutInspector
{
  if (_layoutInspector == nil) {
    UICollectionViewLayout *layout = self.collectionViewLayout;
    if (layout == nil) {
      // Layout hasn't been set yet, we're still init'ing
      return nil;
    }

    _defaultLayoutInspector = [layout asdk_layoutInspector];
    ASDisplayNodeAssertNotNil(_defaultLayoutInspector, @"You must not return nil from -asdk_layoutInspector. Return [super asdk_layoutInspector] if you have to! Layout: %@", layout);
    
    // Explicitly call the setter to wire up the _layoutInspectorFlags
    self.layoutInspector = _defaultLayoutInspector;
  }

  return _layoutInspector;
}

- (void)setLayoutInspector:(id<ASCollectionViewLayoutInspecting>)layoutInspector
{
  _layoutInspector = layoutInspector;
  
  _layoutInspectorFlags.constrainedSizeForSupplementaryNodeOfKindAtIndexPath = [_layoutInspector respondsToSelector:@selector(collectionView:constrainedSizeForSupplementaryNodeOfKind:atIndexPath:)];
  _layoutInspectorFlags.supplementaryNodesOfKindInSection = [_layoutInspector respondsToSelector:@selector(collectionView:supplementaryNodesOfKind:inSection:)];
  _layoutInspectorFlags.didChangeCollectionViewDataSource = [_layoutInspector respondsToSelector:@selector(didChangeCollectionViewDataSource:)];
  _layoutInspectorFlags.didChangeCollectionViewDelegate = [_layoutInspector respondsToSelector:@selector(didChangeCollectionViewDelegate:)];

  if (_layoutInspectorFlags.didChangeCollectionViewDataSource) {
    [_layoutInspector didChangeCollectionViewDataSource:self.asyncDataSource];
  }
  if (_layoutInspectorFlags.didChangeCollectionViewDelegate) {
    [_layoutInspector didChangeCollectionViewDelegate:self.asyncDelegate];
  }
}

- (void)setTuningParameters:(ASRangeTuningParameters)tuningParameters forRangeType:(ASLayoutRangeType)rangeType
{
  [_rangeController setTuningParameters:tuningParameters forRangeMode:ASLayoutRangeModeFull rangeType:rangeType];
}

- (ASRangeTuningParameters)tuningParametersForRangeType:(ASLayoutRangeType)rangeType
{
  return [_rangeController tuningParametersForRangeMode:ASLayoutRangeModeFull rangeType:rangeType];
}

- (void)setTuningParameters:(ASRangeTuningParameters)tuningParameters forRangeMode:(ASLayoutRangeMode)rangeMode rangeType:(ASLayoutRangeType)rangeType
{
  [_rangeController setTuningParameters:tuningParameters forRangeMode:rangeMode rangeType:rangeType];
}

- (ASRangeTuningParameters)tuningParametersForRangeMode:(ASLayoutRangeMode)rangeMode rangeType:(ASLayoutRangeType)rangeType
{
  return [_rangeController tuningParametersForRangeMode:rangeMode rangeType:rangeType];
}

- (void)setZeroContentInsets:(BOOL)zeroContentInsets
{
  _zeroContentInsets = zeroContentInsets;
}

- (BOOL)zeroContentInsets
{
  return _zeroContentInsets;
}

/// Uses latest size range from data source and -layoutThatFits:.
- (CGSize)sizeForElement:(ASCollectionElement *)element
{
  ASDisplayNodeAssertMainThread();
  if (element == nil) {
    return CGSizeZero;
  }

  ASCellNode *node = element.node;
  BOOL useUIKitCell = node.shouldUseUIKitCell;
  if (useUIKitCell) {
    // In this case, we should use the exact value that was stashed earlier by calling sizeForItem:, referenceSizeFor*, etc.
    // Although the node would use the preferredSize in layoutThatFits, we can skip this because there's no constrainedSize.
    ASDisplayNodeAssert([node.superclass isSubclassOfClass:[ASCellNode class]] == NO,
                        @"Placeholder cells for UIKit passthrough should be generic ASCellNodes: %@", node);
    return node.style.preferredSize;
  } else {
    return [node layoutThatFits:element.constrainedSize].size;
  }
}

- (CGSize)calculatedSizeForNodeAtIndexPath:(NSIndexPath *)indexPath
{
  ASDisplayNodeAssertMainThread();

  ASCollectionElement *e = [_dataController.visibleMap elementForItemAtIndexPath:indexPath];
  return [self sizeForElement:e];
}

- (ASCellNode *)nodeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return [_dataController.visibleMap elementForItemAtIndexPath:indexPath].node;
}

- (NSIndexPath *)convertIndexPathFromCollectionNode:(NSIndexPath *)indexPath waitingIfNeeded:(BOOL)wait
{
  if (indexPath == nil) {
    return nil;
  }

  NSIndexPath *viewIndexPath = [_dataController.visibleMap convertIndexPath:indexPath fromMap:_dataController.pendingMap];
  if (viewIndexPath == nil && wait) {
    [self waitUntilAllUpdatesAreCommitted];
    return [self convertIndexPathFromCollectionNode:indexPath waitingIfNeeded:NO];
  }
  return viewIndexPath;
}

/**
 * Asserts that the index path is a valid view-index-path, and returns it if so, nil otherwise.
 */
- (nullable NSIndexPath *)validateIndexPath:(nullable NSIndexPath *)indexPath
{
  if (indexPath == nil) {
    return nil;
  }

  NSInteger section = indexPath.section;
  if (section >= self.numberOfSections) {
    ASDisplayNodeFailAssert(@"Collection view index path has invalid section %lu, section count = %lu", (unsigned long)section, (unsigned long)self.numberOfSections);
    return nil;
  }

  NSInteger item = indexPath.item;
  // item == NSNotFound means e.g. "scroll to this section" and is acceptable
  if (item != NSNotFound && item >= [self numberOfItemsInSection:section]) {
    ASDisplayNodeFailAssert(@"Collection view index path has invalid item %lu in section %lu, item count = %lu", (unsigned long)indexPath.item, (unsigned long)section, (unsigned long)[self numberOfItemsInSection:section]);
    return nil;
  }

  return indexPath;
}

- (NSIndexPath *)convertIndexPathToCollectionNode:(NSIndexPath *)indexPath
{
  if ([self validateIndexPath:indexPath] == nil) {
    return nil;
  }

  return [_dataController.pendingMap convertIndexPath:indexPath fromMap:_dataController.visibleMap];
}

- (NSArray<NSIndexPath *> *)convertIndexPathsToCollectionNode:(NSArray<NSIndexPath *> *)indexPaths
{
  if (indexPaths == nil) {
    return nil;
  }

  NSMutableArray<NSIndexPath *> *indexPathsArray = [NSMutableArray arrayWithCapacity:indexPaths.count];

  for (NSIndexPath *indexPathInView in indexPaths) {
    NSIndexPath *indexPath = [self convertIndexPathToCollectionNode:indexPathInView];
    if (indexPath != nil) {
      [indexPathsArray addObject:indexPath];
    }
  }
  return indexPathsArray;
}

- (ASCellNode *)supplementaryNodeForElementKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
  return [_dataController.visibleMap supplementaryElementOfKind:elementKind atIndexPath:indexPath].node;
}

- (NSIndexPath *)indexPathForNode:(ASCellNode *)cellNode
{
  return [_dataController.visibleMap indexPathForElement:cellNode.collectionElement];
}

- (NSArray *)visibleNodes
{
  NSArray *indexPaths = [self indexPathsForVisibleItems];
  NSMutableArray *visibleNodes = [[NSMutableArray alloc] init];
  
  for (NSIndexPath *indexPath in indexPaths) {
    ASCellNode *node = [self nodeForItemAtIndexPath:indexPath];
    if (node) {
      // It is possible for UICollectionView to return indexPaths before the node is completed.
      [visibleNodes addObject:node];
    }
  }
  
  return visibleNodes;
}

- (BOOL)usesSynchronousDataLoading
{
  return self.dataController.usesSynchronousDataLoading;
}

- (void)setUsesSynchronousDataLoading:(BOOL)usesSynchronousDataLoading
{
  self.dataController.usesSynchronousDataLoading = usesSynchronousDataLoading;
}

- (void)invalidateFlowLayoutDelegateMetrics {
  for (ASCollectionElement *element in self.dataController.pendingMap) {
    // This may be either a Supplementary or Item type element.
    // For UIKit passthrough cells of either type, re-fetch their sizes from the standard UIKit delegate methods.
    ASCellNode *node = element.node;
    if (node.shouldUseUIKitCell) {
      NSIndexPath *indexPath = [self indexPathForNode:node];
      NSString *kind = [element supplementaryElementKind];
      CGSize previousSize = node.style.preferredSize;
      CGSize size = [self _sizeForUIKitCellWithKind:kind atIndexPath:indexPath];

      if (!CGSizeEqualToSize(previousSize, size)) {
        node.style.preferredSize = size;
        [node invalidateCalculatedLayout];
      }
    }
  }
}

#pragma mark Internal

- (void)_configureCollectionViewLayout:(nonnull UICollectionViewLayout *)layout
{
  _hasDataControllerLayoutDelegate = [layout conformsToProtocol:@protocol(ASDataControllerLayoutDelegate)];
  if (_hasDataControllerLayoutDelegate) {
    _dataController.layoutDelegate = (id<ASDataControllerLayoutDelegate>)layout;
  }
}

/**
 This method is called only for UIKit Passthrough cells - either regular Items or Supplementary elements.
 It checks if the delegate implements the UICollectionViewFlowLayout methods that provide sizes, and if not,
 uses the default values set on the flow layout. If a flow layout is not in use, UICollectionView Passthrough
 cells must be sized by logic in the Layout object, and Texture does not participate in these paths.
*/
- (CGSize)_sizeForUIKitCellWithKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
  CGSize size = CGSizeZero;
  UICollectionViewLayout *l = self.collectionViewLayout;

  if (kind == nil) {
    ASDisplayNodeAssert(_asyncDataSourceFlags.interop, @"This code should not be called except for UIKit passthrough compatibility");
    SEL sizeForItem = @selector(collectionView:layout:sizeForItemAtIndexPath:);
    if ([_asyncDelegate respondsToSelector:sizeForItem]) {
      size = [(id)_asyncDelegate collectionView:self layout:l sizeForItemAtIndexPath:indexPath];
    } else {
      size = ASFlowLayoutDefault(l, itemSize, CGSizeZero);
    }
  } else if ([kind isEqualToString:UICollectionElementKindSectionHeader]) {
    ASDisplayNodeAssert(_asyncDataSourceFlags.interopViewForSupplementaryElement, @"This code should not be called except for UIKit passthrough compatibility");
    SEL sizeForHeader = @selector(collectionView:layout:referenceSizeForHeaderInSection:);
    if ([_asyncDelegate respondsToSelector:sizeForHeader]) {
      size = [(id)_asyncDelegate collectionView:self layout:l referenceSizeForHeaderInSection:indexPath.section];
    } else {
      size = ASFlowLayoutDefault(l, headerReferenceSize, CGSizeZero);
    }
  } else if ([kind isEqualToString:UICollectionElementKindSectionFooter]) {
    ASDisplayNodeAssert(_asyncDataSourceFlags.interopViewForSupplementaryElement, @"This code should not be called except for UIKit passthrough compatibility");
    SEL sizeForFooter = @selector(collectionView:layout:referenceSizeForFooterInSection:);
    if ([_asyncDelegate respondsToSelector:sizeForFooter]) {
      size = [(id)_asyncDelegate collectionView:self layout:l referenceSizeForFooterInSection:indexPath.section];
    } else {
      size = ASFlowLayoutDefault(l, footerReferenceSize, CGSizeZero);
    }
  }

  return size;
}

/**
 Performing nested batch updates with super (e.g. resizing a cell node & updating collection view during same frame)
 can cause super to throw data integrity exceptions because it checks the data source counts before
 the update is complete.
 
 Always call [self _superPerform:] rather than [super performBatch:] so that we can keep our `superPerformingBatchUpdates` flag updated.
*/
- (void)_superPerformBatchUpdates:(void(^)())updates completion:(void(^)(BOOL finished))completion
{
  ASDisplayNodeAssertMainThread();
  
  _superBatchUpdateCount++;
  [super performBatchUpdates:updates completion:completion];
  _superBatchUpdateCount--;
}

#pragma mark Assertions.

- (ASDataController *)dataController
{
  return _dataController;
}

- (void)beginUpdates
{
  ASDisplayNodeAssertMainThread();
  // _changeSet must be available during batch update
  ASDisplayNodeAssertTrue((_batchUpdateCount > 0) == (_changeSet != nil));
  
  if (_batchUpdateCount == 0) {
    _changeSet = [[_ASHierarchyChangeSet alloc] initWithOldData:[_dataController itemCountsFromDataSource]];
    _changeSet.rootActivity = as_activity_create("Perform async collection update", AS_ACTIVITY_CURRENT, OS_ACTIVITY_FLAG_DEFAULT);
    _changeSet.submitActivity = as_activity_create("Submit changes for collection update", _changeSet.rootActivity, OS_ACTIVITY_FLAG_DEFAULT);
  }
  _batchUpdateCount++;  
}

- (void)endUpdatesAnimated:(BOOL)animated completion:(nullable void (^)(BOOL))completion
{
  ASDisplayNodeAssertMainThread();
  ASDisplayNodeAssertNotNil(_changeSet, @"_changeSet must be available when batch update ends");

  _batchUpdateCount--;
  // Prevent calling endUpdatesAnimated:completion: in an unbalanced way
  NSAssert(_batchUpdateCount >= 0, @"endUpdatesAnimated:completion: called without having a balanced beginUpdates call");
  
  [_changeSet addCompletionHandler:completion];
  
  if (_batchUpdateCount == 0) {
    _ASHierarchyChangeSet *changeSet = _changeSet;

    // Nil out _changeSet before forwarding to _dataController to allow the change set to cause subsequent batch updates on the same run loop
    _changeSet = nil;
    changeSet.animated = animated;
    [_dataController updateWithChangeSet:changeSet];
  }
}

- (void)performBatchAnimated:(BOOL)animated updates:(void (^)())updates completion:(void (^)(BOOL))completion
{
  ASDisplayNodeAssertMainThread();
  [self beginUpdates];
  as_activity_scope(_changeSet.rootActivity);
  {
    // Only include client code in the submit activity, the rest just lives in the root activity. 
    as_activity_scope(_changeSet.submitActivity);
    if (updates) {
      updates();
    }
  }
  [self endUpdatesAnimated:animated completion:completion];
}

- (void)performBatchUpdates:(void (^)())updates completion:(void (^)(BOOL))completion
{
  // We capture the current state of whether animations are enabled if they don't provide us with one.
  [self performBatchAnimated:[UIView areAnimationsEnabled] updates:updates completion:completion];
}

- (void)registerSupplementaryNodeOfKind:(NSString *)elementKind
{
  ASDisplayNodeAssert(elementKind != nil, @"A kind is needed for supplementary node registration");
  [_registeredSupplementaryKinds addObject:elementKind];
  [self registerClass:[_ASCollectionReusableView class] forSupplementaryViewOfKind:elementKind withReuseIdentifier:kReuseIdentifier];
}

- (void)insertSections:(NSIndexSet *)sections
{
  ASDisplayNodeAssertMainThread();
  if (sections.count == 0) { return; }
  [self performBatchUpdates:^{
    [_changeSet insertSections:sections animationOptions:kASCollectionViewAnimationNone];
  } completion:nil];
}

- (void)deleteSections:(NSIndexSet *)sections
{
  ASDisplayNodeAssertMainThread();
  if (sections.count == 0) { return; }
  [self performBatchUpdates:^{
    [_changeSet deleteSections:sections animationOptions:kASCollectionViewAnimationNone];
  } completion:nil];
}

- (void)reloadSections:(NSIndexSet *)sections
{
  ASDisplayNodeAssertMainThread();
  if (sections.count == 0) { return; }
  [self performBatchUpdates:^{
    [_changeSet reloadSections:sections animationOptions:kASCollectionViewAnimationNone];
  } completion:nil];
}

- (void)moveSection:(NSInteger)section toSection:(NSInteger)newSection
{
  ASDisplayNodeAssertMainThread();
  [self performBatchUpdates:^{
    [_changeSet moveSection:section toSection:newSection animationOptions:kASCollectionViewAnimationNone];
  } completion:nil];
}

- (id<ASSectionContext>)contextForSection:(NSInteger)section
{
  ASDisplayNodeAssertMainThread();
  return [_dataController.visibleMap contextForSection:section];
}

- (void)insertItemsAtIndexPaths:(NSArray *)indexPaths
{
  ASDisplayNodeAssertMainThread();
  if (indexPaths.count == 0) { return; }
  [self performBatchUpdates:^{
    [_changeSet insertItems:indexPaths animationOptions:kASCollectionViewAnimationNone];
  } completion:nil];
}

- (void)deleteItemsAtIndexPaths:(NSArray *)indexPaths
{
  ASDisplayNodeAssertMainThread();
  if (indexPaths.count == 0) { return; }
  [self performBatchUpdates:^{
    [_changeSet deleteItems:indexPaths animationOptions:kASCollectionViewAnimationNone];
  } completion:nil];
}

- (void)reloadItemsAtIndexPaths:(NSArray *)indexPaths
{
  ASDisplayNodeAssertMainThread();
  if (indexPaths.count == 0) { return; }
  [self performBatchUpdates:^{
    [_changeSet reloadItems:indexPaths animationOptions:kASCollectionViewAnimationNone];
  } completion:nil];
}

- (void)moveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath
{
  ASDisplayNodeAssertMainThread();
  [self performBatchUpdates:^{
    [_changeSet moveItemAtIndexPath:indexPath toIndexPath:newIndexPath animationOptions:kASCollectionViewAnimationNone];
  } completion:nil];
}

#pragma mark -
#pragma mark Intercepted selectors.

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
  if (_superIsPendingDataLoad) {
    [_rangeController setNeedsUpdate];
    [self _scheduleCheckForBatchFetchingForNumberOfChanges:1];
    _superIsPendingDataLoad = NO;
  }
  return _dataController.visibleMap.numberOfSections;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  return [_dataController.visibleMap numberOfItemsInSection:section];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)layout
                                            sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  ASDisplayNodeAssertMainThread();
  ASCollectionElement *e = [_dataController.visibleMap elementForItemAtIndexPath:indexPath];
  return e ? [self sizeForElement:e] : ASFlowLayoutDefault(layout, itemSize, CGSizeZero);
}

- (CGSize)collectionView:(UICollectionView *)cv layout:(UICollectionViewLayout *)l
                       referenceSizeForHeaderInSection:(NSInteger)section
{
  ASDisplayNodeAssertMainThread();
  ASElementMap *map = _dataController.visibleMap;
  ASCollectionElement *e = [map supplementaryElementOfKind:UICollectionElementKindSectionHeader
                                               atIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
  return e ? [self sizeForElement:e] : ASFlowLayoutDefault(l, headerReferenceSize, CGSizeZero);
}

- (CGSize)collectionView:(UICollectionView *)cv layout:(UICollectionViewLayout *)l
                       referenceSizeForFooterInSection:(NSInteger)section
{
  ASDisplayNodeAssertMainThread();
  ASElementMap *map = _dataController.visibleMap;
  ASCollectionElement *e = [map supplementaryElementOfKind:UICollectionElementKindSectionFooter
                                               atIndexPath:[NSIndexPath indexPathForItem:0 inSection:section]];
  return e ? [self sizeForElement:e] : ASFlowLayoutDefault(l, footerReferenceSize, CGSizeZero);
}

// For the methods that call delegateIndexPathForSection:withSelector:, translate the section from
// visibleMap to pendingMap. If the section no longer exists, or the delegate doesn't implement
// the selector, we will return NSNotFound (and then use the ASFlowLayoutDefault).
- (NSInteger)delegateIndexForSection:(NSInteger)section withSelector:(SEL)selector
{
  if ([_asyncDelegate respondsToSelector:selector]) {
    return [_dataController.pendingMap convertSection:section fromMap:_dataController.visibleMap];
  } else {
    return NSNotFound;
  }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)cv layout:(UICollectionViewLayout *)l
                                      insetForSectionAtIndex:(NSInteger)section
{
  section = [self delegateIndexForSection:section withSelector:_cmd];
  if (section != NSNotFound) {
    return [(id)_asyncDelegate collectionView:cv layout:l insetForSectionAtIndex:section];
  }
  return ASFlowLayoutDefault(l, sectionInset, UIEdgeInsetsZero);
}

- (CGFloat)collectionView:(UICollectionView *)cv layout:(UICollectionViewLayout *)l
               minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
  section = [self delegateIndexForSection:section withSelector:_cmd];
  if (section != NSNotFound) {
    return [(id)_asyncDelegate collectionView:cv layout:l
               minimumInteritemSpacingForSectionAtIndex:section];
  }
  return ASFlowLayoutDefault(l, minimumInteritemSpacing, 10.0); // Default is documented as 10.0
}

- (CGFloat)collectionView:(UICollectionView *)cv layout:(UICollectionViewLayout *)l
                    minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
  section = [self delegateIndexForSection:section withSelector:_cmd];
  if (section != NSNotFound) {
    return [(id)_asyncDelegate collectionView:cv layout:l
                    minimumLineSpacingForSectionAtIndex:section];
  }
  return ASFlowLayoutDefault(l, minimumLineSpacing, 10.0);      // Default is documented as 10.0
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
  if ([_registeredSupplementaryKinds containsObject:kind] == NO) {
    [self registerSupplementaryNodeOfKind:kind];
  }
  
  UICollectionReusableView *view = nil;
  ASCollectionElement *element = [_dataController.visibleMap supplementaryElementOfKind:kind atIndexPath:indexPath];
  ASCellNode *node = element.node;

  BOOL shouldDequeueExternally = _asyncDataSourceFlags.interopViewForSupplementaryElement && (_asyncDataSourceFlags.interopAlwaysDequeue || node.shouldUseUIKitCell);
  if (shouldDequeueExternally) {
    // This codepath is used for both IGListKit mode, and app-level UICollectionView interop.
    view = [(id<ASCollectionDataSourceInterop>)_asyncDataSource collectionView:collectionView viewForSupplementaryElementOfKind:kind atIndexPath:indexPath];
  } else {
    ASDisplayNodeAssert(node != nil, @"Supplementary node should exist.  Kind = %@, indexPath = %@, collectionDataSource = %@", kind, indexPath, self);
    view = [self dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:kReuseIdentifier forIndexPath:indexPath];
  }
  
  if (_ASCollectionReusableView *reusableView = ASDynamicCastStrict(view, _ASCollectionReusableView)) {
    reusableView.element = element;
  }
  
  if (node) {
    [_rangeController configureContentView:view forCellNode:node];
  }

  return view;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  UICollectionViewCell *cell = nil;
  ASCollectionElement *element = [_dataController.visibleMap elementForItemAtIndexPath:indexPath];
  ASCellNode *node = element.node;

  BOOL shouldDequeueExternally = _asyncDataSourceFlags.interopAlwaysDequeue || (_asyncDataSourceFlags.interop && node.shouldUseUIKitCell);
  if (shouldDequeueExternally) {
    cell = [(id<ASCollectionDataSourceInterop>)_asyncDataSource collectionView:collectionView cellForItemAtIndexPath:indexPath];
  } else {
    cell = [self dequeueReusableCellWithReuseIdentifier:kReuseIdentifier forIndexPath:indexPath];
  }

  ASDisplayNodeAssert(element != nil, @"Element should exist. indexPath = %@, collectionDataSource = %@", indexPath, self);

  if (_ASCollectionViewCell *asCell = ASDynamicCastStrict(cell, _ASCollectionViewCell)) {
    asCell.element = element;
    [_rangeController configureContentView:cell.contentView forCellNode:node];
  }
  
  return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)rawCell forItemAtIndexPath:(NSIndexPath *)indexPath
{
  if (_asyncDelegateFlags.interopWillDisplayCell) {
    ASCellNode *node = [self nodeForItemAtIndexPath:indexPath];
    if (node.shouldUseUIKitCell) {
      [(id <ASCollectionDelegateInterop>)_asyncDelegate collectionView:collectionView willDisplayCell:rawCell forItemAtIndexPath:indexPath];
    }
  }

  _ASCollectionViewCell *cell = ASDynamicCastStrict(rawCell, _ASCollectionViewCell);
  if (cell == nil) {
    [_rangeController setNeedsUpdate];
    return;
  }

  ASCollectionElement *element = cell.element;
  if (element) {
    ASDisplayNodeAssertTrue([_dataController.visibleMap elementForItemAtIndexPath:indexPath] == element);
    [_visibleElements addObject:element];
  } else {
    ASDisplayNodeAssert(NO, @"Unexpected nil element for willDisplayCell: %@, %@, %@", rawCell, self, indexPath);
    return;
  }

  ASCellNode *cellNode = element.node;
  cellNode.scrollView = collectionView;

  // Update the selected background view in collectionView:willDisplayCell:forItemAtIndexPath: otherwise it could be too
  // early e.g. if the selectedBackgroundView was set in didLoad()
  cell.selectedBackgroundView = cellNode.selectedBackgroundView;
  
  // Under iOS 10+, cells may be removed/re-added to the collection view without
  // receiving prepareForReuse/applyLayoutAttributes, as an optimization for e.g.
  // if the user is scrolling back and forth across a small set of items.
  // In this case, we have to fetch the layout attributes manually.
  // This may be possible under iOS < 10 but it has not been observed yet.
  if (cell.layoutAttributes == nil) {
    cell.layoutAttributes = [collectionView layoutAttributesForItemAtIndexPath:indexPath];
  }

  ASDisplayNodeAssertNotNil(cellNode, @"Expected node associated with cell that will be displayed not to be nil. indexPath: %@", indexPath);

  if (_asyncDelegateFlags.collectionNodeWillDisplayItem && self.collectionNode != nil) {
    [_asyncDelegate collectionNode:self.collectionNode willDisplayItemWithNode:cellNode];
  } else if (_asyncDelegateFlags.collectionViewWillDisplayNodeForItem) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [_asyncDelegate collectionView:self willDisplayNode:cellNode forItemAtIndexPath:indexPath];
  } else if (_asyncDelegateFlags.collectionViewWillDisplayNodeForItemDeprecated) {
    [_asyncDelegate collectionView:self willDisplayNodeForItemAtIndexPath:indexPath];
  }
#pragma clang diagnostic pop
  
  [_rangeController setNeedsUpdate];
  
  if ([cell consumesCellNodeVisibilityEvents]) {
    [_cellsForVisibilityUpdates addObject:cell];
  }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)rawCell forItemAtIndexPath:(NSIndexPath *)indexPath
{
  if (_asyncDelegateFlags.interopDidEndDisplayingCell) {
    ASCellNode *node = [self nodeForItemAtIndexPath:indexPath];
    if (node.shouldUseUIKitCell) {
      [(id <ASCollectionDelegateInterop>)_asyncDelegate collectionView:collectionView didEndDisplayingCell:rawCell forItemAtIndexPath:indexPath];
    }
  }

  _ASCollectionViewCell *cell = ASDynamicCastStrict(rawCell, _ASCollectionViewCell);
  if (cell == nil) {
    [_rangeController setNeedsUpdate];
    return;
  }

  // Retrieve the element from cell instead of visible map because at this point visible map could have been updated and no longer holds the element.
  ASCollectionElement *element = cell.element;
  if (element) {
    [_visibleElements removeObject:element];
  } else {
    ASDisplayNodeAssert(NO, @"Unexpected nil element for didEndDisplayingCell: %@, %@, %@", rawCell, self, indexPath);
    return;
  }

  ASCellNode *cellNode = element.node;

  if (_asyncDelegateFlags.collectionNodeDidEndDisplayingItem) {
    if (ASCollectionNode *collectionNode = self.collectionNode) {
    	[_asyncDelegate collectionNode:collectionNode didEndDisplayingItemWithNode:cellNode];
    }
  } else if (_asyncDelegateFlags.collectionViewDidEndDisplayingNodeForItem) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [_asyncDelegate collectionView:self didEndDisplayingNode:cellNode forItemAtIndexPath:indexPath];
#pragma clang diagnostic pop
  }
  
  [_rangeController setNeedsUpdate];
  
  [_cellsForVisibilityUpdates removeObject:cell];
  
  cellNode.scrollView = nil;
  cell.layoutAttributes = nil;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplaySupplementaryView:(UICollectionReusableView *)rawView forElementKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
  if (_asyncDelegateFlags.interopWillDisplaySupplementaryView) {
    ASCellNode *node = [self supplementaryNodeForElementKind:elementKind atIndexPath:indexPath];
    if (node.shouldUseUIKitCell) {
      [(id <ASCollectionDelegateInterop>)_asyncDelegate collectionView:collectionView willDisplaySupplementaryView:rawView forElementKind:elementKind atIndexPath:indexPath];
    }
  }

  _ASCollectionReusableView *view = ASDynamicCastStrict(rawView, _ASCollectionReusableView);
  if (view == nil) {
    return;
  }

  ASCollectionElement *element = view.element;
  if (element) {
    ASDisplayNodeAssertTrue([_dataController.visibleMap supplementaryElementOfKind:elementKind atIndexPath:indexPath] == view.element);
    [_visibleElements addObject:element];
  } else {
    ASDisplayNodeAssert(NO, @"Unexpected nil element for willDisplaySupplementaryView: %@, %@, %@", rawView, self, indexPath);
    return;
  }

  // Under iOS 10+, cells may be removed/re-added to the collection view without
  // receiving prepareForReuse/applyLayoutAttributes, as an optimization for e.g.
  // if the user is scrolling back and forth across a small set of items.
  // In this case, we have to fetch the layout attributes manually.
  // This may be possible under iOS < 10 but it has not been observed yet.
  if (view.layoutAttributes == nil) {
    view.layoutAttributes = [collectionView layoutAttributesForSupplementaryElementOfKind:elementKind atIndexPath:indexPath];
  }

  if (_asyncDelegateFlags.collectionNodeWillDisplaySupplementaryElement) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, (void)0);
    ASCellNode *node = element.node;
    ASDisplayNodeAssert([node.supplementaryElementKind isEqualToString:elementKind], @"Expected node for supplementary element to have kind '%@', got '%@'.", elementKind, node.supplementaryElementKind);
    [_asyncDelegate collectionNode:collectionNode willDisplaySupplementaryElementWithNode:node];
  }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)rawView forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
  if (_asyncDelegateFlags.interopdidEndDisplayingSupplementaryView) {
    ASCellNode *node = [self supplementaryNodeForElementKind:elementKind atIndexPath:indexPath];
    if (node.shouldUseUIKitCell) {
      [(id <ASCollectionDelegateInterop>)_asyncDelegate collectionView:collectionView didEndDisplayingSupplementaryView:rawView forElementOfKind:elementKind atIndexPath:indexPath];
    }
  }

  _ASCollectionReusableView *view = ASDynamicCastStrict(rawView, _ASCollectionReusableView);
  if (view == nil) {
    return;
  }

  // Retrieve the element from cell instead of visible map because at this point visible map could have been updated and no longer holds the element.
  ASCollectionElement *element = view.element;
  if (element) {
    [_visibleElements removeObject:element];
  } else {
    ASDisplayNodeAssert(NO, @"Unexpected nil element for didEndDisplayingSupplementaryView: %@, %@, %@", rawView, self, indexPath);
    return;
  }

  if (_asyncDelegateFlags.collectionNodeDidEndDisplayingSupplementaryElement) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, (void)0);
    ASCellNode *node = element.node;
    ASDisplayNodeAssert([node.supplementaryElementKind isEqualToString:elementKind], @"Expected node for supplementary element to have kind '%@', got '%@'.", elementKind, node.supplementaryElementKind);
    [_asyncDelegate collectionNode:collectionNode didEndDisplayingSupplementaryElementWithNode:node];
  }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
  if (_asyncDelegateFlags.collectionNodeShouldSelectItem) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, NO);
    indexPath = [self convertIndexPathToCollectionNode:indexPath];
    if (indexPath != nil) {
      return [_asyncDelegate collectionNode:collectionNode shouldSelectItemAtIndexPath:indexPath];
    }
  } else if (_asyncDelegateFlags.collectionViewShouldSelectItem) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [_asyncDelegate collectionView:self shouldSelectItemAtIndexPath:indexPath];
#pragma clang diagnostic pop
  }
  return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
  if (_asyncDelegateFlags.collectionNodeDidSelectItem) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, (void)0);
    indexPath = [self convertIndexPathToCollectionNode:indexPath];
    if (indexPath != nil) {
      [_asyncDelegate collectionNode:collectionNode didSelectItemAtIndexPath:indexPath];
    }
  } else if (_asyncDelegateFlags.collectionViewDidSelectItem) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [_asyncDelegate collectionView:self didSelectItemAtIndexPath:indexPath];
#pragma clang diagnostic pop
  }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
  if (_asyncDelegateFlags.collectionNodeShouldDeselectItem) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, NO);
    indexPath = [self convertIndexPathToCollectionNode:indexPath];
    if (indexPath != nil) {
      return [_asyncDelegate collectionNode:collectionNode shouldDeselectItemAtIndexPath:indexPath];
    }
  } else if (_asyncDelegateFlags.collectionViewShouldDeselectItem) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [_asyncDelegate collectionView:self shouldDeselectItemAtIndexPath:indexPath];
#pragma clang diagnostic pop
  }
  return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
  if (_asyncDelegateFlags.collectionNodeDidDeselectItem) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, (void)0);
    indexPath = [self convertIndexPathToCollectionNode:indexPath];
    if (indexPath != nil) {
      [_asyncDelegate collectionNode:collectionNode didDeselectItemAtIndexPath:indexPath];
    }
  } else if (_asyncDelegateFlags.collectionViewDidDeselectItem) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [_asyncDelegate collectionView:self didDeselectItemAtIndexPath:indexPath];
#pragma clang diagnostic pop
  }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
  if (_asyncDelegateFlags.collectionNodeShouldHighlightItem) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, NO);
    indexPath = [self convertIndexPathToCollectionNode:indexPath];
    if (indexPath != nil) {
      return [_asyncDelegate collectionNode:collectionNode shouldHighlightItemAtIndexPath:indexPath];
    } else {
      return YES;
    }
  } else if (_asyncDelegateFlags.collectionViewShouldHighlightItem) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [_asyncDelegate collectionView:self shouldHighlightItemAtIndexPath:indexPath];
#pragma clang diagnostic pop
  }
  return YES;
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
  if (_asyncDelegateFlags.collectionNodeDidHighlightItem) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, (void)0);
    indexPath = [self convertIndexPathToCollectionNode:indexPath];
    if (indexPath != nil) {
      [_asyncDelegate collectionNode:collectionNode didHighlightItemAtIndexPath:indexPath];
    }
  } else if (_asyncDelegateFlags.collectionViewDidHighlightItem) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [_asyncDelegate collectionView:self didHighlightItemAtIndexPath:indexPath];
#pragma clang diagnostic pop
  }
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
  if (_asyncDelegateFlags.collectionNodeDidUnhighlightItem) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, (void)0);
    indexPath = [self convertIndexPathToCollectionNode:indexPath];
    if (indexPath != nil) {
      [_asyncDelegate collectionNode:collectionNode didUnhighlightItemAtIndexPath:indexPath];
    }
  } else if (_asyncDelegateFlags.collectionViewDidUnhighlightItem) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [_asyncDelegate collectionView:self didUnhighlightItemAtIndexPath:indexPath];
#pragma clang diagnostic pop
  }
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
  if (_asyncDelegateFlags.collectionNodeShouldShowMenuForItem) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, NO);
    indexPath = [self convertIndexPathToCollectionNode:indexPath];
    if (indexPath != nil) {
      return [_asyncDelegate collectionNode:collectionNode shouldShowMenuForItemAtIndexPath:indexPath];
    }
  } else if (_asyncDelegateFlags.collectionViewShouldShowMenuForItem) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [_asyncDelegate collectionView:self shouldShowMenuForItemAtIndexPath:indexPath];
#pragma clang diagnostic pop
  }
  return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(nonnull SEL)action forItemAtIndexPath:(nonnull NSIndexPath *)indexPath withSender:(nullable id)sender
{
  if (_asyncDelegateFlags.collectionNodeCanPerformActionForItem) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, NO);
    indexPath = [self convertIndexPathToCollectionNode:indexPath];
    if (indexPath != nil) {
      return [_asyncDelegate collectionNode:collectionNode canPerformAction:action forItemAtIndexPath:indexPath sender:sender];
    }
  } else if (_asyncDelegateFlags.collectionViewCanPerformActionForItem) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [_asyncDelegate collectionView:self canPerformAction:action forItemAtIndexPath:indexPath withSender:sender];
#pragma clang diagnostic pop
  }
  return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(nonnull SEL)action forItemAtIndexPath:(nonnull NSIndexPath *)indexPath withSender:(nullable id)sender
{
  if (_asyncDelegateFlags.collectionNodePerformActionForItem) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, (void)0);
    indexPath = [self convertIndexPathToCollectionNode:indexPath];
    if (indexPath != nil) {
      [_asyncDelegate collectionNode:collectionNode performAction:action forItemAtIndexPath:indexPath sender:sender];
    }
  } else if (_asyncDelegateFlags.collectionViewPerformActionForItem) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [_asyncDelegate collectionView:self performAction:action forItemAtIndexPath:indexPath withSender:sender];
#pragma clang diagnostic pop
  }
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath
{
  // Mimic UIKit's gating logic.
  // If the data source doesn't support moving, then all bets are off.
  if (!_asyncDataSourceFlags.collectionNodeMoveItem) {
    return NO;
  }
  
  // Currently we do not support interactive moves when using async layout. The reason is, we do not have a mechanism
  // to propagate the "presentation data" element map (containing the speculative in-progress moves) to the layout delegate,
  // and this can cause exceptions to be thrown from UICV. For example, if you drag an item out of a section,
  // the element map will still contain N items in that section, even though there's only N-1 shown, and UICV will
  // throw an exception that you specified an element that doesn't exist.
  //
  // In iOS >= 11, this is made much easier by the UIDataSourceTranslating API. In previous versions of iOS our best bet
  // would be to capture the invalidation contexts that are sent during interactive moves and make our own data source translator.
  if ([self.collectionViewLayout isKindOfClass:[ASCollectionLayout class]]) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      as_log_debug(ASCollectionLog(), "Collection node item interactive movement is not supported when using a layout delegate. This message will only be logged once. Node: %@", ASObjectDescriptionMakeTiny(self));
    });
    return NO;
  }

  // If the data source implements canMoveItem, let them decide.
  if (_asyncDataSourceFlags.collectionNodeCanMoveItem) {
    if (auto cellNode = [self nodeForItemAtIndexPath:indexPath]) {
      GET_COLLECTIONNODE_OR_RETURN(collectionNode, NO);
      return [_asyncDataSource collectionNode:collectionNode canMoveItemWithNode:cellNode];
    }
  }
  
  // Otherwise allow the move for all items.
  return YES;
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
  ASDisplayNodeAssert(_asyncDataSourceFlags.collectionNodeMoveItem, @"Should not allow interactive collection item movement if data source does not support it.");
  
  // Inform the data source first, in case they call nodeForItemAtIndexPath:.
  // We want to make sure we return them the node for the item they have in mind.
  if (auto collectionNode = self.collectionNode) {
    [_asyncDataSource collectionNode:collectionNode moveItemAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
  }
  
  // Now we update our data controller's store.
  // Get up to date
  [self waitUntilAllUpdatesAreCommitted];
  // Set our flag to suppress informing super about the change.
  ASDisplayNodeAssertFalse(_updatingInResponseToInteractiveMove);
  _updatingInResponseToInteractiveMove = YES;
  // Submit the move
  [self moveItemAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
  // Wait for it to finish – should be fast!
  [self waitUntilAllUpdatesAreCommitted];
  // Clear the flag
  _updatingInResponseToInteractiveMove = NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  ASInterfaceState interfaceState = [self interfaceStateForRangeController:_rangeController];
  if (ASInterfaceStateIncludesVisible(interfaceState)) {
    [self _checkForBatchFetching];
  }
  for (_ASCollectionViewCell *cell in _cellsForVisibilityUpdates) {
    // _cellsForVisibilityUpdates only includes cells for ASCellNode subclasses with overrides of the visibility method.
    [cell cellNodeVisibilityEvent:ASCellNodeVisibilityEventVisibleRectChanged inScrollView:scrollView];
  }
  if (_asyncDelegateFlags.scrollViewDidScroll) {
    [_asyncDelegate scrollViewDidScroll:scrollView];
  }
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
  CGPoint contentOffset = scrollView.contentOffset;
  _deceleratingVelocity = CGPointMake(
    contentOffset.x - ((targetContentOffset != NULL) ? targetContentOffset->x : 0),
    contentOffset.y - ((targetContentOffset != NULL) ? targetContentOffset->y : 0)
  );

  if (targetContentOffset != NULL) {
    ASDisplayNodeAssert(_batchContext != nil, @"Batch context should exist");
    [self _beginBatchFetchingIfNeededWithContentOffset:*targetContentOffset velocity:velocity];
  }
  
  if (_asyncDelegateFlags.scrollViewWillEndDragging) {
    [_asyncDelegate scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:(targetContentOffset ? : &contentOffset)];
  }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
  _deceleratingVelocity = CGPointZero;
    
  if (_asyncDelegateFlags.scrollViewDidEndDecelerating) {
    [_asyncDelegate scrollViewDidEndDecelerating:scrollView];
  }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
  // If a scroll happens the current range mode needs to go to full
  _rangeController.contentHasBeenScrolled = YES;
  [_rangeController updateCurrentRangeWithMode:ASLayoutRangeModeFull];

  for (_ASCollectionViewCell *cell in _cellsForVisibilityUpdates) {
    [cell cellNodeVisibilityEvent:ASCellNodeVisibilityEventWillBeginDragging inScrollView:scrollView];
  }
  if (_asyncDelegateFlags.scrollViewWillBeginDragging) {
    [_asyncDelegate scrollViewWillBeginDragging:scrollView];
  }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
  for (_ASCollectionViewCell *cell in _cellsForVisibilityUpdates) {
    [cell cellNodeVisibilityEvent:ASCellNodeVisibilityEventDidEndDragging inScrollView:scrollView];
  }
  if (_asyncDelegateFlags.scrollViewDidEndDragging) {
    [_asyncDelegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
  }
}

#pragma mark - Scroll Direction.

- (BOOL)inverted
{
  return _inverted;
}

- (void)setInverted:(BOOL)inverted
{
  _inverted = inverted;
}

- (void)setLeadingScreensForBatching:(CGFloat)leadingScreensForBatching
{
  if (_leadingScreensForBatching != leadingScreensForBatching) {
    _leadingScreensForBatching = leadingScreensForBatching;
    ASPerformBlockOnMainThread(^{
      [self _checkForBatchFetching];
    });
  }
}

- (CGFloat)leadingScreensForBatching
{
  return _leadingScreensForBatching;
}

- (ASScrollDirection)scrollDirection
{
  CGPoint scrollVelocity;
  if (self.isTracking) {
    scrollVelocity = [self.panGestureRecognizer velocityInView:self.superview];
  } else {
    scrollVelocity = _deceleratingVelocity;
  }
  
  ASScrollDirection scrollDirection = [self _scrollDirectionForVelocity:scrollVelocity];
  return ASScrollDirectionApplyTransform(scrollDirection, self.transform);
}

- (ASScrollDirection)_scrollDirectionForVelocity:(CGPoint)scrollVelocity
{
  ASScrollDirection direction = ASScrollDirectionNone;
  ASScrollDirection scrollableDirections = [self scrollableDirections];
  
  if (ASScrollDirectionContainsHorizontalDirection(scrollableDirections)) { // Can scroll horizontally.
    if (scrollVelocity.x < 0.0) {
      direction |= ASScrollDirectionRight;
    } else if (scrollVelocity.x > 0.0) {
      direction |= ASScrollDirectionLeft;
    }
  }
  if (ASScrollDirectionContainsVerticalDirection(scrollableDirections)) { // Can scroll vertically.
    if (scrollVelocity.y < 0.0) {
      direction |= ASScrollDirectionDown;
    } else if (scrollVelocity.y > 0.0) {
      direction |= ASScrollDirectionUp;
    }
  }
  
  return direction;
}

- (ASScrollDirection)scrollableDirections
{
  ASDisplayNodeAssertNotNil(self.layoutInspector, @"Layout inspector should be assigned.");
  return [self.layoutInspector scrollableDirections];
}

- (void)layoutSubviews
{
  if (_cellsForLayoutUpdates.count > 0) {
    NSMutableArray<ASCellNode *> *nodesSizesChanged = [NSMutableArray array];
    [_dataController relayoutNodes:_cellsForLayoutUpdates nodesSizeChanged:nodesSizesChanged];
    [self nodesDidRelayout:nodesSizesChanged];
  }
  [_cellsForLayoutUpdates removeAllObjects];

  // Flush any pending invalidation action if needed.
  ASCollectionViewInvalidationStyle invalidationStyle = _nextLayoutInvalidationStyle;
  _nextLayoutInvalidationStyle = ASCollectionViewInvalidationStyleNone;
  switch (invalidationStyle) {
    case ASCollectionViewInvalidationStyleWithAnimation:
      if (0 == _superBatchUpdateCount) {
        [self _superPerformBatchUpdates:^{ } completion:nil];
      }
      break;
    case ASCollectionViewInvalidationStyleWithoutAnimation:
      [self.collectionViewLayout invalidateLayout];
      break;
    default:
      break;
  }
  
  // To ensure _maxSizeForNodesConstrainedSize is up-to-date for every usage, this call to super must be done last
  [super layoutSubviews];
    
  if (_zeroContentInsets) {
    self.contentInset = UIEdgeInsetsZero;
  }
  
  // Update range controller immediately if possible & needed.
  // Calling -updateIfNeeded in here with self.window == nil (early in the collection view's life)
  // may cause UICollectionView data related crashes. We'll update in -didMoveToWindow anyway.
  if (self.window != nil) {
    [_rangeController updateIfNeeded];
  }
}


#pragma mark - Batch Fetching

- (ASBatchContext *)batchContext
{
  return _batchContext;
}

- (BOOL)canBatchFetch
{
  // if the delegate does not respond to this method, there is no point in starting to fetch
  BOOL canFetch = _asyncDelegateFlags.collectionNodeWillBeginBatchFetch || _asyncDelegateFlags.collectionViewWillBeginBatchFetch;
  if (canFetch && _asyncDelegateFlags.shouldBatchFetchForCollectionNode) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, NO);
    return [_asyncDelegate shouldBatchFetchForCollectionNode:collectionNode];
  } else if (canFetch && _asyncDelegateFlags.shouldBatchFetchForCollectionView) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [_asyncDelegate shouldBatchFetchForCollectionView:self];
#pragma clang diagnostic pop
  } else {
    return canFetch;
  }
}

- (id<ASBatchFetchingDelegate>)batchFetchingDelegate{
  return self.collectionNode.batchFetchingDelegate;
}

- (void)_scheduleCheckForBatchFetchingForNumberOfChanges:(NSUInteger)changes
{
  // Prevent fetching will continually trigger in a loop after reaching end of content and no new content was provided
  if (changes == 0 && _hasEverCheckedForBatchFetchingDueToUpdate) {
    return;
  }
  _hasEverCheckedForBatchFetchingDueToUpdate = YES;
  
  // Push this to the next runloop to be sure the scroll view has the right content size
  dispatch_async(dispatch_get_main_queue(), ^{
    [self _checkForBatchFetching];
  });
}

- (void)_checkForBatchFetching
{
  // Dragging will be handled in scrollViewWillEndDragging:withVelocity:targetContentOffset:
  if (self.isDragging || self.isTracking) {
    return;
  }
  
  [self _beginBatchFetchingIfNeededWithContentOffset:self.contentOffset velocity:CGPointZero];
}

- (void)_beginBatchFetchingIfNeededWithContentOffset:(CGPoint)contentOffset velocity:(CGPoint)velocity
{
  if (ASDisplayShouldFetchBatchForScrollView(self, self.scrollDirection, self.scrollableDirections, contentOffset, velocity)) {
    [self _beginBatchFetching];
  }
}

- (void)_beginBatchFetching
{
  as_activity_create_for_scope("Batch fetch for collection node");
  [_batchContext beginBatchFetching];
  if (_asyncDelegateFlags.collectionNodeWillBeginBatchFetch) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      GET_COLLECTIONNODE_OR_RETURN(collectionNode, (void)0);
      as_log_debug(ASCollectionLog(), "Beginning batch fetch for %@ with context %@", collectionNode, _batchContext);
      [_asyncDelegate collectionNode:collectionNode willBeginBatchFetchWithContext:_batchContext];
    });
  } else if (_asyncDelegateFlags.collectionViewWillBeginBatchFetch) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
      [_asyncDelegate collectionView:self willBeginBatchFetchWithContext:_batchContext];
#pragma clang diagnostic pop
    });
  }
}

#pragma mark - ASDataControllerSource

- (id)dataController:(ASDataController *)dataController nodeModelForItemAtIndexPath:(NSIndexPath *)indexPath
{
  if (!_asyncDataSourceFlags.nodeModelForItem) {
    return nil;
  }

  GET_COLLECTIONNODE_OR_RETURN(collectionNode, nil);
  return [_asyncDataSource collectionNode:collectionNode nodeModelForItemAtIndexPath:indexPath];
}

- (ASCellNodeBlock)dataController:(ASDataController *)dataController nodeBlockAtIndexPath:(NSIndexPath *)indexPath
{
  ASDisplayNodeAssertMainThread();
  ASCellNodeBlock block = nil;
  ASCellNode *cell = nil;

  if (_asyncDataSourceFlags.collectionNodeNodeBlockForItem) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, ^{ return [[ASCellNode alloc] init]; });
    block = [_asyncDataSource collectionNode:collectionNode nodeBlockForItemAtIndexPath:indexPath];
  } else if (_asyncDataSourceFlags.collectionNodeNodeForItem) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, ^{ return [[ASCellNode alloc] init]; });
    cell = [_asyncDataSource collectionNode:collectionNode nodeForItemAtIndexPath:indexPath];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  } else if (_asyncDataSourceFlags.collectionViewNodeBlockForItem) {
    block = [_asyncDataSource collectionView:self nodeBlockForItemAtIndexPath:indexPath];
  } else if (_asyncDataSourceFlags.collectionViewNodeForItem) {
    cell = [_asyncDataSource collectionView:self nodeForItemAtIndexPath:indexPath];
  }
#pragma clang diagnostic pop

  // Handle nil node block or cell
  if (cell && [cell isKindOfClass:[ASCellNode class]]) {
    block = ^{
      return cell;
    };
  }

  if (block == nil) {
    if (_asyncDataSourceFlags.interop) {
      CGSize preferredSize = [self _sizeForUIKitCellWithKind:nil atIndexPath:indexPath];
      block = ^{
        ASCellNode *node = [[ASCellNode alloc] init];
        node.shouldUseUIKitCell = YES;
        node.style.preferredSize = preferredSize;
        return node;
      };
    } else {
      ASDisplayNodeFailAssert(@"ASCollection could not get a node block for item at index path %@: %@, %@. If you are trying to display a UICollectionViewCell, make sure your dataSource conforms to the <ASCollectionDataSourceInterop> protocol!", indexPath, cell, block);
      block = ^{
        return [[ASCellNode alloc] init];
      };
    }
  }

  // Wrap the node block
  __weak __typeof__(self) weakSelf = self;
  return ^{
    __typeof__(self) strongSelf = weakSelf;
    ASCellNode *node = (block != nil ? block() : [[ASCellNode alloc] init]);
    [node enterHierarchyState:ASHierarchyStateRangeManaged];
    if (node.interactionDelegate == nil) {
      node.interactionDelegate = strongSelf;
    }
    if (strongSelf.inverted) {
      node.transform = CATransform3DMakeScale(1, -1, 1) ;
    }
    return node;
  };
  return block;
}

- (NSUInteger)dataController:(ASDataController *)dataController rowsInSection:(NSUInteger)section
{
  if (_asyncDataSourceFlags.collectionNodeNumberOfItemsInSection) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, 0);
    return [_asyncDataSource collectionNode:collectionNode numberOfItemsInSection:section];
  } else if (_asyncDataSourceFlags.collectionViewNumberOfItemsInSection) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [_asyncDataSource collectionView:self numberOfItemsInSection:section];
#pragma clang diagnostic pop
  } else {
    return 0;
  }
}

- (NSUInteger)numberOfSectionsInDataController:(ASDataController *)dataController {
  if (_asyncDataSourceFlags.numberOfSectionsInCollectionNode) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, 0);
    return [_asyncDataSource numberOfSectionsInCollectionNode:collectionNode];
  } else if (_asyncDataSourceFlags.numberOfSectionsInCollectionView) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [_asyncDataSource numberOfSectionsInCollectionView:self];
#pragma clang diagnostic pop
  } else {
    return 1;
  }
}

- (BOOL)dataController:(ASDataController *)dataController presentedSizeForElement:(ASCollectionElement *)element matchesSize:(CGSize)size
{
  NSIndexPath *indexPath = [self indexPathForNode:element.node];
  if (indexPath == nil) {
    ASDisplayNodeFailAssert(@"Data controller should not ask for presented size for element that is not presented.");
    return YES;
  }
  UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:indexPath];
  return CGSizeEqualToSizeWithIn(attributes.size, size, FLT_EPSILON);
}

#pragma mark - ASDataControllerSource optional methods

- (ASCellNodeBlock)dataController:(ASDataController *)dataController supplementaryNodeBlockOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
  ASDisplayNodeAssertMainThread();
  ASCellNodeBlock nodeBlock = nil;
  ASCellNode *node = nil;
  if (_asyncDataSourceFlags.collectionNodeNodeBlockForSupplementaryElement) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, ^{ return [[ASCellNode alloc] init]; });
    nodeBlock = [_asyncDataSource collectionNode:collectionNode nodeBlockForSupplementaryElementOfKind:kind atIndexPath:indexPath];
  } else if (_asyncDataSourceFlags.collectionNodeNodeForSupplementaryElement) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, ^{ return [[ASCellNode alloc] init]; });
    node = [_asyncDataSource collectionNode:collectionNode nodeForSupplementaryElementOfKind:kind atIndexPath:indexPath];
  } else if (_asyncDataSourceFlags.collectionViewNodeForSupplementaryElement) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    node = [_asyncDataSource collectionView:self nodeForSupplementaryElementOfKind:kind atIndexPath:indexPath];
#pragma clang diagnostic pop
  }

  if (nodeBlock == nil) {
    if (node) {
      nodeBlock = ^{ return node; };
    } else {
      // In this case, the app code returned nil for the node and the nodeBlock.
      // If the UIKit method is implemented, then we should use it. Otherwise the CGSizeZero default will cause UIKit to not show it.
      CGSize preferredSize = CGSizeZero;
      BOOL useUIKitCell = _asyncDataSourceFlags.interopViewForSupplementaryElement;
      if (useUIKitCell) {
        preferredSize = [self _sizeForUIKitCellWithKind:kind atIndexPath:indexPath];
      }
      nodeBlock = ^{
        ASCellNode *node = [[ASCellNode alloc] init];
        node.shouldUseUIKitCell = useUIKitCell;
        node.style.preferredSize = preferredSize;
        return node;
      };
    }
  }

  return nodeBlock;
}

- (NSArray<NSString *> *)dataController:(ASDataController *)dataController supplementaryNodeKindsInSections:(NSIndexSet *)sections
{
  if (_asyncDataSourceFlags.collectionNodeSupplementaryElementKindsInSection) {
    NSMutableSet *kinds = [NSMutableSet set];
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, @[]);
    [sections enumerateIndexesUsingBlock:^(NSUInteger section, BOOL * _Nonnull stop) {
      NSArray<NSString *> *kindsForSection = [_asyncDataSource collectionNode:collectionNode supplementaryElementKindsInSection:section];
      [kinds addObjectsFromArray:kindsForSection];
    }];
    return [kinds allObjects];
  } else {
    // TODO: Lock this
    return [_registeredSupplementaryKinds allObjects];
  }
}

- (ASSizeRange)dataController:(ASDataController *)dataController constrainedSizeForNodeAtIndexPath:(NSIndexPath *)indexPath
{
  return [self.layoutInspector collectionView:self constrainedSizeForNodeAtIndexPath:indexPath];
}

- (ASSizeRange)dataController:(ASDataController *)dataController constrainedSizeForSupplementaryNodeOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
  if (_layoutInspectorFlags.constrainedSizeForSupplementaryNodeOfKindAtIndexPath) {
    return [self.layoutInspector collectionView:self constrainedSizeForSupplementaryNodeOfKind:kind atIndexPath:indexPath];
  }
  
  ASDisplayNodeAssert(NO, @"To support supplementary nodes in ASCollectionView, it must have a layoutInspector for layout inspection. (See ASCollectionViewFlowLayoutInspector for an example.)");
  return ASSizeRangeMake(CGSizeZero, CGSizeZero);
}

- (NSUInteger)dataController:(ASDataController *)dataController supplementaryNodesOfKind:(NSString *)kind inSection:(NSUInteger)section
{
  if (_asyncDataSource == nil) {
    return 0;
  }
  
  if (_layoutInspectorFlags.supplementaryNodesOfKindInSection) {
    return [self.layoutInspector collectionView:self supplementaryNodesOfKind:kind inSection:section];
  }

  ASDisplayNodeAssert(NO, @"To support supplementary nodes in ASCollectionView, it must have a layoutInspector for layout inspection. (See ASCollectionViewFlowLayoutInspector for an example.)");
  return 0;
}

- (id<ASSectionContext>)dataController:(ASDataController *)dataController contextForSection:(NSInteger)section
{
  ASDisplayNodeAssertMainThread();
  id<ASSectionContext> context = nil;
  
  if (_asyncDataSourceFlags.collectionNodeContextForSection) {
    GET_COLLECTIONNODE_OR_RETURN(collectionNode, nil);
    context = [_asyncDataSource collectionNode:collectionNode contextForSection:section];
  }
  
  if (context != nil) {
    context.collectionView = self;
  }
  return context;
}

#pragma mark - ASRangeControllerDataSource

- (ASRangeController *)rangeController
{
  return _rangeController;
}

- (NSHashTable<ASCollectionElement *> *)visibleElementsForRangeController:(ASRangeController *)rangeController
{
  return ASPointerTableByFlatMapping(_visibleElements, id element, element);
}

- (ASElementMap *)elementMapForRangeController:(ASRangeController *)rangeController
{
  return _dataController.visibleMap;
}

- (ASScrollDirection)scrollDirectionForRangeController:(ASRangeController *)rangeController
{
  return self.scrollDirection;
}

- (ASInterfaceState)interfaceStateForRangeController:(ASRangeController *)rangeController
{
  return ASInterfaceStateForDisplayNode(self.collectionNode, self.window);
}

- (NSString *)nameForRangeControllerDataSource
{
  return self.asyncDataSource ? NSStringFromClass([self.asyncDataSource class]) : NSStringFromClass([self class]);
}

#pragma mark - ASRangeControllerDelegate

- (void)rangeController:(ASRangeController *)rangeController updateWithChangeSet:(_ASHierarchyChangeSet *)changeSet updates:(dispatch_block_t)updates
{
  ASDisplayNodeAssertMainThread();
  if (!self.asyncDataSource || _superIsPendingDataLoad || _updatingInResponseToInteractiveMove) {
    updates();
    [changeSet executeCompletionHandlerWithFinished:NO];
    return; // if the asyncDataSource has become invalid while we are processing, ignore this request to avoid crashes
  }

  //TODO Do we need to notify _layoutFacilitator before reloadData?
  for (_ASHierarchyItemChange *change in [changeSet itemChangesOfType:_ASHierarchyChangeTypeDelete]) {
    [_layoutFacilitator collectionViewWillEditCellsAtIndexPaths:change.indexPaths batched:YES];
  }

  for (_ASHierarchySectionChange *change in [changeSet sectionChangesOfType:_ASHierarchyChangeTypeDelete]) {
    [_layoutFacilitator collectionViewWillEditSectionsAtIndexSet:change.indexSet batched:YES];
  }

  for (_ASHierarchySectionChange *change in [changeSet sectionChangesOfType:_ASHierarchyChangeTypeInsert]) {
    [_layoutFacilitator collectionViewWillEditSectionsAtIndexSet:change.indexSet batched:YES];
  }

  for (_ASHierarchyItemChange *change in [changeSet itemChangesOfType:_ASHierarchyChangeTypeInsert]) {
    [_layoutFacilitator collectionViewWillEditCellsAtIndexPaths:change.indexPaths batched:YES];
  }

  ASPerformBlockWithoutAnimation(!changeSet.animated, ^{
    as_activity_scope(as_activity_create("Commit collection update", changeSet.rootActivity, OS_ACTIVITY_FLAG_DEFAULT));
    if (changeSet.includesReloadData) {
      _superIsPendingDataLoad = YES;
      updates();
      [super reloadData];
      as_log_debug(ASCollectionLog(), "Did reloadData %@", self.collectionNode);
      [changeSet executeCompletionHandlerWithFinished:YES];
    } else {
      [_layoutFacilitator collectionViewWillPerformBatchUpdates];
      
      __block NSUInteger numberOfUpdates = 0;
      [self _superPerformBatchUpdates:^{
        updates();

        for (_ASHierarchyItemChange *change in [changeSet itemChangesOfType:_ASHierarchyChangeTypeReload]) {
          [super reloadItemsAtIndexPaths:change.indexPaths];
          numberOfUpdates++;
        }
        
        for (_ASHierarchySectionChange *change in [changeSet sectionChangesOfType:_ASHierarchyChangeTypeReload]) {
          [super reloadSections:change.indexSet];
          numberOfUpdates++;
        }
        
        for (_ASHierarchyItemChange *change in [changeSet itemChangesOfType:_ASHierarchyChangeTypeOriginalDelete]) {
          [super deleteItemsAtIndexPaths:change.indexPaths];
          numberOfUpdates++;
        }
        
        for (_ASHierarchySectionChange *change in [changeSet sectionChangesOfType:_ASHierarchyChangeTypeOriginalDelete]) {
          [super deleteSections:change.indexSet];
          numberOfUpdates++;
        }
        
        for (_ASHierarchySectionChange *change in [changeSet sectionChangesOfType:_ASHierarchyChangeTypeOriginalInsert]) {
          [super insertSections:change.indexSet];
          numberOfUpdates++;
        }
        
        for (_ASHierarchyItemChange *change in [changeSet itemChangesOfType:_ASHierarchyChangeTypeOriginalInsert]) {
          [super insertItemsAtIndexPaths:change.indexPaths];
          numberOfUpdates++;
        }
      } completion:^(BOOL finished){
        as_activity_scope(as_activity_create("Handle collection update completion", changeSet.rootActivity, OS_ACTIVITY_FLAG_DEFAULT));
        as_log_verbose(ASCollectionLog(), "Update animation finished %{public}@", self.collectionNode);
        // Flush any range changes that happened as part of the update animations ending.
        [_rangeController updateIfNeeded];
        [self _scheduleCheckForBatchFetchingForNumberOfChanges:numberOfUpdates];
        [changeSet executeCompletionHandlerWithFinished:finished];
      }];
      as_log_debug(ASCollectionLog(), "Completed batch update %{public}@", self.collectionNode);
      
      // Flush any range changes that happened as part of submitting the update.
      as_activity_scope(changeSet.rootActivity);
      [_rangeController updateIfNeeded];
    }
  });
}

#pragma mark - ASCellNodeDelegate

- (void)nodeSelectedStateDidChange:(ASCellNode *)node
{
  NSIndexPath *indexPath = [self indexPathForNode:node];
  if (indexPath) {
    if (node.isSelected) {
      [super selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
    } else {
      [super deselectItemAtIndexPath:indexPath animated:NO];
    }
  }
}

- (void)nodeHighlightedStateDidChange:(ASCellNode *)node
{
  NSIndexPath *indexPath = [self indexPathForNode:node];
  if (indexPath) {
    [self cellForItemAtIndexPath:indexPath].highlighted = node.isHighlighted;
  }
}

- (void)nodeDidInvalidateSize:(ASCellNode *)node
{
  [_cellsForLayoutUpdates addObject:node];
  [self setNeedsLayout];
}

- (void)nodesDidRelayout:(NSArray<ASCellNode *> *)nodes
{
  ASDisplayNodeAssertMainThread();
  
  if (nodes.count == 0) {
    return;
  }

  NSMutableArray<NSIndexPath *> *uikitIndexPaths = [NSMutableArray arrayWithCapacity:nodes.count];
  for (ASCellNode *node in nodes) {
    NSIndexPath *uikitIndexPath = [self indexPathForNode:node];
    if (uikitIndexPath != nil) {
      [uikitIndexPaths addObject:uikitIndexPath];
    }
  }
  
  [_layoutFacilitator collectionViewWillEditCellsAtIndexPaths:uikitIndexPaths batched:NO];
  
  ASCollectionViewInvalidationStyle invalidationStyle = _nextLayoutInvalidationStyle;
  for (ASCellNode *node in nodes) {
    if (invalidationStyle == ASCollectionViewInvalidationStyleNone) {
      // We nodesDidRelayout also while we are in layoutSubviews. This should be no problem as CA will ignore this
      // call while be in a layout pass
      [self setNeedsLayout];
      invalidationStyle = ASCollectionViewInvalidationStyleWithAnimation;
    }
    
    // If we think we're going to animate, check if this node will prevent it.
    if (invalidationStyle == ASCollectionViewInvalidationStyleWithAnimation) {
      // TODO: Incorporate `shouldAnimateSizeChanges` into ASEnvironmentState for performance benefit.
      static dispatch_once_t onceToken;
      static BOOL (^shouldNotAnimateBlock)(ASDisplayNode *);
      dispatch_once(&onceToken, ^{
        shouldNotAnimateBlock = ^BOOL(ASDisplayNode * _Nonnull node) {
          return (node.shouldAnimateSizeChanges == NO);
        };
      });
      if (ASDisplayNodeFindFirstNode(node, shouldNotAnimateBlock) != nil) {
        // One single non-animated node causes the whole layout update to be non-animated
        invalidationStyle = ASCollectionViewInvalidationStyleWithoutAnimation;
        break;
      }
    }
  }
  _nextLayoutInvalidationStyle = invalidationStyle;
}

#pragma mark - _ASDisplayView behavior substitutions
// Need these to drive interfaceState so we know when we are visible, if not nested in another range-managing element.
// Because our superclass is a true UIKit class, we cannot also subclass _ASDisplayView.
- (void)willMoveToWindow:(UIWindow *)newWindow
{
  BOOL visible = (newWindow != nil);
  ASDisplayNode *node = self.collectionNode;
  if (visible && !node.inHierarchy) {
    [node __enterHierarchy];
  }
}

- (void)didMoveToWindow
{
  BOOL visible = (self.window != nil);
  ASDisplayNode *node = self.collectionNode;
  if (!visible && node.inHierarchy) {
    [node __exitHierarchy];
  }

  // Updating the visible node index paths only for not range managed nodes. Range managed nodes will get their
  // their update in the layout pass
  if (![node supportsRangeManagedInterfaceState]) {
    [_rangeController setNeedsUpdate];
    [_rangeController updateIfNeeded];
  }

  // When we aren't visible, we will only fetch up to the visible area. Now that we are visible,
  // we will fetch visible area + leading screens, so we need to check.
  if (visible) {
    [self _checkForBatchFetching];
  }
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
  if (self.superview == nil && newSuperview != nil) {
    _keepalive_node = self.collectionNode;
  }
}

- (void)didMoveToSuperview
{
  if (self.superview == nil) {
    _keepalive_node = nil;
  }
}

#pragma mark ASCALayerExtendedDelegate

/**
 * TODO: This code was added when we used @c calculatedSize as the size for 
 * items (e.g. collectionView:layout:sizeForItemAtIndexPath:) and so it
 * was critical that we remeasured all nodes at this time.
 *
 * The assumption was that cv-bounds-size-change -> constrained-size-change, so
 * this was the time when we get new constrained sizes for all items and remeasure
 * them. However, the constrained sizes for items can be invalidated for many other
 * reasons, hence why we never reuse the old constrained size anymore.
 *
 * UICollectionView inadvertently triggers a -prepareLayout call to its layout object
 * between [super setFrame:] and [self layoutSubviews] during size changes. So we need
 * to get in there and re-measure our nodes before that -prepareLayout call.
 * We can't wait until -layoutSubviews or the end of -setFrame:.
 *
 * @see @p testThatNodeCalculatedSizesAreUpdatedBeforeFirstPrepareLayoutAfterRotation
 */
- (void)layer:(CALayer *)layer didChangeBoundsWithOldValue:(CGRect)oldBounds newValue:(CGRect)newBounds
{
  CGSize newSize = newBounds.size;
  CGSize lastUsedSize = _lastBoundsSizeUsedForMeasuringNodes;
  if (CGSizeEqualToSize(lastUsedSize, newSize)) {
    return;
  }
  if (_hasDataControllerLayoutDelegate || self.collectionViewLayout == nil) {
    // Let the layout delegate handle bounds changes if it's available. If no layout, it will init in the new state.
    return;
  }

  _lastBoundsSizeUsedForMeasuringNodes = newSize;

  // Laying out all nodes is expensive.
  // We only need to do this if the bounds changed in the non-scrollable direction.
  // If, for example, a vertical flow layout has its height changed due to a status bar
  // appearance update, we do not need to relayout all nodes.
  // For a more permanent fix to the unsafety mentioned above, see https://github.com/facebook/AsyncDisplayKit/pull/2182
  ASScrollDirection scrollDirection = self.scrollableDirections;
  BOOL fixedVertically   = (ASScrollDirectionContainsVerticalDirection  (scrollDirection) == NO);
  BOOL fixedHorizontally = (ASScrollDirectionContainsHorizontalDirection(scrollDirection) == NO);

  BOOL changedInNonScrollingDirection = (fixedHorizontally && newSize.width  != lastUsedSize.width) ||
                                        (fixedVertically   && newSize.height != lastUsedSize.height);

  if (changedInNonScrollingDirection) {
    [self relayoutItems];
  }
}

#pragma mark - UICollectionView dead-end intercepts

- (void)setPrefetchDataSource:(id<UICollectionViewDataSourcePrefetching>)prefetchDataSource
{
  return;
}

- (void)setPrefetchingEnabled:(BOOL)prefetchingEnabled
{
  return;
}

@end
