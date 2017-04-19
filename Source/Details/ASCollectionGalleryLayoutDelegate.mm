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

#import <AsyncDisplayKit/ASAssert.h>
#import <AsyncDisplayKit/ASAbstractLayoutController.h>
#import <AsyncDisplayKit/ASCellNode.h>
#import <AsyncDisplayKit/ASCollectionElement.h>
#import <AsyncDisplayKit/ASCollectionLayoutContext.h>
#import <AsyncDisplayKit/ASCollectionLayoutDefines.h>
#import <AsyncDisplayKit/ASCollectionLayoutState.h>
#import <AsyncDisplayKit/ASDispatch.h>
#import <AsyncDisplayKit/ASElementMap.h>
#import <AsyncDisplayKit/ASLayout.h>
#import <AsyncDisplayKit/ASLayoutElementPrivate.h>
#import <AsyncDisplayKit/ASLayoutElementStylePrivate.h>
#import <AsyncDisplayKit/ASLayoutRangeType.h>
#import <AsyncDisplayKit/ASPageTable.h>
#import <AsyncDisplayKit/ASStackLayoutSpec.h>
#import <ASThread.h>

static const ASRangeTuningParameters kASDefaultMeasureRangeTuningParameters = {
  .leadingBufferScreenfuls = 2.0,
  .trailingBufferScreenfuls = 2.0
};

static const ASScrollDirection kASStaticScrollDirection = (ASScrollDirectionRight | ASScrollDirectionDown);

#pragma mark - _ASGalleryLayoutItem

NS_ASSUME_NONNULL_BEGIN

/**
 * A dummy item that represents a collection element to participate in the collection layout calculation process 
 * without triggering measurement on the actual node of the collection element.
 * 
 * This item always has a fixed size that is the item size passed to it.
 */
AS_SUBCLASSING_RESTRICTED
@interface _ASGalleryLayoutItem : NSObject <ASLayoutElement>

@property (nonatomic, assign, readonly) CGSize itemSize;
@property (nonatomic, weak, readonly) ASCollectionElement *collectionElement;

- (instancetype)initWithItemSize:(CGSize)itemSize collectionElement:(ASCollectionElement *)collectionElement;
- (instancetype)init __unavailable;

@end

NS_ASSUME_NONNULL_END

@implementation _ASGalleryLayoutItem {
  ASPrimitiveTraitCollection _primitiveTraitCollection;
}

@synthesize style;

- (instancetype)initWithItemSize:(CGSize)itemSize collectionElement:(ASCollectionElement *)collectionElement
{
  self = [super init];
  if (self) {
    ASDisplayNodeAssert(! CGSizeEqualToSize(CGSizeZero, itemSize), @"Item size should not be zero");
    ASDisplayNodeAssertNotNil(collectionElement, @"Collection element should not be nil");
    _itemSize = itemSize;
    _collectionElement = collectionElement;
  }
  return self;
}

ASLayoutElementFinalLayoutElementDefault
ASLayoutElementStyleExtensibilityForwarding
ASPrimitiveTraitCollectionDefaults
ASPrimitiveTraitCollectionDeprecatedImplementation

- (ASTraitCollection *)asyncTraitCollection
{
  ASDisplayNodeAssertNotSupported();
  return nil;
}

- (ASLayoutElementType)layoutElementType
{
  return ASLayoutElementTypeLayoutSpec;
}

- (NSArray<id<ASLayoutElement>> *)sublayoutElements
{
  ASDisplayNodeAssertNotSupported();
  return nil;
}

ASLayoutElementLayoutCalculationDefaults

- (ASLayout *)calculateLayoutThatFits:(ASSizeRange)constrainedSize
{
  ASDisplayNodeAssert(CGSizeEqualToSize(_itemSize, ASSizeRangeClamp(constrainedSize, _itemSize)),
                      @"Item size %@ can't fit within the bounds of constrained size %@", NSStringFromCGSize(_itemSize), NSStringFromASSizeRange(constrainedSize));
  return [ASLayout layoutWithLayoutElement:self size:_itemSize];
}

@end

#pragma mark - _ASGalleryLayoutStateAdditionInfo

NS_ASSUME_NONNULL_BEGIN

/**
 * A thread-safe object that contains additional information of a collection layout.
 *
 * It keeps track of layout attributes of all unmeasured elements in a layout and facilitates highly-optimized lookups
 * for unmeasured elements within a given rect.
 */
AS_SUBCLASSING_RESTRICTED
@interface _ASGalleryLayoutStateAdditionInfo : NSObject

