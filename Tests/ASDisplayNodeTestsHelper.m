//
//  ASDisplayNodeTestsHelper.m
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

#import "ASDisplayNodeTestsHelper.h"
#import <AsyncDisplayKit/ASDisplayNode.h>
#import <AsyncDisplayKit/ASLayout.h>
#import <AsyncDisplayKit/ASRunLoopQueue.h>

#import <QuartzCore/QuartzCore.h>

#import <libkern/OSAtomic.h>

// Poll the condition 1000 times a second.
static CFTimeInterval kSingleRunLoopTimeout = 0.001;

// Time out after 30 seconds.
static CFTimeInterval kTimeoutInterval = 30.0f;

BOOL ASDisplayNodeRunRunLoopUntilBlockIsTrue(as_condition_block_t block)
{
  CFTimeInterval timeoutDate = CACurrentMediaTime() + kTimeoutInterval;
  BOOL passed = NO;
  while (true) {
    OSMemoryBarrier();
    passed = block();
    OSMemoryBarrier();
    if (passed) {
      break;
    }
    CFTimeInterval now = CACurrentMediaTime();
    if (now > timeoutDate) {
      break;
    }
    // Run until the poll timeout or until timeoutDate, whichever is first.
    CFTimeInterval runLoopTimeout = MIN(kSingleRunLoopTimeout, timeoutDate - now);
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, runLoopTimeout, true);
  }
  return passed;
}

void ASDisplayNodeSizeToFitSize(ASDisplayNode *node, CGSize size)
{
  CGSize sizeThatFits = [node layoutThatFits:ASSizeRangeMake(size)].size;
  node.bounds = (CGRect){.origin = CGPointZero, .size = sizeThatFits};
}

void ASDisplayNodeSizeToFitSizeRange(ASDisplayNode *node, ASSizeRange sizeRange)
{
  CGSize sizeThatFits = [node layoutThatFits:sizeRange].size;
  node.bounds = (CGRect){.origin = CGPointZero, .size = sizeThatFits};
}

void ASCATransactionQueueWait(ASCATransactionQueue *q)
{
  if (!q) { q = ASCATransactionQueue.sharedQueue; }
  NSDate *date = [NSDate dateWithTimeIntervalSinceNow:1];
  BOOL whileResult = YES;
  while ([date timeIntervalSinceNow] > 0 &&
         (whileResult = ![q isEmpty])) {
    [[NSRunLoop currentRunLoop] runUntilDate:
     [NSDate dateWithTimeIntervalSinceNow:0.01]];
  }
}
