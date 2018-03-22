//
//  ASDisplayNode+ASFocus.mm
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASDisplayNodeInternal.h>
#import <AsyncDisplayKit/ASDisplayNode+FrameworkSubclasses.h>

@implementation ASDisplayNode (ASFocus)

- (void)setCanBecomeFocusedBlock:(ASFocusabilityBlock)canBecomeFocusedBlock
{
  // For now there should never be an override of canBecomeFocused and a canBecomeFocusedBlock together.
  ASDisplayNodeAssert(!(_methodOverrides & ASDisplayNodeMethodOverrideCanBecomeFocused),
                      @"Nodes with a .canBecomeFocusedBlock must not also implement -canBecomeFocused");
  ASDN::MutexLocker l(__instanceLock__);
  _canBecomeFocusedBlock = canBecomeFocusedBlock;
}

- (ASFocusabilityBlock)canBecomeFocusedBlock
{
  ASDN::MutexLocker l(__instanceLock__);
  return _canBecomeFocusedBlock;
}

- (void)setShouldUpdateFocusBlock:(ASFocusUpdateContextBlock)shouldUpdateFocusBlock
{
  // For now there should never be an override of shouldUpdateFocusInContext: and a shouldUpdateFocusBlock together.
  ASDisplayNodeAssert(!(_methodOverrides & ASDisplayNodeMethodOverrideShouldUpdateFocus),
                      @"Nodes with a .shouldUpdateFocusBlock must not also implement -shouldUpdateFocusInContext:");
  ASDN::MutexLocker l(__instanceLock__);
  _shouldUpdateFocusBlock = shouldUpdateFocusBlock;
}

- (ASFocusUpdateContextBlock)shouldUpdateFocusBlock
{
  ASDN::MutexLocker l(__instanceLock__);
  return _shouldUpdateFocusBlock;
}

- (void)setDidUpdateFocusBlock:(ASFocusUpdateAnimationCoordinatorBlock)didUpdateFocusBlock
{
  // For now there should never be an override of didUpdateFocusInContext:withAnimationCoordinator: and a didUpdateFocusBlock together.
  ASDisplayNodeAssert(!(_methodOverrides & ASDisplayNodeMethodOverrideDidUpdateFocus),
                      @"Nodes with a .didUpdateFocusBlock must not also implement -didUpdateFocusInContext:withAnimationCoordinator:");
  ASDN::MutexLocker l(__instanceLock__);
  _didUpdateFocusBlock = didUpdateFocusBlock;
}

- (ASFocusUpdateAnimationCoordinatorBlock)didUpdateFocusBlock
{
  ASDN::MutexLocker l(__instanceLock__);
  return _didUpdateFocusBlock;
}

- (void)setPreferredFocusEnvironmentsBlock:(ASFocusEnvironmentsBlock)preferredFocusEnvironmentsBlock
{
  // For now there should never be an override of preferredFocusEnvironments and a preferredFocusEnvironmentsBlock together.
  ASDisplayNodeAssert(!(_methodOverrides & ASDisplayNodeMethodOverridePreferredFocusEnvironments),
                      @"Nodes with a .preferredFocusEnvironmentsBlock must not also implement -preferredFocusEnvironments");
  ASDN::MutexLocker l(__instanceLock__);
  _preferredFocusEnvironmentsBlock = preferredFocusEnvironmentsBlock;
}

- (ASFocusEnvironmentsBlock)preferredFocusEnvironmentsBlock
{
  ASDN::MutexLocker l(__instanceLock__);
  return _preferredFocusEnvironmentsBlock;
}

- (void)setPreferredFocusedViewBlock:(ASFocusViewBlock)preferredFocusedViewBlock
{
  // For now there should never be an override of preferredFocusedView and a preferredFocusedViewBlock together.
  ASDisplayNodeAssert(!(_methodOverrides & ASDisplayNodeMethodOverridePreferredFocusedView),
                      @"Nodes with a .preferredFocusedViewBlock must not also implement -preferredFocusedView");
  ASDN::MutexLocker l(__instanceLock__);
  _preferredFocusedViewBlock = preferredFocusedViewBlock;
}

- (ASFocusViewBlock)preferredFocusedViewBlock
{
  ASDN::MutexLocker l(__instanceLock__);
  return _preferredFocusedViewBlock;
}

@end
