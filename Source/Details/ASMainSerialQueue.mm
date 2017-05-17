//
//  ASMainSerialQueue.mm
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

#import <AsyncDisplayKit/ASMainSerialQueue.h>

#import <AsyncDisplayKit/ASThread.h>
#import <AsyncDisplayKit/ASInternalHelpers.h>

@interface ASMainSerialQueue ()
{
  ASAtomic<NSArray *, NSMutableArray *> *_blocks;
  std::atomic<BOOL> _scheduledOnMainQueue;
}

@end

@implementation ASMainSerialQueue

- (instancetype)init
{
  if (!(self = [super init])) {
    return nil;
  }
  
  _blocks = [ASAtomic atomicWithValue:[NSMutableArray array]];
  return self;
}

- (void)performBlockOnMainThread:(dispatch_block_t)block
{
  // If we're already on the main thread, just run now and return.
  if (ASDisplayNodeThreadIsMain()) {
    block();
    return;
  }
  
  // If we're off-main, add the block to `_blocks` and ensure that we're scheduled to run `_blocks` ASAP.
  [_blocks accessWithBlock:^(NSMutableArray * _Nonnull mutableValue) {
    [mutableValue addObject:block];
  }];
  
  if (!_scheduledOnMainQueue.exchange(YES)) {
    dispatch_async(dispatch_get_main_queue(), ^{
      _scheduledOnMainQueue = NO;
      [self flushAllBlocks];
    });
  }
}

- (void)flushAllBlocks
{
  ASDisplayNodeAssertMainThread();
  NSArray *batch;
  do {
    batch = [_blocks readAndUpdate:^(NSMutableArray * _Nonnull mutableValue) {
      [mutableValue removeAllObjects];
    }];
    for (dispatch_block_t block in batch) {
      block();
    }
  } while (batch.count > 0);
}

- (NSString *)description
{
  return [[super description] stringByAppendingFormat:@" Blocks: %@", _blocks];
}

@end

@implementation ASAtomic {
  ASDN::Mutex _mutex;
  id _value;
}

+ (instancetype)atomicWithValue:(id)value
{
  ASAtomic *atomic = [[ASAtomic alloc] init];
  atomic->_value = value;
  return atomic;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wmismatched-parameter-types"

- (void)accessWithBlock:(__kindof id<NSCopying>  _Nonnull (^)(__kindof id<NSCopying> _Nonnull))block
{
  ASDN::MutexLocker locker (_mutex);
  block(_value);
}

- (id<NSCopying>)readAndUpdate:(void(^)(__kindof id<NSCopying> _Nonnull))block
#pragma clang diagnostic pop
{
  id oldValue;
  
  {
    ASDN::MutexLocker locker (_mutex);
    oldValue = [_value copy];
    if (block) {
      block(_value);
    }
  }
  
  return oldValue;
}

- (id)value
{
  ASDN::MutexLocker locker(_mutex);
  return [_value copy];
}

- (void)setValue:(id)value
{
  ASDN::MutexLocker locker(_mutex);
  _value = value;
}

@end
