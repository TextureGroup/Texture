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
  __unsafe_unretained id<NSLocking> __lockToken __attribute__((cleanup(_ASLockScopeUnownedCleanup))) = nsLocking; \
  [__lockToken lock];

ASDISPLAYNODE_INLINE void _ASLockScopeCleanup(id<NSLocking> __strong * const lockPtr) {
  [*lockPtr unlock];
}

ASDISPLAYNODE_INLINE void _ASLockScopeUnownedCleanup(id<NSLocking> __unsafe_unretained * const lockPtr) {
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

#if DEBUG
#define MUTEX_DEBUG_LOG(msg) if (_debug_name) { as_log_debug(OS_LOG_DEFAULT, "%s: %s", _debug_name, (msg)); }
#else
#define MUTEX_DEBUG_LOG(msg)
#endif

#ifdef __cplusplus

#include <memory>
#include <mutex>
#include <new>
#include <thread>
#include <vector>

// These macros are here for legacy reasons. We may get rid of them later.
#define ASAssertLocked(m) m.AssertHeld()
#define ASAssertUnlocked(m) m.AssertNotHeld()

namespace ASDN {
  
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
          success = ASRecursiveUnfairLockTryLock(&_runfair);
          break;
      }
      if (success) {
        DidLock();
      }
      MUTEX_DEBUG_LOG(success ? "try_lock: pass" : "try_lock: fail");
      return success;
    }
    
    void lock() {
//      MUTEX_DEBUG_LOG("will_lock");
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
          ASRecursiveUnfairLockLock(&_runfair);
          break;
      }
      DidLock();
      MUTEX_DEBUG_LOG("did_lock");
    }

    void unlock() {
      MUTEX_DEBUG_LOG("unlock");
      __typeof(_on_unlocks) on_unlocks;
      if (WillUnlock()) {
        on_unlocks = std::move(_on_unlocks);
        _on_unlocks.clear();
      }
      
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
          ASRecursiveUnfairLockUnlock(&_runfair);
          break;
      }

      for (const auto &b : on_unlocks) {
        AssertNotHeld();
        b.second(b.first);
      }
    }

    void AssertHeld() {
      ASDisplayNodeCAssert(_owner == std::this_thread::get_id(), @"Thread should hold lock");
    }
    
    void AssertNotHeld() {
      ASDisplayNodeCAssert(_owner != std::this_thread::get_id(), @"Thread should not hold lock");
    }
    
    // Perform the given block when
    void OnUnlock(id owner, void (^block)(id owner)) {
      AssertHeld();
      _on_unlocks.emplace_back(owner, block);
    }
    
    explicit Mutex (bool recursive) {
      
      // Check if we can use unfair lock and store in static var.
      static dispatch_once_t onceToken;
      dispatch_once(&onceToken, ^{
        if (AS_AVAILABLE_IOS_TVOS(10, 10)) {
          gMutex_unfair = ASActivateExperimentalFeature(ASExperimentalUnfairLock);
        }
      });
      
      if (recursive) {
        if (gMutex_unfair) {
          _type = RecursiveUnfair;
          _runfair = AS_RECURSIVE_UNFAIR_LOCK_INIT;
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
    
#if DEBUG
    void EnableDebugLogging(const char *name) {
      _debug_name = name;
    }
#endif

  private:
    enum Type {
      Plain,
      Recursive,
      Unfair,
      RecursiveUnfair
    };

    // returns true if this will be the final unlock (non-recursive)
    bool WillUnlock() {
      AssertHeld();
      _count -= 1;
#if ASDISPLAYNODE_ASSERTIONS_ENABLED
      if (_count == 0) {
        _owner = std::thread::id();
      }
#endif
      return (_count == 0);
    }
    
    void DidLock() {
      _count += 1;
#if ASDISPLAYNODE_ASSERTIONS_ENABLED
      if (_count == 1) {
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
    std::vector<std::pair<unowned id, void(^)(id)>> _on_unlocks;
#if ASDISPLAYNODE_ASSERTIONS_ENABLED
    std::thread::id _owner;
#endif
#if DEBUG
    const char *_debug_name = nullptr;
#endif
    int _count = 0;
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

} // namespace ASDN

#endif /* __cplusplus */
