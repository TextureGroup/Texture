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

#import <AsyncDisplayKit/ASAssert.h>
#import <AsyncDisplayKit/ASCellNode+Internal.h>
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

- (instancetype)initWithContext:(ASCollectionLayoutContext *)context layout:(ASLayout *)layout
{
  ASElementMap *elements = context.elements;
  NSMapTable *table = [NSMapTable elementToLayoutAttributesTable];
  
  for (ASLayout *sublayout in layout.sublayouts) {
    ASCollectionElement *element = ((ASCellNode *)sublayout.layoutElement).collectionElement;
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

  return [self initWithContext:context contentSize:layout.size elementToLayoutAttributesTable:table];
}

- (instancetype)initWithContext:(ASCollectionLayoutContext *)context contentSize:(CGSize)contentSize elementToLayoutAttributesTable:(NSMapTable<ASCollectionElement *,UICollectionViewLayoutAttributes *> *)table
{
  self = [super init];
  if (self) {
    _context = context;
    _contentSize = contentSize;
    _elementToLayoutAttributesTable = table;
    _pageToLayoutAttributesTable = [ASPageTable pageTableWithLayoutAttributes:_elementToLayoutAttributesTable.objectEnumerator contentSize:contentSize pageSize:context.viewportSize];
  }
  return self;
}

- (NSArray<UICollectionViewLayoutAttributes *> *)allLayoutAttributes
{
  return [_elementToLayoutAttributesTable.objectEnumerator allObjects];
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect
{
  CGSize pageSize = _context.viewportSize;
  NSPointerArray *pages = ASPageCoordinatesForPagesThatIntersectRect(rect, _contentSize, pageSize);
  if (pages.count == 0) {
    return @[];
  }
  
  // Use a mutable set here because some items may span multiple pages
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

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
  ASCollectionElement *element = [_context.elements elementForItemAtIndexPath:indexPath];
  return [_elementToLayoutAttributesTable objectForKey:element];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
  ASCollectionElement *element = [_context.elements supplementaryElementOfKind:elementKind atIndexPath:indexPath];
  return [_elementToLayoutAttributesTable objectForKey:element];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForElement:(ASCollectionElement *)element
{
  return [_elementToLayoutAttributesTable objectForKey:element];
}

@end
