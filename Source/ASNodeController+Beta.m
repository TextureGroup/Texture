//
//  ASNodeController.mm
//  AsyncDisplayKit
//
//  Created by Hannah Troisi for Scott Goodson on 1/27/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "ASNodeController+Beta.h"
#import "ASDisplayNode+FrameworkPrivate.h"

#if INVERT_NODE_CONTROLLER_OWNERSHIP

@interface ASDisplayNode (ASNodeController)
@property (nonatomic, strong) ASNodeController *asdkNodeController;
@end

@implementation ASDisplayNode (ASNodeController)

- (ASNodeController *)asdkNodeController
{
  return objc_getAssociatedObject(self, @selector(asdkNodeController));
}

- (void)setAsdkNodeController:(ASNodeController *)asdkNodeController
{
  objc_setAssociatedObject(self, @selector(asdkNodeController), asdkNodeController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#endif

@implementation ASNodeController

@synthesize node = _node;

- (instancetype)init
{
  self = [super init];
  if (self) {
    
  }
  return self;
}

- (void)loadNode
{
  self.node = [[ASDisplayNode alloc] init];
}

- (ASDisplayNode *)node
{
  if (_node == nil) {
    [self loadNode];
  }
  return _node;
}

-(void)setNode:(ASDisplayNode *)node
{
  _node = node;
  _node.interfaceStateDelegate = self;
#if INVERT_NODE_CONTROLLER_OWNERSHIP
  _node.asdkNodeController = self;
#endif
}

// subclass overrides
- (void)didEnterVisibleState {}
- (void)didExitVisibleState  {}

- (void)didEnterDisplayState {}
- (void)didExitDisplayState  {}

- (void)didEnterPreloadState {}
- (void)didExitPreloadState  {}

- (void)interfaceStateDidChange:(ASInterfaceState)newState
                      fromState:(ASInterfaceState)oldState {}

@end
