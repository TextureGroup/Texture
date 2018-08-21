//
//  _ASTransitionContext.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>

#import <AsyncDisplayKit/ASContextTransitioning.h>

@class ASLayout;
@class _ASTransitionContext;

@protocol _ASTransitionContextLayoutDelegate <NSObject>

- (NSArray<ASDisplayNode *> *)currentSubnodesWithTransitionContext:(_ASTransitionContext *)context;

- (NSArray<ASDisplayNode *> *)insertedSubnodesWithTransitionContext:(_ASTransitionContext *)context;
- (NSArray<ASDisplayNode *> *)removedSubnodesWithTransitionContext:(_ASTransitionContext *)context;

- (ASLayout *)transitionContext:(_ASTransitionContext *)context layoutForKey:(NSString *)key;
- (ASSizeRange)transitionContext:(_ASTransitionContext *)context constrainedSizeForKey:(NSString *)key;

@end

@protocol _ASTransitionContextCompletionDelegate <NSObject>

- (void)transitionContext:(_ASTransitionContext *)context didComplete:(BOOL)didComplete;

@end

@interface _ASTransitionContext : NSObject <ASContextTransitioning>

@property (nonatomic, readonly, getter=isAnimated) BOOL animated;

- (instancetype)initWithAnimation:(BOOL)animated
                   layoutDelegate:(id<_ASTransitionContextLayoutDelegate>)layoutDelegate
               completionDelegate:(id<_ASTransitionContextCompletionDelegate>)completionDelegate;

@end

@interface _ASAnimatedTransitionContext : NSObject
@property (nonatomic, readonly) ASDisplayNode *node;
@property (nonatomic, readonly) CGFloat alpha;
+ (instancetype)contextForNode:(ASDisplayNode *)node alpha:(CGFloat)alphaValue NS_RETURNS_RETAINED;
@end
