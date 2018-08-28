//
//  ASRectMapTests.m
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <XCTest/XCTest.h>

#import "ASRectMap.h"
#import "ASXCTExtensions.h"

@interface ASRectMapTests : XCTestCase
@end

@implementation ASRectMapTests

- (void)testThatItStoresRects
{
  ASRectMap *table = [ASRectMap rectMapForWeakObjectPointers];
  NSObject *key0 = [[NSObject alloc] init];
  NSObject *key1 = [[NSObject alloc] init];
  ASXCTAssertEqualRects([table rectForKey:key0], CGRectNull);
  ASXCTAssertEqualRects([table rectForKey:key1], CGRectNull);
  CGRect rect0 = CGRectMake(0, 0, 100, 100);
  CGRect rect1 = CGRectMake(0, 0, 50, 50);
  [table setRect:rect0 forKey:key0];
  [table setRect:rect1 forKey:key1];

  ASXCTAssertEqualRects([table rectForKey:key0], rect0);
  ASXCTAssertEqualRects([table rectForKey:key1], rect1);
}


- (void)testCopying
{
  ASRectMap *table = [ASRectMap rectMapForWeakObjectPointers];
  NSObject *key = [[NSObject alloc] init];
  ASXCTAssertEqualRects([table rectForKey:key], CGRectNull);
  CGRect rect0 = CGRectMake(0, 0, 100, 100);
  CGRect rect1 = CGRectMake(0, 0, 50, 50);
  [table setRect:rect0 forKey:key];
  ASRectMap *copy = [table copy];
  [copy setRect:rect1 forKey:key];

  ASXCTAssertEqualRects([table rectForKey:key], rect0);
  ASXCTAssertEqualRects([copy rectForKey:key], rect1);
}

@end
