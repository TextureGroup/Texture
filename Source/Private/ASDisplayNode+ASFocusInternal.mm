//
//  ASDisplayNode+ASFocusInternal.mm
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASDisplayNode+ASFocusInternal.h"
#import <AsyncDisplayKit/ASDisplayNodeInternal.h>
#import <AsyncDisplayKit/ASDisplayNode+FrameworkSubclasses.h>

@implementation ASDisplayNode (ASFocusInternal)

- (BOOL)__canBecomeFocusedWithUIKitFallbackBlock:(BOOL (^)())fallbackBlock
{
  if (_canBecomeFocusedBlock != NULL) {
    ASDN::MutexLocker l(__instanceLock__);
    return _canBecomeFocusedBlock(self);
  } else if (self.methodOverrides & ASDisplayNodeMethodOverrideCanBecomeFocused) {
    return [self canBecomeFocused];
  } else {
    return fallbackBlock();
  }
}

- (BOOL)__shouldUpdateFocusInContext:(UIFocusUpdateContext *)context withUIKitFallbackBlock:(BOOL (^)())fallbackBlock
{
  if (_shouldUpdateFocusBlock != NULL) {
    ASDN::MutexLocker l(__instanceLock__);
    return _shouldUpdateFocusBlock(self, context);
  } else if (self.methodOverrides & ASDisplayNodeMethodOverrideShouldUpdateFocus) {
    return [self shouldUpdateFocusInContext:context];
  } else {
    return fallbackBlock();
  }
}

- (void)__didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator withUIKitFallbackBlock:(void (^)())fallbackBlock
{
  if (_didUpdateFocusBlock != NULL) {
    ASDN::MutexLocker l(__instanceLock__);
    _didUpdateFocusBlock(self, context, coordinator);
  } else if (self.methodOverrides & ASDisplayNodeMethodOverrideDidUpdateFocus) {
    [self didUpdateFocusInContext:context withAnimationCoordinator:coordinator];
  } else {
    if (fallbackBlock != nil) {
      fallbackBlock();
    }
  }
}

- (NSArray<id<UIFocusEnvironment>> *)__preferredFocusEnvironmentsWithUIKitFallbackBlock:(NSArray<id<UIFocusEnvironment>> * _Nonnull (^)())fallbackBlock API_AVAILABLE(ios(10.0), tvos(10.0))
{
  if (_preferredFocusEnvironmentsBlock != NULL) {
    ASDN::MutexLocker l(__instanceLock__);
    return _preferredFocusEnvironmentsBlock(self);
  } else if (self.methodOverrides & ASDisplayNodeMethodOverridePreferredFocusEnvironments) {
    return [self preferredFocusEnvironments];
  } else {
    return fallbackBlock();
  }
}

- (UIView *)__preferredFocusedViewWithUIKitFallbackBlock:(UIView * _Nullable (^)())fallbackBlock
{
  if (_preferredFocusedViewBlock != NULL) {
    ASDN::MutexLocker l(__instanceLock__);
    return _preferredFocusedViewBlock(self);
  } else if (self.methodOverrides & ASDisplayNodeMethodOverridePreferredFocusedView) {
    return [self preferredFocusedView];
  } else {
    return fallbackBlock();
  }
}

@end
