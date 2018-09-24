//
//  ASBoundedQueue.m
//  FudgeFlowLayout
//
//  Created by Adlai Holler on 8/8/18.
//  Copyright © 2018 Adlai Holler. All rights reserved.
//

#import <AsyncDisplayKit/ASBoundedQueue.h>

#import <atomic>
#import <mutex>
#import <queue>

@implementation ASBoundedQueue {
  std::mutex _lock;
  std::queue<void(^)(void)> _blocks;
  std::condition_variable _ready;
  int _threadLimit;
  int _threadCount;
}

- (instancetype)init
{
  if (self = [super init]) {
    _threadLimit = (int)NSProcessInfo.processInfo.processorCount * 2;
  }
  return self;
}

- (void)dispatch:(void(^)(void))block
{
  std::lock_guard<std::mutex> l(_lock);
  _blocks.push(block);
  // Spawn new thread if needed.
  if (_threadCount < _threadLimit) {
    __unsafe_unretained __typeof(self) uSelf = self;
    // NOTE: Using a concurrent queue does not reliably get us the concurrency we want.
    dispatch_queue_t q = dispatch_queue_create("BoundedQueue", NULL);
    dispatch_async(q, ^{
      [uSelf _threadBody];
    });
    _threadCount += 1;
  }
}

- (void)_threadBody
{
  while (true) {
    void (^block)();
    {
      std::lock_guard<std::mutex> l(_lock);
      if (_blocks.empty()) {
        break;
      }
      block = std::move(_blocks.front());
      _blocks.pop();
    }
    block();
  }
  
  // Before exit, decrement thread count and notify any waiters.
  {
    std::lock_guard<std::mutex> l(_lock);
    _threadCount -= 1;
  }
  _ready.notify_all();
}

- (void)waitUntilReady
{
  std::unique_lock<std::mutex> l(_lock);
  while (!(_threadCount < _threadLimit)) {
    _ready.wait(l);
  }
}

@end

@implementation ASBoundedQueue (LayoutQueue)

+ (ASBoundedQueue *)layoutQueue
{
  static ASBoundedQueue *q;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    q = [[ASBoundedQueue alloc] init];
  });
  return q;
}

@end
