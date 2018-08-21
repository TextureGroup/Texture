//
//  UIResponder+AsyncDisplayKit.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "UIResponder+AsyncDisplayKit.h"

#import <AsyncDisplayKit/ASAssert.h>
#import <AsyncDisplayKit/ASBaseDefines.h>
#import <AsyncDisplayKit/ASResponderChainEnumerator.h>

@implementation UIResponder (AsyncDisplayKit)

- (__kindof UIViewController *)asdk_associatedViewController
{
  ASDisplayNodeAssertMainThread();
  
  for (UIResponder *responder in [self asdk_responderChainEnumerator]) {
    UIViewController *vc = ASDynamicCast(responder, UIViewController);
    if (vc) {
      return vc;
    }
  }
  return nil;
}

@end

