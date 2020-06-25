//
//  ASIGListAdapterBasedDataSource.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASAvailability.h>

#if AS_IG_LIST_KIT

#import "ASIGListAdapterBasedDataSource.h"
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import <objc/runtime.h>

typedef IGListSectionController<ASSectionController> ASIGSectionController;

/// The optional methods that a class implements from ASSectionController.
/// Note: Bitfields are not supported by NSValue so we can't use them.
typedef struct {
  BOOL sizeRangeForItem;
  BOOL shouldBatchFetch;
  BOOL beginBatchFetchWithContext;
} ASSectionControllerOverrides;

/// The optional methods that a class implements from ASSupplementaryNodeSource.
/// Note: Bitfields are not supported by NSValue so we can't use them.
typedef struct {
  BOOL sizeRangeForSupplementary;
} ASSupplementarySourceOverrides;

@protocol ASIGSupplementaryNodeSource <IGListSupplementaryViewSource, ASSupplementaryNodeSource>
@end

@interface ASIGListAdapterBasedDataSource ()
@property (nonatomic, weak, readonly) IGListAdapter *listAdapter;
@property (nonatomic, readonly) id<UICollectionViewDelegateFlowLayout> delegate;
@property (nonatomic, readonly) id<UICollectionViewDataSource> dataSource;
@property (nonatomic, weak, readonly) id<ASCollectionDelegate> collectionDelegate;

/**
 * The section controller that we will forward beginBatchFetchWithContext: to.
 * Since shouldBatchFetch: is called on main, we capture the last section controller in there,
 * and then we use it and clear it in beginBatchFetchWithContext: (on default queue).
 *
 * It is safe to use it without a lock in this limited way, since those two methods will
 * never execute in parallel.
 */
@property (nonatomic, weak) ASIGSectionController *sectionControllerForBatchFetching;
@end

@implementation ASIGListAdapterBasedDataSource

- (instancetype)initWithListAdapter:(IGListAdapter *)listAdapter collectionDelegate:(nullable id<ASCollectionDelegate>)collectionDelegate
{
  if (self = [super init]) {
#if IG_LIST_COLLECTION_VIEW
    [ASIGListAdapterBasedDataSource setASCollectionViewSuperclass];
#endif
    [ASIGListAdapterBasedDataSource configureUpdater:listAdapter.updater];

    ASDisplayNodeAssert([listAdapter conformsToProtocol:@protocol(UICollectionViewDataSource)], @"Expected IGListAdapter to conform to UICollectionViewDataSource.");
    ASDisplayNodeAssert([listAdapter conformsToProtocol:@protocol(UICollectionViewDelegateFlowLayout)], @"Expected IGListAdapter to conform to UICollectionViewDelegateFlowLayout.");
    _listAdapter = listAdapter;
    _collectionDelegate = collectionDelegate;
  }
  return self;
}

- (id<UICollectionViewDataSource>)dataSource
{
  return (id<UICollectionViewDataSource>)_listAdapter;
}

- (id<UICollectionViewDelegateFlowLayout>)delegate
{
  return (id<UICollectionViewDelegateFlowLayout>)_listAdapter;
}

#pragma mark - ASCollectionDelegate

- (void)collectionNode:(ASCollectionNode *)collectionNode didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
  [self.delegate collectionView:collectionNode.view didSelectItemAtIndexPath:indexPath];
}

- (void)collectionNode:(ASCollectionNode *)collectionNode didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
  [self.delegate collectionView:collectionNode.view didDeselectItemAtIndexPath:indexPath];
}

- (void)collectionNode:(ASCollectionNode *)collectionNode didHighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
  [self.delegate collectionView:collectionNode.view didHighlightItemAtIndexPath:indexPath];
}

