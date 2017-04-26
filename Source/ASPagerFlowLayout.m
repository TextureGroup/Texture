//
//  ASPagerFlowLayout.m
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

#import <AsyncDisplayKit/ASPagerFlowLayout.h>
#import <AsyncDisplayKit/ASCellNode.h>
#import <AsyncDisplayKit/ASCollectionView.h>

@interface ASPagerFlowLayout () {
  __weak ASCellNode *_currentCellNode;
}

@end

//TODO make this an ASCollectionViewLayout
@implementation ASPagerFlowLayout

- (ASCollectionView *)asCollectionView
{
  // Dynamic cast is too slow and not worth it.
  return (ASCollectionView *)self.collectionView;
}

- (void)prepareLayout
{
  [super prepareLayout];
  if (_currentCellNode == nil) {
    [self _updateCurrentNode];
  }
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset
{
  // Don't mess around if the user is interacting with the page node. Although if just a rotation happened we should
  // try to use the current index path to not end up setting the target content offset to something in between pages
  if (!self.collectionView.decelerating && !self.collectionView.tracking) {
    NSIndexPath *indexPath = [self.asCollectionView indexPathForNode:_currentCellNode];
    if (indexPath) {
      return [self _targetContentOffsetForItemAtIndexPath:indexPath proposedContentOffset:proposedContentOffset];
    }
  }

  return [super targetContentOffsetForProposedContentOffset:proposedContentOffset];
}

- (CGPoint)_targetContentOffsetForItemAtIndexPath:(NSIndexPath *)indexPath proposedContentOffset:(CGPoint)proposedContentOffset
{
  if ([self _dataSourceIsEmpty]) {
    return proposedContentOffset;
  }
  
  UICollectionViewLayoutAttributes *attributes = [self layoutAttributesForItemAtIndexPath:indexPath];
  if (attributes == nil) {
    return proposedContentOffset;
  }

  CGFloat xOffset = (CGRectGetWidth(self.collectionView.bounds) - CGRectGetWidth(attributes.frame)) / 2.0;
  return CGPointMake(attributes.frame.origin.x - xOffset, proposedContentOffset.y);
}

- (BOOL)_dataSourceIsEmpty
{
  return ([self.collectionView numberOfSections] == 0 ||
          [self.collectionView numberOfItemsInSection:0] == 0);
}

- (void)_updateCurrentNode
{
  // Never change node during an animated bounds change (rotation)
  // NOTE! Listening for -prepareForAnimatedBoundsChange and -finalizeAnimatedBoundsChange
  // isn't sufficient here! It's broken!
  NSArray *animKeys = self.collectionView.layer.animationKeys;
  for (NSString *key in animKeys) {
    if ([key hasPrefix:@"bounds"]) {
      return;
    }
  }
  
  CGRect bounds = self.collectionView.bounds;
  CGRect rect = CGRectMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds), 1, 1);

  NSIndexPath *indexPath = [self layoutAttributesForElementsInRect:rect].firstObject.indexPath;
  if (indexPath) {
    ASCellNode *node = [self.asCollectionView nodeForItemAtIndexPath:indexPath];
    if (node) {
      _currentCellNode = node;
    }
  }
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
  [self _updateCurrentNode];
  return [super shouldInvalidateLayoutForBoundsChange:newBounds];
}

- (UICollectionViewLayoutInvalidationContext *)invalidationContextForBoundsChange:(CGRect)newBounds
{
  UICollectionViewFlowLayoutInvalidationContext *ctx = (UICollectionViewFlowLayoutInvalidationContext *)[super invalidationContextForBoundsChange:newBounds];
  ctx.invalidateFlowLayoutDelegateMetrics = YES;
  ctx.invalidateFlowLayoutAttributes = YES;
  return ctx;
}

@end
