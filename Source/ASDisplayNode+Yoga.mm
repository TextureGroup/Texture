//
//  ASDisplayNode+Yoga.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASAvailability.h>

#if YOGA /* YOGA */

#import <AsyncDisplayKit/ASCollections.h>
#import <AsyncDisplayKit/ASDimension.h>
#import <AsyncDisplayKit/ASDisplayNode+Beta.h>
#import <AsyncDisplayKit/ASDisplayNode+FrameworkPrivate.h>
#import <AsyncDisplayKit/ASDisplayNode+Subclasses.h>
#import <AsyncDisplayKit/ASDisplayNode+Yoga2.h>
#import <AsyncDisplayKit/ASDisplayNodeInternal.h>
#import <AsyncDisplayKit/ASLayout.h>
#import <AsyncDisplayKit/ASLayoutElementStylePrivate.h>
#import <AsyncDisplayKit/ASNodeContext+Private.h>
#import <AsyncDisplayKit/ASNodeController+Beta.h>
#import <AsyncDisplayKit/ASNodeControllerInternal.h>
#import <AsyncDisplayKit/ASYogaUtilities.h>
#import <AsyncDisplayKit/_ASDisplayViewAccessiblity.h>
#import <AsyncDisplayKit/ASDisplayNode+LayoutSpec.h>

#define YOGA_LAYOUT_LOGGING 0

// Access style property directly or use the getter to create one
#define _LOCKED_ACCESS_STYLE() (_style ?: [self _locked_style])

AS_ASSUME_NORETAIN_BEGIN

#pragma mark - ASDisplayNode+Yoga

using namespace AS;

@interface ASDisplayNode (YogaPrivate)
@property (nonatomic, weak) ASDisplayNode *yogaParent;
- (ASSizeRange)_locked_constrainedSizeForLayoutPass;
@end

@implementation ASDisplayNode (Yoga)

- (ASDisplayNode *)yogaRoot
{
  Yoga2::AssertEnabled(self);
  ASDisplayNode *yogaRoot = self;
  ASDisplayNode *yogaParent = nil;
  while ((yogaParent = yogaRoot.yogaParent)) {
    yogaRoot = yogaParent;
  }
  return yogaRoot;
}

- (void)setYogaChildren:(NSArray *)yogaChildren
{
  if (ASActivateExperimentalFeature(ASExperimentalUnifiedYogaTree)) {
    Yoga2::SetChildren(self, yogaChildren);
    return;
  }
  LockSet locks = [self lockToRootIfNeededForLayout];
  for (ASDisplayNode *child in [_yogaChildren copy]) {
    // Make sure to un-associate the YGNodeRef tree before replacing _yogaChildren
    // If this becomes a performance bottleneck, it can be optimized by not doing the NSArray removals here.
    [self _locked_removeYogaChild:child];
  }
  _yogaChildren = nil;
  for (ASDisplayNode *child in yogaChildren) {
    [self _locked_addYogaChild:child];
  }
}

- (NSArray *)yogaChildren
{
  if (ASActivateExperimentalFeature(ASExperimentalUnifiedYogaTree)) {
    return Yoga2::CopyChildren(self);
  }
  AS::MutexLocker l(__instanceLock__);
  return [_yogaChildren copy] ?: @[];
}

- (void)addYogaChild:(ASDisplayNode *)child
{
  if (ASActivateExperimentalFeature(ASExperimentalUnifiedYogaTree)) {
    Yoga2::InsertChild(self, child, -1);
    return;
  }
  LockSet locks = [self lockToRootIfNeededForLayout];
  [self _locked_addYogaChild:child];
}

- (void)_locked_addYogaChild:(ASDisplayNode *)child
{
  ASAssertNotExperiment(ASExperimentalUnifiedYogaTree);
  [self _locked_insertYogaChild:child atIndex:_yogaChildren.count];
}

- (void)removeYogaChild:(ASDisplayNode *)child
{
  if (ASActivateExperimentalFeature(ASExperimentalUnifiedYogaTree)) {
    Yoga2::RemoveChild(self, child);
    return;
  }
  LockSet locks = [self lockToRootIfNeededForLayout];
  [self _locked_removeYogaChild:child];
}

- (void)_locked_removeYogaChild:(ASDisplayNode *)child
{
  ASAssertNotExperiment(ASExperimentalUnifiedYogaTree);
  if (child == nil) {
    return;
  }

  [_yogaChildren removeObjectIdenticalTo:child];

  // YGNodeRef removal is done in setParent:
  child.yogaParent = nil;
  [self setNeedsLayout];
}

- (void)insertYogaChild:(ASDisplayNode *)child atIndex:(NSUInteger)index
{
  if (ASActivateExperimentalFeature(ASExperimentalUnifiedYogaTree)) {
    Yoga2::InsertChild(self, child, index);
    return;
  }
  LockSet locks = [self lockToRootIfNeededForLayout];
  [self _locked_insertYogaChild:child atIndex:index];
}

- (void)_locked_insertYogaChild:(ASDisplayNode *)child atIndex:(NSUInteger)index
{
  ASAssertNotExperiment(ASExperimentalUnifiedYogaTree);
  if (child == nil) {
    return;
  }
  ASDisplayNodeAssert(_nodeContext == [child nodeContext],
                      @"Cannot add yoga child from different node context.");
  if (_yogaChildren == nil) {
    _yogaChildren = [[NSMutableArray alloc] init];
  }

  // Clean up state in case this child had another parent.
  [self _locked_removeYogaChild:child];

  [_yogaChildren insertObject:child atIndex:index];

  // YGNodeRef insertion is done in setParent:
  child.yogaParent = self;
  if (_flags.yoga) {
    [child enableYoga];
  }
  [self setNeedsLayout];
}