- (void)collectionNode:(ASCollectionNode *)collectionNode didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath
{
  [self.delegate collectionView:collectionNode.view didUnhighlightItemAtIndexPath:indexPath];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  [self.delegate scrollViewDidScroll:scrollView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
  [self.delegate scrollViewWillBeginDragging:scrollView];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
  // IGListAdapter doesn't implement scrollViewWillEndDragging yet (pending pull request), so we need this check for now. Doesn't hurt to have it anyways :)
  if ([self.delegate respondsToSelector:@selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:)]) {
    [self.delegate scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
  }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
  [self.delegate scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
  [self.delegate scrollViewDidEndDecelerating:scrollView];
}

- (BOOL)shouldBatchFetchForCollectionNode:(ASCollectionNode *)collectionNode
{
  if ([_collectionDelegate respondsToSelector:@selector(shouldBatchFetchForCollectionNode:)]) {
    return [_collectionDelegate shouldBatchFetchForCollectionNode:collectionNode];
  }

  NSInteger sectionCount = [self numberOfSectionsInCollectionNode:collectionNode];
  if (sectionCount == 0) {
    return NO;
  }

  // If they implement shouldBatchFetch, call it. Otherwise, just say YES if they implement beginBatchFetch.
  ASIGSectionController *ctrl = [self sectionControllerForSection:sectionCount - 1];
  ASSectionControllerOverrides o = [ASIGListAdapterBasedDataSource overridesForSectionControllerClass:ctrl.class];
  BOOL result = (o.shouldBatchFetch ? [ctrl shouldBatchFetch] : o.beginBatchFetchWithContext);
  if (result) {
    self.sectionControllerForBatchFetching = ctrl;
  }
  return result;
}

- (void)collectionNode:(ASCollectionNode *)collectionNode willBeginBatchFetchWithContext:(ASBatchContext *)context
{
  if ([_collectionDelegate respondsToSelector:@selector(collectionNode:willBeginBatchFetchWithContext:)]) {
    [_collectionDelegate collectionNode:collectionNode willBeginBatchFetchWithContext:context];
    return;
  }
  
  ASIGSectionController *ctrl = self.sectionControllerForBatchFetching;
  self.sectionControllerForBatchFetching = nil;
  [ctrl beginBatchFetchWithContext:context];
}

- (void)collectionNode:(ASCollectionNode *)collectionNode willDisplayItemWithNode:(ASCellNode *)node
{
  NSIndexPath *indexPath = [collectionNode.view indexPathForNode:node];
  UIView *contentView = node.view.superview;
  UICollectionViewCell *cell = (UICollectionViewCell *)contentView.superview;

  if (cell == nil || indexPath == nil) {
    return;
  }

  [self.delegate collectionView:collectionNode.view willDisplayCell:cell forItemAtIndexPath:indexPath];
}

- (void)collectionNode:(ASCollectionNode *)collectionNode didEndDisplayingItemWithNode:(ASCellNode *)node
{
  NSIndexPath *indexPath = [collectionNode.view indexPathForNode:node];
  UIView *contentView = node.view.superview;
  UICollectionViewCell *cell = (UICollectionViewCell *)contentView.superview;

  if (cell == nil || indexPath == nil) {
    return;
  }

  [self.delegate collectionView:collectionNode.view didEndDisplayingCell:cell forItemAtIndexPath:indexPath];
}

/**
 * Note: It is not documented that ASCollectionNode will forward these UIKit delegate calls if they are implemented.
 * It is not considered harmful to do so, and adding them to documentation will confuse most users, who should
 * instead using the ASCollectionDelegate callbacks.
 */
#pragma mark - ASCollectionDelegateInterop

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
  [self.delegate collectionView:collectionView willDisplayCell:cell forItemAtIndexPath:indexPath];
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
  [self.delegate collectionView:collectionView didEndDisplayingCell:cell forItemAtIndexPath:indexPath];
}

#pragma mark - ASCollectionDelegateFlowLayout

- (ASSizeRange)collectionNode:(ASCollectionNode *)collectionNode sizeRangeForHeaderInSection:(NSInteger)section
{
  id<ASIGSupplementaryNodeSource> src = [self supplementaryElementSourceForSection:section];
  if ([ASIGListAdapterBasedDataSource overridesForSupplementarySourceClass:[src class]].sizeRangeForSupplementary) {
    return [src sizeRangeForSupplementaryElementOfKind:UICollectionElementKindSectionHeader atIndex:0];
  } else {
    return ASSizeRangeZero;
  }
}

- (ASSizeRange)collectionNode:(ASCollectionNode *)collectionNode sizeRangeForFooterInSection:(NSInteger)section
{
  id<ASIGSupplementaryNodeSource> src = [self supplementaryElementSourceForSection:section];
  if ([ASIGListAdapterBasedDataSource overridesForSupplementarySourceClass:[src class]].sizeRangeForSupplementary) {
    return [src sizeRangeForSupplementaryElementOfKind:UICollectionElementKindSectionFooter atIndex:0];
  } else {
    return ASSizeRangeZero;
  }
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
  return [self.delegate collectionView:collectionView layout:collectionViewLayout insetForSectionAtIndex:section];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
  return [self.delegate collectionView:collectionView layout:collectionViewLayout minimumLineSpacingForSectionAtIndex:section];
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
  return [self.delegate collectionView:collectionView layout:collectionViewLayout minimumInteritemSpacingForSectionAtIndex:section];
}

#pragma mark - ASCollectionDataSource

- (NSInteger)collectionNode:(ASCollectionNode *)collectionNode numberOfItemsInSection:(NSInteger)section
{
  return [self.dataSource collectionView:collectionNode.view numberOfItemsInSection:section];
}

- (NSInteger)numberOfSectionsInCollectionNode:(ASCollectionNode *)collectionNode
{
  return [self.dataSource numberOfSectionsInCollectionView:collectionNode.view];
}

- (ASCellNodeBlock)collectionNode:(ASCollectionNode *)collectionNode nodeBlockForItemAtIndexPath:(NSIndexPath *)indexPath
{
  ASIGSectionController *ctrl = [self sectionControllerForSection:indexPath.section];
  ASDisplayNodeAssert([ctrl respondsToSelector:@selector(nodeBlockForItemAtIndex:)], @"Expected section controller to respond to to %@. Controller: %@", NSStringFromSelector(@selector(nodeBlockForItemAtIndex:)), ctrl);
  return [ctrl nodeBlockForItemAtIndex:indexPath.item];
}

- (ASCellNode *)collectionNode:(ASCollectionNode *)collectionNode nodeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  ASIGSectionController *ctrl = [self sectionControllerForSection:indexPath.section];
  ASDisplayNodeAssert([ctrl respondsToSelector:@selector(nodeForItemAtIndex:)], @"Expected section controller to respond to to %@. Controller: %@", NSStringFromSelector(@selector(nodeForItemAtIndex:)), ctrl);
  return [ctrl nodeForItemAtIndex:indexPath.item];
}

