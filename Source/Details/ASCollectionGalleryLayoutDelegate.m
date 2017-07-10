//
//  ASCollectionGalleryLayoutDelegate.mm
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASCollectionGalleryLayoutDelegate.h>

#import <AsyncDisplayKit/_ASCollectionGalleryLayoutItem.h>
#import <AsyncDisplayKit/ASAbstractLayoutController.h>
#import <AsyncDisplayKit/ASAssert.h>
#import <AsyncDisplayKit/ASCellNode.h>
#import <AsyncDisplayKit/ASCollectionElement.h>
#import <AsyncDisplayKit/ASCollectionLayoutContext.h>
#import <AsyncDisplayKit/ASCollectionLayoutDefines.h>
#import <AsyncDisplayKit/ASCollectionLayoutState+Private.h>
#import <AsyncDisplayKit/ASDispatch.h>
#import <AsyncDisplayKit/ASElementMap.h>
#import <AsyncDisplayKit/ASLayout.h>
#import <AsyncDisplayKit/ASLayoutRangeType.h>
#import <AsyncDisplayKit/ASPageTable.h>
#import <AsyncDisplayKit/ASStackLayoutSpec.h>
#import <ASThread.h>

static const ASRangeTuningParameters kASDefaultMeasureRangeTuningParameters = {
  .leadingBufferScreenfuls = 2.0,
  .trailingBufferScreenfuls = 2.0
};

static const ASScrollDirection kASStaticScrollDirection = (ASScrollDirectionRight | ASScrollDirectionDown);

#pragma mark - ASCollectionGalleryLayoutDelegate

@implementation ASCollectionGalleryLayoutDelegate {
  CGSize _itemSize;
  ASSizeRange _itemSizeRange;
}

@synthesize scrollableDirections = _scrollableDirections;

- (instancetype)initWithScrollableDirections:(ASScrollDirection)scrollableDirections itemSize:(CGSize)itemSize
{
  self = [super init];
  if (self) {
    ASDisplayNodeAssertFalse(CGSizeEqualToSize(CGSizeZero, itemSize));
    _scrollableDirections = scrollableDirections;
    _itemSize = itemSize;
    _itemSizeRange = ASSizeRangeMake(_itemSize);
  }
  return self;
}

- (id)additionalInfoForLayoutWithElements:(ASElementMap *)elements
{
  return nil;
}

- (ASCollectionLayoutState *)calculateLayoutWithContext:(ASCollectionLayoutContext *)context
{
  ASElementMap *elements = context.elements;
  CGSize pageSize = context.viewportSize;
  NSMutableArray<_ASGalleryLayoutItem *> *children = ASArrayByFlatMapping(elements.itemElements,
                                                                         ASCollectionElement *element,
                                                                         [[_ASGalleryLayoutItem alloc] initWithItemSize:_itemSize collectionElement:element]);
  if (children.count == 0) {
    return [[ASCollectionLayoutState alloc] initWithContext:context contentSize:CGSizeZero additionalInfo:nil elementToLayoutAttributesTable:[NSMapTable weakToStrongObjectsMapTable]];
  }
  
  // Step 1: Use a stack spec to calculate layout content size and frames of all elements without actually measuring each element
  ASStackLayoutSpec *stackSpec = [ASStackLayoutSpec stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
                                                                         spacing:0
                                                                  justifyContent:ASStackLayoutJustifyContentStart
                                                                      alignItems:ASStackLayoutAlignItemsStart
                                                                        flexWrap:ASStackLayoutFlexWrapWrap
                                                                    alignContent:ASStackLayoutAlignContentStart
                                                                        children:children];
  stackSpec.concurrent = YES;
  ASLayout *layout = [stackSpec layoutThatFits:ASSizeRangeForCollectionLayoutThatFitsViewportSize(pageSize, _scrollableDirections)];
  
  // Step 2: Create neccessary objects to hold information extracted from the layout
  ASCollectionElement * _Nonnull(^getElementBlock)(ASLayout * _Nonnull) = ^ASCollectionElement *(ASLayout *sublayout) {
    return ((_ASGalleryLayoutItem *)sublayout.layoutElement).collectionElement;
  };
  ASCollectionLayoutState *collectionLayout =  [[ASCollectionLayoutState alloc] initWithContext:context
                                                                                         layout:layout
                                                                                 additionalInfo:nil
                                                                                getElementBlock:getElementBlock];
  CGSize contentSize = collectionLayout.contentSize;
  if (CGSizeEqualToSize(contentSize, CGSizeZero)) {
    return collectionLayout;
  }
  
  // Step 3: Measure elements in the measure range ahead of time, block on the initial rect as it'll be visible shortly
  // TODO Consider content offset of the collection node
  CGRect initialRect = CGRectMake(0, 0, pageSize.width, pageSize.height);
  CGRect measureRect = CGRectExpandToRangeWithScrollableDirections(initialRect, kASDefaultMeasureRangeTuningParameters, _scrollableDirections, kASStaticScrollDirection);
  [ASCollectionGalleryLayoutDelegate _measureElementsInRect:measureRect blockingRect:initialRect layout:collectionLayout elementSize:_itemSize];
  
  return collectionLayout;
}

