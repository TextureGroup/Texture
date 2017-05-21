//
//  ASYogaLayoutSpec.mm
//  AsyncDisplayKit
//
//  Created by Scott Goodson on 5/6/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import <AsyncDisplayKit/ASAvailability.h>

#if !YOGA_TREE_CONTIGUOUS /* !YOGA_TREE_CONTIGUOUS */

#import <AsyncDisplayKit/ASYogaLayoutSpec.h>
#import <AsyncDisplayKit/ASYogaUtilities.h>
#import <AsyncDisplayKit/ASDisplayNode+Beta.h>
#import <AsyncDisplayKit/ASLayout.h>
#import <AsyncDisplayKit/ASLayoutSpec+Subclasses.h>

#define YOGA_LAYOUT_LOGGING 0

@implementation ASYogaLayoutSpec

- (ASLayout *)layoutForYogaNode:(YGNodeRef)yogaNode
{
  BOOL isRootNode = (YGNodeGetParent(yogaNode) == NULL);
  uint32_t childCount = YGNodeGetChildCount(yogaNode);

  NSMutableArray *sublayouts = [NSMutableArray arrayWithCapacity:childCount];
  for (uint32_t i = 0; i < childCount; i++) {
    [sublayouts addObject:[self layoutForYogaNode:YGNodeGetChild(yogaNode, i)]];
  }

  id <ASLayoutElement> layoutElement = (__bridge id <ASLayoutElement>)YGNodeGetContext(yogaNode);
  CGSize size = CGSizeMake(YGNodeLayoutGetWidth(yogaNode), YGNodeLayoutGetHeight(yogaNode));

  if (isRootNode) {
    // The layout for root should have position CGPointNull, but include the calculated size.
    return [ASLayout layoutWithLayoutElement:layoutElement size:size sublayouts:sublayouts];
  } else {
    CGPoint position = CGPointMake(YGNodeLayoutGetLeft(yogaNode), YGNodeLayoutGetTop(yogaNode));
    // TODO: If it were possible to set .flattened = YES, it would be valid to do so here.
    return [ASLayout layoutWithLayoutElement:layoutElement size:size position:position sublayouts:nil];
  }
}

- (void)setupYogaNode:(YGNodeRef)yogaNode forElement:(id <ASLayoutElement>)element withParentYogaNode:(YGNodeRef)parentYogaNode
{
  ASLayoutElementStyle *style = element.style;

  YGNodeSetContext(yogaNode, (__bridge void *)element);

  YGNodeStyleSetDirection     (yogaNode, style.direction);

  YGNodeStyleSetFlexWrap      (yogaNode, style.flexWrap);
  YGNodeStyleSetFlexGrow      (yogaNode, style.flexGrow);
  YGNodeStyleSetFlexShrink    (yogaNode, style.flexShrink);
  YGNODE_STYLE_SET_DIMENSION  (yogaNode, FlexBasis, style.flexBasis);

  YGNodeStyleSetFlexDirection (yogaNode, yogaFlexDirection(style.flexDirection));
  YGNodeStyleSetJustifyContent(yogaNode, yogaJustifyContent(style.justifyContent));
  YGNodeStyleSetAlignSelf     (yogaNode, yogaAlignSelf(style.alignSelf));
  ASStackLayoutAlignItems alignItems = style.alignItems;
  if (alignItems != ASStackLayoutAlignItemsNotSet) {
    YGNodeStyleSetAlignItems(yogaNode, yogaAlignItems(alignItems));
  }

  YGNodeStyleSetPositionType  (yogaNode, style.positionType);
  ASEdgeInsets position = style.position;
  ASEdgeInsets margin   = style.margin;
  ASEdgeInsets padding  = style.padding;
  ASEdgeInsets border   = style.border;

  YGEdge edge = YGEdgeLeft;
  for (int i = 0; i < YGEdgeAll + 1; ++i) {
    YGNODE_STYLE_SET_DIMENSION_WITH_EDGE(yogaNode, Position, dimensionForEdgeWithEdgeInsets(edge, position), edge);
    YGNODE_STYLE_SET_DIMENSION_WITH_EDGE(yogaNode, Margin, dimensionForEdgeWithEdgeInsets(edge, margin), edge);
    YGNODE_STYLE_SET_DIMENSION_WITH_EDGE(yogaNode, Padding, dimensionForEdgeWithEdgeInsets(edge, padding), edge);
    YGNODE_STYLE_SET_FLOAT_WITH_EDGE(yogaNode, Border, dimensionForEdgeWithEdgeInsets(edge, border), edge);
    edge = (YGEdge)(edge + 1);
  }

  CGFloat aspectRatio = style.aspectRatio;
  if (aspectRatio > FLT_EPSILON && aspectRatio < CGFLOAT_MAX / 2.0) {
    YGNodeStyleSetAspectRatio(yogaNode, aspectRatio);
  }

  // For the root node, we use rootConstrainedSize above. For children, consult the style for their size.
  if (parentYogaNode != NULL) {
    YGNodeInsertChild(parentYogaNode, yogaNode, YGNodeGetChildCount(parentYogaNode));

    YGNODE_STYLE_SET_DIMENSION(yogaNode, Width, style.width);
    YGNODE_STYLE_SET_DIMENSION(yogaNode, Height, style.height);

    YGNODE_STYLE_SET_DIMENSION(yogaNode, MinWidth, style.minWidth);
    YGNODE_STYLE_SET_DIMENSION(yogaNode, MinHeight, style.minHeight);

    YGNODE_STYLE_SET_DIMENSION(yogaNode, MaxWidth, style.maxWidth);
    YGNODE_STYLE_SET_DIMENSION(yogaNode, MaxHeight, style.maxHeight);

    YGNodeSetMeasureFunc(yogaNode, &ASLayoutElementYogaMeasureFunc);
  }

  // TODO(appleguy): STYLE SETTER METHODS LEFT TO IMPLEMENT: YGNodeStyleSetOverflow, YGNodeStyleSetFlex
}

