//
//  ASTransactionTests.m
//  AsyncDisplayKitTests
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASTestCase.h"
#import <AsyncDisplayKit/AsyncDisplayKit.h>

@interface ASTransactionTests : ASTestCase

@end

@implementation ASTransactionTests

- (void)testWeak
{
  __weak _ASAsyncTransaction* weakTransaction = nil;
  @autoreleasepool {
    CALayer *layer = [[CALayer alloc] init];
    _ASAsyncTransaction *transaction = layer.asyncdisplaykit_asyncTransaction;

    weakTransaction = transaction;
    layer = nil;
  }

  // held by main transaction group
  XCTAssertNotNil(weakTransaction);

  // run so that transaction group drains.
  static NSTimeInterval delay = 0.1;
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:delay]];

  XCTAssertNil(weakTransaction);
}

- (void)testWeakWhenCancelled
{
  __weak _ASAsyncTransaction* weakTransaction = nil;
  @autoreleasepool {
    CALayer *layer = [[CALayer alloc] init];
    _ASAsyncTransaction *transaction = layer.asyncdisplaykit_asyncTransaction;

    weakTransaction = transaction;

    [layer asyncdisplaykit_cancelAsyncTransactions];
    layer = nil;
  }

  XCTAssertNil(weakTransaction);
}

- (void)testWeakWithSingleOperation
{
  __weak _ASAsyncTransaction* weakTransaction = nil;
  @autoreleasepool {
    CALayer *layer = [[CALayer alloc] init];
    _ASAsyncTransaction *transaction = layer.asyncdisplaykit_asyncTransaction;

    [transaction addOperationWithBlock:^id<NSObject> _Nullable{
      return nil;
    } priority:1
                                 queue:dispatch_get_main_queue()
                            completion:^(id  _Nullable value, BOOL canceled) {
                              ;
                            }];

    weakTransaction = transaction;
    layer = nil;
  }

  // held by main transaction group
  XCTAssertNotNil(weakTransaction);

  // run so that transaction group drains.
  static NSTimeInterval delay = 0.1;
  [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:delay]];

  XCTAssertNil(weakTransaction);
}

@end
