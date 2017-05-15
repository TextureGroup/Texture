//
//  MosaicCollectionLayoutDelegate.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "MosaicCollectionLayoutDelegate.h"
#import "ImageCellNode.h"

#import <AsyncDisplayKit/ASCollectionElement.h>

@implementation MosaicCollectionLayoutDelegate {
  // Read-only properties
  NSInteger _numberOfColumns;
  CGFloat _headerHeight;
  CGFloat _columnSpacing;
  UIEdgeInsets _sectionInset;
  UIEdgeInsets _interItemSpacing;
}

- (instancetype)initWithNumberOfColumns:(NSInteger)numberOfColumns headerHeight:(CGFloat)headerHeight
{
  self = [super init];
  if (self != nil) {
    _numberOfColumns = numberOfColumns;
    _headerHeight = headerHeight;
    _columnSpacing = 10.0;
    _sectionInset = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0);
    _interItemSpacing = UIEdgeInsetsMake(10.0, 0, 10.0, 0);
  }
  return self;
}

- (id)additionalInfoForLayoutWithElements:(ASElementMap *)elements
{
  return nil;
}

- (ASCollectionLayoutState *)calculateLayoutWithContext:(ASCollectionLayoutContext *)context
{
  CGFloat layoutWidth = context.viewportSize.width;
  ASElementMap *elements = context.elements;
  CGFloat top = 0;
  
  // TODO use +[NSMapTable elementToLayoutAttributesTable]
  NSMapTable<ASCollectionElement *, UICollectionViewLayoutAttributes *> *attrsMap = [NSMapTable mapTableWithKeyOptions:(NSMapTableObjectPointerPersonality | NSMapTableWeakMemory) valueOptions:NSMapTableStrongMemory];
  NSMutableArray *columnHeights = [NSMutableArray array];
  
  NSInteger numberOfSections = [elements numberOfSections];
  for (NSUInteger section = 0; section < numberOfSections; section++) {
    NSInteger numberOfItems = [elements numberOfItemsInSection:section];
    
    top += _sectionInset.top;
    
    if (_headerHeight > 0) {
      NSIndexPath *indexPath = [NSIndexPath indexPathForItem:0 inSection:section];
      ASCollectionElement *element = [elements supplementaryElementOfKind:UICollectionElementKindSectionHeader
                                                              atIndexPath:indexPath];
      UICollectionViewLayoutAttributes *attrs = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                                                                     withIndexPath:indexPath];
      
      ASSizeRange sizeRange = [self sizeRangeForHeaderOfSection:section withLayoutWidth:layoutWidth];
      CGSize size = [element.node layoutThatFits:sizeRange].size;
      CGRect frame = CGRectMake(_sectionInset.left, top, size.width, size.height);
      
      attrs.frame = frame;
      [attrsMap setObject:attrs forKey:element];
      top = CGRectGetMaxY(frame);
    }
    
    [columnHeights addObject:[NSMutableArray array]];
    for (NSUInteger idx = 0; idx < _numberOfColumns; idx++) {
      [columnHeights[section] addObject:@(top)];
    }
    
    CGFloat columnWidth = [self _columnWidthForSection:section withLayoutWidth:layoutWidth];
    for (NSUInteger idx = 0; idx < numberOfItems; idx++) {
      NSUInteger columnIndex = [self _shortestColumnIndexInSection:section withColumnHeights:columnHeights];
      NSIndexPath *indexPath = [NSIndexPath indexPathForItem:idx inSection:section];
      ASCollectionElement *element = [elements elementForItemAtIndexPath:indexPath];
      UICollectionViewLayoutAttributes *attrs = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
      
      ASSizeRange sizeRange = [self sizeRangeForItem:element.node atIndexPath:indexPath withLayoutWidth:layoutWidth];
      CGSize size = [element.node layoutThatFits:sizeRange].size;
      CGPoint position = CGPointMake(_sectionInset.left + (columnWidth + _columnSpacing) * columnIndex,
                                         [columnHeights[section][columnIndex] floatValue]);
      CGRect frame = CGRectMake(position.x, position.y, size.width, size.height);
      
      attrs.frame = frame;
      [attrsMap setObject:attrs forKey:element];
      // TODO Profile and avoid boxing if there are significant retain/release overheads
      columnHeights[section][columnIndex] = @(CGRectGetMaxY(frame) + _interItemSpacing.bottom);
    }
    
    NSUInteger columnIndex = [self _tallestColumnIndexInSection:section withColumnHeights:columnHeights];
    top = [columnHeights[section][columnIndex] floatValue] - _interItemSpacing.bottom + _sectionInset.bottom;
    
    for (NSUInteger idx = 0; idx < [columnHeights[section] count]; idx++) {
      columnHeights[section][idx] = @(top);
    }
  }
  
  CGFloat contentHeight = [[[columnHeights lastObject] firstObject] floatValue];
  CGSize contentSize = CGSizeMake(layoutWidth, contentHeight);
  return [[ASCollectionLayoutState alloc] initWithContext:context contentSize:contentSize elementToLayoutAttributesTable:attrsMap];
}

- (CGFloat)_widthForSection:(NSUInteger)section withLayoutWidth:(CGFloat)layoutWidth
{
  return layoutWidth - _sectionInset.left - _sectionInset.right;
}

- (CGFloat)_columnWidthForSection:(NSUInteger)section withLayoutWidth:(CGFloat)layoutWidth
{
  return ([self _widthForSection:section withLayoutWidth:layoutWidth] - ((_numberOfColumns - 1) * _columnSpacing)) / _numberOfColumns;
}

- (ASSizeRange)sizeRangeForItem:(ASCellNode *)item atIndexPath:(NSIndexPath *)indexPath withLayoutWidth:(CGFloat)layoutWidth;
{
  CGFloat itemWidth = [self _columnWidthForSection:indexPath.section withLayoutWidth:layoutWidth];
  if ([item isKindOfClass:[ImageCellNode class]]) {
    return ASSizeRangeMake(CGSizeMake(itemWidth, 0), CGSizeMake(itemWidth, CGFLOAT_MAX));
  } else {
    return ASSizeRangeMake(CGSizeMake(itemWidth, itemWidth)); // In kShowUICollectionViewCells = YES mode, make those cells itemWidth x itemWidth.
  }
}

- (ASSizeRange)sizeRangeForHeaderOfSection:(NSInteger)section withLayoutWidth:(CGFloat)layoutWidth
{
  return ASSizeRangeMake(CGSizeMake(0, _headerHeight), CGSizeMake([self _widthForSection:section withLayoutWidth:layoutWidth], _headerHeight));
}

- (NSUInteger)_tallestColumnIndexInSection:(NSUInteger)section withColumnHeights:(NSArray *)columnHeights
{
  __block NSUInteger index = 0;
  __block CGFloat tallestHeight = 0;
  [columnHeights[section] enumerateObjectsUsingBlock:^(NSNumber *height, NSUInteger idx, BOOL *stop) {
    if (height.floatValue > tallestHeight) {
      index = idx;
      tallestHeight = height.floatValue;
    }
  }];
  return index;
}

- (NSUInteger)_shortestColumnIndexInSection:(NSUInteger)section withColumnHeights:(NSArray *)columnHeights
{
  __block NSUInteger index = 0;
  __block CGFloat shortestHeight = CGFLOAT_MAX;
  [columnHeights[section] enumerateObjectsUsingBlock:^(NSNumber *height, NSUInteger idx, BOOL *stop) {
    if (height.floatValue < shortestHeight) {
      index = idx;
      shortestHeight = height.floatValue;
    }
  }];
  return index;
}

@end
