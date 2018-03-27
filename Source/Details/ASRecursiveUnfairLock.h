//
//  ASRecursiveUnfairLock.h
//  AsyncDisplayKit
//
//  Created by Adlai on 3/27/18.
//  Copyright © 2018 Pinterest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <pthread/pthread.h>
#import <os/lock.h>
#import <stdatomic.h>

__IOS_AVAILABLE(10.0)
typedef struct {
  os_unfair_lock lock;
  _Atomic(pthread_t) thread;
  int count;                  // Protected by lock
} ASRecursiveUnfairLock;

CF_EXTERN_C_BEGIN

#define AS_RECURSIVE_UNFAIR_LOCK_INIT ((ASRecursiveUnfairLock){ OS_UNFAIR_LOCK_INIT, ATOMIC_VAR_INIT(NULL), 0})

__IOS_AVAILABLE(10.0)
void ASRecursiveUnfairLockLock(ASRecursiveUnfairLock *l);

__IOS_AVAILABLE(10.0)
BOOL ASRecursiveUnfairLockTryLock(ASRecursiveUnfairLock *l);

/**
 * Unlock. Calling this on a thread that does not own
 * the lock will result in an assertion failure, and undefined
 * behavior if foundation assertions are disabled.
 */
__IOS_AVAILABLE(10.0)
void ASRecursiveUnfairLockUnlock(ASRecursiveUnfairLock *l);

CF_EXTERN_C_END
