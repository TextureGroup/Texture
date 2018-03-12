//
//  ASCache.m
//  Texture
//
//  Copyright (c) 2018-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASCache.h>
#import <AsyncDisplayKit/ASInternalHelpers.h>
#import <AsyncDisplayKit/ASLog.h>
#import <AsyncDisplayKit/ASThread.h>

@implementation ASCache {
#if ASCachingLogEnabled
  NSUInteger _hitCount;
  NSUInteger _missCount;
#endif
}

// If cache logging is on, override this method and track stats.
#if ASCachingLogEnabled
- (id)objectForKey:(id)key
{
  id result = [super objectForKey:key];
  
  {
    static NSLock *l;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      l = [[NSLock alloc] init];
    });
    ASLockScopeUnowned(l);
    if (result) {
      _hitCount += 1;
    } else {
      _missCount += 1;
    }
    NSUInteger totalReads = _hitCount + _missCount;
    if (totalReads % 10 == 0) {
      as_log_info(ASCachingLog(), "%@ hit rate: %d/%d (%.2f%%)", self.name.length ? self.name : self.debugDescription, _hitCount, totalReads, 100.0 * (_hitCount / (double)totalReads));
    }
  }
  
  return result;
}
#endif

- (id)objectForKey:(id)key constructedWithBlock:(id (^)(id))block
{
  // We could do lots of interesting stuff here, including this working
  // implementation of request coalescing, but at the moment none
  // of it is justified. We only coalesce a few hits out of 300 requests.
  // https://gist.github.com/Adlai-Holler/f1e71e94c9fefc27ed87d2b309e98f98
  id object = [self objectForKey:key];
  if (object) {
    return object;
  }
  
  object = block(key);

  // Could do this async but that might cause more misses than its worth.
  [self setObject:object forKey:key];
  return object;
}

@end
