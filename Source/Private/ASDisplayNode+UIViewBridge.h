//
//  ASDisplayNode+UIViewBridge.h
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

@interface ASDisplayNode (InternalMethodBridge)

- (void)_setNeedsFocusUpdate;
- (void)_updateFocusIfNeeded;
- (BOOL)_canBecomeFocused;
- (void)_didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator;
- (BOOL)_shouldUpdateFocusInContext:(UIFocusUpdateContext *)context;
- (NSArray<id<UIFocusEnvironment>> *)_preferredFocusEnvironments;
- (nullable UIView *)_preferredFocusedView;

@end

NS_ASSUME_NONNULL_END
