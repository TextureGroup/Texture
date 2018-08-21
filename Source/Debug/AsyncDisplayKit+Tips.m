//
//  AsyncDisplayKit+Tips.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "AsyncDisplayKit+Tips.h"
#import <AsyncDisplayKit/ASDisplayNode+Ancestry.h>

@implementation ASDisplayNode (Tips)

static char ASDisplayNodeEnableTipsKey;
static ASTipDisplayBlock _Nullable __tipDisplayBlock;

/**
 * Use associated objects with NSNumbers. This is a debug property - simplicity is king.
 */
+ (void)setEnableTips:(BOOL)enableTips
{
  objc_setAssociatedObject(self, &ASDisplayNodeEnableTipsKey, @(enableTips), OBJC_ASSOCIATION_COPY);
}

+ (BOOL)enableTips
{
  NSNumber *result = objc_getAssociatedObject(self, &ASDisplayNodeEnableTipsKey);
  if (result == nil) {
    return YES;
  }
  return result.boolValue;
}


+ (void)setTipDisplayBlock:(ASTipDisplayBlock)tipDisplayBlock
{
  __tipDisplayBlock = tipDisplayBlock;
}

+ (ASTipDisplayBlock)tipDisplayBlock
{
  return __tipDisplayBlock ?: ^(ASDisplayNode *node, NSString *string) {
    NSLog(@"%@. Node ancestry: %@", string, node.ancestryDescription);
  };
}

@end
