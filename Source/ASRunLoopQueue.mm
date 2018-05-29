//
//  ASRunLoopQueue.mm
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

#import <AsyncDisplayKit/ASAvailability.h>
#import <AsyncDisplayKit/ASConfigurationInternal.h>
#import <AsyncDisplayKit/ASLog.h>
#import <AsyncDisplayKit/ASObjectDescriptionHelpers.h>
#import <AsyncDisplayKit/ASRunLoopQueue.h>
#import <AsyncDisplayKit/ASThread.h>
#import <AsyncDisplayKit/ASSignpost.h>
#import <QuartzCore/QuartzCore.h>
#import <cstdlib>
#import <deque>
#import <vector>

#define ASRunLoopQueueLoggingEnabled 0
#define ASRunLoopQueueVerboseLoggingEnabled 0

static void runLoopSourceCallback(void *info) {
  // No-op
#if ASRunLoopQueueVerboseLoggingEnabled
  NSLog(@"<%@> - Called runLoopSourceCallback", info);
#endif
}

#pragma mark - ASDeallocQueue

@interface ASDeallocQueueV1 : ASDeallocQueue
@end
@interface ASDeallocQueueV2 : ASDeallocQueue
@end

@implementation ASDeallocQueue

+ (ASDeallocQueue *)sharedDeallocationQueue NS_RETURNS_RETAINED
{
  static ASDeallocQueue *deallocQueue = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    if (ASActivateExperimentalFeature(ASExperimentalDeallocQueue)) {
      deallocQueue = [[ASDeallocQueueV2 alloc] init];
    } else {
      deallocQueue = [[ASDeallocQueueV1 alloc] init];
    }
  });
  return deallocQueue;
}

- (void)releaseObjectInBackground:(id  _Nullable __strong *)objectPtr
{
  ASDisplayNodeFailAssert(@"Abstract method.");
}

@end

@implementation ASDeallocQueueV1 {
  NSThread *_thread;
  NSCondition *_condition;
  std::deque<id> _queue;
  ASDN::RecursiveMutex _queueLock;
}

- (void)releaseObjectInBackground:(id  _Nullable __strong *)objectPtr
{
  if (objectPtr != NULL && *objectPtr != nil) {
    ASDN::MutexLocker l(_queueLock);
    _queue.push_back(*objectPtr);
    *objectPtr = nil;
  }
}

- (void)threadMain
{
  @autoreleasepool {
    __unsafe_unretained __typeof__(self) weakSelf = self;
    // 100ms timer.  No resources are wasted in between, as the thread sleeps, and each check is fast.
    // This time is fast enough for most use cases without excessive churn.
    CFRunLoopTimerRef timer = CFRunLoopTimerCreateWithHandler(NULL, -1, 0.1, 0, 0, ^(CFRunLoopTimerRef timer) {
      weakSelf->_queueLock.lock();
      if (weakSelf->_queue.size() == 0) {
        weakSelf->_queueLock.unlock();
        return;
      }
      // The scope below is entered while already locked. @autorelease is crucial here; see PR 2890.
      NSInteger count;
      @autoreleasepool {
#if ASRunLoopQueueLoggingEnabled
        NSLog(@"ASDeallocQueue Processing: %lu objects destroyed", weakSelf->_queue.size());
#endif
        // Sometimes we release 10,000 objects at a time.  Don't hold the lock while releasing.
        std::deque<id> currentQueue = weakSelf->_queue;
        count = currentQueue.size();
        ASSignpostStartCustom(ASSignpostDeallocQueueDrain, self, count);
        weakSelf->_queue = std::deque<id>();
        weakSelf->_queueLock.unlock();
        currentQueue.clear();
      }
      ASSignpostEndCustom(ASSignpostDeallocQueueDrain, self, count, ASSignpostColorDefault);
    });
    
    CFRunLoopRef runloop = CFRunLoopGetCurrent();
    CFRunLoopAddTimer(runloop, timer, kCFRunLoopCommonModes);
    
    [_condition lock];
    [_condition signal];
    // At this moment, -init is signalled that the thread is guaranteed to be finished starting.
    [_condition unlock];
    
    // Keep processing events until the runloop is stopped.
    CFRunLoopRun();
    
    CFRunLoopTimerInvalidate(timer);
    CFRunLoopRemoveTimer(runloop, timer, kCFRunLoopCommonModes);
    CFRelease(timer);
    
    [_condition lock];
    [_condition signal];
    // At this moment, -stop is signalled that the thread is guaranteed to be finished exiting.
    [_condition unlock];
  }
}

