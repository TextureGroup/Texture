//
//  ASDisplayNode+Yoga.h
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>

#import <AsyncDisplayKit/ASDisplayNode.h>
#import <AsyncDisplayKit/ASAvailability.h>

#if YOGA

NS_ASSUME_NONNULL_BEGIN

@interface ASDisplayNode (Yoga)

@property(copy) NSArray<ASDisplayNode *> *yogaChildren;
@property(readonly, weak) ASDisplayNode *yogaParent;

// This is class method for the ease of testing rtl behaviors.
+ (BOOL)isRTLForNode:(ASDisplayNode *)node;

- (void)addYogaChild:(ASDisplayNode *)child;
- (void)removeYogaChild:(ASDisplayNode *)child;
- (void)insertYogaChild:(ASDisplayNode *)child atIndex:(NSUInteger)index;

- (void)semanticContentAttributeDidChange:(UISemanticContentAttribute)attribute;
- (UIUserInterfaceLayoutDirection)yogaLayoutDirection;

// If set, Yoga will not perform custom measurement on this node even if it overrides @c
// calculateSizeThatFits:.
@property(nonatomic) BOOL shouldSuppressYogaCustomMeasure;

// Will walk up the Yoga tree and returns the root node
- (ASDisplayNode *)yogaRoot;

@end

#ifdef __cplusplus
@interface ASDisplayNode (YogaLocking)

/**
 * @discussion Attempts (yielding on failure) to lock all nodes up to root node when yoga is
 * enabled. This will lock self when yoga is not enabled. Returns whether the locking into the given
 * LockSet was successful i.e. you can use this inside your while loop for multi-locking.
 */
- (BOOL)lockToRootIfNeededForLayout:(AS::LockSet *)locks;

/**
 * Same as above, but returns a new lock set instead of using one that you provide. Prefer the
 * above method in new code.
 */
- (AS::LockSet)lockToRootIfNeededForLayout;

@end
#endif

@interface ASDisplayNode (YogaDebugging)

- (NSString *)yogaTreeDescription;

@end

@interface ASLayoutElementStyle (Yoga)

@property(readonly) YGNodeRef yogaNode;

@property ASStackLayoutDirection flexDirection;
@property YGDirection direction;
@property ASStackLayoutJustifyContent justifyContent;
@property ASStackLayoutAlignItems alignItems;
@property ASStackLayoutAlignItems alignContent;
@property YGPositionType positionType;
@property ASEdgeInsets position;
@property ASEdgeInsets margin;
@property ASEdgeInsets padding;
@property ASEdgeInsets border;
@property CGFloat aspectRatio;
@property YGWrap flexWrap;

@end

NS_ASSUME_NONNULL_END

#endif
