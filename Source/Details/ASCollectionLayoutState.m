//
//  ASCollectionLayoutState.m
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

#import <AsyncDisplayKit/ASCollectionLayoutState.h>
#import <AsyncDisplayKit/ASCollectionLayoutState+Private.h>

#import <AsyncDisplayKit/ASAssert.h>
#import <AsyncDisplayKit/ASCollectionElement.h>
#import <AsyncDisplayKit/ASCollectionLayoutContext.h>
#import <AsyncDisplayKit/ASElementMap.h>
#import <AsyncDisplayKit/ASLayout.h>
#import <AsyncDisplayKit/ASPageTable.h>

@implementation NSMapTable (ASCollectionLayoutConvenience)

+ (NSMapTable<ASCollectionElement *,UICollectionViewLayoutAttributes *> *)elementToLayoutAttributesTable
{
  return [NSMapTable mapTableWithKeyOptions:(NSMapTableWeakMemory | NSMapTableObjectPointerPersonality) valueOptions:NSMapTableStrongMemory];
}

@end

@implementation ASCollectionLayoutState {
  NSMapTable<ASCollectionElement *,UICollectionViewLayoutAttributes *> *_elementToLayoutAttributesTable;
  ASPageTable<id, NSMutableArray<UICollectionViewLayoutAttributes *> *> *_pageToLayoutAttributesTable;
}

- (instancetype)initWithContext:(ASCollectionLayoutContext *)context
                         layout:(ASLayout *)layout
                 additionalInfo:(nullable id)additionalInfo
                getElementBlock:(ASCollectionElement *(^)(ASLayout *))getElementBlock
{
  ASElementMap *elements = context.elements;
  NSMapTable *table = [NSMapTable elementToLayoutAttributesTable];
  
  for (ASLayout *sublayout in layout.sublayouts) {
    ASCollectionElement *element = getElementBlock(sublayout);
    if (element == nil) {
      ASDisplayNodeFailAssert(@"Element not found!");
      continue;
    }
    
    NSIndexPath *indexPath = [elements indexPathForElement:element];
    NSString *supplementaryElementKind = element.supplementaryElementKind;
    
    UICollectionViewLayoutAttributes *attrs;
    if (supplementaryElementKind == nil) {
      attrs = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    } else {
      attrs = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:supplementaryElementKind withIndexPath:indexPath];
    }
    
    attrs.frame = sublayout.frame;
    [table setObject:attrs forKey:element];
  }

  return [self initWithContext:context contentSize:layout.size additionalInfo:additionalInfo elementToLayoutAttributesTable:table];
}

- (instancetype)initWithContext:(ASCollectionLayoutContext *)context
                    contentSize:(CGSize)contentSize
                 additionalInfo:(id)additionalInfo
 elementToLayoutAttributesTable:(NSMapTable<ASCollectionElement *,UICollectionViewLayoutAttributes *> *)table
{
  self = [super init];
  if (self) {
    _context = context;
    _contentSize = contentSize;
    _elementToLayoutAttributesTable = table;
    _pageToLayoutAttributesTable = [ASPageTable pageTableWithLayoutAttributes:_elementToLayoutAttributesTable.objectEnumerator contentSize:contentSize pageSize:context.viewportSize];
    _additionalInfo = additionalInfo;
  }
  return self;
}

- (NSArray<UICollectionViewLayoutAttributes *> *)allLayoutAttributes
{
  return [_elementToLayoutAttributesTable.objectEnumerator allObjects];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
  ASCollectionElement *element = [_context.elements elementForItemAtIndexPath:indexPath];
  return [_elementToLayoutAttributesTable objectForKey:element];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryElementOfKind:(NSString *)elementKind
                                                                        atIndexPath:(NSIndexPath *)indexPath
{
  ASCollectionElement *element = [_context.elements supplementaryElementOfKind:elementKind atIndexPath:indexPath];
  return [_elementToLayoutAttributesTable objectForKey:element];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForElement:(ASCollectionElement *)element
{
  return [_elementToLayoutAttributesTable objectForKey:element];
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect
{
  CGSize pageSize = _context.viewportSize;
  NSPointerArray *pages = ASPageCoordinatesForPagesThatIntersectRect(rect, _contentSize, pageSize);
  if (pages.count == 0) {
    return @[];
  }

  // Use a set here because some items may span multiple pages
  NSMutableSet<UICollectionViewLayoutAttributes *> *result = [NSMutableSet set];
  for (id pagePtr in pages) {
    ASPageCoordinate page = (ASPageCoordinate)pagePtr;
    NSArray<UICollectionViewLayoutAttributes *> *allAttrs = [_pageToLayoutAttributesTable objectForPage:page];
    if (allAttrs.count > 0) {
      CGRect pageRect = ASPageCoordinateGetPageRect(page, pageSize);

      if (CGRectContainsRect(rect, pageRect)) {
        [result addObjectsFromArray:allAttrs];
      } else {
        for (UICollectionViewLayoutAttributes *attrs in allAttrs) {
          if (CGRectIntersectsRect(rect, attrs.frame)) {
            [result addObject:attrs];
          }
        }
      }
    }
  }
  return [result allObjects];
}

- (ASPageTable<id,NSArray<UICollectionViewLayoutAttributes *> *> *)pageToLayoutAttributesTableForElementsInRect:(CGRect)rect
                                                                                                    contentSize:(CGSize)contentSize
                                                                                                       pageSize:(CGSize)pageSize
{
  if (_pageToLayoutAttributesTable.count == 0 || CGRectIsNull(rect) || CGRectIsEmpty(rect) || CGSizeEqualToSize(CGSizeZero, contentSize) || CGSizeEqualToSize(CGSizeZero, pageSize)) {
    return nil;
  }

  // Step 1: Determine all the pages that intersect the specified rect
  NSPointerArray *pagesInRect = ASPageCoordinatesForPagesThatIntersectRect(rect, contentSize, pageSize);
  if (pagesInRect.count == 0) {
    return nil;
  }

  // Step 2: Filter out attributes in these pages that intersect the specified rect.
  ASPageTable *result = [ASPageTable pageTableForStrongObjectPointers];
  for (id pagePtr in pagesInRect) {
    ASPageCoordinate page = (ASPageCoordinate)pagePtr;
    NSMutableArray *attrsInPage = [_pageToLayoutAttributesTable objectForPage:page];

    NSUInteger attrsCount = attrsInPage.count;
    if (attrsCount > 0) {
      NSMutableArray *interesectingAttrsInPage = nil;

      CGRect pageRect = ASPageCoordinateGetPageRect(page, pageSize);
      if (CGRectContainsRect(rect, pageRect)) {
        // The page fits well within the specified rect. Simply return all attributes in this page.
        // Don't need to make a copy of attrsInPage here because it will be removed from the page table soon anyway.
        interesectingAttrsInPage = attrsInPage;
      } else {
        // The page intersects the specified rect. Some attributes in this page are to be returned, some are not.
        for (UICollectionViewLayoutAttributes *attrs in attrsInPage) {
          if (CGRectIntersectsRect(rect, attrs.frame)) {
            if (interesectingAttrsInPage == nil) {
              interesectingAttrsInPage = [NSMutableArray array];
            }
            [interesectingAttrsInPage addObject:attrs];
          }
        }
      }

      NSUInteger interesectingAttrsCount = interesectingAttrsInPage.count;
      if (interesectingAttrsCount > 0) {
        [result setObject:interesectingAttrsInPage forPage:page];
      }
    }
  }
  
  return result;
}

@end
