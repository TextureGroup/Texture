//
//  ASCollectionViewLayoutInspector.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASCollectionViewLayoutInspector.h>

#import <AsyncDisplayKit/ASCollectionView.h>
#import <AsyncDisplayKit/ASCollectionView+Undeprecated.h>
#import <AsyncDisplayKit/ASCollectionNode.h>

#pragma mark - Helper Functions

// Returns a constrained size to let the cells layout itself as far as possible based on the scrollable direction
// of the collection view
ASSizeRange NodeConstrainedSizeForScrollDirection(ASCollectionView *collectionView) {
  CGSize maxSize = collectionView.bounds.size;
  UIEdgeInsets contentInset = collectionView.contentInset;
  if (ASScrollDirectionContainsHorizontalDirection(collectionView.scrollableDirections)) {
    maxSize.width = CGFLOAT_MAX;
    maxSize.height -= (contentInset.top + contentInset.bottom);
  } else {
    maxSize.width -= (contentInset.left + contentInset.right);
    maxSize.height = CGFLOAT_MAX;
  }
  return ASSizeRangeMake(CGSizeZero, maxSize);
}

#pragma mark - ASCollectionViewLayoutInspector

@implementation ASCollectionViewLayoutInspector {
  struct {
    unsigned int implementsConstrainedSizeForNodeAtIndexPathDeprecated:1;
    unsigned int implementsConstrainedSizeForNodeAtIndexPath:1;
  } _delegateFlags;
}

#pragma mark ASCollectionViewLayoutInspecting

- (void)didChangeCollectionViewDelegate:(id<ASCollectionDelegate>)delegate
{
  if (delegate == nil) {
    memset(&_delegateFlags, 0, sizeof(_delegateFlags));
  } else {
    _delegateFlags.implementsConstrainedSizeForNodeAtIndexPathDeprecated = [delegate respondsToSelector:@selector(collectionView:constrainedSizeForNodeAtIndexPath:)];
    _delegateFlags.implementsConstrainedSizeForNodeAtIndexPath = [delegate respondsToSelector:@selector(collectionNode:constrainedSizeForItemAtIndexPath:)];
  }
}

- (ASSizeRange)collectionView:(ASCollectionView *)collectionView constrainedSizeForNodeAtIndexPath:(NSIndexPath *)indexPath
{
  if (_delegateFlags.implementsConstrainedSizeForNodeAtIndexPath) {
    return [collectionView.asyncDelegate collectionNode:collectionView.collectionNode constrainedSizeForItemAtIndexPath:indexPath];
  } else if (_delegateFlags.implementsConstrainedSizeForNodeAtIndexPathDeprecated) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return [collectionView.asyncDelegate collectionView:collectionView constrainedSizeForNodeAtIndexPath:indexPath];
#pragma clang diagnostic pop
  } else {
    // With 2.0 `collectionView:constrainedSizeForNodeAtIndexPath:` was moved to the delegate. Assert if not implemented on the delegate but on the data source
    ASDisplayNodeAssert([collectionView.asyncDataSource respondsToSelector:@selector(collectionView:constrainedSizeForNodeAtIndexPath:)] == NO, @"collectionView:constrainedSizeForNodeAtIndexPath: was moved from the ASCollectionDataSource to the ASCollectionDelegate.");
  }
  
  return NodeConstrainedSizeForScrollDirection(collectionView);
}

- (ASScrollDirection)scrollableDirections
{
  return ASScrollDirectionNone;
}

@end
