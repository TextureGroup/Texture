//
//  ASDiffingSectionController.h
//  AsyncDisplayKit
//
//  Created by Adlai Holler on 6/20/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/ASAvailability.h>
#import <AsyncDisplayKit/ASSectionController.h>

#if AS_DIFFING

NS_ASSUME_NONNULL_BEGIN

@interface ASDiffingSectionController : NSObject <ASSectionController>

/**
 * This property is automatically set by the infrastructure when a diff is performed
 * and the section view model is updated.
 *
 * Subclasses may override the setter for this property, but not the getter.
 */
@property (atomic, nullable) id viewModel;

/**
 * The array of view models currently displayed by this section controller as items.
 *
 * This property is set by the infrastructure after each item-level diff.
 *
 * Subclasses should not override this property.
 */
@property (atomic, nullable, readonly) NSArray *itemViewModels;

#pragma mark - Public API

/**
 * Invalidate the items for this section controller. Performs a diff against the current set of items.
 *
 * Akin to a series of [UICollectionView insert/delete/reload/moveItemsAtIndexPaths:] calls.
 *
 * This method is automatically called when the view model is updated.
 *
 * Calls to this method will join the current `performBatchUpdates:` if any.
 *
 * Subclasses should not override this method.
 */
- (void)invalidateItems;

/**
 * Invalidates the section including all items and supplementaries. Akin to [UICollectionView reloadSections:].
 *
 * Calls to this method will join the current `performBatchUpdates:` if any.
 *
 * Subclasses should not override this method.
 */
- (void)invalidateSection;

#pragma mark - API for the Infra

/**
 * Asks the section controller to generate and return an array of item view models for the section.
 *
 * You should not call this method directly.
 *
 * Subclasses must override this method.
 */
- (NSArray<id<IGListDiffable>> *)generateItemViewModels;

@end

NS_ASSUME_NONNULL_END

#endif
