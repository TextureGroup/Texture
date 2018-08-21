//
//  ASStackPositionedLayout.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASLayout.h>
#import <AsyncDisplayKit/ASDimension.h>
#import <AsyncDisplayKit/ASStackUnpositionedLayout.h>

/** Represents a set of laid out and positioned stack layout children. */
struct ASStackPositionedLayout {
  const std::vector<ASStackLayoutSpecItem> items;
  /** Final size of the stack */
  const CGSize size;
  
  /** Given an unpositioned layout, computes the positions each child should be placed at. */
  static ASStackPositionedLayout compute(const ASStackUnpositionedLayout &unpositionedLayout,
                                         const ASStackLayoutSpecStyle &style,
                                         const ASSizeRange &constrainedSize);
};
