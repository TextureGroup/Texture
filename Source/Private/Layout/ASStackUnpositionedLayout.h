//
//  ASStackUnpositionedLayout.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <vector>

#import <AsyncDisplayKit/ASLayout.h>
#import <AsyncDisplayKit/ASStackLayoutSpecUtilities.h>
#import <AsyncDisplayKit/ASStackLayoutSpec.h>

/** The threshold that determines if a violation has actually occurred. */
AS_EXTERN CGFloat const kViolationEpsilon;

struct ASStackLayoutSpecChild {
  /** The original source child. */
  id<ASLayoutElement> element;
  /** Style object of element. */
  ASLayoutElementStyle *style;
  /** Size object of the element */
  ASLayoutElementSize size;
};

struct ASStackLayoutSpecItem {
  /** The original source child. */
  ASStackLayoutSpecChild child;
  /** The proposed layout or nil if no is calculated yet. */
  ASLayout *layout;
};

struct ASStackUnpositionedLine {
  /** The set of proposed children in this line, each contains child layout, not yet positioned. */
  std::vector<ASStackLayoutSpecItem> items;
  /** The total size of the children in the stack dimension, including all spacing. */
  CGFloat stackDimensionSum;
  /** The size in the cross dimension */
  CGFloat crossSize;
  /** The baseline of the stack which baseline aligned children should align to */
  CGFloat baseline;
};

/** Represents a set of stack layout children that have their final layout computed, but are not yet positioned. */
struct ASStackUnpositionedLayout {
  /** The set of proposed lines, each contains child layouts, not yet positioned. */
  const std::vector<ASStackUnpositionedLine> lines;
  /** 
   * In a single line stack (e.g no wrao), this is the total size of the children in the stack dimension, including all spacing.
   * In a multi-line stack, this is the largest stack dimension among lines.
   */
  const CGFloat stackDimensionSum;
  const CGFloat crossDimensionSum;
  
  /** Given a set of children, computes the unpositioned layouts for those children. */
  static ASStackUnpositionedLayout compute(const std::vector<ASStackLayoutSpecChild> &children,
                                           const ASStackLayoutSpecStyle &style,
                                           const ASSizeRange &sizeRange,
                                           const BOOL concurrent);
  
  static CGFloat baselineForItem(const ASStackLayoutSpecStyle &style,
                                 const ASStackLayoutSpecItem &l);
  
  static CGFloat computeStackViolation(const CGFloat stackDimensionSum,
                                       const ASStackLayoutSpecStyle &style,
                                       const ASSizeRange &sizeRange);

  static CGFloat computeCrossViolation(const CGFloat crossDimensionSum,
                                       const ASStackLayoutSpecStyle &style,
                                       const ASSizeRange &sizeRange);
};
