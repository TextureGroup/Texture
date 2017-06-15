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
#import <AsyncDisplayKit/ASDisplayNode+FrameworkSubclasses.h>
#import <AsyncDisplayKit/ASDisplayNodeInternal.h>
#import <AsyncDisplayKit/ASLayout.h>

#define YOGA_LAYOUT_LOGGING 0

#pragma mark - ASDisplayNode+Yoga

#if YOGA_TREE_CONTIGUOUS

@interface ASDisplayNode (YogaInternal)
@property (nonatomic, weak) ASDisplayNode *yogaParent;
- (ASSizeRange)_locked_constrainedSizeForLayoutPass;
@end

@interface ASLayout (YogaInternal)
@property (nonatomic, getter=isFlattened) BOOL flattened;
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

  BOOL hadZeroChildren = (_yogaChildren.count == 0);

  [_yogaChildren addObject:child];

#if YOGA_TREE_CONTIGUOUS
  // Ensure any measure function is removed before inserting the YGNodeRef child.
  if (hadZeroChildren) {
    [self updateYogaMeasureFuncIfNeeded];
  }
  // YGNodeRef insertion is done in setParent:
  child.yogaParent = self;
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
  
  BOOL hadChildren = (_yogaChildren.count > 0);
  [_yogaChildren removeObjectIdenticalTo:child];

#if YOGA_TREE_CONTIGUOUS
  // YGNodeRef removal is done in setParent:
  child.yogaParent = nil;
  // Ensure any measure function is re-added after removing the YGNodeRef child.
  if (hadChildren && _yogaChildren.count == 0) {
    [self updateYogaMeasureFuncIfNeeded];
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

- (void)setYogaParent:(ASDisplayNode *)yogaParent
{
  if (_yogaParent == yogaParent) {
    return;
  }

  YGNodeRef yogaNode = [self.style yogaNodeCreateIfNeeded];
  YGNodeRef oldParentRef = YGNodeGetParent(yogaNode);
  if (oldParentRef != NULL) {
    YGNodeRemoveChild(oldParentRef, yogaNode);
  }

  _yogaParent = yogaParent;
  if (yogaParent) {
    YGNodeRef newParentRef = [yogaParent.style yogaNodeCreateIfNeeded];
    YGNodeInsertChild(newParentRef, yogaNode, YGNodeGetChildCount(newParentRef));
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

- (void)setYogaLayoutInProgress:(BOOL)yogaLayoutInProgress
{
  setFlag(YogaLayoutInProgress, yogaLayoutInProgress);
}

- (BOOL)yogaLayoutInProgress
{
  return checkFlag(YogaLayoutInProgress);
}

- (ASLayout *)layoutForYogaNode
{
  YGNodeRef yogaNode = self.style.yogaNode;

  CGSize  size     = CGSizeMake(YGNodeLayoutGetWidth(yogaNode), YGNodeLayoutGetHeight(yogaNode));
  CGPoint position = CGPointMake(YGNodeLayoutGetLeft(yogaNode), YGNodeLayoutGetTop(yogaNode));

  return [ASLayout layoutWithLayoutElement:self size:size position:position sublayouts:nil];
}

- (void)setupYogaCalculatedLayout
{
  YGNodeRef yogaNode = self.style.yogaNode;
  uint32_t childCount = YGNodeGetChildCount(yogaNode);
  ASDisplayNodeAssert(childCount == self.yogaChildren.count,
                      @"Yoga tree should always be in sync with .yogaNodes array! %@", self.yogaChildren);

  NSMutableArray *sublayouts = [NSMutableArray arrayWithCapacity:childCount];
  for (ASDisplayNode *subnode in self.yogaChildren) {
    ASLayout *sublayout = [subnode layoutForYogaNode];
    sublayout.flattened = YES;
    [sublayouts addObject:sublayout];
  }

  // The layout for self should have position CGPointNull, but include the calculated size.
  CGSize size = CGSizeMake(YGNodeLayoutGetWidth(yogaNode), YGNodeLayoutGetHeight(yogaNode));
  ASLayout *layout = [ASLayout layoutWithLayoutElement:self size:size sublayouts:sublayouts];

  self.yogaCalculatedLayout = layout;
}

- (void)updateYogaMeasureFuncIfNeeded
{
  // Size calculation via calculateSizeThatFits: or layoutSpecThatFits:
  // This will be used for ASTextNode, as well as any other node that has no Yoga children
  id <ASLayoutElement> layoutElementToMeasure = (self.yogaChildren.count == 0 ? self : nil);
  ASLayoutElementYogaUpdateMeasureFunc(self.style.yogaNode, layoutElementToMeasure);
}

- (void)invalidateCalculatedYogaLayout
{
  // Yoga internally asserts that this method may only be called on nodes with a measurement function.
  YGNodeRef yogaNode = self.style.yogaNode;
  if (yogaNode && YGNodeGetMeasureFunc(yogaNode)) {
    YGNodeMarkDirty(yogaNode);
  }
  self.yogaCalculatedLayout = nil;
}

- (void)calculateLayoutFromYogaRoot:(ASSizeRange)rootConstrainedSize
{
  ASDisplayNode *yogaParent = self.yogaParent;

  if (yogaParent) {
    ASYogaLog(@"ESCALATING to Yoga root: %@", self);
    // TODO(appleguy): Consider how to get the constrainedSize for the yogaRoot when escalating manually.
    [yogaParent calculateLayoutFromYogaRoot:ASSizeRangeUnconstrained];
    return;
  }

  ASDN::MutexLocker l(__instanceLock__);

  // Prepare all children for the layout pass with the current Yoga tree configuration.
  ASDisplayNodePerformBlockOnEveryYogaChild(self, ^(ASDisplayNode * _Nonnull node) {
    node.yogaLayoutInProgress = YES;
    [node updateYogaMeasureFuncIfNeeded];
  });

  if (ASSizeRangeEqualToSizeRange(rootConstrainedSize, ASSizeRangeUnconstrained)) {
    rootConstrainedSize = [self _locked_constrainedSizeForLayoutPass];
  }

  ASYogaLog(@"CALCULATING at Yoga root with constraint = {%@, %@}: %@",
            NSStringFromCGSize(rootConstrainedSize.min), NSStringFromCGSize(rootConstrainedSize.max), self);

  YGNodeRef rootYogaNode = self.style.yogaNode;

  // Apply the constrainedSize as a base, known frame of reference.
  // If the root node also has style.*Size set, these will be overridden below.
  // YGNodeCalculateLayout currently doesn't offer the ability to pass a minimum size (max is passed there).

  // TODO(appleguy): Reconcile the self.style.*Size properties with rootConstrainedSize
  YGNodeStyleSetMinWidth (rootYogaNode, yogaFloatForCGFloat(rootConstrainedSize.min.width));
  YGNodeStyleSetMinHeight(rootYogaNode, yogaFloatForCGFloat(rootConstrainedSize.min.height));

  // It is crucial to use yogaFloat... to convert CGFLOAT_MAX into YGUndefined here.
  YGNodeCalculateLayout(rootYogaNode,
                        yogaFloatForCGFloat(rootConstrainedSize.max.width),
                        yogaFloatForCGFloat(rootConstrainedSize.max.height),
                        YGDirectionInherit);

  ASDisplayNodePerformBlockOnEveryYogaChild(self, ^(ASDisplayNode * _Nonnull node) {
    [node setupYogaCalculatedLayout];
    node.yogaLayoutInProgress = NO;
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
