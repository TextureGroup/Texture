//
//  TECollectionViewController.m
//  Sample
//
//  Created by Adlai Holler on 9/21/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "TECollectionViewController.h"

@interface TECollectionViewController () <UICollectionViewDelegateFlowLayout, UICollectionViewDataSource>

@end

@implementation TECollectionViewController {
  UICollectionView *_collectionView;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
    static NSInteger instanceID = 1;
    self.title = [NSString stringWithFormat:@"Collection #%ld", (long)instanceID++];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  UIView *view = self.view;
  _collectionView = [[UICollectionView alloc] initWithFrame:view.bounds collectionViewLayout:[UICollectionViewFlowLayout new]];
  [_collectionView registerClass:UICollectionViewCell.class forCellWithReuseIdentifier:TEViewPlatformTexture];
  [_collectionView registerClass:UICollectionViewCell.class forCellWithReuseIdentifier:TEViewPlatformPlain];
  [_collectionView registerClass:UICollectionReusableView.class forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:TEViewPlatformTexture];
  [_collectionView registerClass:UICollectionReusableView.class forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:TEViewPlatformPlain];
  [_collectionView registerClass:UICollectionReusableView.class forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:TEViewPlatformTexture];
  [_collectionView registerClass:UICollectionReusableView.class forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:TEViewPlatformPlain];
  _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  _collectionView.delegate = self;
  _collectionView.dataSource = self;
  [view addSubview:_collectionView];
}

- (void)reloadData {
  [_collectionView reloadData];
}

- (void)perform:(void (NS_NOESCAPE ^)())updates {
  [_collectionView performBatchUpdates:updates completion:nil];
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
  return [self numberOfSections];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return [self numberOfItemsIn:section];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  return [self sizeAt:TEPath::make(indexPath)];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
  return [self sizeAt:TEPath::header(section)];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
  return [self sizeAt:TEPath::footer(section)];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  auto path = TEPath::make(indexPath);
  auto reuseID = [self reuseIdentifierAt:path];
  auto cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseID forIndexPath:indexPath];
  [self hostItemAt:path in:cell.contentView];
  return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
  auto path = TEPath::make(indexPath, kind);
  auto reuseID = [self reuseIdentifierAt:path];
  auto cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:reuseID forIndexPath:indexPath];
  [self hostItemAt:path in:cell];
  return cell;
}

@end
