//
//  ASBoundedQueue.h
//  FudgeFlowLayout
//
//  Created by Adlai Holler on 8/8/18.
//  Copyright © 2018 Adlai Holler. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ASBoundedQueue : NSObject

- (void)dispatch:(void(^)(void))block;

- (BOOL)reserve;

@end

static ASBoundedQueue *_gDefaultBoundedQueue;

NS_INLINE void _EnsureDefaultBoundedQueue(void) {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _gDefaultBoundedQueue = [[ASBoundedQueue alloc] init];
  });
}

#define ASBoundedQueueGetDefault() ({ _EnsureDefaultBoundedQueue(); _gDefaultBoundedQueue; })

@interface ASBoundedQueue (LayoutQueue)
/// The queue to which cell layouts are submitted by default.
@property(class, readonly) ASBoundedQueue *layoutQueue;
@end

NS_ASSUME_NONNULL_END