- (instancetype)init
{
  if ((self = [super init])) {
    _condition = [[NSCondition alloc] init];
    
    _thread = [[NSThread alloc] initWithTarget:self selector:@selector(threadMain) object:nil];
    _thread.name = @"ASDeallocQueue";
    
    // Use condition to ensure NSThread has finished starting.
    [_condition lock];
    [_thread start];
    [_condition wait];
    [_condition unlock];
  }
  return self;
}

- (void)stop
{
  if (!_thread) {
    return;
  }
  
  [_condition lock];
  [self performSelector:@selector(_stop) onThread:_thread withObject:nil waitUntilDone:NO];
  [_condition wait];
  // At this moment, the thread is guaranteed to be finished running.
  [_condition unlock];
  _thread = nil;
}

- (void)drain
{
  [self performSelector:@selector(_drain) onThread:_thread withObject:nil waitUntilDone:YES];
}

- (void)_drain
{
  while (true) {
    @autoreleasepool {
      _queueLock.lock();
      std::deque<id> currentQueue = _queue;
      _queue = std::deque<id>();
      _queueLock.unlock();

      if (currentQueue.empty()) {
        return;
      } else {
        currentQueue.clear();
      }
    }
  }
}

- (void)_stop
{
  CFRunLoopStop(CFRunLoopGetCurrent());
}

- (void)dealloc
{
  [self stop];
}

@end

@implementation ASDeallocQueueV2 {
  std::vector<CFTypeRef> _queue;
  ASDN::Mutex _lock;
}

- (void)dealloc
{
  ASDisplayNodeFailAssert(@"Singleton should not dealloc.");
}

- (void)releaseObjectInBackground:(id  _Nullable __strong *)objectPtr
{
  NSParameterAssert(objectPtr != NULL);
  
  // Cast to CFType so we can manipulate retain count manually.
  auto cfPtr = (CFTypeRef *)(void *)objectPtr;
  if (!cfPtr || !*cfPtr) {
    return;
  }
  
  _lock.lock();
  auto isFirstEntry = _queue.empty();
  // Push the pointer into our queue and clear their pointer.
  // This "steals" the +1 from ARC and nils their pointer so they can't
  // access or release the object.
  _queue.push_back(*cfPtr);
  *cfPtr = NULL;
  _lock.unlock();
  
  if (isFirstEntry) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.100 * NSEC_PER_SEC)), dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
      [self drain];
    });
  }
}

- (void)drain
{
  @autoreleasepool {
    _lock.lock();
    auto q = std::move(_queue);
    _lock.unlock();
    for (auto ref : q) {
      // NOTE: Could check that retain count is 1 and retry later if not.
      CFRelease(ref);
    }
  }
}

@end

#if AS_KDEBUG_ENABLE
/**
 * This is real, private CA API. Valid as of iOS 10.
 */
typedef enum {
  kCATransactionPhasePreLayout,
  kCATransactionPhasePreCommit,
  kCATransactionPhasePostCommit,
} CATransactionPhase;

@interface CATransaction (Private)
+ (void)addCommitHandler:(void(^)(void))block forPhase:(CATransactionPhase)phase;
+ (int)currentState;
@end
#endif

#pragma mark - ASAbstractRunLoopQueue

