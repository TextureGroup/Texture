//
//  ASCollectionLayout.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASCollectionLayout.h>

#import <AsyncDisplayKit/ASAssert.h>
#import <AsyncDisplayKit/ASAbstractLayoutController.h>
#import <AsyncDisplayKit/ASCellNode.h>
#import <AsyncDisplayKit/ASCollectionElement.h>
#import <AsyncDisplayKit/ASCollectionLayoutCache.h>
#import <AsyncDisplayKit/ASCollectionLayoutContext+Private.h>
#import <AsyncDisplayKit/ASCollectionLayoutDelegate.h>
#import <AsyncDisplayKit/ASCollectionLayoutState+Private.h>
#import <AsyncDisplayKit/ASCollectionNode+Beta.h>
#import <AsyncDisplayKit/ASDispatch.h>
#import <AsyncDisplayKit/ASDisplayNode+FrameworkPrivate.h>
#import <AsyncDisplayKit/ASElementMap.h>
#import <AsyncDisplayKit/ASEqualityHelpers.h>
#import <AsyncDisplayKit/ASPageTable.h>

static const ASRangeTuningParameters kASDefaultMeasureRangeTuningParameters = {
  .leadingBufferScreenfuls = 2.0,
  .trailingBufferScreenfuls = 2.0
};

static const ASScrollDirection kASStaticScrollDirection = (ASScrollDirectionRight | ASScrollDirectionDown);

@interface ASCollectionLayout () <ASDataControllerLayoutDelegate> {
  ASCollectionLayoutCache *_layoutCache;
  ASCollectionLayoutState *_layout; // Main thread only.

  struct {
    unsigned int implementsAdditionalInfoForLayoutWithElements:1;
  } _layoutDelegateFlags;
}

@end

@implementation ASCollectionLayout

- (instancetype)initWithLayoutDelegate:(id<ASCollectionLayoutDelegate>)layoutDelegate
{
  self = [super init];
  if (self) {
    ASDisplayNodeAssertNotNil(layoutDelegate, @"Collection layout delegate cannot be nil");
    _layoutDelegate = layoutDelegate;
    _layoutDelegateFlags.implementsAdditionalInfoForLayoutWithElements = [layoutDelegate respondsToSelector:@selector(additionalInfoForLayoutWithElements:)];
    _layoutCache = [[ASCollectionLayoutCache alloc] init];
  }
  return self;
}

#pragma mark - ASDataControllerLayoutDelegate

- (ASCollectionLayoutContext *)layoutContextWithElements:(ASElementMap *)elements
{
  ASDisplayNodeAssertMainThread();
  CGSize viewportSize = [self _viewportSize];
  id additionalInfo = nil;
  if (_layoutDelegateFlags.implementsAdditionalInfoForLayoutWithElements) {
    additionalInfo = [_layoutDelegate additionalInfoForLayoutWithElements:elements];
  }
  return [[ASCollectionLayoutContext alloc] initWithViewportSize:viewportSize elements:elements additionalInfo:additionalInfo];
}

- (ASCollectionLayoutState *)calculateLayoutWithContext:(ASCollectionLayoutContext *)context
{
  ASCollectionLayoutState *layout = [_layoutDelegate calculateLayoutWithContext:context];
  [_layoutCache setLayout:layout forContext:context];

  // Measure elements in the measure range ahead of time, block on the initial rect as it'll be visible shortly
  CGSize viewportSize = context.viewportSize;
  // TODO Consider content offset of the collection node
  CGRect initialRect = CGRectMake(0, 0, viewportSize.width, viewportSize.height);
  CGRect measureRect = CGRectExpandToRangeWithScrollableDirections(initialRect,
                                                                   kASDefaultMeasureRangeTuningParameters,
                                                                   _layoutDelegate.scrollableDirections,
                                                                   kASStaticScrollDirection);
  ASCollectionLayoutMeasureElementsInRects(measureRect, initialRect, layout);

  return layout;
}

#pragma mark - UICollectionViewLayout overrides

- (void)prepareLayout
{
  ASDisplayNodeAssertMainThread();
  [super prepareLayout];

  ASCollectionLayoutContext *context = [self layoutContextWithElements:_collectionNode.visibleElements];
  if (_layout != nil && ASObjectIsEqual(_layout.context, context)) {
    // The existing layout is still valid. No-op
    return;
  }

  if (ASCollectionLayoutState *cachedLayout = [_layoutCache layoutForContext:context]) {
    _layout = cachedLayout;
  } else {
    // A new layout is needed now. Calculate and apply it immediately
    _layout = [self calculateLayoutWithContext:context];
  }
}

