//
//  ASLocking.h
//  Texture
//
//  Copyright (c) 2018-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>
#import <pthread/sched.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ASLocking <NSLocking>

/// Try to take lock without blocking. Returns whether the lock was taken.
- (BOOL)tryLock;

@end

/**
 * Take multiple locks "simultaneously," avoiding deadlocks
 * caused by lock ordering.
 *
 * We use an explicit count argument to handle nil locks.
 * If you pass a nil lock, obviously we ignore it.
 *
 * TODO: Implement a scoped version. The scope variable would be
 * a struct containing the lock count and the locks to unlock.
 */
NS_INLINE void ASLockMany(unsigned count, id<ASLocking> _Nullable arg0, ...) {
  if (count == 0) {
    return;
  }
  
  BOOL done = NO;
  while (!done) {
    // Don't retain/release locks. Arguments are retained by caller.
    __unsafe_unretained id<ASLocking> ownedLocks[count];
    va_list locks;
    va_start(locks, arg0);
    for (int i = 0; i < count; i++) {
      __unsafe_unretained id<ASLocking> lock = va_arg(locks, id<ASLocking>);
      
      // Attempt to lock, or pass if nil.
      BOOL locked = (lock ? [lock tryLock] : YES);
      
      if (!locked) {
        // If we failed to lock, release what we have, yield, and start over.
        for (int j = 0; j < i; j++) {
          [ownedLocks[j] unlock];
        }
        sched_yield();
        break;
      } else if (i == count - 1) {
        // If we suceeded and this was the last, we're done.
        done = YES;
      } else {
        // Otherwise note that we have this lock and keep going.
        ownedLocks[i] = lock;
      }
    }
    va_end(locks);
  }
}

NS_INLINE void ASUnlockMany(unsigned count, id<NSLocking> arg0, ...)
{
  va_list locks;
  va_start(locks, arg0);
  for (int i = 0; i < count; i++) {
    __unsafe_unretained id<ASLocking> lock = va_arg(locks, id<ASLocking>);
    [lock unlock];
  }
  va_end(locks);
}

@interface NSLock (ASLocking) <ASLocking>
@end

@interface NSRecursiveLock (ASLocking) <ASLocking>
@end

@interface NSConditionLock (ASLocking) <ASLocking>
@end

NS_ASSUME_NONNULL_END
