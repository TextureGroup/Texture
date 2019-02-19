//
//  ASWeakSetTests.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <XCTest/XCTest.h>
#import <AsyncDisplayKit/ASWeakSet.h>

@interface ASWeakSetTests : XCTestCase

@end

@implementation ASWeakSetTests

- (void)testAddingACoupleRetainedObjects
{
  ASWeakSet <NSString *> *weakSet = [ASWeakSet new];
  NSString *hello = @"hello";
  NSString *world = @"hello";
  [weakSet addObject:hello];
  [weakSet addObject:world];
  XCTAssert([weakSet containsObject:hello]);
  XCTAssert([weakSet containsObject:world]);
  XCTAssert(![weakSet containsObject:@"apple"]);
}

- (void)testThatCountIncorporatesDeallocatedObjects
{
  ASWeakSet *weakSet = [ASWeakSet new];
  XCTAssertEqual(weakSet.count, 0);
  NSObject *a = [NSObject new];
  NSObject *b = [NSObject new];
  [weakSet addObject:a];
  [weakSet addObject:b];
  XCTAssertEqual(weakSet.count, 2);

  @autoreleasepool {
    NSObject *doomedObject = [NSObject new];
    [weakSet addObject:doomedObject];
    XCTAssertEqual(weakSet.count, 3);
  }

  XCTAssertEqual(weakSet.count, 2);
}

- (void)testThatIsEmptyIncorporatesDeallocatedObjects
{
  ASWeakSet *weakSet = [ASWeakSet new];
  XCTAssertTrue(weakSet.isEmpty);
  @autoreleasepool {
    NSObject *doomedObject = [NSObject new];
    [weakSet addObject:doomedObject];
    XCTAssertFalse(weakSet.isEmpty);
  }
  XCTAssertTrue(weakSet.isEmpty);
}

- (void)testThatContainsObjectWorks
{
  ASWeakSet *weakSet = [ASWeakSet new];
  NSObject *a = [NSObject new];
  NSObject *b = [NSObject new];
  [weakSet addObject:a];
  XCTAssertTrue([weakSet containsObject:a]);
  XCTAssertFalse([weakSet containsObject:b]);
}

- (void)testThatRemoveObjectWorks
{
  ASWeakSet *weakSet = [ASWeakSet new];
  NSObject *a = [NSObject new];
  NSObject *b = [NSObject new];
  [weakSet addObject:a];
  [weakSet addObject:b];
  XCTAssertTrue([weakSet containsObject:a]);
  XCTAssertTrue([weakSet containsObject:b]);
  XCTAssertEqual(weakSet.count, 2);

  [weakSet removeObject:b];
  XCTAssertTrue([weakSet containsObject:a]);
  XCTAssertFalse([weakSet containsObject:b]);
  XCTAssertEqual(weakSet.count, 1);
}

- (void)testThatFastEnumerationWorks
{
  ASWeakSet *weakSet = [ASWeakSet new];
  NSObject *a = [NSObject new];
  NSObject *b = [NSObject new];
  [weakSet addObject:a];
  [weakSet addObject:b];

  @autoreleasepool {
    NSObject *doomedObject = [NSObject new];
    [weakSet addObject:doomedObject];
    XCTAssertEqual(weakSet.count, 3);
  }

  NSInteger i = 0;
  NSMutableSet *awaitingObjects = [NSMutableSet setWithObjects:a, b, nil];
  for (NSObject *object in weakSet) {
    XCTAssertTrue([awaitingObjects containsObject:object]);
    [awaitingObjects removeObject:object];
    i += 1;
  }

  XCTAssertEqual(i, 2);
}

- (void)testThatRemoveAllObjectsWorks
{
  ASWeakSet *weakSet = [ASWeakSet new];
  NSObject *a = [NSObject new];
  NSObject *b = [NSObject new];
  [weakSet addObject:a];
  [weakSet addObject:b];
  XCTAssertEqual(weakSet.count, 2);

  [weakSet removeAllObjects];

  XCTAssertEqual(weakSet.count, 0);

  NSInteger i = 0;
  for (__unused NSObject *object in weakSet) {
    i += 1;
  }

  XCTAssertEqual(i, 0);
}

@end
