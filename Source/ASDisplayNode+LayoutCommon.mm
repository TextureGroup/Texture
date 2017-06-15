//
//  ASDisplayNode+LayoutCommon.mm
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

#import <AsyncDisplayKit/ASLayoutSpec.h>

#pragma mark -
#pragma mark - ASLayoutElementAsciiArtProtocol

@implementation ASDisplayNode (ASLayoutElementAsciiArtProtocol)

- (NSString *)asciiArtString
{
  return [ASLayoutSpec asciiArtStringForChildren:@[] parentName:[self asciiArtName]];
}

- (NSString *)asciiArtName
{
  NSString *string = NSStringFromClass([self class]);
  if (_debugName) {
    string = [string stringByAppendingString:[NSString stringWithFormat:@"\"%@\"",_debugName]];
  }
  return string;
}

@end

#pragma mark -
#pragma mark - ASDisplayNode (ASLayoutElementStylability)

@implementation ASDisplayNode (ASLayoutElementStylability)

- (instancetype)styledWithBlock:(AS_NOESCAPE void (^)(__kindof ASLayoutElementStyle *style))styleBlock
{
  styleBlock(self.style);
  return self;
}

@end

#pragma mark -
#pragma mark - ASDisplayNode (ASAutomatic Subnode Management)

@implementation ASDisplayNode (ASAutomaticSubnodeManagement)

#pragma mark Automatically Manages Subnodes

- (BOOL)automaticallyManagesSubnodes
{
  ASDN::MutexLocker l(__instanceLock__);
  return _automaticallyManagesSubnodes;
}

- (void)setAutomaticallyManagesSubnodes:(BOOL)automaticallyManagesSubnodes
{
  ASDN::MutexLocker l(__instanceLock__);
  _automaticallyManagesSubnodes = automaticallyManagesSubnodes;
}

@end
