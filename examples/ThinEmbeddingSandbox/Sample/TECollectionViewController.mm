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
  ASCollectionViewHelper *_textureHelper;
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
  [_collectionView registerClass:UICollectionViewCell.class forCellWithReuseIdentifier:TECellNativeReuseIdentifier];
  [_collectionView registerClass:UICollectionReusableView.class forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:TECellNativeReuseIdentifier];
  [_collectionView registerClass:UICollectionReusableView.class forSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:TECellNativeReuseIdentifier];
  _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  _collectionView.delegate = self;
  _collectionView.dataSource = self;
  [view addSubview:_collectionView];
  _textureHelper = [[ASCollectionViewHelper alloc] initWithCollectionView:_collectionView dataSource:self];
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
  CGSize texSize;
  if ([_textureHelper collectionView:collectionView layout:collectionViewLayout sizeForItemAtIndexPath:indexPath size:&texSize]) {
    return texSize;
  }
  
  return [self sizeAt:TEPath::make(indexPath)];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
  CGSize texSize;
  if ([_textureHelper collectionView:collectionView layout:collectionViewLayout referenceSizeForHeaderInSection:section size:&texSize]) {
    return texSize;
  }
  return [self sizeAt:TEPath::header(section)];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
  CGSize texSize;
  if ([_textureHelper collectionView:collectionView layout:collectionViewLayout referenceSizeForFooterInSection:section size:&texSize]) {
    return texSize;
  }
  return [self sizeAt:TEPath::footer(section)];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  if (auto texCell = [_textureHelper collectionView:collectionView cellForItemAtIndexPath:indexPath]) {
    return texCell;
  }
  auto path = TEPath::make(indexPath);
  auto cell = [collectionView dequeueReusableCellWithReuseIdentifier:TECellNativeReuseIdentifier forIndexPath:indexPath];
  [self hostItemAt:path in:cell.contentView];
  return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
  if (auto texView = [_textureHelper collectionView:collectionView viewForSupplementaryElementOfKind:kind atIndexPath:indexPath]) {
    return texView;
  }
  auto path = TEPath::make(indexPath, kind);
  auto cell = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:TECellNativeReuseIdentifier forIndexPath:indexPath];
  [self hostItemAt:path in:cell];
  return cell;
}

@end
