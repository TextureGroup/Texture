//
//  ASDisplayNode+Yoga.mm
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

#import <AsyncDisplayKit/ASAvailability.h>

#if YOGA /* YOGA */

#import <AsyncDisplayKit/ASYogaLayoutSpec.h>
#import <AsyncDisplayKit/ASYogaUtilities.h>
#import <AsyncDisplayKit/ASDisplayNode+Beta.h>
#import <AsyncDisplayKit/ASDisplayNode+FrameworkPrivate.h>
#import <AsyncDisplayKit/ASDisplayNode+Subclasses.h>
#import <AsyncDisplayKit/ASDisplayNodeInternal.h>
#import <AsyncDisplayKit/ASLayout.h>

#define YOGA_LAYOUT_LOGGING 0

#pragma mark - ASDisplayNode+Yoga

#if YOGA_TREE_CONTIGUOUS

@interface ASDisplayNode (YogaInternal)
@property (nonatomic, weak) ASDisplayNode *yogaParent;
@property (nonatomic, assign) YGNodeRef yogaNode;
@end

#endif /* YOGA_TREE_CONTIGUOUS */

@implementation ASDisplayNode (Yoga)

- (void)setYogaChildren:(NSArray *)yogaChildren
{
  for (ASDisplayNode *child in _yogaChildren) {
    // Make sure to un-associate the YGNodeRef tree before replacing _yogaChildren
    // If this becomes a performance bottleneck, it can be optimized by not doing the NSArray removals here.
    [self removeYogaChild:child];
  }
  _yogaChildren = nil;
  for (ASDisplayNode *child in yogaChildren) {
    [self addYogaChild:child];
  }
}

- (NSArray *)yogaChildren
{
  return _yogaChildren;
}

- (void)addYogaChild:(ASDisplayNode *)child
{
  if (child == nil) {
    return;
  }
  if (_yogaChildren == nil) {
    _yogaChildren = [NSMutableArray array];
  }

  // Clean up state in case this child had another parent.
  [self removeYogaChild:child];
  [_yogaChildren addObject:child];

#if YOGA_TREE_CONTIGUOUS
  // YGNodeRef insertion is done in setParent:
  child.yogaParent = self;
  self.hierarchyState |= ASHierarchyStateYogaLayoutEnabled;
#else
  // When using non-contiguous Yoga layout, each level in the node hierarchy independently uses an ASYogaLayoutSpec
  __weak ASDisplayNode *weakSelf = self;
  self.layoutSpecBlock = ^ASLayoutSpec * _Nonnull(__kindof ASDisplayNode * _Nonnull node, ASSizeRange constrainedSize) {
    ASYogaLayoutSpec *spec = [[ASYogaLayoutSpec alloc] init];
    spec.rootNode = weakSelf;
    spec.children = weakSelf.yogaChildren;
    return spec;
  };
#endif
}

- (void)removeYogaChild:(ASDisplayNode *)child
{
  if (child == nil) {
    return;
  }
  [_yogaChildren removeObjectIdenticalTo:child];

#if YOGA_TREE_CONTIGUOUS
  // YGNodeRef removal is done in setParent:
  child.yogaParent = nil;
  if (_yogaChildren.count == 0 && self.yogaParent == nil) {
    self.hierarchyState &= ~ASHierarchyStateYogaLayoutEnabled;
  }
#else
  if (_yogaChildren.count == 0) {
    self.layoutSpecBlock = nil;
  }
#endif
}

- (void)semanticContentAttributeDidChange:(UISemanticContentAttribute)attribute
{
  if (AS_AT_LEAST_IOS9) {
    UIUserInterfaceLayoutDirection layoutDirection =
    [UIView userInterfaceLayoutDirectionForSemanticContentAttribute:attribute];
    self.style.direction = (layoutDirection == UIUserInterfaceLayoutDirectionLeftToRight
                            ? YGDirectionLTR : YGDirectionRTL);
  }
}

#if YOGA_TREE_CONTIGUOUS /* YOGA_TREE_CONTIGUOUS */

- (void)setYogaNode:(YGNodeRef)yogaNode
{
  _yogaNode = yogaNode;
}

