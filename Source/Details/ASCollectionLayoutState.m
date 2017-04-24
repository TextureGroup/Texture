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
#import <AsyncDisplayKit/ASElementMap.h>
#import <AsyncDisplayKit/ASLayout.h>

@implementation ASCollectionLayoutState

- (instancetype)initWithElements:(ASElementMap *)elements layout:(ASLayout *)layout
{
  NSMapTable<ASCollectionElement *, UICollectionViewLayoutAttributes *> *attrsMap = [NSMapTable mapTableWithKeyOptions:(NSMapTableObjectPointerPersonality | NSMapTableWeakMemory) valueOptions:NSMapTableStrongMemory];
  for (ASLayout *sublayout in layout.sublayouts) {
    ASCollectionElement *element = ((ASCellNode *)sublayout.layoutElement).collectionElement;
    NSIndexPath *indexPath = [elements indexPathForElement:element];
    NSString *supplementaryElementKind = element.supplementaryElementKind;
    
    UICollectionViewLayoutAttributes *attrs;
    if (supplementaryElementKind == nil) {
      attrs = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    } else {
      attrs = [UICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:supplementaryElementKind withIndexPath:indexPath];
    }
    
    attrs.frame = sublayout.frame;
    [attrsMap setObject:attrs forKey:element];
  }

  return [self initWithElements:elements contentSize:layout.size elementToLayoutArrtibutesMap:attrsMap];
}

- (instancetype)initWithElements:(ASElementMap *)elements contentSize:(CGSize)contentSize elementToLayoutArrtibutesMap:(NSMapTable<ASCollectionElement *,UICollectionViewLayoutAttributes *> *)attrsMap
{
  self = [super init];
  if (self) {
    _elements = elements;
    _contentSize = contentSize;
    _elementToLayoutArrtibutesMap = attrsMap;
  }
  return self;
}

@end
