//
//  ASCollectionNode+Beta.h
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

#import <AsyncDisplayKit/ASCollectionNode.h>

@protocol ASCollectionViewLayoutFacilitatorProtocol, ASCollectionLayoutDelegate, ASBatchFetchingDelegate;
@class ASElementMap;

NS_ASSUME_NONNULL_BEGIN

@interface ASCollectionNode (Beta)

/**
 * Allows providing a custom subclass of ASCollectionView to be managed by ASCollectionNode.
 *
 * @default [ASCollectionView class] is used whenever this property is unset or nil.
 */
@property (strong, nonatomic, nullable) Class collectionViewClass;

/**
 * The elements that are currently displayed. The "UIKit index space". Must be accessed on main thread.
 */
@property (strong, nonatomic, readonly) ASElementMap *visibleElements;

@property (strong, readonly, nullable) id<ASCollectionLayoutDelegate> layoutDelegate;

@property (nonatomic, weak) id<ASBatchFetchingDelegate> batchFetchingDelegate;

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout layoutFacilitator:(nullable id<ASCollectionViewLayoutFacilitatorProtocol>)layoutFacilitator;

- (instancetype)initWithLayoutDelegate:(id<ASCollectionLayoutDelegate>)layoutDelegate layoutFacilitator:(nullable id<ASCollectionViewLayoutFacilitatorProtocol>)layoutFacilitator;

- (void)beginUpdates ASDISPLAYNODE_DEPRECATED_MSG("Use -performBatchUpdates:completion: instead.");

- (void)endUpdatesAnimated:(BOOL)animated ASDISPLAYNODE_DEPRECATED_MSG("Use -performBatchUpdates:completion: instead.");

- (void)endUpdatesAnimated:(BOOL)animated completion:(nullable void (^)(BOOL))completion ASDISPLAYNODE_DEPRECATED_MSG("Use -performBatchUpdates:completion: instead.");

@end

NS_ASSUME_NONNULL_END
