//
//  ASLocking.h
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * An extension of NSLocking that supports -tryLock.
 */
@protocol ASLocking <NSLocking>

/// Try to take lock without blocking. Returns whether the lock was taken.
- (BOOL)tryLock;

@end

/**
 * These Foundation classes already implement -tryLock.
 */
@interface NSLock (ASLocking) <ASLocking>
@end

@interface NSRecursiveLock (ASLocking) <ASLocking>
@end

@interface NSConditionLock (ASLocking) <ASLocking>
@end

NS_ASSUME_NONNULL_END

#ifdef __cplusplus

#include <array>
#include <mutex>
#include <thread>
#include <utility>
#include <vector>

#import <AsyncDisplayKit/ASThread.h>

NS_ASSUME_NONNULL_BEGIN

namespace AS {

/**
 * A helper class for locking multiple mutexes safely in sequence. Usage is like this:
 *
 * LockSet locks;
 * while (locks.empty()) {
 *   if (!locks.TryAdd(my_object_1, my_object_1->__instanceLock__)) continue;
 *   // my_object_1 is now locked. If it failed to add, `locks` is now empty.
 *   // Additionally, my_object_1 is retained by the set.
 *   if (!locks.TryAdd(my_object_2, my_object_2->__instanceLock__)) continue;
 *   // my_object_2 is now also locked and retained.
 * }
 * // Once we're here, `locks` contains locks and retains on both objects. Either
 * // wait for the object to go out of scope, or explicitly call Clear() to release
 * // everything.
 */
class LockSet {
public:
  // Note that destruction order matters here. The UniqueLock must be destroyed before the owner is released.
  typedef std::pair<id, AS::UniqueLock> OwnedLock;

  LockSet() = default;
  ~LockSet() = default;

  // Move is allowed.
  LockSet(LockSet &&locks) = default;
  LockSet &operator=(LockSet &&locks) = default;

  bool empty() const { return inline_locks_count_ == 0; }

  /**
   * Attempt to add a lock on the given mutex to the set. Returns whether
   * a lock was successfully added. If this function returns false, the lock set
   * is reset. Your while loop should `continue` if this function returns false.
   *
   * On success, the owner will also be retained by the lock set, to avoid issues with
   * objects being deallocated while locked.
   *
   * Linter note: We suppress linting the function signature because it takes a
   * non-const reference which is unusual, but in keeping with the pattern from
   * the constructor for std::unique_lock, which is analogous to this function.
   */
  // NOLINTNEXTLINE
  bool TryAdd(__unsafe_unretained id owner, AS::Mutex &mutex) {
    std::unique_lock<AS::Mutex> l(mutex, std::try_to_lock);
    if (!l.owns_lock()) {
      clear();
      std::this_thread::yield();
      return false;
    }

    if (inline_locks_count_ < inline_locks_.size()) {
      inline_locks_[inline_locks_count_++] = OwnedLock(owner, std::move(l));
    } else {
      overflow_locks_.push_back(OwnedLock(owner, std::move(l)));
    }
    return true;
  }

  /**
   * Unlock all locks in the set, release their owners. After this call the set will be empty.
   */
  void clear() {
    for (auto it = inline_locks_.begin(), end = it + inline_locks_count_; it != end; ++it) {
      *it = OwnedLock();
    }
    inline_locks_count_ = 0;
    overflow_locks_.clear();
  }

private:
  static constexpr size_t kInlineLocksCapacity = 16;
  size_t inline_locks_count_ = 0;
  std::array<OwnedLock, kInlineLocksCapacity> inline_locks_;
  std::vector<OwnedLock> overflow_locks_;
};

} // namespace AS

NS_ASSUME_NONNULL_END

#endif  // __cplusplus
