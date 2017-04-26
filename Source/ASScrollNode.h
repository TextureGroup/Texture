//
//  ASScrollNode.h
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

#import <AsyncDisplayKit/ASDisplayNode.h>
#import <AsyncDisplayKit/ASScrollDirection.h>

NS_ASSUME_NONNULL_BEGIN

@class UIScrollView;

/**
 * Simple node that wraps UIScrollView.
 */
@interface ASScrollNode : ASDisplayNode

/**
 * @abstract The node's UIScrollView.
 */
@property (nonatomic, readonly, strong) UIScrollView *view;

/**
 * @abstract When enabled, the size calculated by the node's layout spec is used as
 * the .contentSize of the scroll view, instead of the bounds size.  The bounds is instead
 * allowed to match the parent's size (whenever it is finite - otherwise, the bounds size
 * also grows to the full contentSize).  It also works with .layoutSpecBlock().
 * NOTE: Most users of ASScrollView will want to use this, and may be enabled by default later.
 */
@property (nonatomic, assign) BOOL automaticallyManagesContentSize;

/**
 * @abstract This property controls how the constrainedSize is interpreted when sizing the content.
 * if you are using automaticallyManagesContentSize, it can be crucial to ensure that the sizing is
 * done how you expect.
 * Vertical: The constrainedSize is interpreted as having unbounded .height (CGFLOAT_MAX), allowing
 * stacks and other content in the layout spec to expand and result in scrollable content.
 * Horizontal: The constrainedSize is interpreted as having unbounded .width (CGFLOAT_MAX), ...
 * Vertical & Horizontal: the constrainedSize is interpreted as unbounded in both directions.
 * @default ASScrollDirectionVerticalDirections
 */
@property (nonatomic, assign) ASScrollDirection scrollableDirections;

@end

NS_ASSUME_NONNULL_END
