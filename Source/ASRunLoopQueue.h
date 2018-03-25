//
//  ASRunLoopQueue.h
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

@protocol ASCATransactionQueueObserving <NSObject>
- (void)prepareForCATransactionCommit;
@end

@interface ASAbstractRunLoopQueue : NSObject
@end

AS_SUBCLASSING_RESTRICTED
@interface ASRunLoopQueue<ObjectType> : ASAbstractRunLoopQueue <NSLocking>

/**
 * Create a new queue with the given run loop and handler.
 *
 * @param runloop The run loop that will drive this queue.
 * @param retainsObjects Whether the queue should retain its objects.
 * @param handlerBlock An optional block to be run for each enqueued object.
 *
 * @discussion You may pass @c nil for the handler if you simply want the objects to
 * be retained at enqueue time, and released during the run loop step. This is useful
 * for creating a "main deallocation queue", as @c ASDeallocQueue creates its own 
 * worker thread with its own run loop.
 */
- (instancetype)initWithRunLoop:(CFRunLoopRef)runloop
                  retainObjects:(BOOL)retainsObjects
                        handler:(nullable void(^)(ObjectType dequeuedItem, BOOL isQueueDrained))handlerBlock;

- (void)enqueue:(ObjectType)object;

@property (atomic, readonly) BOOL isEmpty;

@property (nonatomic, assign) NSUInteger batchSize;           // Default == 1.
@property (nonatomic, assign) BOOL ensureExclusiveMembership; // Default == YES.  Set-like behavior.

@end

AS_SUBCLASSING_RESTRICTED
@interface ASCATransactionQueue : ASAbstractRunLoopQueue

@property (atomic, readonly) BOOL isEmpty;

@property (atomic, readonly, getter=isEnabled) BOOL enabled;

/**
 * The queue to run on main run loop before CATransaction commit.
 *
 * @discussion this queue will run after ASRunLoopQueue and before CATransaction commit
 * to get last chance of updating/coalesce info like interface state.
 * Each node will only be called once per transaction commit to reflect interface change.
 */
@property (class, atomic, readonly) ASCATransactionQueue *sharedQueue;
+ (ASCATransactionQueue *)sharedQueue NS_RETURNS_RETAINED;

- (void)enqueue:(id<ASCATransactionQueueObserving>)object;

@end


AS_SUBCLASSING_RESTRICTED
@interface ASDeallocQueue : NSObject

@property (class, atomic, readonly) ASDeallocQueue *sharedDeallocationQueue;
+ (ASDeallocQueue *)sharedDeallocationQueue NS_RETURNS_RETAINED;

- (void)test_drain;

- (void)releaseObjectInBackground:(id __strong _Nullable * _Nonnull)objectPtr;

@end

NS_ASSUME_NONNULL_END
