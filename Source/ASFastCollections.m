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

@implementation NSObject (ASFastCollections)

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
+ (instancetype)fastCollectionWithCapacity:(NSUInteger)capacity constructor:(void (^)(CFTypeRef[], NSUInteger *))body
#pragma clang diagnostic pop
{
  NSParameterAssert(self == [NSArray class] || self == [NSMutableArray class] || self == [NSSet class] || self == [NSMutableSet class]);
  
  // If they asked for capacity 0, go ahead and allocate space for 1
  // to make the rest of our code run safely.
  capacity = MAX(capacity, 1);
  
  // This will be an array of +1 CFTypeRefs (since the block takes `__strong id[]`)
  CFTypeRef buffer[capacity];
  memset(buffer, 0, sizeof(buffer));
  NSUInteger count = 0;
  body(buffer, &count);
  
  // N = 0 or 1, immutable, use NSArray0 or NSSingleObjectArray, faster.
  if (self == [NSArray class] || self == [NSSet class]) {
    id obj = (__bridge_transfer id)buffer[0];
    return [[self alloc] initWithObjects:&obj count:count];
  }
  
  // N > 1
  static CFArrayCallBacks arrayCallbacks;
  static CFSetCallBacks setCallbacks;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    arrayCallbacks = kCFTypeArrayCallBacks;
    arrayCallbacks.retain = ASRetainOrSkip;
    setCallbacks = kCFTypeSetCallBacks;
    setCallbacks.retain = ASRetainOrSkip;
  });
  ASSkipRetainCheckOrSetFlag(YES, YES);
  id result;
  if (self == [NSArray class]) {
    result = (__bridge_transfer NSArray *)CFArrayCreate(NULL, buffer, count, &arrayCallbacks);
  } else if (self == [NSMutableArray class]) {
    CFMutableArrayRef cfArray = CFArrayCreateMutable(NULL, count, &arrayCallbacks);
    for (NSUInteger i = 0; i < count; i++) {
      CFArraySetValueAtIndex(cfArray, i, buffer[i]);
    }
    result = (__bridge_transfer NSMutableArray *)cfArray;
  } else if (self == [NSSet class]) {
    result = (__bridge_transfer NSSet *)CFSetCreate(NULL, buffer, count, &setCallbacks);
  } else if (self == [NSMutableSet class]) {
    CFMutableSetRef cfSet = CFSetCreateMutable(NULL, count, &setCallbacks);
    for (NSUInteger i = 0; i < count; i++) {
      CFSetAddValue(cfSet, buffer[i]);
    }
    result = (__bridge_transfer NSMutableSet *)cfSet;
  }
  ASSkipRetainCheckOrSetFlag(YES, NO);
  return result;
}

@end

