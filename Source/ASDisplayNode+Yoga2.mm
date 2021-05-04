//
//  ASDisplayNode+Yoga2.mm
//  AsyncDisplayKit
//
//  Created by Adlai Holler on 3/8/19.
//  Copyright © 2019 Pinterest. All rights reserved.
//

#import <AsyncDisplayKit/ASDisplayNode+Yoga2.h>
#import <AsyncDisplayKit/ASAvailability.h>
#import <AsyncDisplayKit/ASBaseDefines.h>

AS_ASSUME_NORETAIN_BEGIN

#if YOGA

#import <AsyncDisplayKit/ASDisplayNode+IGListKit.h>
#import <AsyncDisplayKit/ASDisplayNode+Yoga2Logging.h>
#import <AsyncDisplayKit/ASAssert.h>
#import <AsyncDisplayKit/NSArray+Diffing.h>
#import <AsyncDisplayKit/ASCellNode+Internal.h>
#import <AsyncDisplayKit/ASDisplayNode+FrameworkPrivate.h>
#import <AsyncDisplayKit/ASDisplayNodeInternal.h>
#import <AsyncDisplayKit/ASInternalHelpers.h>
#import <AsyncDisplayKit/ASLayoutElementStylePrivate.h>

#import YOGA_HEADER_PATH

