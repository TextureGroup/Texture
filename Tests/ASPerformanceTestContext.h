//
//  ASPerformanceTestContext.h
//  Texture
//
//  Copyright (c) 2018-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTestAssertionsImpl.h>
#import <AsyncDisplayKit/ASBaseDefines.h>

#define ASXCTAssertRelativePerformanceInRange(test, caseName, min, max) \
  _XCTPrimitiveAssertLessThanOrEqual(self, test.results[caseName].relativePerformance, @#caseName, max, @#max);\
  _XCTPrimitiveAssertGreaterThanOrEqual(self, test.results[caseName].relativePerformance, @#caseName, min, @#min)

NS_ASSUME_NONNULL_BEGIN

typedef void (^ASTestPerformanceCaseBlock)(NSUInteger i, dispatch_block_t startMeasuring, dispatch_block_t stopMeasuring);

@interface ASPerformanceTestResult : NSObject
@property (nonatomic, readonly) NSTimeInterval timePer1000;
@property (nonatomic, readonly) NSString *caseName;

@property (nonatomic, readonly, getter=isReferenceCase) BOOL referenceCase;
@property (nonatomic, readonly) float relativePerformance;

@property (nonatomic, readonly) NSMutableDictionary *userInfo;
@end

@interface ASPerformanceTestContext : NSObject

/**
 * The first case you add here will be considered the reference case.
 */
- (void)addCaseWithName:(NSString *)caseName block:(AS_NOESCAPE ASTestPerformanceCaseBlock)block;

@property (nonatomic, copy, readonly) NSDictionary<NSString *, ASPerformanceTestResult *> *results;

- (BOOL)areAllUserInfosEqual;

@end

NS_ASSUME_NONNULL_END
