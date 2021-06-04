//
//  ASDisplayNode+Yoga2.h
//  AsyncDisplayKit
//
//  Created by Adlai Holler on 3/8/19.
//  Copyright © 2019 Pinterest. All rights reserved.
//

#if defined(__cplusplus)

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import <AsyncDisplayKit/ASAvailability.h>
#import <UIKit/UIKit.h>

#if YOGA
#import YOGA_HEADER_PATH
#endif

NS_ASSUME_NONNULL_BEGIN
AS_ASSUME_NORETAIN_BEGIN

namespace AS {
namespace Yoga2 {

/**
 * Returns whether Yoga2 is enabled for this node.
 */
bool GetEnabled(ASDisplayNode *node);

inline void AssertEnabled() {
  ASDisplayNodeCAssert(false, @"Expected Yoga2 to be enabled.");
}

inline void AssertEnabled(ASDisplayNode *node) {
  ASDisplayNodeCAssert(GetEnabled(node), @"Expected Yoga2 to be enabled.");
}

inline void AssertDisabled(ASDisplayNode *node) {
  ASDisplayNodeCAssert(!GetEnabled(node), @"Expected Yoga2 to be disabled.");
}

/**
 * Enable Yoga2 for this node. This should be done only once, and before any layout calculations
 * have occurred.
 */
void Enable(ASDisplayNode *node);

/**
 * Update or clear measure function according to @c -[ASDisplayNode shouldSuppressMeasureFunction].
 * This should be called with lock held.
 */
void UpdateMeasureFunction(ASDisplayNode *texture);

/**
 * Enable using style yoga node globally for all nodes if Yoga2 is enabled.
 * This is a global flag and should be set within initialization.
 */
void SetEnableStyleYogaNode(bool enable);

/**
 * Asserts unlocked. Locks to root.
 * Marks the node dirty if it has a custom measure function (e.g. text node). Otherwise does
 * nothing.
 */
void MarkContentMeasurementDirty(ASDisplayNode *node);

/**
 * Asserts root. Asserts locked.
 * This is analogous to -sizeThatFits:.
 * Subsequent calls to GetCalculatedSize and GetCalculatedLayout will return values based on this.
 */
void CalculateLayoutAtRoot(ASDisplayNode *node, CGSize maxSize);

/**
 * Asserts locked. Asserts thread affinity.
 * Update layout for all nodes in tree from yoga root based on its bounds.
 * This is analogous to -layoutSublayers. If not root, does nothing.
 */
void ApplyLayoutForCurrentBoundsIfRoot(ASDisplayNode *node);

/**
 * Handle a call to -layoutIfNeeded. Asserts thread affinity. Other cases should be handled by
 * pending state.
 *
 * Note: this method _also_ asserts thread affinity for the root yoga node. There are cases where
 * people call -layoutIfNeeded on an unloaded node that has a yoga ancestor that is in hierarchy
 * i.e. the receiver node is pending addition to the layer tree. This is legal only on main.
 */
void HandleExplicitLayoutIfNeeded(ASDisplayNode *node);

/**
 * The size of the most recently calculated layout. Asserts root, locked.
 * Returns CGSizeZero if never measured.
 */
CGSize GetCalculatedSize(ASDisplayNode *node);

/**
 * Returns the most recently calculated layout. Asserts root, locked.
 * The size of the returning ASLayout will take in the consideration of the
 * ASSizeRange passed in. If ASSizeRangeZero is passed in no clamping will happen.
 * Note: The layout will be returned even if the tree is dirty.
 */
ASLayout *_Nullable GetCalculatedLayout(ASDisplayNode *node, ASSizeRange sizeRange);

/**
 * Returns a CGRect corresponding to the position and size of the node's children. This is safe to
 * call even during layout or from calculatedLayoutDidChange.
 */
CGRect GetChildrenRect(ASDisplayNode *node);

/** Return the number of times external measurement methods have been called by Yoga since the last
 * root layout began. **/
int MeasuredNodesForThread();

/// This section for functions only available when yoga is linked.
#if YOGA

/**
 * Insert the display node into the yoga tree at the given position.
 * @precondition index <= parent.childCount
 * @precondition Parent and child are in the same node context.
 * If child has a different parent it will be removed.
 * Pass -1 as index to indicate you want to append child.
 */
void InsertChild(ASDisplayNode *node, ASDisplayNode *child, int index);

/**
 * Remove the display node from the yoga tree.
 */
void RemoveChild(ASDisplayNode *node, ASDisplayNode *child);

/**
 * Update the yoga children of the given display node.
 */
void SetChildren(ASDisplayNode *node, NSArray<ASDisplayNode *> *children);

/**
 * Call from dealloc.
 */
void TearDown(AS_NORETAIN_ALWAYS ASDisplayNode *node);

/**
 * Copy the child array, translated into Texture nodes.
 */
NSArray<ASDisplayNode *> *CopyChildren(ASDisplayNode *node);

/**
 * Visit the yoga children using a std::function.
 */
void VisitChildren(ASDisplayNode *node,
                   const std::function<void(unowned ASDisplayNode *, int)> &visitor);

/**
 * Get the display node corresponding to the given yoga node.
 * Macros are ugly but you simply can't return ObjC objects without retain/release under ARC. Even a
 * function that is inlined by the compiler will still cause retain/release.
 */
#define GetTexture(yoga) ((__bridge ASDisplayNode *)GetTextureCF(yoga))

/** Get display node without ARC traffic. */
CFTypeRef GetTextureCF(YGNodeRef yoga);
#endif

}  // namespace Yoga2
}  // namespace AS

AS_ASSUME_NORETAIN_END
NS_ASSUME_NONNULL_END

#endif  // defined(__cplusplus)