- (YGNodeRef)yogaNode
{
  if (_yogaNode == NULL) {
    _yogaNode = YGNodeNew();
  }
  return _yogaNode;
}

- (void)setYogaParent:(ASDisplayNode *)yogaParent
{
  if (_yogaParent == yogaParent) {
    return;
  }

  YGNodeRef yogaNode = self.yogaNode; // Use property to assign Ref if needed.
  YGNodeRef oldParentRef = YGNodeGetParent(yogaNode);
  if (oldParentRef != NULL) {
    YGNodeRemoveChild(oldParentRef, yogaNode);
  }

  _yogaParent = yogaParent;
  if (yogaParent) {
    self.hierarchyState |= ASHierarchyStateYogaLayoutEnabled;
    YGNodeRef newParentRef = yogaParent.yogaNode;
    YGNodeInsertChild(newParentRef, yogaNode, YGNodeGetChildCount(newParentRef));
  } else {
    self.hierarchyState &= ~ASHierarchyStateYogaLayoutEnabled;
  }
}

- (ASDisplayNode *)yogaParent
{
  return _yogaParent;
}

- (void)setYogaCalculatedLayout:(ASLayout *)yogaCalculatedLayout
{
  _yogaCalculatedLayout = yogaCalculatedLayout;
}

- (ASLayout *)yogaCalculatedLayout
{
  return _yogaCalculatedLayout;
}

- (ASLayout *)layoutForYogaNode
{
  YGNodeRef yogaNode = self.yogaNode;

  CGSize  size     = CGSizeMake(YGNodeLayoutGetWidth(yogaNode), YGNodeLayoutGetHeight(yogaNode));
  CGPoint position = CGPointMake(YGNodeLayoutGetLeft(yogaNode), YGNodeLayoutGetTop(yogaNode));

  // TODO: If it were possible to set .flattened = YES, it would be valid to do so here.
  return [ASLayout layoutWithLayoutElement:self size:size position:position sublayouts:nil];
}

- (void)setupYogaCalculatedLayout
{
  YGNodeRef yogaNode = self.yogaNode; // Use property to assign Ref if needed.
  uint32_t childCount = YGNodeGetChildCount(yogaNode);
  ASDisplayNodeAssert(childCount == self.yogaChildren.count,
                      @"Yoga tree should always be in sync with .yogaNodes array! %@", self.yogaChildren);

  NSMutableArray *sublayouts = [NSMutableArray arrayWithCapacity:childCount];
  for (ASDisplayNode *subnode in self.yogaChildren) {
    [sublayouts addObject:[subnode layoutForYogaNode]];
  }

  // The layout for self should have position CGPointNull, but include the calculated size.
  CGSize size = CGSizeMake(YGNodeLayoutGetWidth(yogaNode), YGNodeLayoutGetHeight(yogaNode));
  ASLayout *layout = [ASLayout layoutWithLayoutElement:self size:size sublayouts:sublayouts];
  self.yogaCalculatedLayout = layout;
}

- (void)setYogaMeasureFuncIfNeeded
{
  // Size calculation via calculateSizeThatFits: or layoutSpecThatFits:
  // This will be used for ASTextNode, as well as any other node that has no Yoga children
  if (self.yogaChildren.count == 0) {
    YGNodeRef yogaNode = self.yogaNode; // Use property to assign Ref if needed.
    YGNodeSetContext(yogaNode, (__bridge void *)self);
    YGNodeSetMeasureFunc(yogaNode, &ASLayoutElementYogaMeasureFunc);
  }
}

- (void)invalidateCalculatedYogaLayout
{
  // Yoga internally asserts that this method may only be called on nodes with a measurement function.
  YGNodeRef yogaNode = self.yogaNode;
  if (YGNodeGetMeasureFunc(yogaNode)) {
    YGNodeMarkDirty(yogaNode);
  }
  self.yogaCalculatedLayout = nil;
}

