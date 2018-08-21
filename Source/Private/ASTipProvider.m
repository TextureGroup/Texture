//
//  ASTipProvider.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASTipProvider.h"

#if AS_ENABLE_TIPS

#import <AsyncDisplayKit/ASAssert.h>

// Concrete classes
#import <AsyncDisplayKit/ASLayerBackingTipProvider.h>

@implementation ASTipProvider

- (ASTip *)tipForNode:(ASDisplayNode *)node
{
  ASDisplayNodeFailAssert(@"Subclasses must override %@", NSStringFromSelector(_cmd));
  return nil;
}

@end

@implementation ASTipProvider (Lookup)

+ (NSArray<ASTipProvider *> *)all
{
  static NSArray<ASTipProvider *> *providers;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    providers = @[ [ASLayerBackingTipProvider new] ];
  });
  return providers;
}

@end

#endif // AS_ENABLE_TIPS
