//
//  _ASScopeTimer.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#pragma once

/**
 Must compile as c++ for this to work.

 Usage:
 // Can be an ivar or local variable
 NSTimeInterval placeToStoreTiming;

 {
   // some scope
   ASDisplayNode::ScopeTimer t(placeToStoreTiming);
   DoPotentiallySlowWork();
   MorePotentiallySlowWork();
 }

 */

namespace ASDN {
  struct ScopeTimer {
    NSTimeInterval begin;
    NSTimeInterval &outT;
    ScopeTimer(NSTimeInterval &outRef) : outT(outRef) {
      begin = CACurrentMediaTime();
    }
    ~ScopeTimer() {
      outT = CACurrentMediaTime() - begin;
    }
  };

  // variant where repeated calls are summed
  struct SumScopeTimer {
    NSTimeInterval begin;
    NSTimeInterval &outT;
    BOOL enable;
    SumScopeTimer(NSTimeInterval &outRef, BOOL enable = YES) : outT(outRef), enable(enable) {
      if (enable) {
        begin = CACurrentMediaTime();
      }
    }
    ~SumScopeTimer() {
      if (enable) {
        outT += CACurrentMediaTime() - begin;
      }
    }
  };
}
