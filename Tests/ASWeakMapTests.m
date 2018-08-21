//
//  ASWeakMapTests.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <XCTest/XCTest.h>
#import <AsyncDisplayKit/ASWeakMap.h>

NS_ASSUME_NONNULL_BEGIN

@interface ASWeakMapTests : XCTestCase

@end

@implementation ASWeakMapTests

- (void)testKeyAndValueAreReleasedWhenEntryIsReleased
{
  ASWeakMap <NSObject *, NSObject *> *weakMap = [[ASWeakMap alloc] init];

  __weak NSObject *weakKey;
  __weak NSObject *weakValue;
  @autoreleasepool {
    NSObject *key = [[NSObject alloc] init];
    NSObject *value = [[NSObject alloc] init];
    ASWeakMapEntry *entry = [weakMap setObject:value forKey:key];
    XCTAssertEqual([weakMap entryForKey:key], entry);

    weakKey = key;
    weakValue = value;
}
  XCTAssertNil(weakKey);
  XCTAssertNil(weakValue);
}

- (void)testKeyEquality
{
  ASWeakMap <NSString *, NSObject *> *weakMap = [[ASWeakMap alloc] init];
  NSString *keyA = @"key";
  NSString *keyB = [keyA copy];  // `isEqual` but not pointer equal
  NSObject *value = [[NSObject alloc] init];
  
  ASWeakMapEntry *entryA = [weakMap setObject:value forKey:keyA];
  ASWeakMapEntry *entryB = [weakMap entryForKey:keyB];
  XCTAssertEqual(entryA, entryB);
}

@end

NS_ASSUME_NONNULL_END
