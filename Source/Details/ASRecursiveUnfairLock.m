//
//  ASRecursiveUnfairLock.m
//  AsyncDisplayKit
//
//  Created by Adlai on 3/27/18.
//  Copyright © 2018 Pinterest. All rights reserved.
//

#import "ASRecursiveUnfairLock.h"

#define rul_set_thread(l, t) atomic_store_explicit(&l->thread, t, memory_order_release)
#define rul_get_thread(l) atomic_load_explicit(&l->thread, memory_order_acquire)

void ASRecursiveUnfairLockLock(ASRecursiveUnfairLock *l)
{
  // Just a cache for pthread_self so that we never call it twice.
  pthread_t s = NULL;
  
  // Try to lock without blocking. If we fail, check what thread owns it.
  // Note that the owning thread CAN CHANGE freely, but it can't become `self`
  // because only we are `self`. So the value of (thread != self) cannot change on us.
  
  if (!os_unfair_lock_trylock(&l->lock) && (rul_get_thread(l) != (s = pthread_self()))) {
    // Owned by other thread. Possibly other threads are waiting too. Block.
    os_unfair_lock_lock(&l->lock);
  }
  // Now we've got the lock. Update the thread pointer and count.
  rul_set_thread(l, s ?: pthread_self());
  l->count++;
}

BOOL ASRecursiveUnfairLockTryLock(ASRecursiveUnfairLock *l)
{
  // Just a cache for pthread_self so that we never call it twice.
  pthread_t s = NULL;
  
  // Try to lock without blocking. If we fail, check what thread owns it.
  // Note that the owning thread CAN CHANGE freely, but it can't become `self`
  // because only we are `self`. So the value of (thread != self) cannot change on us.
  if (!os_unfair_lock_trylock(&l->lock) && (rul_get_thread(l) != (s = pthread_self()))) {
    // Owned by other thread. Fail.
    return NO;
  }
  // Now we've got the lock. Update the thread pointer and count.
  rul_set_thread(l, s ?: pthread_self());
  l->count++;
  return YES;
}

void ASRecursiveUnfairLockUnlock(ASRecursiveUnfairLock *l)
{
  // Ensure we have the lock. This check may miss some pathological cases,
  // but it'll catch 99.999999% of this serious programmer error.
  NSCAssert(rul_get_thread(l) == pthread_self(), @"Unlocking from a different thread than locked.");
  
  if (0 == --l->count) {
    // Note that we have to clear this before unlocking because, if another thread
    // succeeds in locking above, but hasn't managed to update _thread, and we
    // try to re-lock, and fail the -tryLock, and read _thread, then we'll mistakenly
    // think that we still own the lock and proceed without blocking.
    rul_set_thread(l, NULL);
    os_unfair_lock_unlock(&l->lock);
  }
}