- (ASSizeRange)collectionNode:(ASCollectionNode *)collectionNode constrainedSizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  ASIGSectionController *ctrl = [self sectionControllerForSection:indexPath.section];
  if ([ASIGListAdapterBasedDataSource overridesForSectionControllerClass:ctrl.class].sizeRangeForItem) {
    return [ctrl sizeRangeForItemAtIndex:indexPath.item];
  } else {
    return ASSizeRangeUnconstrained;
  }
}

- (ASCellNodeBlock)collectionNode:(ASCollectionNode *)collectionNode nodeBlockForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
  id<ASSupplementaryNodeSource> ctrl = [self supplementaryElementSourceForSection:indexPath.section];
  ASDisplayNodeAssert([ctrl respondsToSelector:@selector(nodeBlockForSupplementaryElementOfKind:atIndex:)], @"Expected section controller to respond to to %@. Controller: %@", NSStringFromSelector(@selector(nodeBlockForSupplementaryElementOfKind:atIndex:)), ctrl);
  return [ctrl nodeBlockForSupplementaryElementOfKind:kind atIndex:indexPath.item];
}

- (ASCellNode *)collectionNode:(ASCollectionNode *)collectionNode nodeForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
  id<ASSupplementaryNodeSource> ctrl = [self supplementaryElementSourceForSection:indexPath.section];
  ASDisplayNodeAssert([ctrl respondsToSelector:@selector(nodeForSupplementaryElementOfKind:atIndex:)], @"Expected section controller to respond to to %@. Controller: %@", NSStringFromSelector(@selector(nodeForSupplementaryElementOfKind:atIndex:)), ctrl);
  return [ctrl nodeForSupplementaryElementOfKind:kind atIndex:indexPath.item];
}

- (NSArray<NSString *> *)collectionNode:(ASCollectionNode *)collectionNode supplementaryElementKindsInSection:(NSInteger)section
{
  return [[self supplementaryElementSourceForSection:section] supportedElementKinds];
}

