//
//  ASDisplayNode+Yoga.h
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASAvailability.h"

#if YOGA

NS_ASSUME_NONNULL_BEGIN

@class ASLayout;

ASDK_EXTERN void ASDisplayNodePerformBlockOnEveryYogaChild(ASDisplayNode * _Nullable node, void(^block)(ASDisplayNode *node));

@interface ASDisplayNode (Yoga)

@property (copy) NSArray *yogaChildren;

- (void)addYogaChild:(ASDisplayNode *)child;
- (void)removeYogaChild:(ASDisplayNode *)child;
- (void)insertYogaChild:(ASDisplayNode *)child atIndex:(NSUInteger)index;

- (void)semanticContentAttributeDidChange:(UISemanticContentAttribute)attribute;

@property BOOL yogaLayoutInProgress;
// TODO: Make this atomic (lock).
@property (nullable, nonatomic) ASLayout *yogaCalculatedLayout;
@property (nonatomic) BOOL willApplyNextYogaCalculatedLayout;

// Will walk up the Yoga tree and returns the root node
- (ASDisplayNode *)yogaRoot;


@end

@interface ASDisplayNode (YogaLocking)
/**
 * @discussion Attempts(spinning) to lock all node up to root node when yoga is enabled.
 * This will lock self when yoga is not enabled;
 */
- (ASLockSet)lockToRootIfNeededForLayout;

@end


// These methods are intended to be used internally to Texture, and should not be called directly.
@interface ASDisplayNode (YogaInternal)

/// For internal usage only
- (BOOL)shouldHaveYogaMeasureFunc;
/// For internal usage only
- (ASLayout *)calculateLayoutYoga:(ASSizeRange)constrainedSize;
/// For internal usage only
- (void)calculateLayoutFromYogaRoot:(ASSizeRange)rootConstrainedSize willApply:(BOOL)willApply;
/// For internal usage only
- (void)invalidateCalculatedYogaLayout;
/**
 * @discussion return true only when yoga enabled and the node is in yoga tree and the node is
 * not leaf that implemented measure function.
 */
- (BOOL)locked_shouldLayoutFromYogaRoot;

@end

@interface ASDisplayNode (YogaDebugging)

- (NSString *)yogaTreeDescription;

@end

@interface ASLayoutElementStyle (Yoga)

- (YGNodeRef)yogaNodeCreateIfNeeded;
- (void)destroyYogaNode;

@property (readonly) YGNodeRef yogaNode;

@property ASStackLayoutDirection flexDirection;
@property YGDirection direction;
@property ASStackLayoutJustifyContent justifyContent;
@property ASStackLayoutAlignItems alignItems;
@property YGPositionType positionType;
@property ASEdgeInsets position;
@property ASEdgeInsets margin;
@property ASEdgeInsets padding;
@property ASEdgeInsets border;
@property CGFloat aspectRatio;
@property YGWrap flexWrap;

@end

NS_ASSUME_NONNULL_END

// When Yoga is enabled, there are several points where we want to lock the tree to the root but otherwise (without Yoga)
// will want to simply lock self.
#define ASScopedLockSelfOrToRoot() ASScopedLockSet lockSet = [self lockToRootIfNeededForLayout]
#else
#define ASScopedLockSelfOrToRoot() ASLockScopeSelf()
#endif
