//
//  ASPerformanceTestContext.m
//  Texture
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the /ASDK-Licenses directory of this source tree. An additional
//  grant of patent rights can be found in the PATENTS file in the same directory.
//
//  Modifications to this file made after 4/13/2017 are: Copyright (c) through the present,
//  Pinterest, Inc.  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>
#import "ASPerformanceTestContext.h"
#import <AsyncDisplayKit/ASAssert.h>

@interface ASPerformanceTestResult ()
@property (nonatomic) NSTimeInterval timePer1000;
@property (nonatomic) NSString *caseName;

@property (nonatomic, getter=isReferenceCase) BOOL referenceCase;
@property (nonatomic) float relativePerformance;
@end

@implementation ASPerformanceTestResult

- (instancetype)init
{
  self = [super init];
  if (self != nil) {
    _userInfo = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (NSString *)description
{
  NSString *userInfoStr = [_userInfo.description stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
  return [NSString stringWithFormat:@"<%-20s: time-per-1000=%04.2f rel-perf=%04.2f user-info=%@>", _caseName.UTF8String, _timePer1000, _relativePerformance, userInfoStr];
}

@end

@implementation ASPerformanceTestContext {
  NSMutableDictionary *_results;
  NSInteger _iterationCount;
  ASPerformanceTestResult * _Nullable _referenceResult;
}

- (instancetype)init
{
  self = [super init];
  if (self != nil) {
    _iterationCount = 1E4;
    _results = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (void)dealloc
{
  /**
   * I know this seems wacky but it's a pain to have to put this in every single test method.
   */
  NSLog(@"%@", self.description);
}

- (BOOL)areAllUserInfosEqual
{
  ASDisplayNodeAssert(_results.count >= 2, nil);
  NSEnumerator *resultsEnumerator = [_results objectEnumerator];
  NSDictionary *userInfo = [[resultsEnumerator nextObject] userInfo];
  for (ASPerformanceTestResult *otherResult in resultsEnumerator) {
    if ([userInfo isEqualToDictionary:otherResult.userInfo] == NO) {
      return NO;
    }
  }
  return YES;
}

- (void)addCaseWithName:(NSString *)caseName block:(AS_NOESCAPE ASTestPerformanceCaseBlock)block
{
  ASDisplayNodeAssert(_results[caseName] == nil, @"Already have a case named %@", caseName);
  ASPerformanceTestResult *result = [[ASPerformanceTestResult alloc] init];
  result.caseName = caseName;
  result.timePer1000 = [self _testPerformanceForCaseWithBlock:block] / (_iterationCount / 1000);
  if (_referenceResult == nil) {
    result.referenceCase = YES;
    result.relativePerformance = 1.0f;
    _referenceResult = result;
  } else {
    result.relativePerformance = _referenceResult.timePer1000 / result.timePer1000;
  }
  _results[caseName] = result;
}

/// Returns total work time
- (CFTimeInterval)_testPerformanceForCaseWithBlock:(AS_NOESCAPE ASTestPerformanceCaseBlock)block
{
  __block CFTimeInterval time = 0;
  for (NSInteger i = 0; i < _iterationCount; i++) {
    __block CFTimeInterval start = 0;
    __block BOOL calledStop = NO;
    @autoreleasepool {
      block(i, ^{
        ASDisplayNodeAssert(start == 0, @"Called startMeasuring block twice.");
        start = CACurrentMediaTime();
      }, ^{
        time += (CACurrentMediaTime() - start);
        ASDisplayNodeAssert(calledStop == NO, @"Called stopMeasuring block twice.");
        ASDisplayNodeAssert(start != 0, @"Failed to call startMeasuring block");
        calledStop = YES;
      });
    }

    ASDisplayNodeAssert(calledStop, @"Failed to call stopMeasuring block.");
  }
  return time;
}

- (NSString *)description
{
  NSMutableString *str = [NSMutableString stringWithString:@"Results:\n"];
  for (ASPerformanceTestResult *result in [_results objectEnumerator]) {
    [str appendFormat:@"\t%@\n", result];
  }
  return str;
}

@end
