//
//  ASThread.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>

#import <os/lock.h>
#import <pthread.h>

#import <AsyncDisplayKit/ASAssert.h>
#import <AsyncDisplayKit/ASAvailability.h>
#import <AsyncDisplayKit/ASBaseDefines.h>
#import <AsyncDisplayKit/ASConfigurationInternal.h>
#import <AsyncDisplayKit/ASLog.h>
#import <AsyncDisplayKit/ASObjectDescriptionHelpers.h>
#import <AsyncDisplayKit/ASRecursiveUnfairLock.h>

ASDISPLAYNODE_INLINE AS_WARN_UNUSED_RESULT BOOL ASDisplayNodeThreadIsMain()
{
  return 0 != pthread_main_np();
}

/**
 * Adds the lock to the current scope.
 *
 * A C version of the C++ lockers. Pass in any id<NSLocking>.
 * One benefit this has over C++ lockers is that the lock is retained. We
 * had bugs in the past where an object would be deallocated while someone
 * had locked its instanceLock, and we'd get a crash. This macro
 * retains the locked object until it can be unlocked, which is nice.
 */
#define ASLockScope(nsLocking) \
  id<NSLocking> __lockToken __attribute__((cleanup(_ASLockScopeCleanup))) NS_VALID_UNTIL_END_OF_SCOPE = nsLocking; \
  [__lockToken lock];

/// Same as ASLockScope(1) but lock isn't retained (be careful).
#define ASLockScopeUnowned(nsLocking) \
  unowned id<NSLocking> __lockToken __attribute__((cleanup(_ASLockScopeUnownedCleanup))) = nsLocking; \
  [__lockToken lock];

ASDISPLAYNODE_INLINE void _ASLockScopeCleanup(id<NSLocking> __strong * const lockPtr) {
  [*lockPtr unlock];
}

ASDISPLAYNODE_INLINE void _ASLockScopeUnownedCleanup(id<NSLocking> unowned * const lockPtr) {
  [*lockPtr unlock];
}

/**
 * Same as ASLockScope(1) but it uses self, so we can skip retain/release.
 */
#define ASLockScopeSelf() ASLockScopeUnowned(self)

/// One-liner while holding the lock.
#define ASLocked(nsLocking, expr) ({ ASLockScope(nsLocking); expr; })

/// Faster self-version.
#define ASLockedSelf(expr) ({ ASLockScopeSelf(); expr; })

#define ASLockedSelfCompareAssign(lvalue, newValue) \
  ASLockedSelf(ASCompareAssign(lvalue, newValue))

#define ASLockedSelfCompareAssignObjects(lvalue, newValue) \
  ASLockedSelf(ASCompareAssignObjects(lvalue, newValue))

#define ASLockedSelfCompareAssignCustom(lvalue, newValue, isequal) \
  ASLockedSelf(ASCompareAssignCustom(lvalue, newValue, isequal))

#define ASLockedSelfCompareAssignCopy(lvalue, obj) \
  ASLockedSelf(ASCompareAssignCopy(lvalue, obj))

#define ASUnlockScope(nsLocking) \
  id<NSLocking> __lockToken __attribute__((cleanup(_ASUnlockScopeCleanup))) NS_VALID_UNTIL_END_OF_SCOPE = nsLocking; \
  [__lockToken unlock];

#define ASSynthesizeLockingMethodsWithMutex(mutex) \
- (void)lock { mutex.lock(); } \
- (void)unlock { mutex.unlock(); } \
- (BOOL)tryLock { return (BOOL)mutex.try_lock(); }

#define ASSynthesizeLockingMethodsWithObject(object) \
- (void)lock { [object lock]; } \
- (void)unlock { [object unlock]; } \
- (BOOL)tryLock { return [object tryLock]; }

ASDISPLAYNODE_INLINE void _ASUnlockScopeCleanup(id<NSLocking> __strong *lockPtr) {
  [*lockPtr lock];
}

#ifdef __cplusplus

#include <memory>
#include <mutex>
#include <new>
#include <thread>

// These macros are here for legacy reasons. We may get rid of them later.
#define DISABLED_ASAssertLocked(m)
#define DISABLED_ASAssertUnlocked(m)

namespace AS {
  
  // Set once in Mutex constructor. Linker fails if this is a member variable. ??
  static bool gMutex_unfair;

// Silence unguarded availability warnings in here, because
// perf is critical and we will check availability once
// and not again.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
  class Mutex
  {
  public:
    /// Constructs a plain mutex (the default).
    Mutex () : Mutex (false) {}

    void SetDebugNameWithObject(id object) {
#if ASEnableVerboseLogging && ASDISPLAYNODE_ASSERTIONS_ENABLED
      _debug_name = std::string(ASObjectDescriptionMakeTiny(object).UTF8String);
#endif
    }

    ~Mutex () {
      // Manually destroy since unions can't do it.
      switch (_type) {
        case Plain:
          _plain.~mutex();
          break;
        case Recursive:
          _recursive.~recursive_mutex();
          break;
        case Unfair:
          // nop
          break;
        case RecursiveUnfair:
          // nop
          break;
      }
    }

