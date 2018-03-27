//
//  ASRecursiveUnfairLockTests.m
//  AsyncDisplayKitTests
//
//  Created by Adlai on 3/27/18.
//  Copyright © 2018 Pinterest. All rights reserved.
//

#import "ASTestCase.h"
#import <AsyncDisplayKit/ASRecursiveUnfairLock.h>
#import <stdatomic.h>

@interface ASRecursiveUnfairLockTests : ASTestCase

@end

@implementation ASRecursiveUnfairLockTests {
  ASRecursiveUnfairLock lock;
}

- (void)setUp
{
  [super setUp];
  lock = AS_RECURSIVE_UNFAIR_LOCK_INIT;
}

- (void)testTheAtomicIsLockFree
{
  XCTAssertTrue(atomic_is_lock_free(&lock._thread));
}

- (void)testRelockingFromSameThread
{
  ASRecursiveUnfairLockLock(&lock);
  ASRecursiveUnfairLockLock(&lock);
  ASRecursiveUnfairLockUnlock(&lock);
  // Now try locking from another thread.
  XCTestExpectation *e1 = [self expectationWithDescription:@"Other thread tried lock."];
  [NSThread detachNewThreadWithBlock:^{
    XCTAssertFalse(ASRecursiveUnfairLockTryLock(&self->lock));
    [e1 fulfill];
  }];
  [self waitForExpectationsWithTimeout:1 handler:nil];
  ASRecursiveUnfairLockUnlock(&lock);
  
  XCTestExpectation *e2 = [self expectationWithDescription:@"Other thread tried lock again"];
  [NSThread detachNewThreadWithBlock:^{
    XCTAssertTrue(ASRecursiveUnfairLockTryLock(&self->lock));
    ASRecursiveUnfairLockUnlock(&self->lock);
    [e2 fulfill];
  }];
  [self waitForExpectationsWithTimeout:1 handler:nil];
}

- (void)testThatUnlockingWithoutHoldingAsserts
{
#ifdef NS_BLOCK_ASSERTIONS
#warning Assertions should be on for `testThatUnlockingWithoutHoldingAsserts`
  NSLog(@"Passing because assertions are off.");
#else
  ASRecursiveUnfairLockLock(&lock);
  XCTestExpectation *e1 = [self expectationWithDescription:@"Other thread tried lock."];
  [NSThread detachNewThreadWithBlock:^{
    XCTAssertThrows(ASRecursiveUnfairLockUnlock(&lock));
    [e1 fulfill];
  }];
  [self waitForExpectationsWithTimeout:10 handler:nil];
  ASRecursiveUnfairLockUnlock(&lock);
#endif
}

#define CHAOS_TEST_BODY(prefix, infix, postfix) \
for (int i = 0; i < 16; i++) {\
dispatch_group_enter(g);\
[NSThread detachNewThreadWithBlock:^{\
  for (int i = 0; i < 10000; i++) {\
    prefix;\
    *valuePtr += 150;\
    infix;\
    *valuePtr -= 150;\
    postfix;\
  }\
  dispatch_group_leave(g);\
}];\
}\
dispatch_group_wait(g, DISPATCH_TIME_FOREVER);

- (void)testChaos
{
  // First try without the lock and assert that the value
  // is corrupted.
  int value = 0;
  int * const valuePtr = &value;
  dispatch_group_t g = dispatch_group_create();
  CFTimeInterval startNoLock = CACurrentMediaTime();
  CHAOS_TEST_BODY({}, {}, {});
  CFTimeInterval noLockDuration = CACurrentMediaTime() - startNoLock;
  XCTAssertNotEqual(value, 0);
  
  // Then try with our lock.
  value = 0;
  CFTimeInterval startWithLock = CACurrentMediaTime();
  CHAOS_TEST_BODY(ASRecursiveUnfairLockLock(&lock), {}, ASRecursiveUnfairLockUnlock(&lock));
  CFTimeInterval lockedDuration = CACurrentMediaTime() - startWithLock;
  XCTAssertEqual(value, 0);
  
  // Now try with recursive pthread_mutex
  value = 0;
  pthread_mutexattr_t attr;
  pthread_mutexattr_init (&attr);
  pthread_mutexattr_settype (&attr, PTHREAD_MUTEX_RECURSIVE);
  __block pthread_mutex_t m;
  pthread_mutex_init (&m, &attr);
  pthread_mutexattr_destroy (&attr);
  
  CFTimeInterval startWithMutex = CACurrentMediaTime();
  CHAOS_TEST_BODY(pthread_mutex_lock(&m), {}, pthread_mutex_unlock(&m));
  CFTimeInterval mutexDuration = CACurrentMediaTime() - startWithMutex;
  NSLog(@"Duration no lock %.2fms, with lock %.2fms, mutex %.2fms", noLockDuration * 1000, lockedDuration * 1000, mutexDuration * 1000);
  XCTAssertEqual(value, 0);
}

// Same as `testChaos` but we lock the locks twice, then do one op, then
// unlock once, then another op, then unlock again.
- (void)testChaosRecursiveLock
{
  // First try without the lock and assert that the value
  // is corrupted.
  int value = 0;
  int * const valuePtr = &value;
  dispatch_group_t g = dispatch_group_create();
  CFTimeInterval startNoLock = CACurrentMediaTime();
  CHAOS_TEST_BODY({}, {}, {});
  CFTimeInterval noLockDuration = CACurrentMediaTime() - startNoLock;
  XCTAssertNotEqual(value, 0);
  
  // Then try with our lock.
  value = 0;
  CFTimeInterval startWithLock = CACurrentMediaTime();
  CHAOS_TEST_BODY({ ASRecursiveUnfairLockLock(&lock); ASRecursiveUnfairLockLock(&lock); },
                  ASRecursiveUnfairLockUnlock(&lock),
                  ASRecursiveUnfairLockUnlock(&lock));
  CFTimeInterval lockedDuration = CACurrentMediaTime() - startWithLock;
  XCTAssertEqual(value, 0);
  
  // Now try with recursive pthread_mutex
  value = 0;
  pthread_mutexattr_t attr;
  pthread_mutexattr_init (&attr);
  pthread_mutexattr_settype (&attr, PTHREAD_MUTEX_RECURSIVE);
  __block pthread_mutex_t m;
  pthread_mutex_init (&m, &attr);
  pthread_mutexattr_destroy (&attr);
  
  CFTimeInterval startWithMutex = CACurrentMediaTime();
  CHAOS_TEST_BODY({ pthread_mutex_lock(&m); pthread_mutex_lock(&m); },
                  pthread_mutex_unlock(&m),
                  pthread_mutex_unlock(&m));
  CFTimeInterval mutexDuration = CACurrentMediaTime() - startWithMutex;
  NSLog(@"Duration no lock %.2fms, with lock %.2fms, mutex %.2fms", noLockDuration * 1000, lockedDuration * 1000, mutexDuration * 1000);
  XCTAssertEqual(value, 0);
}

@end
