//
//  ASFastCollections.m
//  Texture
//
//  Copyright (c) 2018-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASFastCollections.h>
#import <pthread/pthread.h>

/**
 * We use a pthread specific to communicate to our retain callback that
 * it should skip retaining. We set the flag before creating an array
 * with our callback, then clear the flag after.
 * There's no need for re-entrance support on this flag.
 *
 * @param set Whether you want to set or get the flag.
 * @param newValue The new value if you want to set. Ignored otherwise.
 * @return The value of the flag.
 */
BOOL ASSkipRetainCheckOrSetFlag(BOOL set, BOOL newValue) {
  pthread_key_t key = ASPthreadStaticKey(NULL);
  
  if (set) {
    pthread_setspecific(key, (void *)(uintptr_t)newValue);
    return newValue;
  } else {
    return (pthread_getspecific(key) != NULL);
  }
}

/**
 * Our custom CFArray/Set RetainCallback. It checks the thread flag and either
 * skips the retain or calls the default CFType array retain callback (-retain).
 */
const void *ASRetainOrSkip(CFAllocatorRef allocator, const void *value)
{
  if (ASSkipRetainCheckOrSetFlag(NO, NO)) {
    return value;
  } else {
    return (&kCFTypeArrayCallBacks)->retain(allocator, value);
  }
}

@implementation NSArray (ASFast)

/**
 * We pull a bit of a nasty trick here.
 *
 * We publicly declared the buffer as being `__strong id[]`, so that ARC will put +1s into
 * our buffer. However, we treat it as `CFTypeRef[]` so ARC will not
 * do any retain/releasing on our local array inside this method. We need ARC
 * to give us the +1, and then leave it alone since we're transferring that +1 into the array.
 */
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wmismatched-parameter-types"
+ (NSArray *)fastArrayWithCapacity:(NSUInteger)capacity
                      constructor:(AS_NOESCAPE void (^)(CFTypeRef buffer[], NSUInteger *count))body
#pragma clang diagnostic pop

{
  // This will be an array of +1 CFTypeRefs (since the block takes `__strong id[]`)
  CFTypeRef buffer[capacity];
  memset(buffer, 0, sizeof(buffer));
  NSUInteger count = 0;
  body(buffer, &count);
  
  // N = 0 or 1, use NSArray0 or NSSingleObjectArray
  if (count == 0) {
    return @[];
  } else if (count == 1) {
    // Transfer our +1 CFTypeRef into ARC
    return @[ (__bridge_transfer id)buffer[0] ];
  }
  
  // N > 1
  static CFArrayCallBacks cb;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    cb = kCFTypeArrayCallBacks;
    cb.retain = ASRetainOrSkip;
  });
  ASSkipRetainCheckOrSetFlag(YES, YES);
  CFArrayRef result = CFArrayCreate(NULL, buffer, count, &cb);
  ASSkipRetainCheckOrSetFlag(YES, NO);
  return (__bridge_transfer NSArray *)result;
}

@end

@implementation NSMutableArray (ASFast)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wmismatched-parameter-types"
+ (NSArray *)fastArrayWithCapacity:(NSUInteger)capacity
                       constructor:(AS_NOESCAPE void (^)(CFTypeRef buffer[], NSUInteger *count))body
#pragma clang diagnostic pop

{
  // This will be an array of +1 CFTypeRefs (since the block takes `__strong id[]`)
  CFTypeRef buffer[capacity];
  memset(buffer, 0, sizeof(buffer));
  NSUInteger count = 0;
  body(buffer, &count);
  
  static CFArrayCallBacks cb;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    cb = kCFTypeArrayCallBacks;
    cb.retain = ASRetainOrSkip;
  });
  CFMutableArrayRef result = CFArrayCreateMutable(NULL, count, &cb);
  ASSkipRetainCheckOrSetFlag(YES, YES);
  for (NSUInteger i = 0; i < count; i++) {
    CFArraySetValueAtIndex(result, i, buffer[i]);
  }
  ASSkipRetainCheckOrSetFlag(YES, NO);
  return (__bridge_transfer NSMutableArray *)result;
}

@end

@implementation NSSet (ASFast)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wmismatched-parameter-types"
+ (NSSet *)fastSetWithCapacity:(NSUInteger)capacity
                   constructor:(void (^)(CFTypeRef buffer[], NSUInteger *count))body
#pragma clang diagnostic pop
{
  // This will be an array of +1 CFTypeRefs (since the block takes `__strong id[]`)
  CFTypeRef buffer[capacity];
  memset(buffer, 0, sizeof(buffer));
  NSUInteger count = 0;
  body(buffer, &count);
  
  // N = 0 or 1, use NSArray0 or NSSingleObjectArray
  if (count == 0) {
    return [NSSet set];
  } else if (count == 1) {
    // Transfer our +1 CFTypeRef into ARC
    return [NSSet setWithObject:(__bridge_transfer id)buffer[0]];
  }
  
  // N > 1
  static CFSetCallBacks cb;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    cb = kCFTypeSetCallBacks;
    cb.retain = ASRetainOrSkip;
  });
  ASSkipRetainCheckOrSetFlag(YES, YES);
  CFSetRef result = CFSetCreate(NULL, buffer, count, &cb);
  ASSkipRetainCheckOrSetFlag(YES, NO);
  return (__bridge_transfer NSSet *)result;
}

@end