    Mutex (const Mutex&) = delete;
    Mutex &operator=(const Mutex&) = delete;

    bool try_lock() {
      bool success = false;
      switch (_type) {
        case Plain:
          success = _plain.try_lock();
          break;
        case Recursive:
          success = _recursive.try_lock();
          break;
        case Unfair:
          success = os_unfair_lock_trylock(&_unfair);
          break;
        case RecursiveUnfair:
          if (@available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *)) {
            success = ASRecursiveUnfairLockTryLock(&_runfair);
          } else {
            success = _recursive.try_lock();
          }
          break;
      }
      if (success) {
        DidLock();
      }
      return success;
    }
    
    void lock() {
      switch (_type) {
        case Plain:
          _plain.lock();
          break;
        case Recursive:
          _recursive.lock();
          break;
        case Unfair:
          os_unfair_lock_lock(&_unfair);
          break;
        case RecursiveUnfair:
          if (@available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *)) {
            ASRecursiveUnfairLockLock(&_runfair);
          } else {
            _recursive.lock();
          }
          break;
      }
      DidLock();
    }

    void unlock() {
      WillUnlock();
      switch (_type) {
        case Plain:
          _plain.unlock();
          break;
        case Recursive:
          _recursive.unlock();
          break;
        case Unfair:
          os_unfair_lock_unlock(&_unfair);
          break;
        case RecursiveUnfair:
          if (@available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *)) {
            ASRecursiveUnfairLockUnlock(&_runfair);
          } else {
            _recursive.unlock();
          }
          break;
      }
    }

    void AssertHeld() {
      ASDisplayNodeCAssert(_owner == std::this_thread::get_id(), @"Thread should hold lock");
    }
    
    void AssertNotHeld() {
      ASDisplayNodeCAssert(_owner != std::this_thread::get_id(), @"Thread should not hold lock");
    }
    
    explicit Mutex (bool recursive) {
      
      // Check if we can use unfair lock and store in static var.
      static dispatch_once_t onceToken;
      dispatch_once(&onceToken, ^{
        if (AS_AVAILABLE_IOS_TVOS(10, 10)) {
          gMutex_unfair = YES;
        }
      });
      
      if (recursive) {
        if (gMutex_unfair) {
          _type = RecursiveUnfair;
          if (@available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *)) {
            _runfair = AS_RECURSIVE_UNFAIR_LOCK_INIT;
          } else {
            new (&_recursive) std::recursive_mutex();
          }
        } else {
          _type = Recursive;
          new (&_recursive) std::recursive_mutex();
        }
      } else {
        if (gMutex_unfair) {
          _type = Unfair;
          _unfair = OS_UNFAIR_LOCK_INIT;
        } else {
          _type = Plain;
          new (&_plain) std::mutex();
        }
      }
    }
    
  private:
    enum Type {
      Plain,
      Recursive,
      Unfair,
      RecursiveUnfair
    };

    void WillUnlock() {
#if ASDISPLAYNODE_ASSERTIONS_ENABLED
#if ASEnableVerboseLogging
      if (!_debug_name.empty()) {
        as_log_verbose(ASLockingLog(), "unlock %s, count is %d", _debug_name.c_str(), (int)(_count - 1));
      }
#endif
      if (--_count == 0) {
        _owner = std::thread::id();
      }
#endif
    }
    
    void DidLock() {
#if ASDISPLAYNODE_ASSERTIONS_ENABLED
#if ASEnableVerboseLogging
      if (!_debug_name.empty()) {
        as_log_verbose(ASLockingLog(), "lock %s, count is %d", _debug_name.c_str(), (int)(_count + 1));
      }
#endif
      if (++_count == 1) {
        // New owner.
        _owner = std::this_thread::get_id();
      }
#endif
    }
    
    Type _type;
    union {
      os_unfair_lock _unfair;
      ASRecursiveUnfairLock _runfair;
      std::mutex _plain;
      std::recursive_mutex _recursive;
    };
#if ASEnableVerboseLogging
    std::string _debug_name;
#endif

#if ASDISPLAYNODE_ASSERTIONS_ENABLED
    std::thread::id _owner = std::thread::id();
    int _count = 0;
#endif
  };
#pragma clang diagnostic pop // ignored "-Wunguarded-availability"
  
  /**
   Obj-C doesn't allow you to pass parameters to C++ ivar constructors.
   Provide a convenience to change the default from non-recursive to recursive.

   But wait! Recursive mutexes are a bad idea. Think twice before using one:

   http://www.zaval.org/resources/library/butenhof1.html
   http://www.fieryrobot.com/blog/2008/10/14/recursive-locks-will-kill-you/
   */
  class RecursiveMutex : public Mutex
  {
  public:
    RecursiveMutex () : Mutex (true) {}
  };

  typedef std::lock_guard<Mutex> MutexLocker;
  typedef std::unique_lock<Mutex> UniqueLock;

} // namespace AS

#endif /* __cplusplus */
