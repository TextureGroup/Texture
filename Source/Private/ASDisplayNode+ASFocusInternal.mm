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

- (BOOL)_canBecomeFocused
{
  if (_canBecomeFocusedBlock != NULL) {
    ASDN::MutexLocker l(__instanceLock__);
    return _canBecomeFocusedBlock(self);
  } else {
    return [self canBecomeFocused];
  }
}

- (BOOL)_shouldUpdateFocusInContext:(UIFocusUpdateContext *)context
{
  if (_shouldUpdateFocusBlock != NULL) {
    ASDN::MutexLocker l(__instanceLock__);
    return _shouldUpdateFocusBlock(self, context);
  } else {
    return [self shouldUpdateFocusInContext:context];
  }
}

- (void)_didUpdateFocusInContext:(UIFocusUpdateContext *)context withAnimationCoordinator:(UIFocusAnimationCoordinator *)coordinator
{
  if (_didUpdateFocusBlock != NULL) {
    ASDN::MutexLocker l(__instanceLock__);
    return _didUpdateFocusBlock(self, context, coordinator);
  } else {
    return [self didUpdateFocusInContext:context withAnimationCoordinator:coordinator];
  }
}

- (NSArray<id<UIFocusEnvironment>> *)_preferredFocusEnvironments API_AVAILABLE(ios(10.0), tvos(10.0))
{
  if (_preferredFocusEnvironmentsBlock != NULL) {
    ASDN::MutexLocker l(__instanceLock__);
    return _preferredFocusEnvironmentsBlock(self);
  } else {
    return [self preferredFocusEnvironments];
  }
}

- (UIView *)_preferredFocusedView
{
  if (_preferredFocusedViewBlock != NULL) {
    ASDN::MutexLocker l(__instanceLock__);
    return _preferredFocusedViewBlock(self);
  } else {
    return [self preferredFocusedView];
  }
}

@end
