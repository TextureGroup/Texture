//
//  ASTestCase.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASTestCase.h"
#import <objc/runtime.h>

@implementation ASTestCase

- (void)tearDown
{
  // Clear out all application windows. Note: the system will retain these sometimes on its
  // own but we'll do our best.
  for (UIWindow *window in [UIApplication sharedApplication].windows) {
    [window resignKeyWindow];
    window.hidden = YES;
    for (UIView *view in window.subviews) {
      [view removeFromSuperview];
    }
  }
  
  // Set nil for all our subclasses' ivars. Use setValue:forKey: so memory is managed correctly.
  Class c = [self class];
  while (c != [ASTestCase class]) {
    unsigned int ivarCount;
    Ivar *ivars = class_copyIvarList(c, &ivarCount);
    for (unsigned int i = 0; i < ivarCount; i++) {
      Ivar ivar = ivars[i];
      NSString *key = [NSString stringWithCString:ivar_getName(ivar) encoding:NSUTF8StringEncoding];
      [self setValue:nil forKey:key];
    }
    if (ivars) {
      free(ivars);
    }
    
    c = [c superclass];
  }
  
  [super tearDown];
}

@end
