//
//  ASLRUCache.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#pragma once

#include <algorithm>
#include <cstdint>
#include <list>
#include <mutex>
#include <stdexcept>
#include <thread>
#include <unordered_map>

namespace ASDN {

/**
 * LRUCache implements a cache map with an LRU eviction policy.
 *
 * It's templated by:
 *    KeyType - key type
 *    ValueType - value type
 *    LockType - a lock type that satisfies the Lockable concept
 *    MapType - an associative container like std::unordered_map
 *
 * Sizing: The max size is the hard limit of keys and (maxSize + elasticity) is the soft limit the cache
 * is allowed to grow till maxSize + elasticity and is trimmed back to maxSize keys.
 *
 * Threading: By default std::mutex is used as LockType what makes it thread safe. Every
 * LockType that satisfies the Lockable concept is allowed.
 *
 */
template <class KeyType, class ValueType, class LockType = std::mutex,
          class MapType = std::unordered_map<
              KeyType, typename std::list<std::pair<KeyType, ValueType>>::iterator>>
class LRUCache final {
 public:
  typedef std::pair<KeyType, ValueType> node_type;
  typedef std::list<node_type> list_type;
  typedef MapType map_type;
  typedef LockType lock_type;
  using LockGuard = std::lock_guard<lock_type>;

  explicit LRUCache(size_t maxSize = 64, size_t elasticity = 10)
      : maxSize_(maxSize), elasticity_(elasticity) {}
  
  // No moving or copying
  LRUCache(const LRUCache&) = delete;
  LRUCache& operator=(const LRUCache&) = delete;
  LRUCache(LRUCache&&) = delete;
  LRUCache& operator=(LRUCache&&) = delete;
  
  /**
   * Returns the current size of the Cache
   */
  size_t size() const {
    LockGuard g(lock_);
    return cache_.size();
  }
  
  /**
   * Returns if the Cache is empty
   */
  bool empty() const {
    LockGuard g(lock_);
    return cache_.empty();
  }
  
  /**
   * Removes all Values from the Cache.
   */
  void clear() {
    LockGuard g(lock_);
    cache_.clear();
    keys_.clear();
  }
  
  /**
   * Insert the given Value for the Key.
   */
  void insert(const KeyType& k, const ValueType& v) {
    LockGuard g(lock_);
    const auto iter = cache_.find(k);
    if (iter != cache_.end()) {
      iter->second->second = v;
      keys_.splice(keys_.begin(), keys_, iter->second);
      return;
    }

    keys_.emplace_front(k, v);
    cache_[k] = keys_.begin();
    trim();
  }
  
  /**
   * Returns Value for the given Key. Throws std::out_of_range exception if the
   * Value for the given Key was not found
   */
  const ValueType& get(const KeyType& k) {
    LockGuard g(lock_);
    const auto iter = cache_.find(k);
    if (iter == cache_.end()) {
      throw std::out_of_range("key_not_found");
    }
    keys_.splice(keys_.begin(), keys_, iter->second);
    return iter->second->second;
  }
  
  /**
   * Try to get the Value for the given Key and assigns to vOut parameter. Returns false if Value was not found.
   */
  bool try_get(const KeyType& kIn, ValueType& vOut) {
    LockGuard g(lock_);
    const auto iter = cache_.find(kIn);
    if (iter == cache_.end()) {
      return false;
    }
    keys_.splice(keys_.begin(), keys_, iter->second);
    vOut = iter->second->second;
    return true;
  }
  
  /**
   * Remove the Value for the given Key. Returns if removal was succesfull.
   */
  bool remove(const KeyType& k) {
    LockGuard g(lock_);
    auto iter = cache_.find(k);
    if (iter == cache_.end()) {
      return false;
    }
    keys_.erase(iter->second);
    cache_.erase(iter);
    return true;
  }
  
  /**
   * Returns if the cache contains a Value for the given Key.
   */
  bool contains(const KeyType& k) {
    LockGuard g(lock_);
    return cache_.find(k) != cache_.end();
  }

  /**
   * Returns the max size for the Cache.
   */
  size_t getMaxSize() const { return maxSize_; }
  
  /**
   * Returns the elasticity for the Cache.
   */
  size_t getElasticity() const { return elasticity_; }

  /**
   * Returns the max allowed size based on the maxSize and the elasticity.
   */
  size_t getMaxAllowedSize() const { return maxSize_ + elasticity_; }

 protected:
  /**
   * Trims the Cache's elements based on the maxSize and the elasticity.
   */
  size_t trim() {
    size_t maxAllowed = maxSize_ + elasticity_;
    if (maxSize_ == 0 || cache_.size() < maxAllowed) {
      return 0;
    }
    size_t count = 0;
    while (cache_.size() > maxSize_) {
      cache_.erase(keys_.back().first);
      keys_.pop_back();
      ++count;
    }
    return count;
  }

 private:
  mutable lock_type lock_;
  map_type cache_;
  list_type keys_;
  size_t maxSize_;
  size_t elasticity_;
};

}  // namespace ASDN
