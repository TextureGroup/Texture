//
//  NSInvocation+ASTestHelpers.m
//  AsyncDisplayKit
//
//  Created by Adlai Holler on 6/10/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "NSInvocation+ASTestHelpers.h"

@implementation NSInvocation (ASTestHelpers)

- (id)as_argumentAtIndexAsObject:(NSInteger)index
{
  void *buf;
  [self getArgument:&buf atIndex:index];
  return (__bridge id)buf;
}

- (void)as_setReturnValueWithObject:(id)object
{
  if (object == nil) {
    const void *fixedBuf = NULL;
    [self setReturnValue:&fixedBuf];
  } else {
    // Retain, then autorelease.
    const void *fixedBuf = CFAutorelease((__bridge_retained void *)object);
    [self setReturnValue:&fixedBuf];
  }
}

@end