- (void)invalidateLayout
{
  ASDisplayNodeAssertMainThread();
  [super invalidateLayout];
  if (_layout != nil) {
    [_layoutCache removeLayoutForContext:_layout.context];
    _layout = nil;
  }
}

- (CGSize)collectionViewContentSize
{
  ASDisplayNodeAssertMainThread();
  ASDisplayNodeAssertNotNil(_layout, @"Collection layout state should not be nil at this point");
  return _layout.contentSize;
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)blockingRect
{
  ASDisplayNodeAssertMainThread();
  if (CGRectIsEmpty(blockingRect)) {
    return nil;
  }

  // Measure elements in the measure range, block on the requested rect
  CGRect measureRect = CGRectExpandToRangeWithScrollableDirections(blockingRect, kASDefaultMeasureRangeTuningParameters, _layoutDelegate.scrollableDirections, kASStaticScrollDirection);
  ASCollectionLayoutMeasureElementsInRects(measureRect, blockingRect, _layout);
  
  NSArray<UICollectionViewLayoutAttributes *> *result = [_layout layoutAttributesForElementsInRect:blockingRect];

  ASElementMap *elements = _layout.context.elements;
  for (UICollectionViewLayoutAttributes *attrs in result) {
    ASCollectionElement *element = [elements elementForLayoutAttributes:attrs];
    ASCollectionLayoutSetSizeToElement(attrs.frame.size, element);
  }

  return result;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
  ASDisplayNodeAssertMainThread();

  ASCollectionElement *element = [_layout.context.elements elementForItemAtIndexPath:indexPath];
  UICollectionViewLayoutAttributes *attrs = [_layout layoutAttributesForElement:element];

  ASCellNode *node = element.node;
  CGSize elementSize = attrs.frame.size;
  if (! CGSizeEqualToSize(elementSize, node.calculatedSize)) {
    [node layoutThatFits:ASCollectionLayoutElementSizeRangeFromSize(elementSize)];
  }

  ASCollectionLayoutSetSizeToElement(attrs.frame.size, element);
  return attrs;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
  ASCollectionElement *element = [_layout.context.elements supplementaryElementOfKind:elementKind atIndexPath:indexPath];
  UICollectionViewLayoutAttributes *attrs = [_layout layoutAttributesForElement:element];

  ASCellNode *node = element.node;
  CGSize elementSize = attrs.frame.size;
  if (! CGSizeEqualToSize(elementSize, node.calculatedSize)) {
    [node layoutThatFits:ASCollectionLayoutElementSizeRangeFromSize(elementSize)];
  }

  ASCollectionLayoutSetSizeToElement(attrs.frame.size, element);
  return attrs;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
  return (! CGSizeEqualToSize([self _viewportSize], newBounds.size));
}

#pragma mark - Private methods

- (CGSize)_viewportSize
{
  ASCollectionNode *collectionNode = _collectionNode;
  if (collectionNode != nil && !collectionNode.isNodeLoaded) {
    // TODO consider calculatedSize as well
    return collectionNode.threadSafeBounds.size;
  } else {
    ASDisplayNodeAssertMainThread();
    return self.collectionView.bounds.size;
  }
}

# pragma mark - Convenient inline functions

ASDISPLAYNODE_INLINE ASSizeRange ASCollectionLayoutElementSizeRangeFromSize(CGSize size)
{
  // The layout delegate consulted us that this element must fit within this size,
  // and the only way to achieve that without asking it again is to use an exact size range here.
  return ASSizeRangeMake(size);
}

ASDISPLAYNODE_INLINE void ASCollectionLayoutSetSizeToElement(CGSize size, ASCollectionElement *element)
{
  if (ASCellNode *node = element.node) {
    if (! CGSizeEqualToSize(size, node.frame.size)) {
      CGRect frame = CGRectZero;
      frame.size = size;
      node.frame = frame;
    }
  }
}

/**
 * Measures all elements in the specified rect and blocks the calling thread while measuring those in the blocking rect.
 */
