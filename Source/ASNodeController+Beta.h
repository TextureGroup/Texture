//
//  ASNodeController+Beta.h
//  Texture
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the /ASDK-Licenses directory of this source tree. An additional
//  grant of patent rights can be found in the PATENTS file in the same directory.
//
//  Modifications to this file made after 4/13/2017 are: Copyright (c) 2017-present,
//  Pinterest, Inc.  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASDisplayNode.h>
#import <AsyncDisplayKit/ASDisplayNode+Subclasses.h> // for ASInterfaceState protocol

/* ASNodeController is currently beta and open to change in the future */
@interface ASNodeController<__covariant DisplayNodeType : ASDisplayNode *> : NSObject <ASInterfaceStateDelegate>

@property (nonatomic, strong /* may be weak! */) DisplayNodeType node;

// Until an ASNodeController can be provided in place of an ASCellNode, some apps may prefer to have
// nodes keep their controllers alive (and a weak reference from controller to node)

@property (nonatomic) BOOL shouldInvertStrongReference;

- (void)loadNode;

// for descriptions see <ASInterfaceState> definition
- (void)nodeDidLoad NS_REQUIRES_SUPER;
- (void)nodeDidLayout NS_REQUIRES_SUPER;

- (void)didEnterVisibleState NS_REQUIRES_SUPER;
- (void)didExitVisibleState  NS_REQUIRES_SUPER;

- (void)didEnterDisplayState NS_REQUIRES_SUPER;
- (void)didExitDisplayState  NS_REQUIRES_SUPER;

- (void)didEnterPreloadState NS_REQUIRES_SUPER;
- (void)didExitPreloadState  NS_REQUIRES_SUPER;

- (void)interfaceStateDidChange:(ASInterfaceState)newState
                      fromState:(ASInterfaceState)oldState NS_REQUIRES_SUPER;

@end

@interface ASDisplayNode (ASNodeController)

@property(nonatomic, readonly) ASNodeController *nodeController;

@end