@interface ASAbstractRunLoopQueue (Private)
+ (void)load;
+ (void)registerCATransactionObservers;
@end

@implementation ASAbstractRunLoopQueue

- (instancetype)init
{
  if (self != [super init]) {
    return nil;
  }
  ASDisplayNodeAssert(self.class != [ASAbstractRunLoopQueue class], @"Should never create instances of abstract class ASAbstractRunLoopQueue.");
  return self;
}

#if AS_KDEBUG_ENABLE
+ (void)load
{
  [self registerCATransactionObservers];
}

+ (void)registerCATransactionObservers
{
  static BOOL privateCAMethodsExist;
  static dispatch_block_t preLayoutHandler;
  static dispatch_block_t preCommitHandler;
  static dispatch_block_t postCommitHandler;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    privateCAMethodsExist = [CATransaction respondsToSelector:@selector(addCommitHandler:forPhase:)];
    privateCAMethodsExist &= [CATransaction respondsToSelector:@selector(currentState)];
    if (!privateCAMethodsExist) {
      NSLog(@"Private CA methods are gone.");
    }
    preLayoutHandler = ^{
      ASSignpostStartCustom(ASSignpostCATransactionLayout, 0, [CATransaction currentState]);
    };
    preCommitHandler = ^{
      int state = [CATransaction currentState];
      ASSignpostEndCustom(ASSignpostCATransactionLayout, 0, state, ASSignpostColorDefault);
      ASSignpostStartCustom(ASSignpostCATransactionCommit, 0, state);
    };
    postCommitHandler = ^{
      ASSignpostEndCustom(ASSignpostCATransactionCommit, 0, [CATransaction currentState], ASSignpostColorDefault);
      // Can't add new observers inside an observer. rdar://problem/31253952
      dispatch_async(dispatch_get_main_queue(), ^{
        [self registerCATransactionObservers];
      });
    };
  });

  if (privateCAMethodsExist) {
    [CATransaction addCommitHandler:preLayoutHandler forPhase:kCATransactionPhasePreLayout];
    [CATransaction addCommitHandler:preCommitHandler forPhase:kCATransactionPhasePreCommit];
    [CATransaction addCommitHandler:postCommitHandler forPhase:kCATransactionPhasePostCommit];
  }
}

#endif // AS_KDEBUG_ENABLE

@end

#pragma mark - ASRunLoopQueue

@interface ASRunLoopQueue () {
  CFRunLoopRef _runLoop;
  CFRunLoopSourceRef _runLoopSource;
  CFRunLoopObserverRef _runLoopObserver;
  NSPointerArray *_internalQueue; // Use NSPointerArray so we can decide __strong or __weak per-instance.
  ASDN::RecursiveMutex _internalQueueLock;

  // In order to not pollute the top-level activities, each queue has 1 root activity.
  os_activity_t _rootActivity;

#if ASRunLoopQueueLoggingEnabled
  NSTimer *_runloopQueueLoggingTimer;
#endif
}

@property (nonatomic) void (^queueConsumer)(id dequeuedItem, BOOL isQueueDrained);

@end

@implementation ASRunLoopQueue

