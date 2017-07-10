//
//  ASCollectionLayoutState+Private.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASCollectionLayoutState.h>
#import <AsyncDisplayKit/ASPageTable.h>

NS_ASSUME_NONNULL_BEGIN

@interface ASCollectionLayoutState (Private)

/// Returns layout attributes for elements that intersect the specified rect
- (nullable ASPageTable<id, NSArray<UICollectionViewLayoutAttributes *> *> *)pageToLayoutAttributesTableForElementsInRect:(CGRect)rect
                                                                                                              contentSize:(CGSize)contentSize
                                                                                                                 pageSize:(CGSize)pageSize;

@end

NS_ASSUME_NONNULL_END
