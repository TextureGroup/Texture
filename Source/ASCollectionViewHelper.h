//
//  ASCollectionViewHelper.h
//  Sample
//
//  Created by Adlai Holler on 9/7/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <AsyncDisplayKit/AsyncDisplayKit.h>
NS_ASSUME_NONNULL_BEGIN

@class ASCollectionViewHelper;

@protocol ASCollectionViewHelperDataSource <NSObject>

/// always called on main.
- (nullable id)collectionViewHelper:(ASCollectionViewHelper *)helper
           objectForItemAtIndexPath:(NSIndexPath *)path;

- (nullable id)collectionViewHelper:(ASCollectionViewHelper *)helper
 objectForSupplementaryElementOfKind:(NSString *)elementKind
                         atIndexPath:(NSIndexPath *)indexPath;
@end


@interface ASCollectionViewHelper : NSObject

/**
 * Note: Data source is expected to deallocate on the main thread.
 * The collection view's layout must conform to ASCompatibleCollectionViewLayout.
 */
- (instancetype)initWithCollectionView:(UICollectionView *)collectionView
                            dataSource:(id<ASCollectionViewHelperDataSource>)dataSource NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithTableView:(UITableView *)tableView
                       dataSource:(id<ASCollectionViewHelperDataSource>)dataSource NS_DESIGNATED_INITIALIZER;

#pragma mark - Output

#pragma mark - Table View

- (CGFloat)heightForRowAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)heightForHeaderInSection:(NSInteger)section;
- (CGFloat)heightForFooterInSection:(NSInteger)section;

/// our implementation of the data source method.
/// returns nil if this cell is not a node.
- (nullable UITableViewCell *)tableView:(UITableView *)tableView
                  cellForRowAtIndexPath:(NSIndexPath *)indexPath;

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section;
- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section;

#pragma mark - Collection View

/**
 * Requests the size for the given item.
 * NOTE: You should not call this method except from -collectionView:layout:sizeForItemAtIndexPath:
 * or some other point driven by the UICollectionViewLayout.
 *
 * Calls to this method outside of UICollectionViewLayout's preparation process result in undefined behavior.
 */
- (CGSize)sizeForItemAtIndexPath:(NSIndexPath *)indexPath;

- (CGSize)flowLayoutReferenceSizeForHeaderInSection:(NSInteger)section;
- (CGSize)flowLayoutReferenceSizeForFooterInSection:(NSInteger)section;

/// Generic supplementary sizing method.
- (CGSize)sizeForSupplementaryElementOfKind:(NSString *)elementKind
                                atIndexPath:(NSIndexPath *)indexPath;

/// our implementation of the data source method.
/// returns nil if this cell is not a node.
- (nullable UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                           cellForItemAtIndexPath:(NSIndexPath *)indexPath;

- (nullable UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
                    viewForSupplementaryElementOfKind:(NSString *)kind
                                          atIndexPath:(NSIndexPath *)indexPath;

#pragma mark - Unavailable

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