- (instancetype)initWithRunLoop:(CFRunLoopRef)runloop retainObjects:(BOOL)retainsObjects handler:(void (^)(id _Nullable, BOOL))handlerBlock
{
  if (self = [super init]) {
    _runLoop = runloop;
    NSPointerFunctionsOptions options = retainsObjects ? NSPointerFunctionsStrongMemory : NSPointerFunctionsWeakMemory;
    _internalQueue = [[NSPointerArray alloc] initWithOptions:options];
    _queueConsumer = handlerBlock;
    _batchSize = 1;
    _ensureExclusiveMembership = YES;

    // We don't want to pollute the top-level app activities with run loop batches, so we create one top-level
    // activity per queue, and each batch activity joins that one instead.
    _rootActivity = as_activity_create("Process run loop queue items", OS_ACTIVITY_NONE, OS_ACTIVITY_FLAG_DEFAULT);
    {
      // Log a message identifying this queue into the queue's root activity.
      as_activity_scope_verbose(_rootActivity);
      as_log_verbose(ASDisplayLog(), "Created run loop queue: %@", self);
    }
    
    // Self is guaranteed to outlive the observer.  Without the high cost of a weak pointer,
    // __unsafe_unretained allows us to avoid flagging the memory cycle detector.
    __unsafe_unretained __typeof__(self) weakSelf = self;
    void (^handlerBlock) (CFRunLoopObserverRef observer, CFRunLoopActivity activity) = ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
      [weakSelf processQueue];
    };
    _runLoopObserver = CFRunLoopObserverCreateWithHandler(NULL, kCFRunLoopBeforeWaiting, true, 0, handlerBlock);
    CFRunLoopAddObserver(_runLoop, _runLoopObserver,  kCFRunLoopCommonModes);
    
    // It is not guaranteed that the runloop will turn if it has no scheduled work, and this causes processing of
    // the queue to stop. Attaching a custom loop source to the run loop and signal it if new work needs to be done
    CFRunLoopSourceContext sourceContext = {};
    sourceContext.perform = runLoopSourceCallback;
#if ASRunLoopQueueLoggingEnabled
    sourceContext.info = (__bridge void *)self;
#endif
    _runLoopSource = CFRunLoopSourceCreate(NULL, 0, &sourceContext);
    CFRunLoopAddSource(runloop, _runLoopSource, kCFRunLoopCommonModes);

#if ASRunLoopQueueLoggingEnabled
    _runloopQueueLoggingTimer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(checkRunLoop) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_runloopQueueLoggingTimer forMode:NSRunLoopCommonModes];
#endif
  }
  return self;
}

- (void)dealloc
{
  if (CFRunLoopContainsSource(_runLoop, _runLoopSource, kCFRunLoopCommonModes)) {
    CFRunLoopRemoveSource(_runLoop, _runLoopSource, kCFRunLoopCommonModes);
  }
  CFRelease(_runLoopSource);
  _runLoopSource = nil;
  
  if (CFRunLoopObserverIsValid(_runLoopObserver)) {
    CFRunLoopObserverInvalidate(_runLoopObserver);
  }
  CFRelease(_runLoopObserver);
  _runLoopObserver = nil;
}

#if ASRunLoopQueueLoggingEnabled
- (void)checkRunLoop
{
    NSLog(@"<%@> - Jobs: %ld", self, _internalQueue.size());
}
#endif

