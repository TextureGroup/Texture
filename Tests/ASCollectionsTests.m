//
//  ASCollectionsTests.m
//  Texture
//
//  Copyright (c) 2018-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <XCTest/XCTest.h>
#import <AsyncDisplayKit/ASCollections.h>

@interface ASCollectionsTests : XCTestCase

@end

@implementation ASCollectionsTests

- (void)testTransferArray {
  id objs[2];
  objs[0] = [NSObject new];
  id o0 = objs[0];
  objs[1] = [NSObject new];
  __weak id w0 = objs[0];
  __weak id w1 = objs[1];
  CFTypeRef cf0 = (__bridge CFTypeRef)objs[0];
  CFTypeRef cf1 = (__bridge CFTypeRef)objs[1];
  XCTAssertEqual(CFGetRetainCount(cf0), 2);
  XCTAssertEqual(CFGetRetainCount(cf1), 1);
  NSArray *arr = [NSArray arrayByTransferring:objs count:2];
  XCTAssertNil(objs[0]);
  XCTAssertNil(objs[1]);
  XCTAssertEqual(CFGetRetainCount(cf0), 2);
  XCTAssertEqual(CFGetRetainCount(cf1), 1);
  NSArray *immutableCopy = [arr copy];
  XCTAssertEqual(immutableCopy, arr);
  XCTAssertEqual(CFGetRetainCount(cf0), 2);
  XCTAssertEqual(CFGetRetainCount(cf1), 1);
  NSMutableArray *mc = [arr mutableCopy];
  XCTAssertEqual(CFGetRetainCount(cf0), 3);
  XCTAssertEqual(CFGetRetainCount(cf1), 2);
  arr = nil;
  immutableCopy = nil;
  XCTAssertEqual(CFGetRetainCount(cf0), 2);
  XCTAssertEqual(CFGetRetainCount(cf1), 1);
  [mc removeObjectAtIndex:0];
  XCTAssertEqual(CFGetRetainCount(cf0), 1);
  XCTAssertEqual(CFGetRetainCount(cf1), 1);
  [mc removeObjectAtIndex:0];
  XCTAssertEqual(CFGetRetainCount(cf0), 1);
  XCTAssertNil(w1);
  o0 = nil;
  XCTAssertNil(w0);
}

@end
