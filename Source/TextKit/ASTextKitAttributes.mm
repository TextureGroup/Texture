//
//  ASTextKitAttributes.mm
//  AsyncDisplayKit
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

#import <AsyncDisplayKit/ASTextKitAttributes.h>

#import <AsyncDisplayKit/ASEqualityHashHelpers.h>

#include <functional>

NSString *const ASTextKitTruncationAttributeName = @"ck_truncation";
NSString *const ASTextKitEntityAttributeName = @"ck_entity";

size_t ASTextKitAttributes::hash() const
{
  NSUInteger subhashes[] = {
    [attributedString hash],
    [truncationAttributedString hash],
    [avoidTailTruncationSet hash],
    std::hash<NSInteger>()(lineBreakMode),
    std::hash<NSInteger>()(maximumNumberOfLines),
    [exclusionPaths hash],
    std::hash<CGFloat>()(shadowOffset.width),
    std::hash<CGFloat>()(shadowOffset.height),
    [shadowColor hash],
    std::hash<CGFloat>()(shadowOpacity),
    std::hash<CGFloat>()(shadowRadius),
  };
  return ASIntegerArrayHash(subhashes, sizeof(subhashes) / sizeof(subhashes[0]));
}