#pragma mark - Subclass Hooks

+ (BOOL)isRTLForNode:(ASDisplayNode *)node {
  return [node yogaLayoutDirection] == UIUserInterfaceLayoutDirectionRightToLeft;
}

- (void)semanticContentAttributeDidChange:(UISemanticContentAttribute)attribute
{
  Yoga2::AssertEnabled(self);
  UIUserInterfaceLayoutDirection layoutDirection =
  [UIView userInterfaceLayoutDirectionForSemanticContentAttribute:attribute];
  ASLockScopeSelf();
  _LOCKED_ACCESS_STYLE().direction = (layoutDirection == UIUserInterfaceLayoutDirectionLeftToRight
                                      ? YGDirectionLTR : YGDirectionRTL);
}

- (UIUserInterfaceLayoutDirection)yogaLayoutDirection
{
  Yoga2::AssertEnabled(self);
  return _LOCKED_ACCESS_STYLE().direction == YGDirectionRTL
             ? UIUserInterfaceLayoutDirectionRightToLeft
             : UIUserInterfaceLayoutDirectionLeftToRight;
}

- (void)setYogaParent:(ASDisplayNode *)yogaParent
{
  ASAssertNotExperiment(ASExperimentalUnifiedYogaTree);
  ASLockScopeSelf();
  if (_yogaParent == yogaParent) {
    return;
  }

  YGNodeRef yogaNode = [_LOCKED_ACCESS_STYLE() yogaNode];
  YGNodeRef oldParentRef = YGNodeGetParent(yogaNode);
  if (oldParentRef != NULL) {
    YGNodeRemoveChild(oldParentRef, yogaNode);
  }

  _yogaParent = yogaParent;
  if (yogaParent) {
    YGNodeRef newParentRef = [yogaParent.style yogaNode];
    YGNodeInsertChild(newParentRef, yogaNode, YGNodeGetChildCount(newParentRef));
  }
}

- (ASDisplayNode *)yogaParent
{
  return _yogaParent;
}

- (BOOL)shouldSuppressYogaCustomMeasure {
  MutexLocker l(__instanceLock__);
  return _flags.shouldSuppressYogaCustomMeasure;
}

- (void)setShouldSuppressYogaCustomMeasure:(BOOL)shouldSuppressYogaCustomMeasure {
  Yoga2::AssertEnabled(self);
  BOOL shouldMarkContentDirty = NO;
  BOOL yoga2Enabled = NO;
  {
    MutexLocker l(__instanceLock__);
    if (_flags.shouldSuppressYogaCustomMeasure != shouldSuppressYogaCustomMeasure) {
      _flags.shouldSuppressYogaCustomMeasure = shouldSuppressYogaCustomMeasure;
      Yoga2::UpdateMeasureFunction(self);
      shouldMarkContentDirty = YES;
      yoga2Enabled = AS::Yoga2::GetEnabled(self);
    }
  }
  if (shouldMarkContentDirty && yoga2Enabled) {
    Yoga2::MarkContentMeasurementDirty(self);
  }
}

@end

#pragma mark - ASDisplayNode (YogaLocking)

@implementation ASDisplayNode (YogaLocking)

- (BOOL)lockToRootIfNeededForLayout:(AS::LockSet *)locks {
  // If we have a Texture context, then there is no need to lock to root. Just lock the context.
  if (_nodeContext) {
    if (!locks->TryAdd(_nodeContext, _nodeContext->_mutex)) return NO;
    return YES;
  }

  if (!locks->TryAdd(self, __instanceLock__)) return NO;

  // In Yoga we always lock to root.
  if (Yoga2::GetEnabled(self)) {
    ASNodeController *ctrl = ASDisplayNodeGetController(self);
    if (ctrl && !locks->TryAdd(ctrl, ctrl->__instanceLock__)) {
      return NO;
    }
    ASDisplayNode *parent = _supernode;
    while (parent) {
      if (!locks->TryAdd(parent, parent->__instanceLock__)) {
        return NO;
      }
      ASNodeController *parentCtrl = ASDisplayNodeGetController(parent);
      if (parentCtrl && !locks->TryAdd(parentCtrl, parentCtrl->__instanceLock__)) {
        return NO;
      }
      parent = parent->_supernode;
    }
  }
  return YES;
}

- (AS::LockSet)lockToRootIfNeededForLayout {
  AS::LockSet locks;
  while (locks.empty()) {
    if (![self lockToRootIfNeededForLayout:&locks]) continue;
  }
  return locks;
}

@end

@implementation ASDisplayNode (YogaDebugging)

- (NSString *)yogaTreeDescription {
  return [self _yogaTreeDescription:@""];
}

- (NSString *)_yogaTreeDescription:(NSString *)indent {
  // TODO: In Yoga v1.16.0, YGNodeToString has become available only #if DEBUG.
  // #if DEBUG
  //   facebook::yoga::YGNodeToString(s, self.style.yogaNode, (YGPrintOptions)(YGPrintOptionsStyle |
  //   YGPrintOptionsLayout), 0);
  // #endif
  return [self debugDescription];  // way less useful but temporary
}
@end

AS_ASSUME_NORETAIN_END

#endif /* YOGA */
