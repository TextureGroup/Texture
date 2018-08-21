//
//  ASDisplayNode+DebugTiming.mm
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASDisplayNode+DebugTiming.h>
#import <AsyncDisplayKit/ASDisplayNodeInternal.h>

@implementation ASDisplayNode (DebugTiming)

#if TIME_DISPLAYNODE_OPS
- (NSTimeInterval)debugTimeToCreateView
{
  return _debugTimeToCreateView;
}

- (NSTimeInterval)debugTimeToApplyPendingState
{
  return _debugTimeToApplyPendingState;
}

- (NSTimeInterval)debugTimeToAddSubnodeViews
{
  return _debugTimeToAddSubnodeViews;
}

- (NSTimeInterval)debugTimeForDidLoad
{
  return _debugTimeForDidLoad;
}

- (NSTimeInterval)debugAllCreationTime
{
  return self.debugTimeToCreateView + self.debugTimeToApplyPendingState + self.debugTimeToAddSubnodeViews + self.debugTimeForDidLoad;
}

// This would over-count views that are created in the parent's didload or addsubnodesubviews, so we need to take a more basic approach
//- (NSTimeInterval)debugRecursiveAllCreationTime
//{
//  __block NSTimeInterval total = 0;
//  ASDisplayNodeFindAllSubnodes(self, ^(ASDisplayNode *n){
//    total += self.debugTimeToCreateView;
//    total += self.debugTimeToApplyPendingState;
//    total += self.debugTimeToAddSubnodeViews;
//    total += self.debugTimeForDidLoad;
//    return NO;
//  });
//  return total;
//}

#else

// These ivars are compiled out so we don't have the info available
- (NSTimeInterval)debugTimeToCreateView
{
  return -1;
}

- (NSTimeInterval)debugTimeToApplyPendingState
{
  return -1;
}

- (NSTimeInterval)debugTimeToAddSubnodeViews
{
  return -1;
}

- (NSTimeInterval)debugTimeForDidLoad
{
  return -1;
}

- (NSTimeInterval)debugAllCreationTime
{
  return -1;
}

#endif

@end