- (ASLayout *)calculateLayoutThatFits:(ASSizeRange)constrainedSize
                     restrictedToSize:(ASLayoutElementSize)layoutElementSize
                 relativeToParentSize:(CGSize)parentSize
{
  ASSizeRange styleAndParentSize = ASLayoutElementSizeResolve(layoutElementSize, parentSize);
  const ASSizeRange rootConstrainedSize = ASSizeRangeIntersect(constrainedSize, styleAndParentSize);

  YGNodeRef rootYogaNode = YGNodeNew();

  // YGNodeCalculateLayout currently doesn't offer the ability to pass a minimum size (max is passed there).
  // Apply the constrainedSize.min directly to the root node so that layout accounts for it.
  YGNodeStyleSetMinWidth (rootYogaNode, yogaFloatForCGFloat(rootConstrainedSize.min.width));
  YGNodeStyleSetMinHeight(rootYogaNode, yogaFloatForCGFloat(rootConstrainedSize.min.height));

  [self setupYogaNode:rootYogaNode forElement:self.rootNode withParentYogaNode:NULL];
  for (id <ASLayoutElement> child in self.children) {
    YGNodeRef yogaNode = YGNodeNew();
    [self setupYogaNode:yogaNode forElement:child withParentYogaNode:rootYogaNode];
  }

  // It is crucial to use yogaFloat... to convert CGFLOAT_MAX into YGUndefined here.
  YGNodeCalculateLayout(rootYogaNode,
                        yogaFloatForCGFloat(rootConstrainedSize.max.width),
                        yogaFloatForCGFloat(rootConstrainedSize.max.height),
                        YGDirectionInherit);

  ASLayout *layout = [self layoutForYogaNode:rootYogaNode];

#if YOGA_LAYOUT_LOGGING
  // Concurrent layouts will interleave the NSLog messages unless we serialize.
  // Use @synchornize rather than trampolining to the main thread so the tree state isn't changed.
  @synchronized ([ASDisplayNode class]) {
    NSLog(@"****************************************************************************");
    NSLog(@"******************** STARTING YOGA -> ASLAYOUT CREATION ********************");
    NSLog(@"****************************************************************************");
      NSLog(@"node = %@", self.rootNode);
      NSLog(@"style = %@", self.rootNode.style);
      YGNodePrint(rootYogaNode, (YGPrintOptions)(YGPrintOptionsStyle | YGPrintOptionsLayout));
  }
  NSLog(@"rootConstraint = (%@, %@), layout = %@, sublayouts = %@", NSStringFromCGSize(rootConstrainedSize.min), NSStringFromCGSize(rootConstrainedSize.max), layout, layout.sublayouts);
#endif

  return layout;
}

@end

#endif /* !YOGA_TREE_CONTIGUOUS */
