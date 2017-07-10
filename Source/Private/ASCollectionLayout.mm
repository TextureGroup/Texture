//
//  ASCollectionLayout.mm
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

#import <AsyncDisplayKit/ASCollectionLayout.h>

#import <AsyncDisplayKit/ASAssert.h>
#import <AsyncDisplayKit/ASCellNode.h>
#import <AsyncDisplayKit/ASCollectionElement.h>
#import <AsyncDisplayKit/ASCollectionLayoutContext+Private.h>
#import <AsyncDisplayKit/ASCollectionLayoutDelegate.h>
#import <AsyncDisplayKit/ASCollectionLayoutState.h>
#import <AsyncDisplayKit/ASCollectionNode+Beta.h>
#import <AsyncDisplayKit/ASDisplayNode+FrameworkPrivate.h>
#import <AsyncDisplayKit/ASElementMap.h>
#import <AsyncDisplayKit/ASEqualityHelpers.h>
#import <AsyncDisplayKit/ASThread.h>

struct ASCollectionLayoutDelegateFlags {
  unsigned int implementsAdditionalInfoForLayoutWithElements:1;
  unsigned int implementsEnsureLayoutAttributesForElementsInRect:1;
  unsigned int implementsEnsureLayoutAttributesForItemAtIndexPath:1;
  unsigned int implementsEnsureLayoutAttributesForSupplementaryElementOfKind:1;
};

@interface ASCollectionLayout () <ASDataControllerLayoutDelegate> {
  ASDN::Mutex __instanceLock__; // Non-recursive mutex, ftw!
  
  // Main thread only.
  ASCollectionLayoutState *_layout;
  
  // The pending state calculated ahead of time, if any.
  ASCollectionLayoutState *_pendingLayout;
  
  ASCollectionLayoutDelegateFlags _layoutDelegateFlags;
}

@end

@implementation ASCollectionLayout

- (instancetype)initWithLayoutDelegate:(id<ASCollectionLayoutDelegate>)layoutDelegate
{
  self = [super init];
  if (self) {
    ASDisplayNodeAssertNotNil(layoutDelegate, @"Collection layout delegate cannot be nil");
    _layoutDelegate = layoutDelegate;
    _layoutDelegateFlags.implementsAdditionalInfoForLayoutWithElements = [layoutDelegate respondsToSelector:@selector(additionalInfoForLayoutWithElements:)];
    _layoutDelegateFlags.implementsEnsureLayoutAttributesForElementsInRect = [layoutDelegate respondsToSelector:@selector(ensureLayoutAttributesForElementsInRect:withLayout:)];
    _layoutDelegateFlags.implementsEnsureLayoutAttributesForItemAtIndexPath = [layoutDelegate respondsToSelector:@selector(ensureLayoutAttributesForItemAtIndexPath:withLayout:)];
    _layoutDelegateFlags.implementsEnsureLayoutAttributesForSupplementaryElementOfKind = [layoutDelegate respondsToSelector:@selector(ensureLayoutAttributesForSupplementaryElementOfKind:atIndexPath:withLayout:)];
  }
  return self;
}

#pragma mark - ASDataControllerLayoutDelegate

- (id)layoutContextWithElements:(ASElementMap *)elements
{
  ASDisplayNodeAssertMainThread();
  CGSize viewportSize = [self viewportSize];
  id additionalInfo = nil;
  if (_layoutDelegateFlags.implementsAdditionalInfoForLayoutWithElements) {
    additionalInfo = [_layoutDelegate additionalInfoForLayoutWithElements:elements];
  }
  return [[ASCollectionLayoutContext alloc] initWithViewportSize:viewportSize elements:elements additionalInfo:additionalInfo];
}

- (void)prepareLayoutWithContext:(id)context
{
  ASCollectionLayoutState *layout = [_layoutDelegate calculateLayoutWithContext:context];
  
  ASDN::MutexLocker l(__instanceLock__);
  _pendingLayout = layout;
}

