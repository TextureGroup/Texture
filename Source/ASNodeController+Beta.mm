//
//  ASNodeController+Beta.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASDisplayNodeInternal.h>
#import <AsyncDisplayKit/ASDisplayNode+FrameworkPrivate.h>
#import <AsyncDisplayKit/ASNodeController+Beta.h>
#import <AsyncDisplayKit/ASThread.h>

@implementation ASNodeController
{
  unowned ASDisplayNode *_node;
  ASDN::Mutex _nodeLock;
}

- (ASDisplayNode *)createNode
{
  return [[ASDisplayNode alloc] init];
}

- (ASDisplayNode *)node
{
  ASDN::MutexLocker l(_nodeLock);
  if (!_node) {
    ASDisplayNode *node = [self createNode];
    if (!node) {
      ASDisplayNodeCFailAssert(@"Returned nil from -createNode.");
      node = [[ASDisplayNode alloc] init];
    }
    _node = node;
    if (!_shouldInvertStrongReference) {
      CFRetain((__bridge CFTypeRef)node);
    }
    ASDN::MutexLocker l(node->__instanceLock__);
    [node __setNodeController:self];
    [node addInterfaceStateDelegate:self];
  }
  return _node;
}

- (void)setShouldInvertStrongReference:(BOOL)shouldInvertStrongReference
{
  if (_shouldInvertStrongReference == shouldInvertStrongReference) {
    return;
  }
  
  ASDN::MutexLocker l(_nodeLock);
  if (_node) {
    if (shouldInvertStrongReference) {
      CFRelease((__bridge CFTypeRef)_node);
    } else {
      CFRetain((__bridge CFTypeRef)_node);
    }
  }
}

- (void)nodeWillDeallocate
{
  ASDN::MutexLocker l(_nodeLock);
  _node = nil;
}

- (void)dealloc
{
  ASDN::MutexLocker l(_nodeLock);
  if (_node && !_shouldInvertStrongReference) {
    CFRelease((__bridge CFTypeRef)_node);
  }
}

// subclass overrides
- (void)nodeDidLoad {}
- (void)nodeDidLayout {}
- (void)nodeWillCalculateLayout:(ASSizeRange)constrainedSize {}

- (void)didEnterVisibleState {}
- (void)didExitVisibleState  {}

- (void)didEnterDisplayState {}
- (void)didExitDisplayState  {}

- (void)didEnterPreloadState {}
- (void)didExitPreloadState  {}

- (void)interfaceStateDidChange:(ASInterfaceState)newState
                      fromState:(ASInterfaceState)oldState {}

- (void)hierarchyDisplayDidFinish {}

#pragma mark NSLocking

- (void)lock
{
  [self.node lock];
}

- (void)unlock
{
  // Since the node is already locked, we don't need to 
  ASDN::MutexLocker l(_nodeLock);
  [_node unlock];
}

- (BOOL)tryLock
{
  return [self.node tryLock];
}

@end

@implementation ASDisplayNode (ASNodeController)

- (ASNodeController *)nodeController
{
  return _weakNodeController ?: _strongNodeController;
}

@end
