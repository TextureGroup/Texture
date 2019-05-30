//
//  ASCollectionViewLayoutController.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASCollectionViewLayoutController.h>

#import <AsyncDisplayKit/ASAssert.h>
#import <AsyncDisplayKit/ASCollectionView+Undeprecated.h>
#import <AsyncDisplayKit/ASElementMap.h>
#import <AsyncDisplayKit/CoreGraphics+ASConvenience.h>
#import <AsyncDisplayKit/UICollectionViewLayout+ASConvenience.h>

struct ASRangeGeometry {
  CGRect rangeBounds;
  CGRect updateBounds;
};
typedef struct ASRangeGeometry ASRangeGeometry;

#pragma mark -
#pragma mark ASCollectionViewLayoutController

@interface ASCollectionViewLayoutController ()
{
  @package
  ASCollectionView * __weak _collectionView;
  UICollectionViewLayout * __strong _collectionViewLayout;
}
@end

@implementation ASCollectionViewLayoutController

- (instancetype)initWithCollectionView:(ASCollectionView *)collectionView
{
  if (!(self = [super init])) {
    return nil;
  }
  
  _collectionView = collectionView;
  _collectionViewLayout = [collectionView collectionViewLayout];
  return self;
}

- (CGRect)bounds
{
  ASDisplayNodeAssertMainThread();
  return _collectionView.bounds;
}

- (void)getLayoutItemsInRect:(CGRect)rect buffer:(std::vector<ASCollectionLayoutItem> *)buffer
{
  ASDisplayNodeAssertMainThread();
  NSParameterAssert(buffer->empty());

  __autoreleasing NSArray<UICollectionViewLayoutAttributes *> *attrs = [_collectionViewLayout layoutAttributesForElementsInRect:rect];
  buffer->reserve(attrs.count);
  for (UICollectionViewLayoutAttributes *cvla in attrs) {
    buffer->push_back({cvla.frame, cvla.indexPath, cvla.representedElementKind});
  }
}

@end
