//
//  ArrayDiffingTests.m
//  Texture
//
//  Created by Levi McCallum on 1/29/16.
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

#import <XCTest/XCTest.h>

#import <AsyncDisplayKit/NSArray+Diffing.h>

@interface NSArray (ArrayDiffingTests)
- (NSIndexSet *)_asdk_commonIndexesWithArray:(NSArray *)array compareBlock:(BOOL (^)(id lhs, id rhs))comparison;
@end

@interface ArrayDiffingTests : XCTestCase

@end

@implementation ArrayDiffingTests

- (void)testDiffingCommonIndexes
{
  NSArray<NSArray *> *tests = @[
    @[
      @[@"bob", @"alice", @"dave"],
      @[@"bob", @"alice", @"dave", @"gary"],
      @[@0, @1, @2]
    ],
    @[
      @[@"bob", @"alice", @"dave"],
      @[@"bob", @"gary", @"dave"],
      @[@0, @2]
    ],
    @[
      @[@"bob", @"alice"],
      @[@"gary", @"dave"],
      @[],
    ],
    @[
      @[@"bob", @"alice", @"dave"],
      @[],
      @[],
    ],
    @[
      @[],
      @[@"bob", @"alice", @"dave"],
      @[],
    ],
  ];

  for (NSArray *test in tests) {
    NSIndexSet *indexSet = [test[0] _asdk_commonIndexesWithArray:test[1] compareBlock:^BOOL(id lhs, id rhs) {
      return [lhs isEqual:rhs];
    }];
    NSMutableIndexSet *mutableIndexSet = [indexSet mutableCopy];
    
    for (NSNumber *index in (NSArray *)test[2]) {
      XCTAssert([indexSet containsIndex:[index integerValue]]);
      [mutableIndexSet removeIndex:[index integerValue]];
    }

    XCTAssert([mutableIndexSet count] == 0, @"Unaccounted deletions: %@", mutableIndexSet);
  }
}

- (void)testDiffingInsertionsAndDeletions {
  NSArray<NSArray *> *tests = @[
      @[
        @[@"bob", @"alice", @"dave"],
        @[@"bob", @"alice", @"dave", @"gary"],
        @[@3],
        @[],
      ],
      @[
        @[@"a", @"b", @"c", @"d"],
        @[@"d", @"c", @"b", @"a"],
        @[@1, @2, @3],
        @[@0, @1, @2],
      ],
      @[
        @[@"bob", @"alice", @"dave"],
        @[@"bob", @"gary", @"alice", @"dave"],
        @[@1],
        @[],
      ],
      @[
        @[@"bob", @"alice", @"dave"],
        @[@"bob", @"alice"],
        @[],
        @[@2],
      ],
      @[
        @[@"bob", @"alice", @"dave"],
        @[],
        @[],
        @[@0, @1, @2],
      ],
      @[
        @[@"bob", @"alice", @"dave"],
        @[@"gary", @"alice", @"dave", @"jack"],
        @[@0, @3],
        @[@0],
      ],
      @[
        @[@"bob", @"alice", @"dave", @"judy", @"lynda", @"tony"],
        @[@"gary", @"bob", @"suzy", @"tony"],
        @[@0, @2],
        @[@1, @2, @3, @4],
      ],
      @[
        @[@"bob", @"alice", @"dave", @"judy"],
        @[@"judy", @"dave", @"alice", @"bob"],
        @[@1, @2, @3],
        @[@0, @1, @2],
      ],
  ];
  
  for (NSArray *test in tests) {
    NSIndexSet *insertions, *deletions;
    [test[0] asdk_diffWithArray:test[1] insertions:&insertions deletions:&deletions];
    NSMutableIndexSet *mutableInsertions = [insertions mutableCopy];
    NSMutableIndexSet *mutableDeletions = [deletions mutableCopy];

    for (NSNumber *index in (NSArray *)test[2]) {
      XCTAssert([mutableInsertions containsIndex:[index integerValue]]);
      [mutableInsertions removeIndex:[index integerValue]];
    }
    for (NSNumber *index in (NSArray *)test[3]) {
      XCTAssert([mutableDeletions containsIndex:[index integerValue]]);
      [mutableDeletions removeIndex:[index integerValue]];
    }

    XCTAssert([mutableInsertions count] == 0, @"Unaccounted insertions: %@", mutableInsertions);
    XCTAssert([mutableDeletions count] == 0, @"Unaccounted deletions: %@", mutableDeletions);
  }
}

@end
