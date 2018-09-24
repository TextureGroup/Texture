//
//  BoundedQueue.h
//  FudgeFlowLayout
//
//  Created by Adlai Holler on 8/8/18.
//  Copyright © 2018 Adlai Holler. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BoundedQueue : NSObject

- (void)dispatch:(void(^)(void))block;

- (void)waitUntilReady;

@end

static BoundedQueue *_gDefaultBoundedQueue;

NS_INLINE void _EnsureDefaultBoundedQueue(void) {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _gDefaultBoundedQueue = [[BoundedQueue alloc] init];
  });
}

#define BoundedQueueGetDefault() ({ _EnsureDefaultBoundedQueue(); _gDefaultBoundedQueue; })

@interface BoundedQueue (LayoutQueue)
/// The queue to which cell layouts are submitted by default.
@property(class, readonly) BoundedQueue *layoutQueue;
@end

NS_ASSUME_NONNULL_END

