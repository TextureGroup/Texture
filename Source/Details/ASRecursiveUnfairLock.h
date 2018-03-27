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

#define AS_RECURSIVE_UNFAIR_LOCK_INIT ((ASRecursiveUnfairLock){ OS_UNFAIR_LOCK_INIT, ATOMIC_VAR_INIT(NULL), 0})

NS_ASSUME_NONNULL_BEGIN

OS_UNFAIR_LOCK_AVAILABILITY
typedef struct {
  os_unfair_lock _lock;
  _Atomic(pthread_t) _thread;
  int _count;                  // Protected by lock
} ASRecursiveUnfairLock;

CF_EXTERN_C_BEGIN

/**
 * Lock, blocking if needed.
 */
OS_UNFAIR_LOCK_AVAILABILITY
void ASRecursiveUnfairLockLock(ASRecursiveUnfairLock *l);

/**
 * Try to lock without blocking. Returns whether we took the lock.
 */
OS_UNFAIR_LOCK_AVAILABILITY
BOOL ASRecursiveUnfairLockTryLock(ASRecursiveUnfairLock *l);

/**
 * Unlock. Calling this on a thread that does not own
 * the lock will result in an assertion failure, and undefined
 * behavior if foundation assertions are disabled.
 */
OS_UNFAIR_LOCK_AVAILABILITY
void ASRecursiveUnfairLockUnlock(ASRecursiveUnfairLock *l);

CF_EXTERN_C_END

NS_ASSUME_NONNULL_END