ASDISPLAYNODE_INLINE void ASCollectionLayoutMeasureElementsInRects(CGRect rect, CGRect blockingRect, ASCollectionLayoutState *layout)
{
  if (CGRectIsEmpty(rect) || layout == nil) {
    return;
  }
  BOOL hasBlockingRect = !CGRectIsEmpty(blockingRect);
  if (hasBlockingRect && CGRectContainsRect(rect, blockingRect) == NO) {
    ASDisplayNodeCAssert(NO, @"Blocking rect, if specified, must be within the other (outer) rect");
    return;
  }

  // Step 1: Clamp the specified rects between the bounds of content rect
  CGSize contentSize = layout.contentSize;
  CGRect contentRect = CGRectMake(0, 0, contentSize.width, contentSize.height);
  rect = CGRectIntersection(contentRect, rect);
  if (CGRectIsNull(rect)) {
    return;
  }
  if (hasBlockingRect) {
    blockingRect = CGRectIntersection(contentRect, blockingRect);
    hasBlockingRect = !CGRectIsNull(blockingRect);
  }

  // Step 2: Get layout attributes of all elements within the specified outer rect
  ASCollectionLayoutContext *context = layout.context;
  CGSize pageSize = context.viewportSize;
  ASPageTable *attrsTable = [layout getAndRemoveUnmeasuredLayoutAttributesPageTableInRect:rect
                                                                              contentSize:contentSize
                                                                                 pageSize:pageSize];
  if (attrsTable.count == 0) {
    // No elements in this rect! Bail early
    return;
  }

  // Step 3: Split all those attributes into blocking and non-blocking buckets
  // Use an ordered set here because some items may span multiple pages and they will be accessed by indexes.
  NSMutableOrderedSet<UICollectionViewLayoutAttributes *> *blockingAttrs = hasBlockingRect ? [NSMutableOrderedSet orderedSet] : nil;
  // Use a set here because some items may span multiple pages
  NSMutableSet<UICollectionViewLayoutAttributes *> *nonBlockingAttrs = [NSMutableSet set];
  for (id pagePtr in attrsTable) {
    ASPageCoordinate page = (ASPageCoordinate)pagePtr;
    NSArray<UICollectionViewLayoutAttributes *> *attrsInPage = [attrsTable objectForPage:page];
    // Calculate the page's rect but only if it's going to be used.
    CGRect pageRect = hasBlockingRect ? ASPageCoordinateGetPageRect(page, pageSize) : CGRectZero;

    if (hasBlockingRect && CGRectContainsRect(blockingRect, pageRect)) {
      // The page fits well within the blocking rect. All attributes in this page are blocking.
      [blockingAttrs addObjectsFromArray:attrsInPage];
    } else if (hasBlockingRect && CGRectIntersectsRect(blockingRect, pageRect)) {
      // The page intersects the blocking rect. Some elements in this page are blocking, some are not.
      for (UICollectionViewLayoutAttributes *attrs in attrsInPage) {
        if (CGRectIntersectsRect(blockingRect, attrs.frame)) {
          [blockingAttrs addObject:attrs];
        } else {
          [nonBlockingAttrs addObject:attrs];
        }
      }
    } else {
      // The page doesn't intersect the blocking rect. All elements in this page are non-blocking.
      [nonBlockingAttrs addObjectsFromArray:attrsInPage];
    }
  }

  // Step 4: Allocate and measure blocking elements' node
  ASElementMap *elements = context.elements;
  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  NSUInteger count = blockingAttrs.count;
  if (count > 0) {
    ASDispatchApply(count, queue, 0, ^(size_t i) {
      UICollectionViewLayoutAttributes *attrs = blockingAttrs[i];
      CGSize elementSize = attrs.frame.size;
      ASCollectionElement *element = [elements elementForItemAtIndexPath:attrs.indexPath];
      ASCellNode *node = element.node;
      if (! CGSizeEqualToSize(elementSize, node.calculatedSize)) {
        [node layoutThatFits:ASCollectionLayoutElementSizeRangeFromSize(elementSize)];
      }
    });
  }

  // Step 5: Allocate and measure non-blocking ones
  // TODO Limit the number of threads
  for (UICollectionViewLayoutAttributes *attrs in nonBlockingAttrs) {
    CGSize elementSize = attrs.frame.size;
    __weak ASCollectionElement *weakElement = [elements elementForItemAtIndexPath:attrs.indexPath];
    dispatch_async(queue, ^{
      __strong ASCollectionElement *strongElement = weakElement;
      if (strongElement) {
        ASCellNode *node = strongElement.node;
        if (! CGSizeEqualToSize(elementSize, node.calculatedSize)) {
          [node layoutThatFits:ASCollectionLayoutElementSizeRangeFromSize(elementSize)];
        }
      }
    });
  }
}

@end
