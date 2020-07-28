//
//  ASRecursiveUnfairLock.mm
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASRecursiveUnfairLock.h"

#import <stdatomic.h>

/**
 * Since the lock itself is a memory barrier, we only need memory_order_relaxed for our
 * thread atomic. That guarantees we won't have torn writes, but otherwise no ordering
 * is required.
 */
#define rul_set_thread(l, t) atomic_store_explicit(&l->_thread, t, memory_order_relaxed)
#define rul_get_thread(l) atomic_load_explicit(&l->_thread, memory_order_relaxed)

OS_UNFAIR_LOCK_AVAILABILITY
NS_INLINE void ASRecursiveUnfairLockDidAcquire(ASRecursiveUnfairLock *l, pthread_t tid) {
  NSCAssert(pthread_equal(rul_get_thread(l), NULL) && l->_count == 0, @"Unfair lock error");
  rul_set_thread(l, tid);
}

OS_UNFAIR_LOCK_AVAILABILITY
NS_INLINE void ASRecursiveUnfairLockWillRelease(ASRecursiveUnfairLock *l) {
  NSCAssert(pthread_equal(rul_get_thread(l), pthread_self()) && l->_count == 0, @"Unfair lock error");
  rul_set_thread(l, NULL);
}

OS_UNFAIR_LOCK_AVAILABILITY
NS_INLINE void ASRecursiveUnfairLockAssertHeld(ASRecursiveUnfairLock *l) {
  NSCAssert(pthread_equal(rul_get_thread(l), pthread_self()) && l->_count > 0, @"Unfair lock error");
}

void ASRecursiveUnfairLockLock(ASRecursiveUnfairLock *l)
{
  // Try to lock without blocking. If we fail, check what thread owns it.
  // Note that the owning thread CAN CHANGE freely, but if the thread is specifically `self` then we know
  // it is a recursive call, because we clear it before unlocking, and only `self` can set it
  // to `self`.

  const pthread_t s = pthread_self();
  if (pthread_equal(rul_get_thread(l), s)) {
    // Owned by self (recursive lock.) nop.
    ASRecursiveUnfairLockAssertHeld(l);
  } else {
    os_unfair_lock_lock(&l->_lock);
    ASRecursiveUnfairLockDidAcquire(l, s);
  }

  l->_count++;
}

BOOL ASRecursiveUnfairLockTryLock(ASRecursiveUnfairLock *l) {
  // Same as Lock above. See comments there.
  const pthread_t s = pthread_self();
  if (pthread_equal(rul_get_thread(l), s)) {
    ASRecursiveUnfairLockAssertHeld(l);
  } else if (os_unfair_lock_trylock(&l->_lock)) {
    ASRecursiveUnfairLockDidAcquire(l, s);
  } else {
    // Owned by other thread. Fail.
    return NO;
  }

  l->_count++;
  return YES;
}

void ASRecursiveUnfairLockUnlock(ASRecursiveUnfairLock *l)
{
  // Ensure we have the lock. This check may miss some pathological cases,
  // but it'll catch 99.999999% of this serious programmer error.
  NSCAssert(pthread_equal(rul_get_thread(l), pthread_self()), @"Unlocking from a different thread than locked.");
  
  if (0 == --l->_count) {
    // Note that we have to clear this before unlocking because, if another thread
    // succeeds in locking above, but hasn't managed to update _thread, and we
    // try to re-lock, and fail the -tryLock, and read _thread, then we'll mistakenly
    // think that we still own the lock and proceed without blocking.
    ASRecursiveUnfairLockWillRelease(l);
    os_unfair_lock_unlock(&l->_lock);
  }
}
