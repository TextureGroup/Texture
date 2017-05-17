//
//  ASMainSerialQueue.h
//  Texture
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the /ASDK-Licenses directory of this source tree. An additional
//  grant of patent rights can be found in the PATENTS file in the same directory.
//
//  Modifications to this file made after 4/13/2017 are: Copyright (c) 2017-present,
//  Pinterest, Inc.  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/ASBaseDefines.h>

NS_ASSUME_NONNULL_BEGIN

AS_SUBCLASSING_RESTRICTED
@interface ASMainSerialQueue : NSObject

- (void)performBlockOnMainThread:(dispatch_block_t)block;

- (void)flushAllBlocks;

@end


/**
 * A shortcut to read one property from an atomic without copying the whole value.
 *
 * For example, `NSUInteger c = ASAtomicAccessOneProperty(myAtomicArray, count);`
 * The slower form would be `NSUInteger c = myAtomicArray.value.count;`
 */
#define ASAtomicAccessOneProperty(instance, getterName) ({ \
  __block __typeof([instance.value getterName]) __value; \
  [instance accessWithBlock:^(id mutableValue) { \
    __value = [mutableValue getterName]; \
  }]; \
  __value; \
})

#define ASAtomicArrayType(T) ASAtomic<NSArray<T *> *, NSMutableArray<T *> *>

/**
 * An atomic object container designed for classes that have mutable instances. 
 */
@interface ASAtomic<CopiedType : id<NSCopying>, MutableType : id<NSCopying>> : NSObject

+ (instancetype)atomicWithValue:(MutableType)value;

- (void)accessWithBlock:(AS_NOESCAPE void (^)(MutableType mutableValue))block;

- (CopiedType)readAndUpdate:(nullable AS_NOESCAPE void (^)(MutableType mutableValue))block;

@property (atomic, copy, readonly) CopiedType value;

@end

NS_ASSUME_NONNULL_END