#pragma mark - ASCollectionDataSourceInterop

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
  return [self.dataSource collectionView:collectionView cellForItemAtIndexPath:indexPath];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
  return [self.dataSource collectionView:collectionView viewForSupplementaryElementOfKind:kind atIndexPath:indexPath];
}

+ (BOOL)dequeuesCellsForNodeBackedItems
{
  return YES;
}

#pragma mark - Helpers

- (id<ASIGSupplementaryNodeSource>)supplementaryElementSourceForSection:(NSInteger)section
{
  ASIGSectionController *ctrl = [self sectionControllerForSection:section];
  id<ASIGSupplementaryNodeSource> src = (id<ASIGSupplementaryNodeSource>)ctrl.supplementaryViewSource;
  ASDisplayNodeAssert(src == nil || [src conformsToProtocol:@protocol(ASSupplementaryNodeSource)], @"Supplementary view source should conform to %@", NSStringFromProtocol(@protocol(ASSupplementaryNodeSource)));
  return src;
}

- (ASIGSectionController *)sectionControllerForSection:(NSInteger)section
{
  id object = [_listAdapter objectAtSection:section];
  ASIGSectionController *ctrl = (ASIGSectionController *)[_listAdapter sectionControllerForObject:object];
  ASDisplayNodeAssert([ctrl conformsToProtocol:@protocol(ASSectionController)], @"Expected section controller to conform to %@. Controller: %@", NSStringFromProtocol(@protocol(ASSectionController)), ctrl);
  return ctrl;
}

/// If needed, set ASCollectionView's superclass to IGListCollectionView (IGListKit < 3.0).
#if IG_LIST_COLLECTION_VIEW
+ (void)setASCollectionViewSuperclass
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    class_setSuperclass([ASCollectionView class], [IGListCollectionView class]);
  });
#pragma clang diagnostic pop
}
#endif

/// Ensure updater won't call reloadData on us.
+ (void)configureUpdater:(id<IGListUpdatingDelegate>)updater
{
  // Cast to NSObject will be removed after https://github.com/Instagram/IGListKit/pull/435
  if ([(id<NSObject>)updater isKindOfClass:[IGListAdapterUpdater class]]) {
    [(IGListAdapterUpdater *)updater setAllowsBackgroundReloading:NO];
  } else {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      NSLog(@"WARNING: Use of non-%@ updater with AsyncDisplayKit is discouraged. Updater: %@", NSStringFromClass([IGListAdapterUpdater class]), updater);
    });
  }
}

+ (ASSupplementarySourceOverrides)overridesForSupplementarySourceClass:(Class)c
{
  static NSCache<Class, NSValue *> *cache;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    cache = [[NSCache alloc] init];
  });
  NSValue *obj = [cache objectForKey:c];
  ASSupplementarySourceOverrides o;
  if (obj == nil) {
    o.sizeRangeForSupplementary = [c instancesRespondToSelector:@selector(sizeRangeForSupplementaryElementOfKind:atIndex:)];
    obj = [NSValue valueWithBytes:&o objCType:@encode(ASSupplementarySourceOverrides)];
    [cache setObject:obj forKey:c];
  } else {
    [obj getValue:&o];
  }
  return o;
}

+ (ASSectionControllerOverrides)overridesForSectionControllerClass:(Class)c
{
  static NSCache<Class, NSValue *> *cache;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    cache = [[NSCache alloc] init];
  });
  NSValue *obj = [cache objectForKey:c];
  ASSectionControllerOverrides o;
  if (obj == nil) {
    o.sizeRangeForItem = [c instancesRespondToSelector:@selector(sizeRangeForItemAtIndex:)];
    o.beginBatchFetchWithContext = [c instancesRespondToSelector:@selector(beginBatchFetchWithContext:)];
    o.shouldBatchFetch = [c instancesRespondToSelector:@selector(shouldBatchFetch)];
    obj = [NSValue valueWithBytes:&o objCType:@encode(ASSectionControllerOverrides)];
    [cache setObject:obj forKey:c];
  } else {
    [obj getValue:&o];
  }
  return o;
}

@end

#endif // AS_IG_LIST_KIT
