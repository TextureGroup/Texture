//
//  AsyncDisplayKit+IGListKitMethods.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASAvailability.h>

#if AS_IG_LIST_KIT

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AsyncDisplayKit/ASBaseDefines.h>
#import <IGListKit/IGListKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * If you are using AsyncDisplayKit with IGListKit, you should use
 * these methods to provide implementations for methods like
 * -cellForItemAtIndex: that don't apply when used with AsyncDisplayKit.
 *
 * Your section controllers should also conform to @c ASSectionController and your
 * supplementary view sources should conform to @c ASSupplementaryNodeSource.
 */

AS_SUBCLASSING_RESTRICTED
@interface ASIGListSectionControllerMethods : NSObject

/**
 * Call this for your section controller's @c cellForItemAtIndex: method.
 */
+ (__kindof UICollectionViewCell *)cellForItemAtIndex:(NSInteger)index sectionController:(IGListSectionController *)sectionController;

/**
 * Call this for your section controller's @c sizeForItemAtIndex: method.
 */
+ (CGSize)sizeForItemAtIndex:(NSInteger)index;

@end

AS_SUBCLASSING_RESTRICTED
@interface ASIGListSupplementaryViewSourceMethods : NSObject

/**
 * Call this for your supplementary source's @c viewForSupplementaryElementOfKind:atIndex: method.
 */
+ (__kindof UICollectionReusableView *)viewForSupplementaryElementOfKind:(NSString *)elementKind
                                                                 atIndex:(NSInteger)index
                                                       sectionController:(IGListSectionController *)sectionController;

/**
 * Call this for your supplementary source's @c sizeForSupplementaryViewOfKind:atIndex: method.
 */
+ (CGSize)sizeForSupplementaryViewOfKind:(NSString *)elementKind atIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END

#endif
