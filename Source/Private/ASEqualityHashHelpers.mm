//
//  ASEqualityHashHelpers.mm
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

#import <AsyncDisplayKit/ASEqualityHashHelpers.h>

#import <functional>

NSUInteger ASHashFromCGPoint(const CGPoint point)
{
  return ASHash64ToNative(ASHashCombine(std::hash<CGFloat>()(point.x), std::hash<CGFloat>()(point.y)));
}

NSUInteger ASHashFromCGSize(const CGSize size)
{
  return ASHash64ToNative(ASHashCombine(std::hash<CGFloat>()(size.width), std::hash<CGFloat>()(size.height)));
}

NSUInteger ASHashFromCGRect(const CGRect rect)
{
  return ASHashFromCGPoint(rect.origin) + ASHashFromCGSize(rect.size);
}

NSUInteger ASIntegerArrayHash(const NSUInteger *subhashes, NSUInteger count)
{
  uint64_t result = subhashes[0];
  for (int ii = 1; ii < count; ++ii) {
    result = ASHashCombine(result, subhashes[ii]);
  }
  return ASHash64ToNative(result);
}