- (void)processQueue
{
  BOOL hasExecutionBlock = (_queueConsumer != nil);

  // If we have an execution block, this vector will be populated, otherwise remains empty.
  // This is to avoid needlessly retaining/releasing the objects if we don't have a block.
  std::vector<id> itemsToProcess;

  BOOL isQueueDrained = NO;
  {
    ASDN::MutexLocker l(_internalQueueLock);

    NSInteger internalQueueCount = _internalQueue.count;
    // Early-exit if the queue is empty.
    if (internalQueueCount == 0) {
      return;
    }

    ASSignpostStart(ASSignpostRunLoopQueueBatch);

    // Snatch the next batch of items.
    NSInteger maxCountToProcess = MIN(internalQueueCount, self.batchSize);

    /**
     * For each item in the next batch, if it's non-nil then NULL it out
     * and if we have an execution block then add it in.
     * This could be written a bunch of different ways but
     * this particular one nicely balances readability, safety, and efficiency.
     */
    NSInteger foundItemCount = 0;
    for (NSInteger i = 0; i < internalQueueCount && foundItemCount < maxCountToProcess; i++) {
      /**
       * It is safe to use unsafe_unretained here. If the queue is weak, the
       * object will be added to the autorelease pool. If the queue is strong,
       * it will retain the object until we transfer it (retain it) in itemsToProcess.
       */
      __unsafe_unretained id ptr = (__bridge id)[_internalQueue pointerAtIndex:i];
      if (ptr != nil) {
        foundItemCount++;
        if (hasExecutionBlock) {
          itemsToProcess.push_back(ptr);
        }
        [_internalQueue replacePointerAtIndex:i withPointer:NULL];
      }
    }

    if (foundItemCount == 0) {
      // If _internalQueue holds weak references, and all of them just become NULL, then the array
      // is never marked as needsCompletion, and compact will return early, not removing the NULL's.
      // Inserting a NULL here ensures the compaction will take place.
      // See http://www.openradar.me/15396578 and https://stackoverflow.com/a/40274426/1136669
      [_internalQueue addPointer:NULL];
    }

    [_internalQueue compact];
    if (_internalQueue.count == 0) {
      isQueueDrained = YES;
    }
  }

  // itemsToProcess will be empty if _queueConsumer == nil so no need to check again.
  auto count = itemsToProcess.size();
  if (count > 0) {
    as_activity_scope_verbose(as_activity_create("Process run loop queue batch", _rootActivity, OS_ACTIVITY_FLAG_DEFAULT));
    auto itemsEnd = itemsToProcess.cend();
    for (auto iterator = itemsToProcess.begin(); iterator < itemsEnd; iterator++) {
      __unsafe_unretained id value = *iterator;
      _queueConsumer(value, isQueueDrained && iterator == itemsEnd - 1);
      as_log_verbose(ASDisplayLog(), "processed %@", value);
    }
    if (count > 1) {
      as_log_verbose(ASDisplayLog(), "processed %lu items", (unsigned long)count);
    }
  }

  // If the queue is not fully drained yet force another run loop to process next batch of items
  if (!isQueueDrained) {
    CFRunLoopSourceSignal(_runLoopSource);
    CFRunLoopWakeUp(_runLoop);
  }
  
  ASSignpostEnd(ASSignpostRunLoopQueueBatch);
}

- (void)enqueue:(id)object
{
  if (!object) {
    return;
  }
  
  ASDN::MutexLocker l(_internalQueueLock);

  // Check if the object exists.
  BOOL foundObject = NO;
    
  if (_ensureExclusiveMembership) {
    for (id currentObject in _internalQueue) {
      if (currentObject == object) {
        foundObject = YES;
        break;
      }
    }
  }

  if (!foundObject) {
    [_internalQueue addPointer:(__bridge void *)object];

    CFRunLoopSourceSignal(_runLoopSource);
    CFRunLoopWakeUp(_runLoop);
  }
}

- (BOOL)isEmpty
{
  ASDN::MutexLocker l(_internalQueueLock);
  return _internalQueue.count == 0;
}

#pragma mark - NSLocking

- (void)lock
{
  _internalQueueLock.lock();
}

- (void)unlock
{
  _internalQueueLock.unlock();
}

@end

#pragma mark - ASCATransactionQueue

@interface ASCATransactionQueue () {
  CFRunLoopRef _runLoop;
  CFRunLoopSourceRef _runLoopSource;
  CFRunLoopObserverRef _preTransactionObserver;
  CFRunLoopObserverRef _postTransactionObserver;
  NSPointerArray *_internalQueue;
  ASDN::RecursiveMutex _internalQueueLock;
  BOOL _CATransactionCommitInProgress;

  // In order to not pollute the top-level activities, each queue has 1 root activity.
  os_activity_t _rootActivity;

#if ASRunLoopQueueLoggingEnabled
  NSTimer *_runloopQueueLoggingTimer;
#endif
}

@end

@implementation ASCATransactionQueue

// CoreAnimation commit order is 2000000, the goal of this is to process shortly beforehand
// but after most other scheduled work on the runloop has processed.
static int const kASASCATransactionQueueOrder = 1000000;
// This will mark the end of current loop and any node enqueued between kASASCATransactionQueueOrder
// and kASASCATransactionQueuePostOrder will apply interface change immediately.
static int const kASASCATransactionQueuePostOrder = 3000000;

