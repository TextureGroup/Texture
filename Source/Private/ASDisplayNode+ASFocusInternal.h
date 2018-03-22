//
//  ASDisplayNode+ASFocusInternal.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASDisplayNode.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * These methods will call the block implementation if it exists
 * If a block implementation does not exist, the call will be forwarded to the node implementation
 */
@interface ASDisplayNode (ASFocusInternal)

- (BOOL)__canBecomeFocusedWithUIKitFallbackBlock:(BOOL (^)(void))fallbackBlock;
- (void)__didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator withUIKitFallbackBlock:(void (^_Nullable)(void))fallbackBlock;
- (BOOL)__shouldUpdateFocusInContext:(UIFocusUpdateContext *)context withUIKitFallbackBlock:(BOOL (^)(void))fallbackBlock;
- (NSArray<id<UIFocusEnvironment>> *)__preferredFocusEnvironmentsWithUIKitFallbackBlock:(NSArray<id<UIFocusEnvironment>> * (^)(void))fallbackBlock API_AVAILABLE(ios(10.0), tvos(10.0));
- (nullable UIView *)__preferredFocusedViewWithUIKitFallbackBlock:(UIView *_Nullable (^)(void))fallbackBlock;

@end

NS_ASSUME_NONNULL_END
