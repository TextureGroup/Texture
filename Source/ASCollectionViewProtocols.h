//
//  ASCollectionViewProtocols.h
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

#import <UIKit/UIKit.h>
#import <AsyncDisplayKit/ASBaseDefines.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * This is a subset of UICollectionViewDataSource.
 *
 * @see ASCollectionDataSource
 */
@protocol ASCommonCollectionDataSource <NSObject>

@optional

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section ASDISPLAYNODE_DEPRECATED_MSG("Implement -collectionNode:numberOfItemsInSection: instead.");

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView ASDISPLAYNODE_DEPRECATED_MSG("Implement -numberOfSectionsInCollectionNode: instead.");

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath ASDISPLAYNODE_DEPRECATED_MSG("Implement - collectionNode:nodeForSupplementaryElementOfKind:atIndexPath: instead.");

@end


/**
 * This is a subset of UICollectionViewDelegate.
 *
 * @see ASCollectionDelegate
 */
@protocol ASCommonCollectionDelegate <NSObject, UIScrollViewDelegate>

@optional

- (UICollectionViewTransitionLayout *)collectionView:(UICollectionView *)collectionView transitionLayoutForOldLayout:(UICollectionViewLayout *)fromLayout newLayout:(UICollectionViewLayout *)toLayout;

- (void)collectionView:(UICollectionView *)collectionView willDisplaySupplementaryView:(UICollectionReusableView *)view forElementKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath ASDISPLAYNODE_DEPRECATED_MSG("Implement -collectionNode:willDisplaySupplementaryView:forElementKind:atIndexPath: instead.");
- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingSupplementaryView:(UICollectionReusableView *)view forElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath ASDISPLAYNODE_DEPRECATED_MSG("Implement -collectionNode:didEndDisplayingSupplementaryView:forElementKind:atIndexPath: instead.");

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath ASDISPLAYNODE_DEPRECATED_MSG("Implement collectionNode:shouldHighlightItemAtIndexPath: instead.");
- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath ASDISPLAYNODE_DEPRECATED_MSG("Implement collectionNode:didHighlightItemAtIndexPath: instead.");
- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath ASDISPLAYNODE_DEPRECATED_MSG("Implement collectionNode:didUnhighlightItemAtIndexPath: instead.");

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath ASDISPLAYNODE_DEPRECATED_MSG("Implement collectionNode:shouldSelectItemAtIndexPath: instead.");
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath ASDISPLAYNODE_DEPRECATED_MSG("Implement collectionNode:didSelectItemAtIndexPath: instead.");
- (BOOL)collectionView:(UICollectionView *)collectionView shouldDeselectItemAtIndexPath:(NSIndexPath *)indexPath ASDISPLAYNODE_DEPRECATED_MSG("Implement collectionNode:shouldDeselectItemAtIndexPath: instead.");
- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath ASDISPLAYNODE_DEPRECATED_MSG("Implement collectionNode:didDeselectItemAtIndexPath: instead.");

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath ASDISPLAYNODE_DEPRECATED_MSG("Implement collectionNode:shouldShowMenuForItemAtIndexPath: instead.");
- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(nullable id)sender ASDISPLAYNODE_DEPRECATED_MSG("Implement collectionNode:canPerformAction:forItemAtIndexPath:withSender: instead.");
- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(nullable id)sender ASDISPLAYNODE_DEPRECATED_MSG("Implement collectionNode:performAction:forItemAtIndexPath:withSender: instead.");

@end

NS_ASSUME_NONNULL_END
