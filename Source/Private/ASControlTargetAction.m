//
//  ASControlTargetAction.m
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

#import <AsyncDisplayKit/ASControlTargetAction.h>

@implementation ASControlTargetAction
{
  __weak id _target;
  BOOL _createdWithNoTarget;
}

- (void)setTarget:(id)target {
  _target = target;
  
  if (!target) {
    _createdWithNoTarget = YES;
  }
}

- (id)target {
  return _target;
}

- (BOOL)isEqual:(id)object {
  if (![object isKindOfClass:[ASControlTargetAction class]]) {
    return NO;
  }
  
  ASControlTargetAction *otherObject = (ASControlTargetAction *)object;
  
  BOOL areTargetsEqual;
  
  if (self.target != nil && otherObject.target != nil && self.target == otherObject.target) {
    areTargetsEqual = YES;
  }
  else if (self.target == nil && otherObject.target == nil && self.createdWithNoTarget && otherObject.createdWithNoTarget) {
    areTargetsEqual = YES;
  }
  else {
    areTargetsEqual = NO;
  }
  
  if (!areTargetsEqual) {
    return NO;
  }
  
  if (self.action && otherObject.action && self.action == otherObject.action) {
    return YES;
  }
  else {
    return NO;
  }
}

- (NSUInteger)hash {
  return [self.target hash];
}

@end