namespace AS {
namespace Yoga2 {

bool GetEnabled(ASDisplayNode *node) {
  if (node) {
    MutexLocker l(node->__instanceLock__);
    return node->_flags.yoga;
  } else {
    return false;
  }
}

/**
 * Whether to manually round using ASCeilPixelValue instead of Yoga's internal pixel-grid rounding.
 *
 * When it's critical to have exact layout parity between yoga2 and the other layout systems, this
 * flag must be on.
 */
static constexpr bool kUseLegacyRounding = true;

/**
 * Whether to clamp measurement results before returning them into Yoga. This may produce worse
 * visual results, but it matches existing mainline Texture layout. See b/129227140.
 */
static constexpr bool kClampMeasurementResults = true;

/// Texture -> Yoga node.
static inline YGNodeRef GetYoga(ASDisplayNode *node) { return [node.style yogaNode]; }

CFTypeRef GetTextureCF(YGNodeRef yoga) {
  CFTypeRef result = nullptr;
  if (yoga) {
    result = (CFTypeRef)YGNodeGetContext(yoga);
    ASDisplayNodeCAssert(result, @"Failed to get Texture node for yoga node.");
  }
  return result;
}

/// Asserts all nodes already locked.
static inline YGNodeRef GetRoot(YGNodeRef yoga) {
  DISABLED_ASAssertLocked(GetTexture(yoga)->__instanceLock__);
  YGNodeRef next = YGNodeGetOwner(yoga);
  while (next) {
    yoga = next;
    DISABLED_ASAssertLocked(GetTexture(yoga)->__instanceLock__);
    next = YGNodeGetOwner(next);
  }
  return yoga;
}

static inline bool IsRoot(YGNodeRef yoga) { return !YGNodeGetOwner(yoga); }

// Read node layout origin, round if legacy, and return as CGPoint.
static inline CGPoint CGOriginOfYogaLayout(YGNodeRef yoga) {
  if (kUseLegacyRounding) {
    return CGPointMake(ASCeilPixelValue(YGNodeLayoutGetLeft(yoga)),
                       ASCeilPixelValue(YGNodeLayoutGetTop(yoga)));
  }

  return CGPointMake(YGNodeLayoutGetLeft(yoga),
  YGNodeLayoutGetTop(yoga));
}

// Read YGLayout size, round if legacy, and return as CGSize.
// If layout has undefined values, returns CGSizeZero.
static inline CGSize CGSizeOfYogaLayout(YGNodeRef yoga) {
  if (YGFloatIsUndefined(YGNodeLayoutGetHeight(yoga))) {
    return CGSizeZero;
  }

  if (kUseLegacyRounding) {
    return CGSizeMake(ASCeilPixelValue(YGNodeLayoutGetWidth(yoga)),
                      ASCeilPixelValue(YGNodeLayoutGetHeight(yoga)));
  }

  return CGSizeMake(YGNodeLayoutGetWidth(yoga),
  YGNodeLayoutGetHeight(yoga));
}

static inline CGRect CGRectOfYogaLayout(YGNodeRef yoga) {
  return {CGOriginOfYogaLayout(yoga), CGSizeOfYogaLayout(yoga)};
}

static inline void AssertRoot(ASDisplayNode *node) {
  ASDisplayNodeCAssert(IsRoot(GetYoga(node)), @"Must be called on root: %@", node);
}

static thread_local int measuredNodes = 0;
/**
 * We are root and the tree is dirty. There are few things we need to do.
 * **All of the following must be done on the main thread, so the first thing is to get there.**
 * - If we are loaded, we need to call [layer setNeedsLayout] on main.
 * - If we are range-managed, we need to inform our container that our size is invalid.
 * - If we are in hierarchy, we need to call [superlayer setNeedsLayout] so that it knows that we
 * (may) need resizing.
 */
void HandleRootDirty(ASDisplayNode *node) {
  MutexLocker l(node->__instanceLock__);
  unowned CALayer *layer = node->_layer;
  const bool isRangeManaged = ASHierarchyStateIncludesRangeManaged(node->_hierarchyState);

  // Not loaded, not range managed, nothing to be done.
  if (!layer && !isRangeManaged) {
    return;
  }

  // Not on main thread. Get on the main thread and come back in.
  if (!ASDisplayNodeThreadIsMain()) {
    dispatch_async(dispatch_get_main_queue(), ^{
      HandleRootDirty(node);
    });
    return;
  }

  // On main. If no longer root, nothing to be done. Our new tree was invalidated when we got
  // added to it.
  YGNodeRef yoga = GetYoga(node);
  if (!IsRoot(yoga)) {
    return;
  }

  // Loaded or range-managed. On main. Root. Locked.

  // Dirty our own layout so that even if our size didn't change we get a layout pass.
  [layer setNeedsLayout];

  // If we are a cell node with an interaction delegate, inform it our size is invalid.
  if (id<ASCellNodeInteractionDelegate> interactionDelegate =
          ASDynamicCast(node, ASCellNode).interactionDelegate) {
    [interactionDelegate nodeDidInvalidateSize:(ASCellNode *)node];
  } else {
    // Otherwise just inform our superlayer (if we have one.)
    [layer.superlayer setNeedsLayout];
  }
}

void YogaDirtied(YGNodeRef yoga) {
  // NOTE: We may be locked – if someone set a property directly on us – or we may not – if this
  // dirtiness is propagating up from below.

  // If we are not root, ignore. Yoga will propagate the dirt up to root.
  if (IsRoot(yoga)) {
    ASDisplayNode *node = [GetTexture(yoga) tryRetain];
    if (node) {
      HandleRootDirty(node);
    }
  }
}

/// If mode is undefined, returns CGFLOAT_MAX. Otherwise asserts valid & converts to CGFloat.
CGFloat CGConstraintFromYoga(float dim, YGMeasureMode mode) {
  if (mode == YGMeasureModeUndefined) {
    return CGFLOAT_MAX;
  } else {
    ASDisplayNodeCAssert(!YGFloatIsUndefined(dim), @"Yoga said it gave us a size but it didn't.");
    return dim;
  }
}

inline float YogaConstraintFromCG(CGFloat constraint) {
  return constraint == CGFLOAT_MAX || isinf(constraint) ? YGUndefined : constraint;
}

/// Convert a Yoga layout to an ASLayout.
ASLayout *ASLayoutCreateFromYogaNodeLayout(YGNodeRef yoga, ASSizeRange sizeRange) {
  // If our layout has no dimensions, return nil now.
  if (YGFloatIsUndefined(YGNodeLayoutGetHeight(yoga))) {
    return nil;
  }

  const uint32_t child_count = YGNodeGetChildCount(yoga);
  ASLayout *sublayouts[child_count];
  for (uint32_t i = 0; i < child_count; i++) {
    // If any node in the subtree has no layout, then there is no layout. Return nil.
    YGNodeRef child = YGNodeGetChild(yoga, i);
    if (!(sublayouts[i] = ASLayoutCreateFromYogaNodeLayout(child, sizeRange))) {
      return nil;
    }
  }
  auto boxed_sublayouts = [NSArray<ASLayout *> arrayByTransferring:sublayouts
                                                             count:child_count];
  CGSize yogaLayoutSize = CGSizeOfYogaLayout(yoga);
  if (!ASSizeRangeEqualToSizeRange(sizeRange, ASSizeRangeZero)) {
    yogaLayoutSize = CGSizeMake(std::max(yogaLayoutSize.width, sizeRange.min.width),
                                std::max(yogaLayoutSize.height, sizeRange.min.height));
  }

  return [[ASLayout alloc] initWithLayoutElement:GetTexture(yoga)
                                            size:yogaLayoutSize
                                        position:CGOriginOfYogaLayout(yoga)
                                      sublayouts:boxed_sublayouts];
}

// Only set on nodes that implement calculateSizeThatFits:.
YGSize YogaMeasure(YGNodeRef yoga, float width, YGMeasureMode widthMode, float height,
                   YGMeasureMode heightMode) {
  ASDisplayNode *node = GetTexture(yoga);

  // Go straight to calculateSizeThatFits:, not sizeThatFits:. Caching is handled inside of yoga –
  // if we got here, we need to do a calculation so call out to the node subclass.
  const CGSize constraint =
      CGSizeMake(CGConstraintFromYoga(width, widthMode), CGConstraintFromYoga(height, heightMode));
  CGSize size = [node calculateSizeThatFits:constraint];

  if (kClampMeasurementResults) {
    size.width = MIN(size.width, constraint.width);
    size.height = MIN(size.height, constraint.height);
  }

  // To match yoga1, we ceil this value (see ASLayoutElementYogaMeasureFunc).
  if (kUseLegacyRounding) {
    size = ASCeilSizeValues(size);
  }

  // Do verbose logging if enabled.
  measuredNodes++;
#if ASEnableVerboseLogging
  NSString *thread = @"";
  if (ASDisplayNodeThreadIsMain()) {
    // good place for a breakpoint.
    thread = @"main thread ";
  }
  as_log_verbose(ASLayoutLog(), "did %@leaf measurement for %@ (%g %g) -> (%g %g)", thread,
                 ASObjectDescriptionMakeTiny(node), constraint.width, constraint.height, size.width,
                 size.height);
#endif  // ASEnableVerboseLogging

  return {(float)size.width, (float)size.height};
}

float YogaBaseline(YGNodeRef yoga, float width, float height) {
  return [GetTexture(yoga) yogaBaselineWithSize:CGSizeMake(width, height)];
}

void Enable(ASDisplayNode *texture) {
  NSCParameterAssert(texture != nil);
  if (!texture) {
    return;
  }
  MutexLocker l(texture->__instanceLock__);
  YGNodeRef yoga = GetYoga(texture);
  YGNodeSetContext(yoga, (__bridge void *)texture);
  YGNodeSetDirtiedFunc(yoga, &YogaDirtied);
  // Note: No print func. See Yoga2Logging.h.

  // Set measure & baseline funcs if needed.
  if (texture->_methodOverrides & ASDisplayNodeMethodOverrideYogaBaseline) {
    YGNodeSetBaselineFunc(yoga, &YogaBaseline);
  }

  UpdateMeasureFunction(texture);
}

void UpdateMeasureFunction(ASDisplayNode *texture) {
  DISABLED_ASAssertLocked(node);
  YGNodeRef yoga = GetYoga(texture);
  if (texture.shouldSuppressYogaCustomMeasure) {
    YGNodeSetMeasureFunc(yoga, NULL);
  } else {
    if (0 != (texture->_methodOverrides & ASDisplayNodeMethodOverrideCalcSizeThatFits)) {
      YGNodeSetMeasureFunc(yoga, &YogaMeasure);
    }
  }
}

void MarkContentMeasurementDirty(ASDisplayNode *node) {
  DISABLED_ASAssertUnlocked(node);
  AS::LockSet locks = [node lockToRootIfNeededForLayout];
  AssertEnabled(node);
  YGNodeRef yoga = GetYoga(node);
  if (YGNodeHasMeasureFunc(yoga) && !YGNodeIsDirty(yoga)) {
    as_log_verbose(ASLayoutLog(), "mark content dirty for %@", ASObjectDescriptionMakeTiny(node));
    YGNodeMarkDirty(yoga);
  }
}

void CalculateLayoutAtRoot(ASDisplayNode *node, CGSize maxSize) {
  AssertEnabled(node);
  DISABLED_ASAssertLocked(node->__instanceLock__);
  AssertRoot(node);

  // Notify.
  measuredNodes = 0;
  const ASSizeRange sizeRange = ASSizeRangeMake(CGSizeZero, maxSize);
  [node willCalculateLayout:sizeRange];
  [node enumerateInterfaceStateDelegates:^(id<ASInterfaceStateDelegate> _Nonnull delegate) {
    if ([delegate respondsToSelector:@selector(nodeWillCalculateLayout:)]) {
      [delegate nodeWillCalculateLayout:sizeRange];
    }
  }];

  // Log the calculation request.
#if ASEnableVerboseLogging
  static std::atomic<long> counter(1);
  const long request_id = counter.fetch_add(1);
  as_log_verbose(ASLayoutLog(), "enter layout calculation %ld for %@: %@", request_id,
                 ASObjectDescriptionMakeTiny(node), NSStringFromCGSize(maxSize));
#endif

  const YGNodeRef yoga = GetYoga(node);

  // Force setting flex shrink to 0 on all children of nodes with YGOverflowScroll. This preserves
  // backwards compatibility with Yoga1, but we should consider a breaking change going forward to
  // remove this, as it's not great to meddle with flex properties arbitrarily.
  // TODO(b/134073740): [Yoga2 Launch] Re-consider this.
  YGTraversePreOrder(yoga, [](YGNodeRef yoga) {
    if (YGNodeStyleGetOverflow(yoga) == YGOverflowScroll) {
      for (uint32_t i = 0, iMax = YGNodeGetChildCount(yoga); i < iMax; ++i) {
        YGNodeRef yoga_child = YGNodeGetChild(yoga, i);
        YGNodeStyleSetFlexShrink(yoga_child, 0);
      }
    }
  });

  // Do the calculation.
  YGNodeCalculateLayout(yoga, YogaConstraintFromCG(maxSize.width),
                        YogaConstraintFromCG(maxSize.height), YGDirectionInherit);
  node->_yogaCalculatedLayoutMaxSize = maxSize;

  [node didCalculateLayout:sizeRange];
  // Log and return result.
#if ASEnableVerboseLogging
  const CGSize result = CGSizeOfYogaLayout(yoga);
  as_log_verbose(ASLayoutLog(), "finish layout calculation %ld with %@", request_id,
                 NSStringFromCGSize(result));
#endif
}

/// Collect all flattened children for given node
static void CollectChildrenRecursively(unowned NSMutableArray *children, ASDisplayNode *node) {
  if (ASActivateExperimentalFeature(ASExperimentalUnifiedYogaTree)) {
    VisitChildren(node, [&](unowned ASDisplayNode *subnode, int index){
      if (subnode.isFlattenable) {
        CollectChildrenRecursively(children, subnode);
      } else {
        [children addObject:subnode];
      }
    });
    return;
  }

  for (ASDisplayNode *subnode in node->_yogaChildren) {
    if (subnode.isFlattenable) {
      CollectChildrenRecursively(children, subnode);
    } else {
      [children addObject:subnode];
    }
  }
}

void ApplyLayoutForCurrentBoundsIfRoot(ASDisplayNode *node) {
  AssertEnabled(node);
  ASDisplayNodeCAssertThreadAffinity(node);
  DISABLED_ASAssertLocked(node->__instanceLock__);
  YGNodeRef yoga_root = GetYoga(node);

  // We always update the entire tree from root and push all invalidations to the top. Nodes that do
  // not have a different layout will be ignored using their `YGNodeGetHasNewLayout` flag.
  if (!IsRoot(yoga_root)) {
    return;
  }

  // In some cases, a descendent view will call layoutIfNeeded during a layout application.
  // This will escalate up to the root and we re-enter here. If this happens, we do not want to
  // interrupt our layout so we instead take note and perform another layout pass immediately after
  // finishing the current one.
  if (node->_flags.yogaIsApplyingLayout) {
    node->_flags.yogaRequestedNestedLayout = 1;
    return;
  }
  node->_flags.yogaIsApplyingLayout = 1;
  Cleanup layout_flag_cleanup([&] { node->_flags.yogaIsApplyingLayout = 0; });

  // Note: We used to short-circuit here when the Yoga root had no children. However, we need to
  // ensure that calculatedLayoutDidChange is called, so we need to pass through. The Yoga
  // calculation should be cached, so it should be a cheap operation.

#if ASEnableVerboseLogging
  static std::atomic<long> counter(1);
  const long layout_id = counter.fetch_add(1);
  as_log_verbose(ASLayoutLog(), "enter layout apply %ld for %@", layout_id,
                 ASObjectDescriptionMakeTiny(node));
#endif

  // Determine a compatible size range to measure with. Yoga can create slightly different layouts
  // if we re-measure with a different constraint than previously (even if it matches the resulting
  // size of the previous measurement, due to rounding errors!), so avoid remeasuring if the
  // caller is clearly just trying to apply the previous measurement.


  CGSize sizeForLayout = node.bounds.size;
  if (CGSizeEqualToSize(sizeForLayout, GetCalculatedSize(node))) {
    sizeForLayout = node->_yogaCalculatedLayoutMaxSize;
  }

  // Calculate layout for our bounds. If this size is compatible with a previous calculation
  // then the measurement cache will kick in.
  CalculateLayoutAtRoot(node, sizeForLayout);

  const bool tree_loaded = _loaded(node);

  // Traverse down the yoga tree, cleaning each node.
  YGTraversePreOrder(yoga_root, [&yoga_root, tree_loaded](YGNodeRef yoga) {
    unowned ASDisplayNode *node = GetTexture(yoga);

    bool use_layout_flattening = node->_flags.viewFlattening;

    if (!YGNodeGetHasNewLayout(yoga) &&
        // We can only short circuit if the node is flattenable. Otherwise the child
        // frame could have changed and need to be adjusted
        (!use_layout_flattening || (use_layout_flattening && node.isFlattenable))) {
      if (YGNodeStyleGetOverflow(yoga) == YGOverflowScroll) {
        // If a node has YGOverflowScroll, then always call calculatedLayoutDidChange so it can
        // respond to any changes in the layout of its children.
        [node calculatedLayoutDidChange];
      }
      return;
    }
    YGNodeSetHasNewLayout(yoga, false);

    if (DISPATCH_EXPECT(node == nil, 0)) {
      ASDisplayNodeCFailAssert(@"No texture node.");
      return;
    }

    // If the node is a layoutContainer and therefore will not appear in the view hierarchy
    // continue without any flattening process, but only if it's not the root node.
    if (use_layout_flattening && node.isFlattenable && yoga != yoga_root) {
      // We can short-circuit here, because if this node is flattened, it means that all of its
      // Yoga children have already been added to one of this node's ancestors.

      // We will clear the subnodes for nodes that gonna be flattened due to cases like:
      // - A container node exists that was previously *not* flattenable and has subnodes
      // - In an update it goes from *not* flattenable to flattenable and the _yogaChildren
      // are changing due to the update. This container still existing subnodes that are not the
      // same which will not be the same as it's `_yogaChildren` though, therefore it will still
      // have subnodes although it's flattened away.
      // - Subnodes that will eventually move to other nodes will be retained due to the Yoga tree
      // Go in reverse order so we don't shift our indexes.
      NSInteger count = node->_subnodes.count;
      for (NSInteger i = count-1; i >= 0; --i) {
        [node->_subnodes[i] removeFromSupernode];
      }
      return;
    }

    // Lock this node. Note we are already locked at root so if we ever get to the point where trees
    // share one lock, this line can go away.
    MutexLocker l(node->__instanceLock__);

    // Set node frame unless we ARE root. Root already has its frame.
    if (yoga != yoga_root) {
      CGRect newFrame = CGRectOfYogaLayout(yoga);
      as_log_verbose(ASLayoutLog(), "layout: %@ %@ -> %@", ASObjectDescriptionMakeTiny(node),
                     NSStringFromCGRect(node.frame), NSStringFromCGRect(newFrame));

      // Adjust the node's frame if view flattening is happening
      if (use_layout_flattening) {
        // Walk up the tree until the first non container node and from there add
        // all origins to get the adjustment we need for this node's frame.
        // At this point all of the frames of the supernodes should be set

        // Go up to first non container node and collect all the layout offset adjustments
        CGPoint layoutOffset = CGPointZero;
        YGNodeRef firstNonContainerNode = YGNodeGetOwner(yoga);
        while (GetTexture(firstNonContainerNode).isFlattenable && firstNonContainerNode != yoga_root) {
          CGPoint parentOrigin = CGRectOfYogaLayout(firstNonContainerNode).origin;
          layoutOffset = ASPointAddPoint(layoutOffset, parentOrigin);
          firstNonContainerNode = YGNodeGetOwner(firstNonContainerNode);
        }

        NSCAssert(firstNonContainerNode, @"At least one non container node need to exist in tree.");

        // Adjust the frame for the node to the node that is not flattened via the layoutOffset
        newFrame.origin = ASPointAddPoint(newFrame.origin, layoutOffset);
      }

      // Set the new Frame
      node.frame = newFrame;
    }

    // Collect the new subnodes. Apply flattening if enabled, or just the yoga children.
    NSArray<ASDisplayNode *> *newSubnodes;
    if (use_layout_flattening || ASActivateExperimentalFeature(ASExperimentalUnifiedYogaTree)) {
      // In the flattening or unified-tree case, we reuse a temporary non-owning buffer.
      // In the legacy case, we already have an NSArray we can use.
      static dispatch_once_t onceToken;
      static pthread_key_t threadKey;
      dispatch_once(&onceToken, ^{
        ASInitializeTemporaryObjectStorage(&threadKey);
      });
      NSMutableArray<ASDisplayNode *> *mNewSubnodes;
      if (ASActivateExperimentalFeature(ASExperimentalUseNonThreadLocalArrayWhenApplyingLayout)) {
        mNewSubnodes = ASCreateNonOwningMutableArray();
      } else {
        mNewSubnodes = (__bridge id)ASGetTemporaryNonowningMutableArray(threadKey);
      }
      if (use_layout_flattening) {
        CollectChildrenRecursively(mNewSubnodes, node);
      } else {
        VisitChildren(node, [&](unowned ASDisplayNode *node, int index) {
          [mNewSubnodes addObject:node];
        });
      }
      newSubnodes = mNewSubnodes;
    } else {
      newSubnodes = node->_yogaChildren;
    }

    // Cancel disappearing of any of the now-present subnodes.
    for (ASDisplayNode *yogaChild in newSubnodes) {
      if (yogaChild.isDisappearing) {
        [yogaChild.layer removeAllAnimations];
      }
      yogaChild.isDisappearing = NO;
    }

    // Update the node tree to match the new subnodes.
    if (!ASObjectIsEqual(node->_subnodes, newSubnodes)) {
      // NOTE: Calculate the diff only if subnodes is non-empty. Otherwise insert
      // (0, newSubnodeCount).
      NSUInteger newSubnodeCount = newSubnodes.count;
      IGListIndexSetResult *diff;
      if (node->_subnodes.count > 0) {
        diff = IGListDiff(node->_subnodes, newSubnodes, IGListDiffPointerPersonality);
      }

      // Log the diff.
      as_log_verbose(ASLayoutLog(), "layout: %@ updating children",
                     ASObjectDescriptionMakeTiny(node));

      // Apply the diff.

      // If we have moves, we need to apply them at the end but use the original indexes for
      // move-from. It would be great to do this in-place but correctness comes first. See
      // discussion at https://github.com/Instagram/IGListKit/issues/1006 We use unowned here
      // because ownership is established by the _real_ subnodes array, and this is quite a
      // performance-sensitive code path. Note also, we could opt to create a vector of ONLY the
      // moved subnodes, but I bet this approach is faster since it's just a memcpy rather than
      // repeated objectAtIndex: calls with all their retain/release traffic.
      std::vector<unowned ASDisplayNode *> oldSubnodesForMove;
      if (diff.moves.count) {
        oldSubnodesForMove.resize(node->_subnodes.count);
        [node->_subnodes getObjects:oldSubnodesForMove.data()
                              range:NSMakeRange(0, node->_subnodes.count)];
      }

      // deferredRemovalFixups maintains a mapping for _subnodes insertion index. Because we
      // sometimes defer subnode removal, while the indices returned from IGListDiff assume that
      // we have actually removed the nodes, we need to maintain this fixup table. The fixup entry
      // in the array is added to the IGListDiff index to map to the actual index needed. To avoid
      // this somewhat-expensive operation when it's unnecessary, we keep a flag to indicate whether
      // any subnodes have their removal deferred and don't allocate the vector contents until
      // we know it will be used.
      std::vector<NSInteger> deferredRemovalFixups;
      BOOL needToFixupIndices = NO;
      NSUInteger numSubnodes = node->_subnodes.count;

      // Deletes descending so we don't invalidate our own indexes.
      NSIndexSet *deletes = diff.deletes;
      for (NSInteger i = deletes.lastIndex; deletes != nil && i != NSNotFound;
           i = [deletes indexLessThanIndex:i]) {
        as_log_verbose(ASLayoutLog(), "removing %@",
                       ASObjectDescriptionMakeTiny(node->_subnodes[i]));
        // If tree isn't loaded, we never do deferred removal. Remove now.
        if (!tree_loaded) {
          [node->_subnodes[i] removeFromSupernode];
          continue;
        }

        if (node->_subnodes[i].isDisappearing) {
          // Do not try to disappear a node more than once as it could interfere with the
          // animation and cause the node removal to be called twice.
          needToFixupIndices = YES;
          deferredRemovalFixups.resize(numSubnodes + 1);
          for (NSInteger j = i + 1; j < deferredRemovalFixups.size(); j++) {
            deferredRemovalFixups[j]++;
          }
          continue;
        }
        node->_subnodes[i].isDisappearing = YES;

        // If it is loaded, ask if any node in the subtree wants to defer.
        // Unfortunately unconditionally deferring causes unexpected behavior for e.g. unit tests
        // that depend on the tree reflecting its new state immediately by default.
        [CATransaction begin];
        __block BOOL shouldDefer = NO;
        ASDisplayNodePerformBlockOnEveryNode(
            nil, node->_subnodes[i], NO, ^(ASDisplayNode *blockNode) {
              NSDictionary<NSString *, id<CAAction>> *actions = blockNode.disappearanceActions;
              if (![actions count]) return;
              if (!shouldDefer) {
                // We must set the completion block before doing any animations.
                ASDisplayNode *subnode = node->_subnodes[i];
                [CATransaction setCompletionBlock:^{
                  // The disappearance may have been cancelled if the node was re-added while
                  // being disappeared.
                  if (subnode.isDisappearing) {
                    [subnode removeFromSupernode];
                  }
                }];
              }
              shouldDefer = YES;

              for (NSString *key in actions) {
                id<CAAction> action = actions[key];
                [action runActionForKey:key object:blockNode.layer arguments:nil];
              }
            });
        if (shouldDefer) {
          needToFixupIndices = YES;
          deferredRemovalFixups.resize(numSubnodes + 1);
          for (NSInteger j = i + 1; j < deferredRemovalFixups.size(); j++) {
            deferredRemovalFixups[j]++;
          }
        } else {
          [node->_subnodes[i] removeFromSupernode];
        }
        [CATransaction commit];
      }

      // Inserts. Note we need to handle the case where diff is nil, which means we skipped the diff
      // and just insert (0, newSubnodeCount).
      NSIndexSet *inserts = diff.inserts;
      for (NSInteger i = inserts ? inserts.firstIndex : 0;
           inserts ? i != NSNotFound : i < newSubnodeCount;
           inserts ? i = [inserts indexGreaterThanIndex:i] : ++i) {
        NSInteger fixedUpIndex = i;
        if (needToFixupIndices) {
          fixedUpIndex = i + deferredRemovalFixups[i];
          // Fixup the fixups to account for the new inserted item.
          deferredRemovalFixups.insert(deferredRemovalFixups.begin() + i, deferredRemovalFixups[i]);
        }
        as_log_verbose(ASLayoutLog(), "inserting %@ at %ld",
                       ASObjectDescriptionMakeTiny(newSubnodes[i]), (long)fixedUpIndex);
        [node insertSubnode:newSubnodes[i] atIndex:fixedUpIndex];
      }

      // Moves. Manipulate the arrays directly to avoid extra traffic.
      for (IGListMoveIndex *idx in diff.moves) {
        auto &subnode = oldSubnodesForMove[idx.from];
        as_log_verbose(ASLayoutLog(), "moving %@ to %ld", ASObjectDescriptionMakeTiny(subnode),
                       (long)idx.to);
        MutexLocker l(subnode->__instanceLock__);
        if (needToFixupIndices) {
          NSInteger fromIndex = [node->_subnodes indexOfObjectIdenticalTo:subnode];
          deferredRemovalFixups.erase(deferredRemovalFixups.begin() + fromIndex);
        }
        [node->_subnodes removeObjectIdenticalTo:subnode];
        NSInteger fixedUpIndex = idx.to;
        if (needToFixupIndices) {
          fixedUpIndex = idx.to + deferredRemovalFixups[idx.to];
          deferredRemovalFixups.insert(deferredRemovalFixups.begin() + idx.to, deferredRemovalFixups[idx.to]);
        }
        [node->_subnodes insertObject:subnode atIndex:fixedUpIndex];
        // If tree is loaded and subnode isn't rasterized, update view or layer array.
        if (tree_loaded && !ASHierarchyStateIncludesRasterized(subnode->_hierarchyState)) {
          if (subnode->_flags.layerBacked) {
            [node->_layer insertSublayer:subnode->_layer atIndex:(unsigned int)fixedUpIndex];
          } else {
            [node->_view insertSubview:subnode->_view atIndex:fixedUpIndex];
          }
        }
      }

      // Invalidate accessibility if needed due to tree change.
      [node invalidateFirstAccessibilityContainerOrNonLayerBackedNode];
    }
  });

  // Traverse again, calling calculatedLayoutDidChange. This is done after updating frames
  // so that higher nodes have an accurate picture of lower nodes' current frames.
  // Note: "calculated" here really means "applied" – misnomer.
  YGTraversePreOrder(yoga_root, [](YGNodeRef yoga) {
    [GetTexture(yoga) calculatedLayoutDidChange];
  });

  // Reset the flag and repeat if needed.
  layout_flag_cleanup.release()();
  if (node->_flags.yogaRequestedNestedLayout) {
    node->_flags.yogaRequestedNestedLayout = 0;
    ApplyLayoutForCurrentBoundsIfRoot(node);
  }
}

void HandleExplicitLayoutIfNeeded(ASDisplayNode *node) {
  ASDisplayNodeCAssertThreadAffinity(node);
  if (_loaded(node)) {
    // We are loaded. Just call this on the layer. It will escalate to the highest dirty layer and
    // update downward. Since we're on main, we can access the layer without lock.
    [node->_layer layoutIfNeeded];
    return;
  }

  // We are not loaded. Our yoga root actually might be loaded and in hierarchy though!
  // Lock to root, and repeat the call on the yoga root.
  LockSet locks = [node lockToRootIfNeededForLayout];
  YGNodeRef yoga_self = GetYoga(node);
  YGNodeRef yoga_root = GetRoot(yoga_self);
  // Unfortunately we have to unlock here, or else we trigger an assertion when we call out to the
  // subclasses during layout.
  locks.clear();
  if (yoga_self != yoga_root) {
    // Go back through the layoutIfNeeded code path in case the root node is loaded when we aren't.
    ASDisplayNode *rootNode = GetTexture(yoga_root);
    [rootNode layoutIfNeeded];
  } else {
    // OK we are: yoga root, not loaded.
    // That means all we need to do is call __layout and we will apply layout based on current
    // bounds.
    [node __layout];
  }
}

CGSize GetCalculatedSize(ASDisplayNode *node) {
  AssertEnabled(node);
  DISABLED_ASAssertLocked(GetTexture(GetRoot(GetYoga(node)))->__instanceLock__);
  
  return CGSizeOfYogaLayout(GetYoga(node));
}

ASLayout *GetCalculatedLayout(ASDisplayNode *node, ASSizeRange sizeRange) {
  AssertEnabled(node);
  DISABLED_ASAssertLocked(GetTexture(GetRoot(GetYoga(node)))->__instanceLock__);

  return ASLayoutCreateFromYogaNodeLayout(GetYoga(node), sizeRange);
}

CGRect GetChildrenRect(ASDisplayNode *node) {
  AssertEnabled(node);
  DISABLED_ASAssertLocked(GetTexture(GetRoot(GetYoga(node)))->__instanceLock__);

  CGRect childrenRect = CGRectZero;
  YGNodeRef yoga_self = GetYoga(node);
  for (uint32_t i = 0, iMax = YGNodeGetChildCount(yoga_self); i < iMax; ++i) {
    YGNodeRef yoga_child = YGNodeGetChild(yoga_self, i);
    CGRect frame = CGRectOfYogaLayout(yoga_child);
    childrenRect = CGRectUnion(childrenRect, frame);
  }

  return childrenRect;
}

void InsertChild(ASDisplayNode *node, ASDisplayNode *child, int index) {
  ASCAssertExperiment(ASExperimentalUnifiedYogaTree);
  if (AS_PREDICT_FALSE(!child || !node)) return;
  LockSet locks = [node lockToRootIfNeededForLayout];
  ASDisplayNodeCAssert([node nodeContext] == [child nodeContext],
                      @"Cannot add yoga child from different node context.");
  YGNodeRef yoga = GetYoga(node);
  YGNodeRef yogaChild = GetYoga(child);
  int childCount = YGNodeGetChildCount(yoga);
  if (index > childCount) {
    ASDisplayNodeCFailAssert(@"Index out of bounds! %d vs. %d", childCount, (int)index);
    index = childCount;
  } else if (index == -1) {
    index = childCount;
  }
  YGNodeRef oldOwner = YGNodeGetOwner(yogaChild);
  if (oldOwner) {
    // Was in tree before. Remove child but "steal" +1 i.e. do not release.
    YGNodeRemoveChild(oldOwner, yogaChild);
  } else {
    // Was not in a tree before. Retain now.
    CFRetain((CFTypeRef)child);
  }

  YGNodeInsertChild(yoga, yogaChild, index);
  child->_yogaParent = node;
}

void RemoveChild(ASDisplayNode *node, ASDisplayNode *child) {
  ASCAssertExperiment(ASExperimentalUnifiedYogaTree);
  if (AS_PREDICT_FALSE(!node || !child)) return;
  LockSet locks = [node lockToRootIfNeededForLayout];
  YGNodeRef yoga = GetYoga(node);
  YGNodeRef childYoga = GetYoga(child);
  YGNodeRemoveChild(yoga, childYoga);
  child->_yogaParent = nil;
  CFRelease((CFTypeRef)child);
}

void SetChildren(ASDisplayNode *node, NSArray<ASDisplayNode *> *children) {
  ASCAssertExperiment(ASExperimentalUnifiedYogaTree);
  if (AS_PREDICT_FALSE(!node)) return;
  LockSet locks = [node lockToRootIfNeededForLayout];
  YGNodeRef yoga = GetYoga(node);
  int newCount = children.count;
  int oldCount = YGNodeGetChildCount(yoga);

  // Fast paths for some special cases.
  if (newCount == 0) {
    if (oldCount == 0) return;
    for (int i = 0; i < oldCount; ++i) {
      unowned ASDisplayNode *node = GetTexture(YGNodeGetChild(yoga, i));
      node->_yogaParent = nil;
      CFRelease((CFTypeRef)node);
    }
    YGNodeRemoveAllChildren(yoga);
    return;
  }

  // Go through new children putting them in a vector, and updating the parent if they aren't
  // already.
  std::vector<YGNodeRef> rawYogaChildren;
  rawYogaChildren.reserve(newCount);
  for (ASDisplayNode *child in children) {
    YGNodeRef childYoga = GetYoga(child);
    rawYogaChildren.emplace_back(childYoga);
    if (!YGNodeGetOwner(childYoga)) {
      // Not previously in a tree. Retain.
      CFRetain((CFTypeRef)child);
    }
    // Update parent pointer.
    child->_yogaParent = node;
  }

  // Go through old children, clearing parent & releasing for any that aren't also in the new
  // children.
  for (int i = 0; i < oldCount; ++i) {
    YGNodeRef childYoga = YGNodeGetChild(yoga, i);
    auto it = std::find(rawYogaChildren.begin(), rawYogaChildren.end(), childYoga);
    // If child is being removed, clear its pointer and release it.
    if (it == rawYogaChildren.end()) {
      unowned ASDisplayNode *node = GetTexture(childYoga);
      node->_yogaParent = nil;
      CFRelease((CFTypeRef)node);
    }
  }

  // Actually update the yoga tree.
  YGNodeSetChildren(yoga, rawYogaChildren);
}

void TearDown(AS_NORETAIN_ALWAYS ASDisplayNode *node) {
  ASCAssertExperiment(ASExperimentalUnifiedYogaTree);
  if (AS_PREDICT_FALSE(!node)) return;
  MutexLocker lock(node->__instanceLock__);
  YGNodeRef yoga = GetYoga(node);
  uint32_t count = YGNodeGetChildCount(yoga);
  for (uint32_t i = 0; i < count; ++i) {
    YGNodeRef childYoga = YGNodeGetChild(yoga, i);
    if (unowned ASDisplayNode *child = GetTexture(childYoga)) {
      child->_yogaParent = nil;
      CFRelease((CFTypeRef)child);
    }
  }
  // No need to call YGNodeRemoveAllChildren, that will come from YGNodeFree which is
  // run by the style.
}

NSArray<ASDisplayNode *> *CopyChildren(ASDisplayNode *node) {
  ASCAssertExperiment(ASExperimentalUnifiedYogaTree);
  if (AS_PREDICT_FALSE(!node)) return @[];
  MutexLocker lock(node->__instanceLock__);
  YGNodeRef yoga = GetYoga(node);
  uint32_t count = YGNodeGetChildCount(yoga);
  std::vector<ASDisplayNode *> rawChildren;
  rawChildren.reserve(count);
  VisitChildren(node, [&](unowned ASDisplayNode *node, int _) { rawChildren.emplace_back(node); });
  return [NSArray arrayByTransferring:rawChildren.data() count:rawChildren.size()];
}

void VisitChildren(ASDisplayNode *node,
                   const std::function<void(unowned ASDisplayNode *, int)> &f) {
  ASCAssertExperiment(ASExperimentalUnifiedYogaTree);
  if (AS_PREDICT_FALSE(!node)) return;
  MutexLocker lock(node->__instanceLock__);
  YGNodeRef yoga = GetYoga(node);
  uint32_t count = YGNodeGetChildCount(yoga);
  for (uint32_t i = 0; i < count; ++i) {
    YGNodeRef childYoga = YGNodeGetChild(yoga, i);
    if (unowned ASDisplayNode *child = GetTexture(childYoga)) {
      f(child, i);
    }
  }
}

int MeasuredNodesForThread() {
  return measuredNodes;
}

#else  // !YOGA

namespace AS {
namespace Yoga2 {

void AlertNeedYoga() {
  ASDisplayNodeCFailAssert(@"Yoga experiment is enabled but we were compiled without yoga!");
}

void CalculateLayoutAtRoot(ASDisplayNode *node, CGSize maxSize) {
  AssertEnabled();
  AlertNeedYoga();
}

void HandleExplicitLayoutIfNeeded(ASDisplayNode *node) {
  AssertEnabled();
  AlertNeedYoga();
}

bool GetEnabled(ASDisplayNode *node) { return false; }
void Enable(ASDisplayNode *node) {
  AssertEnabled();
  AlertNeedYoga();
}
void MarkContentMeasurementDirty(ASDisplayNode *node) {
  AssertEnabled();
  AlertNeedYoga();
}
CGSize SizeThatFits(ASDisplayNode *node, CGSize maxSize) {
  AssertEnabled();
  AlertNeedYoga();
  return CGSizeZero;
}
void ApplyLayoutForCurrentBoundsIfRoot(ASDisplayNode *node) {
  AssertEnabled();
  AlertNeedYoga();
}
CGSize GetCalculatedSize(ASDisplayNode *node) {
  AssertEnabled();
  AlertNeedYoga();
  return CGSizeZero;
}
ASLayout *GetCalculatedLayout(ASDisplayNode *node, ASSizeRange sizeRange) {
  AssertEnabled();
  AlertNeedYoga();
  return nil;
}
CGRect GetChildrenRect(ASDisplayNode *node) {
  AssertEnabled();
  AlertNeedYoga();
  return CGRectZero;
}
int MeasuredNodesForThread() {
  AssertEnabled();
  AlertNeedYoga();
  return 0;
}
#endif  // YOGA

}  // namespace Yoga2
}  // namespace AS

AS_ASSUME_NORETAIN_END
