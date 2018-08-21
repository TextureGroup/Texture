//
//  ASSupplementaryNodeSource.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/ASBlockTypes.h>
#import <AsyncDisplayKit/ASDimension.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ASSupplementaryNodeSource <NSObject>

/**
 * A method to provide the node-block for the supplementary element.
 *
 * @param elementKind The kind of supplementary element.
 * @param index The index of the item.
 * @return A node block for the supplementary element.
 * @see collectionNode:nodeForSupplementaryElementOfKind:atIndexPath:
 */
- (ASCellNodeBlock)nodeBlockForSupplementaryElementOfKind:(NSString *)elementKind atIndex:(NSInteger)index;

@optional

/**
 * A method to provide the size range used for measuring the supplementary
 * element of the given kind at the given index.
 *
 * @param elementKind The kind of supplementary element.
 * @param index The index of the item.
 * @return A size range used for asynchronously measuring the node.
 * @see collectionNode:constrainedSizeForSupplementaryElementOfKind:atIndexPath:
 */
- (ASSizeRange)sizeRangeForSupplementaryElementOfKind:(NSString *)elementKind atIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
