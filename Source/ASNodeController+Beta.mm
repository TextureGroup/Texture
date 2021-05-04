//
//  ASNodeController+Beta.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASDisplayNodeInternal.h>
#import <AsyncDisplayKit/ASNodeController+Beta.h>
#import <AsyncDisplayKit/ASNodeControllerInternal.h>

#define _node (_shouldInvertStrongReference ? _weakNode : _strongNode)

AS_ASSUME_NORETAIN_BEGIN

@implementation ASNodeController

- (instancetype)init
{
  if (self = [super init]) {
    _nodeContext = ASNodeContextGet();
    __instanceLock__.Configure(_nodeContext ? &_nodeContext->_mutex : nullptr) ;
  }
  return self;
}

- (void)loadNode
{
  ASLockScopeSelf();
  self.node = [[ASDisplayNode alloc] init];
}

- (ASDisplayNode *)node
{
  ASLockScopeSelf();
  if (_node == nil) {
    ASNodeContextPush(_nodeContext);
    [self loadNode];
    ASNodeContextPop();
    ASDisplayNodeAssert(_node == nil || _nodeContext == [_node nodeContext],
                        @"Controller and node must share context.\n%@\nvs\n%@", _nodeContext,
                        [_node nodeContext]);
  }
  return _node;
}

- (void)setupReferencesWithNode:(ASDisplayNode *)node
{
  ASLockScopeSelf();
  if (_shouldInvertStrongReference) {
    // The node should own the controller; weak reference from controller to node.
    _weakNode = node;
    _strongNode = nil;
  } else {
    // The controller should own the node; weak reference from node to controller.
    _strongNode = node;
    _weakNode = nil;
  }

  [node __setNodeController:self];
}

- (void)setNode:(ASDisplayNode *)node
{
  ASLockScopeSelf();
  if (node == _node) {
    return;
  }
  [self setupReferencesWithNode:node];
  [node addInterfaceStateDelegate:self];
}

- (void)setShouldInvertStrongReference:(BOOL)shouldInvertStrongReference
{
  ASLockScopeSelf();
  if (_shouldInvertStrongReference != shouldInvertStrongReference) {
    // At this point the node needs to be loaded and a strong reference needs to be captured
    // if shouldInvertStrongReference will be set to YES, otherwise the node will be deallocated
    // immediately in loadNode that is called within the -[ASNodeController node] acccessor.
    ASDisplayNodeAssert(!shouldInvertStrongReference || (shouldInvertStrongReference && _node != nil),
                        @"Node needs to be loaded and captured outside before setting "
                        @"shouldInvertStrongReference to YES");

    // Because the BOOL controls which ivar we access, get the node before toggling.
    ASDisplayNode *node = _node;
    _shouldInvertStrongReference = shouldInvertStrongReference;
    [self setupReferencesWithNode:node];
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

- (void)didEnterHierarchy {}
- (void)didExitHierarchy  {}

- (AS::LockSet)lockPair {
  AS::LockSet locks;
  while (locks.empty()) {
    // If we have a node context, we just need to lock it. Nothing else.
    if (_nodeContext) {
      if (!locks.TryAdd(_nodeContext, _nodeContext->_mutex)) continue;
      break;
    }
    if (_node && !locks.TryAdd(_node, _node->__instanceLock__)) continue;
    if (!locks.TryAdd(self, __instanceLock__)) continue;
  }

  return locks;
}

- (id)debugQuickLookObject
{
  return [_node debugQuickLookObject];
}

#pragma mark NSLocking

- (void)lock
{
  __instanceLock__.lock();
}

- (void)unlock
{
  __instanceLock__.unlock();
}

- (BOOL)tryLock
{
  return __instanceLock__.try_lock();
}

@end

@implementation ASDisplayNode (ASNodeController)

- (ASNodeController *)nodeController
{
  return _weakNodeController ?: _strongNodeController;
}

@end

AS_ASSUME_NORETAIN_END