#pragma mark - UICollectionViewLayout overrides

- (void)prepareLayout
{
  ASDisplayNodeAssertMainThread();
  [super prepareLayout];
  ASCollectionLayoutContext *context = [self layoutContextWithElements:_collectionNode.visibleElements];
  
  ASCollectionLayoutState *layout = nil;
  {
    ASDN::MutexLocker l(__instanceLock__);
    if (_pendingLayout != nil && ASObjectIsEqual(_pendingLayout.context, context)) {
      // Looks like we can use the pending layout. Great!
      layout = _pendingLayout;
      _pendingLayout = nil;
    }
  }
  
  if (layout == nil) {
    layout = [_layoutDelegate calculateLayoutWithContext:context];
  }
  
  _layout = layout;
}

- (void)invalidateLayout
{
  ASDisplayNodeAssertMainThread();
  [super invalidateLayout];
  _layout = nil;
}

- (CGSize)collectionViewContentSize
{
  ASDisplayNodeAssertMainThread();
  ASDisplayNodeAssertNotNil(_layout, @"Collection layout state should not be nil at this point");
  return _layout.contentSize;
}

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect
{
  ASDisplayNodeAssertMainThread();
  
  if (_layoutDelegate != nil && _layoutDelegateFlags.implementsEnsureLayoutAttributesForElementsInRect) {
    [_layoutDelegate ensureLayoutAttributesForElementsInRect:rect withLayout:_layout];
  }
  
  NSArray<UICollectionViewLayoutAttributes *> *result = [_layout layoutAttributesForElementsInRect:rect];
  
  ASElementMap *elements = _layout.context.elements;
  for (UICollectionViewLayoutAttributes *attrs in result) {
    ASCollectionElement *element = [elements elementForLayoutAttributes:attrs];
    [ASCollectionLayout setSize:attrs.frame.size toElement:element];
  }
  
  return result;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
  if (_layoutDelegate != nil &&  _layoutDelegateFlags.implementsEnsureLayoutAttributesForItemAtIndexPath) {
    [_layoutDelegate ensureLayoutAttributesForItemAtIndexPath:indexPath withLayout:_layout];
  }
  
  ASCollectionElement *element = [_layout.context.elements elementForItemAtIndexPath:indexPath];
  UICollectionViewLayoutAttributes *attrs = [_layout layoutAttributesForElement:element];
  [ASCollectionLayout setSize:attrs.frame.size toElement:element];
  return attrs;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)indexPath
{
  if (_layoutDelegate != nil && _layoutDelegateFlags.implementsEnsureLayoutAttributesForSupplementaryElementOfKind) {
    [_layoutDelegate ensureLayoutAttributesForSupplementaryElementOfKind:elementKind atIndexPath:indexPath withLayout:_layout];
  }
  
  ASCollectionElement *element = [_layout.context.elements supplementaryElementOfKind:elementKind atIndexPath:indexPath];
  UICollectionViewLayoutAttributes *attrs = [_layout layoutAttributesForElement:element];
  [ASCollectionLayout setSize:attrs.frame.size toElement:element];
  return attrs;
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
  return (! CGSizeEqualToSize([self viewportSize], newBounds.size));
}

#pragma mark - Private methods

+ (void)setSize:(CGSize)size toElement:(ASCollectionElement *)element
{
  ASCellNode *node = element.node;
  if (! CGSizeEqualToSize(size, node.frame.size)) {
    CGRect nodeFrame = CGRectZero;
    nodeFrame.size = size;
    node.frame = nodeFrame;
  }
}

- (CGSize)viewportSize
{
  ASCollectionNode *collectionNode = _collectionNode;
  if (collectionNode != nil && !collectionNode.isNodeLoaded) {
    // TODO consider calculatedSize as well
    return collectionNode.threadSafeBounds.size;
  } else {
    ASDisplayNodeAssertMainThread();
    return self.collectionView.bounds.size;
  }
}

@end
