//
//  ASTipProvider.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASTipProvider.h"

#if AS_ENABLE_TIPS

#import "ASAssert.h"

// Concrete classes
#import "ASLayerBackingTipProvider.h"

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
