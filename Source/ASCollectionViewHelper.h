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
/// Can return nil or NSNull to indicate that this isn't a Texture-managed item.
- (nullable id)collectionViewHelper:(ASCollectionViewHelper *)helper
           objectForItemAtIndexPath:(NSIndexPath *)path;

- (nullable id)collectionViewHelper:(ASCollectionViewHelper *)helper objectForHeaderInSection:(NSInteger)section;
- (nullable id)collectionViewHelper:(ASCollectionViewHelper *)helper objectForFooterInSection:(NSInteger)section;

- (id(^)(void))collectionViewHelper:(ASCollectionViewHelper *)helper
                 nodeBlockForObject:(id)object
                          indexPath:(NSIndexPath *)indexPath
           supplementaryElementKind:(nullable NSString *)supplementaryElementKind;

@end

AS_SUBCLASSING_RESTRICTED
@interface ASCollectionViewHelper : NSObject

- (instancetype)initWithCollectionView:(UICollectionView *)collectionView
                            dataSource:(id<ASCollectionViewHelperDataSource>)dataSource;

- (instancetype)initWithTableView:(UITableView *)tableView
                       dataSource:(id<ASCollectionViewHelperDataSource>)dataSource;

#pragma mark - Table View

- (BOOL)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
           height:(out CGFloat *)height;
- (BOOL)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
           height:(out CGFloat *)height;
- (BOOL)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
           height:(out CGFloat *)height;


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
- (BOOL)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)layout
sizeForItemAtIndexPath:(NSIndexPath *)indexPath
                  size:(out CGSize *)sizePtr;

- (BOOL)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)layout
referenceSizeForHeaderInSection:(NSInteger)section
                  size:(out CGSize *)sizePtr;

- (BOOL)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)layout
referenceSizeForFooterInSection:(NSInteger)section
                  size:(out CGSize *)sizePtr;

/// our implementation of the data source method.
/// returns nil if this cell is not a node.
- (nullable UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                           cellForItemAtIndexPath:(NSIndexPath *)indexPath;

- (nullable UICollectionReusableView *)collectionView:(UICollectionView *)collectionView
                    viewForSupplementaryElementOfKind:(NSString *)kind
                                          atIndexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
