//
//  _ASCollectionViewCell.h
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

#import <UIKit/UIKit.h>
#import <AsyncDisplayKit/ASBaseDefines.h>
#import <AsyncDisplayKit/ASCellNode.h>

@class ASCollectionElement;

/**
 * Attempts to cast x to _ASCollectionViewCell, or nil if not possible.
 *
 * Since _ASCollectionViewCell is not available for subclassing (see below),
 * comparing x's and _ASCollectionViewCell's classes is faster than calling -isKindOfClass: on x.
 */
#define ASCollectionViewCellCast(x) ({ \
  id __var = x; \
  ((_ASCollectionViewCell *) (x.class == [_ASCollectionViewCell class] ? __var : nil)); \
})

/**
 * Attempts to cast x to _ASCollectionViewCell and assigns to __var. If not possible, returns the given __val.
 *
 * Since _ASCollectionViewCell is not available for subclassing (see below),
 * comparing x's and _ASCollectionViewCell's classes is faster than calling -isKindOfClass: on x.
 */
#define ASCollectionViewCellCastOrReturn(x, __var, __val) \
  _ASCollectionViewCell *__var = ASCollectionViewCellCast(x); \
  if (__var == nil) { \
    return __val; \
  }

NS_ASSUME_NONNULL_BEGIN

AS_SUBCLASSING_RESTRICTED
@interface _ASCollectionViewCell : UICollectionViewCell

/**
 * Whether or not this cell is interested in cell node visibility events.
 * -cellNodeVisibilityEvent:inScrollView: should be called only if this property is YES.
 */
@property (nonatomic, readonly) BOOL consumesCellNodeVisibilityEvents;
@property (nonatomic, strong, nullable) UICollectionViewLayoutAttributes *layoutAttributes;

- (void)setElement:(ASCollectionElement *)element;

- (void)cellNodeVisibilityEvent:(ASCellNodeVisibilityEvent)event inScrollView:(UIScrollView *)scrollView;

@end

NS_ASSUME_NONNULL_END
