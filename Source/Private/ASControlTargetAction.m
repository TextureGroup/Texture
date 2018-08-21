//
//  ASControlTargetAction.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
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
