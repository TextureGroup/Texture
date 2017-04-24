//
//  CollectionViewController.m
//  Sample
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
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//  FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
//  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "CollectionViewController.h"
#import "KittenNode.h"
#import <AsyncDisplayKit/ASTraitCollection.h>

@interface CollectionViewController () <ASCollectionDelegate, ASCollectionDataSource>
@property (nonatomic, strong) ASCollectionNode *collectionNode;
@end

@implementation CollectionViewController

- (instancetype)init
{
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.minimumLineSpacing = 10;
  layout.minimumInteritemSpacing = 10;
  
  ASCollectionNode *collectionNode = [[ASCollectionNode alloc] initWithCollectionViewLayout:layout];
  
  if (!(self = [super initWithNode:collectionNode]))
    return nil;
  
  self.title = @"Collection Node";
  _collectionNode = collectionNode;
  collectionNode.dataSource = self;
  collectionNode.delegate = self;
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.collectionNode.view.contentInset = UIEdgeInsetsMake(20, 10, CGRectGetHeight(self.tabBarController.tabBar.frame), 10);
}

#pragma mark - ASCollectionDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  return 50;
}

- (ASCellNode *)collectionView:(ASCollectionView *)collectionView nodeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  KittenNode *cell = [[KittenNode alloc] init];
  cell.textNode.maximumNumberOfLines = 3;
  cell.imageTappedBlock = ^{
    [KittenNode defaultImageTappedAction:self];
  };
  return cell;
}

- (ASSizeRange)collectionView:(ASCollectionView *)collectionView constrainedSizeForNodeAtIndexPath:(NSIndexPath *)indexPath
{
  ASTraitCollection *traitCollection = [self.collectionNode asyncTraitCollection];
  
  if (traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
    return ASSizeRangeMake(CGSizeMake(200, 120), CGSizeMake(200, 120));
  }
  return ASSizeRangeMake(CGSizeMake(132, 180), CGSizeMake(132, 180));
}

@end