- (void)ensureLayoutAttributesForElementsInRect:(CGRect)rect withLayout:(ASCollectionLayoutState *)layout
{
  ASDisplayNodeAssertMainThread();
  if (CGRectIsEmpty(rect) || layout == nil) {
    return;
  }
  
  // Measure elements in the measure range, block on the requested rect
  CGRect measureRect = CGRectExpandToRangeWithScrollableDirections(rect, kASDefaultMeasureRangeTuningParameters, _scrollableDirections, kASStaticScrollDirection);
  [ASCollectionGalleryLayoutDelegate _measureElementsInRect:measureRect blockingRect:rect layout:layout elementSize:_itemSize];
}

- (void)ensureLayoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath withLayout:(ASCollectionLayoutState *)layout
{
  ASDisplayNodeAssertMainThread();
  if (layout == nil) {
    return;
  }

  ASCollectionElement *element = [layout.context.elements elementForItemAtIndexPath:indexPath];
  ASCellNode *node = element.node;
  if (! CGSizeEqualToSize(_itemSize, node.calculatedSize)) {
    [node layoutThatFits:ASSizeRangeMake(_itemSize, _itemSize)];
  }
}

/**
 * Measures all elements in the specified rect and blocks the calling thread while measuring those in the blocking rect.
 */
+ (void)_measureElementsInRect:(CGRect)rect blockingRect:(CGRect)blockingRect layout:(ASCollectionLayoutState *)layout elementSize:(CGSize)elementSize
{
  if (CGRectIsEmpty(rect) || layout == nil || CGSizeEqualToSize(CGSizeZero, elementSize)) {
    return;
  }
  BOOL hasBlockingRect = !CGRectIsEmpty(blockingRect);
  if (hasBlockingRect && CGRectContainsRect(rect, blockingRect) == NO) {
    ASDisplayNodeAssert(NO, @"Blocking rect, if specified, must be within the other (outer) rect");
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
  ASPageTable *attrsTable = [layout pageToLayoutAttributesTableForElementsInRect:rect contentSize:contentSize pageSize:pageSize];
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
    NSArray<UICollectionViewLayoutAttributes *> *attrsInPage = [[attrsTable objectForPage:page] allObjects];
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
  ASSizeRange sizeRange = ASSizeRangeMake(elementSize);
  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  NSUInteger count = blockingAttrs.count;
  if (count > 0) {
    ASDispatchApply(count, queue, 0, ^(size_t i) {
      ASCollectionElement *element = [elements elementForItemAtIndexPath:blockingAttrs[i].indexPath];
      ASCellNode *node = element.node;
      if (! CGSizeEqualToSize(elementSize, node.calculatedSize)) {
        [node layoutThatFits:sizeRange];
      }
    });
  }
  
  // Step 5: Allocate and measure non-blocking ones
  // TODO Limit the number of threads
  for (UICollectionViewLayoutAttributes *attrs in nonBlockingAttrs) {
    __weak ASCollectionElement *weakElement = [elements elementForItemAtIndexPath:attrs.indexPath];
    dispatch_async(queue, ^{
      __strong ASCollectionElement *strongElement = weakElement;
      if (strongElement) {
        ASCellNode *node = strongElement.node;
        if (! CGSizeEqualToSize(elementSize, node.calculatedSize)) {
          [node layoutThatFits:sizeRange];
        }
      }
    });
  }
}

@end
