//
//  ASCollectionGalleryLayoutDelegate.m
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
#import <AsyncDisplayKit/ASAssert.h>
#import <AsyncDisplayKit/ASCellNode.h>
#import <AsyncDisplayKit/ASCollectionElement.h>
#import <AsyncDisplayKit/ASCollectionLayoutContext.h>
#import <AsyncDisplayKit/ASCollectionLayoutDefines.h>
#import <AsyncDisplayKit/ASCollectionLayoutState.h>
#import <AsyncDisplayKit/ASElementMap.h>
#import <AsyncDisplayKit/ASLayout.h>
#import <AsyncDisplayKit/ASLayoutRangeType.h>
#import <AsyncDisplayKit/ASStackLayoutSpec.h>

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

- (ASScrollDirection)scrollableDirections
{
  return _scrollableDirections;
}

- (id)additionalInfoForLayoutWithElements:(ASElementMap *)elements
{
  return [NSValue valueWithCGSize:_itemSize];
}

+ (ASCollectionLayoutState *)calculateLayoutWithContext:(ASCollectionLayoutContext *)context
{
  ASElementMap *elements = context.elements;
  CGSize pageSize = context.viewportSize;
  CGSize itemSize = ((NSValue *)context.additionalInfo).CGSizeValue;
  ASScrollDirection scrollableDirections = context.scrollableDirections;
  NSMutableArray<_ASGalleryLayoutItem *> *children = ASArrayByFlatMapping(elements.itemElements,
                                                                         ASCollectionElement *element,
                                                                         [[_ASGalleryLayoutItem alloc] initWithItemSize:itemSize collectionElement:element]);
  if (children.count == 0) {
    return [[ASCollectionLayoutState alloc] initWithContext:context
                                                contentSize:CGSizeZero
                             elementToLayoutAttributesTable:[NSMapTable weakToStrongObjectsMapTable]];
  }
  
  // Use a stack spec to calculate layout content size and frames of all elements without actually measuring each element
  ASStackLayoutSpec *stackSpec = [ASStackLayoutSpec stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
                                                                         spacing:0
                                                                  justifyContent:ASStackLayoutJustifyContentStart
                                                                      alignItems:ASStackLayoutAlignItemsStart
                                                                        flexWrap:ASStackLayoutFlexWrapWrap
                                                                    alignContent:ASStackLayoutAlignContentStart
                                                                        children:children];
  stackSpec.concurrent = YES;
  ASLayout *layout = [stackSpec layoutThatFits:ASSizeRangeForCollectionLayoutThatFitsViewportSize(pageSize, scrollableDirections)];
  
  return [[ASCollectionLayoutState alloc] initWithContext:context layout:layout getElementBlock:^ASCollectionElement *(ASLayout *sublayout) {
    return ((_ASGalleryLayoutItem *)sublayout.layoutElement).collectionElement;
  }];
}

@end