+ (ASCATransactionQueue *)sharedQueue NS_RETURNS_RETAINED
{
  static dispatch_once_t onceToken;
  static ASCATransactionQueue *sharedQueue;
  dispatch_once(&onceToken, ^{
    sharedQueue = [[ASCATransactionQueue alloc] init];
  });
  return sharedQueue;
}

- (instancetype)init
{
  if (self = [super init]) {
    _runLoop = CFRunLoopGetMain();
    NSPointerFunctionsOptions options = NSPointerFunctionsStrongMemory;
    _internalQueue = [[NSPointerArray alloc] initWithOptions:options];

    // We don't want to pollute the top-level app activities with run loop batches, so we create one top-level
    // activity per queue, and each batch activity joins that one instead.
    _rootActivity = as_activity_create("Process run loop queue items", OS_ACTIVITY_NONE, OS_ACTIVITY_FLAG_DEFAULT);
    {
      // Log a message identifying this queue into the queue's root activity.
      as_activity_scope_verbose(_rootActivity);
      as_log_verbose(ASDisplayLog(), "Created run loop queue: %@", self);
    }

    // Self is guaranteed to outlive the observer.  Without the high cost of a weak pointer,
    // __unsafe_unretained allows us to avoid flagging the memory cycle detector.
    __unsafe_unretained __typeof__(self) weakSelf = self;
    void (^handlerBlock) (CFRunLoopObserverRef observer, CFRunLoopActivity activity) = ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
      [weakSelf processQueue];
    };
    void (^postHandlerBlock) (CFRunLoopObserverRef observer, CFRunLoopActivity activity) = ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
      ASDN::MutexLocker l(_internalQueueLock);
      _CATransactionCommitInProgress = NO;
    };
    _preTransactionObserver = CFRunLoopObserverCreateWithHandler(NULL, kCFRunLoopBeforeWaiting, true, kASASCATransactionQueueOrder, handlerBlock);
    _postTransactionObserver = CFRunLoopObserverCreateWithHandler(NULL, kCFRunLoopBeforeWaiting, true, kASASCATransactionQueuePostOrder, postHandlerBlock);

    CFRunLoopAddObserver(_runLoop, _preTransactionObserver,  kCFRunLoopCommonModes);
    CFRunLoopAddObserver(_runLoop, _postTransactionObserver,  kCFRunLoopCommonModes);

    // It is not guaranteed that the runloop will turn if it has no scheduled work, and this causes processing of
    // the queue to stop. Attaching a custom loop source to the run loop and signal it if new work needs to be done
    CFRunLoopSourceContext sourceContext = {};
    sourceContext.perform = runLoopSourceCallback;
#if ASRunLoopQueueLoggingEnabled
    sourceContext.info = (__bridge void *)self;
#endif
    _runLoopSource = CFRunLoopSourceCreate(NULL, 0, &sourceContext);
    CFRunLoopAddSource(_runLoop, _runLoopSource, kCFRunLoopCommonModes);

#if ASRunLoopQueueLoggingEnabled
    _runloopQueueLoggingTimer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(checkRunLoop) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_runloopQueueLoggingTimer forMode:NSRunLoopCommonModes];
#endif
  }
  return self;
}

- (void)dealloc
{
  CFRunLoopRemoveSource(_runLoop, _runLoopSource, kCFRunLoopCommonModes);
  CFRelease(_runLoopSource);
  _runLoopSource = nil;

  if (CFRunLoopObserverIsValid(_preTransactionObserver)) {
    CFRunLoopObserverInvalidate(_preTransactionObserver);
  }
  if (CFRunLoopObserverIsValid(_postTransactionObserver)) {
    CFRunLoopObserverInvalidate(_postTransactionObserver);
  }
  CFRelease(_preTransactionObserver);
  CFRelease(_postTransactionObserver);
  _preTransactionObserver = nil;
  _postTransactionObserver = nil;
}

