//
//  ASDisplayNode+Convenience.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASDisplayNode+Convenience.h"

#import <UIKit/UIViewController.h>

#import <AsyncDisplayKit/ASDisplayNodeExtras.h>
#import <AsyncDisplayKit/ASResponderChainEnumerator.h>

@implementation ASDisplayNode (Convenience)

- (__kindof UIViewController *)closestViewController
{
  ASDisplayNodeAssertMainThread();
  
  // Careful not to trigger node loading here.
  if (!self.nodeLoaded) {
    return nil;
  }

  // Get the closest view.
  UIView *view = ASFindClosestViewOfLayer(self.layer);
  // Travel up the responder chain to find a view controller.
  for (UIResponder *responder in [view asdk_responderChainEnumerator]) {
    UIViewController *vc = ASDynamicCast(responder, UIViewController);
    if (vc != nil) {
      return vc;
    }
  }
  return nil;
}

@end
