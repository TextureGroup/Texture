//
//  _ASCollectionViewCell.m
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

#import "_ASCollectionViewCell.h"
#import "ASCellNode+Internal.h"
#import <AsyncDisplayKit/AsyncDisplayKit.h>

@implementation _ASCollectionViewCell

- (void)setNode:(ASCellNode *)node
{
  ASDisplayNodeAssertMainThread();
  node.layoutAttributes = _layoutAttributes;
  _node = node;
  
  [node __setSelectedFromUIKit:self.selected];
  [node __setHighlightedFromUIKit:self.highlighted];
}

- (void)setSelected:(BOOL)selected
{
  [super setSelected:selected];
  [_node __setSelectedFromUIKit:selected];
}

- (void)setHighlighted:(BOOL)highlighted
{
  [super setHighlighted:highlighted];
  [_node __setHighlightedFromUIKit:highlighted];
}

- (void)setLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
  _layoutAttributes = layoutAttributes;
  _node.layoutAttributes = layoutAttributes;
}

- (void)prepareForReuse
{
  self.layoutAttributes = nil;

  // Need to clear node pointer before UIKit calls setSelected:NO / setHighlighted:NO on its cells
  self.node = nil;
  [super prepareForReuse];
}

/**
 * In the initial case, this is called by UICollectionView during cell dequeueing, before
 *   we get a chance to assign a node to it, so we must be sure to set these layout attributes
 *   on our node when one is next assigned to us in @c setNode: . Since there may be cases when we _do_ already
 *   have our node assigned e.g. during a layout update for existing cells, we also attempt
 *   to update it now.
 */
- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
  [super applyLayoutAttributes:layoutAttributes];
  self.layoutAttributes = layoutAttributes;
}

/**
 * Keep our node filling our content view.
 */
- (void)layoutSubviews
{
  [super layoutSubviews];
  self.node.frame = self.contentView.bounds;
}

@end

/**
 * A category that makes _ASCollectionViewCell conform to IGListBindable.
 *
 * We don't need to do anything to bind the view model – the cell node
 * serves the same purpose.
 */
#if __has_include(<IGListKit/IGListBindable.h>)

#import <IGListKit/IGListBindable.h>

@interface _ASCollectionViewCell (IGListBindable) <IGListBindable>
@end

@implementation _ASCollectionViewCell (IGListBindable)

- (void)bindViewModel:(id)viewModel
{
  // nop
}

@end

#endif