#if ASRunLoopQueueLoggingEnabled
- (void)checkRunLoop
{
  NSLog(@"<%@> - Jobs: %ld", self, _internalQueue.size());
}
#endif

- (void)processQueue
{
  // If we have an execution block, this vector will be populated, otherwise remains empty.
  // This is to avoid needlessly retaining/releasing the objects if we don't have a block.
  std::vector<id> itemsToProcess;

  {
    ASDN::MutexLocker l(_internalQueueLock);

    // Mark the queue will end coalescing shortly until after CATransactionCommit.
    // This will give the queue a chance to apply any further interfaceState changes/enqueue
    // immediately within current runloop instead of pushing the work to next runloop cycle.
    _CATransactionCommitInProgress = YES;

    NSInteger internalQueueCount = _internalQueue.count;
    // Early-exit if the queue is empty.
    if (internalQueueCount == 0) {
      return;
    }

    ASSignpostStart(ASSignpostRunLoopQueueBatch);

    /**
     * For each item in the next batch, if it's non-nil then NULL it out
     * and if we have an execution block then add it in.
     * This could be written a bunch of different ways but
     * this particular one nicely balances readability, safety, and efficiency.
     */
    NSInteger foundItemCount = 0;
    for (NSInteger i = 0; i < internalQueueCount && foundItemCount < internalQueueCount; i++) {
      /**
       * It is safe to use unsafe_unretained here. If the queue is weak, the
       * object will be added to the autorelease pool. If the queue is strong,
       * it will retain the object until we transfer it (retain it) in itemsToProcess.
       */
      __unsafe_unretained id ptr = (__bridge id)[_internalQueue pointerAtIndex:i];
      if (ptr != nil) {
        foundItemCount++;
        itemsToProcess.push_back(ptr);
        [_internalQueue replacePointerAtIndex:i withPointer:NULL];
      }
    }

    [_internalQueue compact];
  }

  // itemsToProcess will be empty if _queueConsumer == nil so no need to check again.
  auto count = itemsToProcess.size();
  if (count > 0) {
    as_activity_scope_verbose(as_activity_create("Process run loop queue batch", _rootActivity, OS_ACTIVITY_FLAG_DEFAULT));
    auto itemsEnd = itemsToProcess.cend();
    for (auto iterator = itemsToProcess.begin(); iterator < itemsEnd; iterator++) {
      __unsafe_unretained id value = *iterator;
      [value prepareForCATransactionCommit];
      as_log_verbose(ASDisplayLog(), "processed %@", value);
    }
    if (count > 1) {
      as_log_verbose(ASDisplayLog(), "processed %lu items", (unsigned long)count);
    }
  }

  ASSignpostEnd(ASSignpostRunLoopQueueBatch);
}

- (void)enqueue:(id<ASCATransactionQueueObserving>)object
{
  if (!object) {
    return;
  }

  if (!self.enabled || _CATransactionCommitInProgress) {
    [object prepareForCATransactionCommit];
    return;
  }

  ASDN::MutexLocker l(_internalQueueLock);

  // Check if the object exists.
  BOOL foundObject = NO;

  for (id currentObject in _internalQueue) {
    if (currentObject == object) {
      foundObject = YES;
      break;
    }
  }

  if (!foundObject) {
    [_internalQueue addPointer:(__bridge void *)object];

    CFRunLoopSourceSignal(_runLoopSource);
    CFRunLoopWakeUp(_runLoop);
  }
}

- (BOOL)isEmpty
{
  ASDN::MutexLocker l(_internalQueueLock);
  return _internalQueue.count == 0;
}

- (BOOL)isEnabled
{
  return ASActivateExperimentalFeature(ASExperimentalInterfaceStateCoalescing);
}

@end