- (void)calculateLayoutFromYogaRoot:(ASSizeRange)rootConstrainedSize
{
  if (self.yogaParent) {
    if (self.yogaCalculatedLayout == nil) {
      [self _setNeedsLayoutFromAbove];
    }
    return;
  }
  if (ASHierarchyStateIncludesYogaLayoutMeasuring(self.hierarchyState)) {
    ASDisplayNodeAssert(NO, @"A Yoga layout is being performed by a parent; children must not perform their own until it is done! %@", [self displayNodeRecursiveDescription]);
    return;
  }

  ASDisplayNodePerformBlockOnEveryYogaChild(self, ^(ASDisplayNode * _Nonnull node) {
    node.hierarchyState |= ASHierarchyStateYogaLayoutMeasuring;
  });

  YGNodeRef rootYogaNode = self.yogaNode;

  // Apply the constrainedSize as a base, known frame of reference.
  // If the root node also has style.*Size set, these will be overridden below.
  // YGNodeCalculateLayout currently doesn't offer the ability to pass a minimum size (max is passed there).
  YGNodeStyleSetMinWidth (rootYogaNode, yogaFloatForCGFloat(rootConstrainedSize.min.width));
  YGNodeStyleSetMinHeight(rootYogaNode, yogaFloatForCGFloat(rootConstrainedSize.min.height));

  ASDisplayNodePerformBlockOnEveryYogaChild(self, ^(ASDisplayNode * _Nonnull node) {
    ASLayoutElementStyle *style = node.style;
    YGNodeRef yogaNode = node.yogaNode;

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
    if (node != self) {
      YGNODE_STYLE_SET_DIMENSION(yogaNode, Width, style.width);
      YGNODE_STYLE_SET_DIMENSION(yogaNode, Height, style.height);

      YGNODE_STYLE_SET_DIMENSION(yogaNode, MinWidth, style.minWidth);
      YGNODE_STYLE_SET_DIMENSION(yogaNode, MinHeight, style.minHeight);

      YGNODE_STYLE_SET_DIMENSION(yogaNode, MaxWidth, style.maxWidth);
      YGNODE_STYLE_SET_DIMENSION(yogaNode, MaxHeight, style.maxHeight);
    }

    [node setYogaMeasureFuncIfNeeded];

    /* TODO(appleguy): STYLE SETTER METHODS LEFT TO IMPLEMENT
     void YGNodeStyleSetOverflow(YGNodeRef node, YGOverflow overflow);
     void YGNodeStyleSetFlex(YGNodeRef node, float flex);
     */
  });

  // It is crucial to use yogaFloat... to convert CGFLOAT_MAX into YGUndefined here.
  YGNodeCalculateLayout(rootYogaNode,
                        yogaFloatForCGFloat(rootConstrainedSize.max.width),
                        yogaFloatForCGFloat(rootConstrainedSize.max.height),
                        YGDirectionInherit);

  ASDisplayNodePerformBlockOnEveryYogaChild(self, ^(ASDisplayNode * _Nonnull node) {
    [node setupYogaCalculatedLayout];
    node.hierarchyState &= ~ASHierarchyStateYogaLayoutMeasuring;
  });

#if YOGA_LAYOUT_LOGGING /* YOGA_LAYOUT_LOGGING */
  // Concurrent layouts will interleave the NSLog messages unless we serialize.
  // Use @synchornize rather than trampolining to the main thread so the tree state isn't changed.
  @synchronized ([ASDisplayNode class]) {
    NSLog(@"****************************************************************************");
    NSLog(@"******************** STARTING YOGA -> ASLAYOUT CREATION ********************");
    NSLog(@"****************************************************************************");
    ASDisplayNodePerformBlockOnEveryYogaChild(self, ^(ASDisplayNode * _Nonnull node) {
      NSLog(@" "); // Newline
      NSLog(@"node = %@", node);
      NSLog(@"style = %@", node.style);
      NSLog(@"layout = %@", node.yogaCalculatedLayout);
      YGNodePrint(node.yogaNode, (YGPrintOptions)(YGPrintOptionsStyle | YGPrintOptionsLayout));
    });
  }
#endif /* YOGA_LAYOUT_LOGGING */
}

#endif /* YOGA_TREE_CONTIGUOUS */

@end

#endif /* YOGA */