/// Sets unmeasured layout attributes to this object.
- (void)setUnmeasuredLayoutAttributes:(NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributes withPageSize:(CGSize)pageSize;

/// Removes and returns unmeasured layout attributes that intersect the specified rect
- (nullable ASPageTable<id, NSSet<UICollectionViewLayoutAttributes *> *> *)getAndRemoveUnmeasuredLayoutAttributesInRect:(CGRect)rect contentSize:(CGSize)contentSize pageSize:(CGSize)pageSize;

@end

NS_ASSUME_NONNULL_END

@implementation _ASGalleryLayoutStateAdditionInfo {
  ASDN::Mutex __instanceLock__;
  ASPageTable<id, NSMutableSet<UICollectionViewLayoutAttributes *> *> *_pageToUnmeasuredLayoutAttributesTable;
}

- (void)setUnmeasuredLayoutAttributes:(NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributes withPageSize:(CGSize)pageSize
{
  ASDN::MutexLocker l(__instanceLock__);
  _pageToUnmeasuredLayoutAttributesTable = [ASPageTable pageTableWithLayoutAttributes:layoutAttributes pageSize:pageSize];
}

- (ASPageTable<id, NSSet<UICollectionViewLayoutAttributes *> *> *)getAndRemoveUnmeasuredLayoutAttributesInRect:(CGRect)rect contentSize:(CGSize)contentSize pageSize:(CGSize)pageSize
{
  if (CGRectIsNull(rect) || CGRectIsEmpty(rect) || CGSizeEqualToSize(CGSizeZero, pageSize) || CGSizeEqualToSize(CGSizeZero, contentSize)) {
    return nil;
  }

  ASDN::MutexLocker l(__instanceLock__);
  ASDisplayNodeAssertNotNil(_pageToUnmeasuredLayoutAttributesTable, @"Unmeasured page map hasn't been set");
  if (_pageToUnmeasuredLayoutAttributesTable.count == 0) {
    return nil;
  }
  
  // Step 1: Determine all the pages that intersect the specified rect
  NSPointerArray *pagesInRect = ASPageCoordinatesForPagesThatIntersectRect(rect, contentSize, pageSize);
  if (pagesInRect.count == 0) {
    return nil;
  }
  
  // Step 2: Filter out attributes in these pages that intersect the specified rect. Remove them from the internal table as we go
  ASPageTable *results = [ASPageTable pageTableForStrongObjectPointers];
  for (id pagePtr in pagesInRect) {
    ASPageCoordinate page = (ASPageCoordinate)pagePtr;
    NSMutableSet *attrsInPage = [_pageToUnmeasuredLayoutAttributesTable objectForPage:page];
    NSUInteger attrsCount = attrsInPage.count;
    
    if (attrsCount > 0) {
      NSMutableSet *interesectingAttrsInPage = nil;
      
      CGRect pageRect = ASPageCoordinateGetPageRect(page, pageSize);
      if (CGRectContainsRect(rect, pageRect)) {
        // The page fits well within the specified rect. Simply return all attributes in this page.
        interesectingAttrsInPage = [attrsInPage copy];
      } else {
        // The page intersects the specified rect. Some attributes in this page are to be returned, some are not.
        for (UICollectionViewLayoutAttributes *attrs in attrsInPage) {
          if (CGRectIntersectsRect(rect, attrs.frame)) {
            if (interesectingAttrsInPage == nil) {
              interesectingAttrsInPage = [NSMutableSet set];
            }
            [interesectingAttrsInPage addObject:attrs];
          }
        }
      }
      
      NSUInteger interesectingAttrsCount = interesectingAttrsInPage.count;
      if (interesectingAttrsCount > 0) {
        [results setObject:interesectingAttrsInPage forPage:page];
        if (attrsCount == interesectingAttrsCount) {
          // All attributes in this page intersect the specified rect. Remove the whole page.
          [_pageToUnmeasuredLayoutAttributesTable removeObjectForPage:page];
        } else {
          [attrsInPage minusSet:interesectingAttrsInPage];
        }
      }
    }
  }
  
  return results;
}

@end

#pragma mark - ASCollectionGalleryLayoutDelegate

@implementation ASCollectionGalleryLayoutDelegate {
  ASScrollDirection _scrollableDirections;
  CGSize _itemSize;
}

- (instancetype)initWithScrollableDirections:(ASScrollDirection)scrollableDirections itemSize:(CGSize)itemSize
{
  self = [super init];
  if (self) {
    ASDisplayNodeAssertFalse(CGSizeEqualToSize(CGSizeZero, itemSize));
    _scrollableDirections = scrollableDirections;
    _itemSize = itemSize;
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
  // TODO Profile to see if a concurrent stack helps here?
  ASLayout *layout = [stackSpec layoutThatFits:ASSizeRangeForCollectionLayoutThatFitsViewportSize(pageSize, _scrollableDirections)];
  
  // Step 2: Create neccessary objects to hold information extracted from the layout
  ASCollectionElement * _Nonnull(^getElementBlock)(ASLayout * _Nonnull) = ^ASCollectionElement *(ASLayout *sublayout) {
    return ((_ASGalleryLayoutItem *)sublayout.layoutElement).collectionElement;
  };
  ASCollectionLayoutState *collectionLayout =  [[ASCollectionLayoutState alloc] initWithContext:context
                                                                                         layout:layout
                                                                                 additionalInfo:[[_ASGalleryLayoutStateAdditionInfo alloc] init]
                                                                                getElementBlock:getElementBlock];
  if (CGSizeEqualToSize(collectionLayout.contentSize, CGSizeZero)) {
    return collectionLayout;
  }
  
  // Step 3: Since _ASGalleryLayoutItem is a dummy layout object, register all elements as unmeasured.
  [collectionLayout.additionalInfo setUnmeasuredLayoutAttributes:[collectionLayout allLayoutAttributes] withPageSize:pageSize];
  
  // Step 4: Measure elements in the measure range ahead of time, block on the initial rect as it'll be visible shortly
  // TODO Consider content offset of the collection node
  CGRect initialRect = CGRectMake(0, 0, pageSize.width, pageSize.height);
  CGRect measureRect = CGRectExpandToRangeWithScrollableDirections(initialRect, kASDefaultMeasureRangeTuningParameters, _scrollableDirections, kASStaticScrollDirection);
  [ASCollectionGalleryLayoutDelegate _measureElementsInRect:measureRect blockingRect:initialRect layout:collectionLayout elementSize:_itemSize];
  
  return collectionLayout;
}

- (void)ensureLayoutAttributesForElementsInRect:(CGRect)rect withLayout:(ASCollectionLayoutState *)layout
{
  ASDisplayNodeAssertMainThread();
  if (CGRectIsEmpty(rect) || (! CGRectIntersectsRect(layout.contentRect, rect))) {
    return;
  }
  
  // Measure elements in the measure range, block on the requested rect
  CGRect measureRect = CGRectExpandToRangeWithScrollableDirections(rect, kASDefaultMeasureRangeTuningParameters, _scrollableDirections, kASStaticScrollDirection);
  [ASCollectionGalleryLayoutDelegate _measureElementsInRect:measureRect blockingRect:rect layout:layout elementSize:_itemSize];
}

- (void)ensureLayoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath withLayout:(ASCollectionLayoutState *)layout
{
  ASDisplayNodeAssertMainThread();
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
  if (CGRectIsEmpty(rect)) {
    return;
  }
  BOOL hasBlockingRect = !CGRectIsEmpty(blockingRect);
  ASDisplayNodeAssert(! hasBlockingRect || CGRectContainsRect(rect, blockingRect), @"Blocking rect, if specified, must be within the other (outer) rect");
  
  // Step 1: Clamp the specified rects between the bounds of content rect
  CGRect contentRect = layout.contentRect;
  rect = CGRectIntersection(contentRect, rect);
  if (CGRectIsNull(rect)) {
    return;
  }
  if (hasBlockingRect) {
    blockingRect = CGRectIntersection(contentRect, blockingRect);
    hasBlockingRect = !CGRectIsNull(blockingRect);
  }
  
  // Step 2: Get layout attributes of all unmeasured elements within the specified outer rect
  ASCollectionLayoutContext *context = layout.context;
  CGSize pageSize = context.viewportSize;
  ASPageTable *unmeasuredAttrsTable = [layout.additionalInfo getAndRemoveUnmeasuredLayoutAttributesInRect:rect contentSize:layout.contentSize pageSize:pageSize];
  if (unmeasuredAttrsTable.count == 0) {
    // No unmeasured elements in this rect! Bail early
    return;
  }
  
  // Step 3: Split all those attributes into blocking and non-blocking buckets
  NSMutableArray<UICollectionViewLayoutAttributes *> *blockingAttrs = hasBlockingRect ? [NSMutableArray array] : nil;
  NSMutableArray<UICollectionViewLayoutAttributes *> *nonBlockingAttrs = [NSMutableArray array];
  for (id pagePtr in unmeasuredAttrsTable) {
    ASPageCoordinate page = (ASPageCoordinate)pagePtr;
    NSArray<UICollectionViewLayoutAttributes *> *attrsInPage = [[unmeasuredAttrsTable objectForPage:page] allObjects];
    // Calcualte the page's rect but only if it's going to be used.
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
  if (NSUInteger count = blockingAttrs.count > 0) {
    ASDispatchApply(count, queue, 0, ^(size_t i) {
      ASCollectionElement *element = [elements elementForItemAtIndexPath:blockingAttrs[i].indexPath];
      ASCellNode *node = element.node;
      if (! CGSizeEqualToSize(elementSize, node.calculatedSize)) {
        [node layoutThatFits:sizeRange];
      }
    });
  }
  
  // Step 5: Allocate and measure non-blocking ones
  for (UICollectionViewLayoutAttributes *attrs in nonBlockingAttrs) {
    __weak ASCollectionElement *weakElement = [elements elementForItemAtIndexPath:attrs.indexPath];
    dispatch_async(queue, ^{
      __strong ASCollectionElement *strongElement = weakElement;
      if (strongElement != nil) {
        ASCellNode *node = strongElement.node;
        if (! CGSizeEqualToSize(elementSize, node.calculatedSize)) {
          [node layoutThatFits:sizeRange];
        }
      }
    });
  }
}

@end
