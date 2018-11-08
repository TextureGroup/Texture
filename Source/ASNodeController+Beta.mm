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

#import <mutex>

#define _node (_shouldInvertStrongReference ? _weakNode : _strongNode)

@implementation ASNodeController
{
  ASDisplayNode *_strongNode;
  __weak ASDisplayNode *_weakNode;
  std::once_flag _nodeOnce;
}

- (ASDisplayNode *)createNode
{
  return [[ASDisplayNode alloc] init];
}

- (ASDisplayNode *)node
{
  std::call_once(_nodeOnce, [self](){
    [self setupReferencesWithNode:[self createNode]];
  });
  return _node;
}

- (void)setupReferencesWithNode:(ASDisplayNode *)node
{
  ASDN::MutexLocker l(node->__instanceLock__);
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
  [node addInterfaceStateDelegate:self];
}

- (void)setShouldInvertStrongReference:(BOOL)shouldInvertStrongReference
{
  if (_shouldInvertStrongReference != shouldInvertStrongReference) {
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

@end

@implementation ASDisplayNode (ASNodeController)

- (ASNodeController *)nodeController
{
  return _weakNodeController ?: _strongNodeController;
}

@end
