//
//  ASRecursiveUnfairLock.m
//  Texture
//
//  Copyright (c) 2018-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASRecursiveUnfairLock.h"

/**
 * For our atomic _thread, we use acquire/release memory order so that we can have
 * the minimum possible constraint on the hardware. The default, `memory_order_seq_cst`
 * demands that there be a total order of all such modifications as seen by all threads.
 * Acquire/release only requires that modifications to this specific atomic are
 * synchronized across acquire/release pairs.
 * http://en.cppreference.com/w/cpp/atomic/memory_order
 *
 * Note also that the unfair_lock involves a thread fence as well, so we don't need to
 * take care of synchronizing other values. Just the thread value.
 */
#define rul_set_thread(l, t) atomic_store_explicit(&l->_thread, t, memory_order_release)
#define rul_get_thread(l) atomic_load_explicit(&l->_thread, memory_order_acquire)

void ASRecursiveUnfairLockLock(ASRecursiveUnfairLock *l)
{
  // Try to lock without blocking. If we fail, check what thread owns it.
  // Note that the owning thread CAN CHANGE freely, but it can't become `self`
  // because only we are `self`. And if it's already `self` then we already have
  // the lock, because we reset it to NULL before we unlock. So (thread == self) is
  // invariant.
  
  const pthread_t s = pthread_self();
  if (os_unfair_lock_trylock(&l->_lock)) {
    // Owned by nobody. We now have the lock. Assign self.
    rul_set_thread(l, s);
  } else if (rul_get_thread(l) == s) {
    // Owned by self (recursive lock). nop.
  } else {
    // Owned by other thread. Block and then set thread to self.
    os_unfair_lock_lock(&l->_lock);
    rul_set_thread(l, s);
  }
  
  l->_count++;
}

BOOL ASRecursiveUnfairLockTryLock(ASRecursiveUnfairLock *l)
{
  // Same as Lock above. See comments there.
  
  const pthread_t s = pthread_self();
  if (os_unfair_lock_trylock(&l->_lock)) {
    // Owned by nobody. We now have the lock. Assign self.
    rul_set_thread(l, s);
  } else if (rul_get_thread(l) == s) {
    // Owned by self (recursive lock). nop.
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
  NSCAssert(rul_get_thread(l) == pthread_self(), @"Unlocking from a different thread than locked.");
  
  if (0 == --l->_count) {
    // Note that we have to clear this before unlocking because, if another thread
    // succeeds in locking above, but hasn't managed to update _thread, and we
    // try to re-lock, and fail the -tryLock, and read _thread, then we'll mistakenly
    // think that we still own the lock and proceed without blocking.
    rul_set_thread(l, NULL);
    os_unfair_lock_unlock(&l->_lock);
  }
}
