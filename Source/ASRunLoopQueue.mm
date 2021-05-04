//
//  ASRunLoopQueue.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASAvailability.h>
#import <AsyncDisplayKit/ASConfigurationInternal.h>
#import <AsyncDisplayKit/ASLog.h>
#import <AsyncDisplayKit/ASRunLoopQueue.h>
#import <AsyncDisplayKit/ASThread.h>
#import <AsyncDisplayKit/ASSignpost.h>
#import <vector>

#define ASRunLoopQueueLoggingEnabled 0
#define ASRunLoopQueueVerboseLoggingEnabled 0

using AS::MutexLocker;

static void runLoopSourceCallback(void *info) {
  // No-op
#if ASRunLoopQueueVerboseLoggingEnabled
  NSLog(@"<%@> - Called runLoopSourceCallback", info);
#endif
}

#pragma mark - ASDeallocQueue

@implementation ASDeallocQueue {
  std::vector<CFTypeRef> _queue;
  AS::Mutex _lock;
}

+ (ASDeallocQueue *)sharedDeallocationQueue NS_RETURNS_RETAINED
{
  static ASDeallocQueue *deallocQueue = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    deallocQueue = [[ASDeallocQueue alloc] init];
  });
  return deallocQueue;
}

- (void)dealloc
{
  ASDisplayNodeFailAssert(@"Singleton should not dealloc.");
}

- (void)releaseObjectInBackground:(id  _Nullable __strong *)objectPtr
{
  NSParameterAssert(objectPtr != NULL);
  
  // Cast to CFType so we can manipulate retain count manually.
  const auto cfPtr = (CFTypeRef *)(void *)objectPtr;
  if (!cfPtr || !*cfPtr) {
    return;
  }
  
  _lock.lock();
  const auto isFirstEntry = _queue.empty();
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
  _lock.lock();
  const auto q = std::move(_queue);
  _lock.unlock();
  for (CFTypeRef ref : q) {
    // NOTE: Could check that retain count is 1 and retry later if not.
    CFRelease(ref);
  }
}

@end

@implementation ASAbstractRunLoopQueue

- (instancetype)init
{
  self = [super init];
  if (self == nil) {
    return nil;
  }
  ASDisplayNodeAssert(self.class != [ASAbstractRunLoopQueue class], @"Should never create instances of abstract class ASAbstractRunLoopQueue.");
  return self;
}

@end

#pragma mark - ASRunLoopQueue

@interface ASRunLoopQueue () {
  CFRunLoopRef _runLoop;
  CFRunLoopSourceRef _runLoopSource;
  CFRunLoopObserverRef _runLoopObserver;
  NSPointerArray *_internalQueue; // Use NSPointerArray so we can decide __strong or __weak per-instance.
  AS::RecursiveMutex _internalQueueLock;

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
    // unowned(__unsafe_unretained) allows us to avoid flagging the memory cycle detector.
    unowned __typeof__(self) weakSelf = self;
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
    NSLog(@"<%@> - Jobs: %ld", self, _internalQueue.count);
}
#endif

- (void)processQueue
{
  // This vector is populated regardless of whether we have an execution block,
  // because it's important that any objects we release are released while unlocked.
  std::vector<id> itemsToProcess;

  BOOL isQueueDrained = NO;
  {
    MutexLocker l(_internalQueueLock);

    NSInteger internalQueueCount = _internalQueue.count;
    // Early-exit if the queue is empty.
    if (internalQueueCount == 0) {
      return;
    }

    ASSignpostStart(RunLoopQueueBatch, self, "%s", object_getClassName(self));

    // Snatch the next batch of items.
    NSInteger maxCountToProcess = MIN(internalQueueCount, self.batchSize);

    /**
     * For each item in the next batch, if it's non-nil then dequeue it nil it out of source array.
     */
    itemsToProcess.reserve(maxCountToProcess);
    for (NSInteger i = 0; i < internalQueueCount && itemsToProcess.size() < maxCountToProcess; i++) {
      // Note: If this is a weak NSPointerArray, the object will end up in the autorelease pool.
      // There is no way around this – it is fate.
      if (id o = (__bridge id)[_internalQueue pointerAtIndex:i]) {
        // std::move avoids retain/release.
        itemsToProcess.push_back(std::move(o));
        [_internalQueue replacePointerAtIndex:i withPointer:NULL];
      }
    }

    if (itemsToProcess.empty()) {
      // If _internalQueue holds weak references, and all of them just become NULL, then the array
      // is never marked as needsCompaction, and compact will return early, not removing the NULL's.
      // Inserting a NULL here ensures the compaction will take place.
      // See http://www.openradar.me/15396578 and https://stackoverflow.com/a/40274426/1136669
      [_internalQueue addPointer:NULL];
    }

    [_internalQueue compact];
    if (_internalQueue.count == 0) {
      isQueueDrained = YES;
    }
  } // end of lock

  const auto count = itemsToProcess.size();
  if (_queueConsumer && count > 0) {
    as_activity_scope_verbose(as_activity_create("Process run loop queue batch", _rootActivity, OS_ACTIVITY_FLAG_DEFAULT));
    // Use const-ref because this is a __strong id.
    for (const auto &value : itemsToProcess) {
      bool isLast = isQueueDrained && &value == &itemsToProcess.back();
      _queueConsumer(value, isLast);
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
  
  // Clear before ending signpost so that the releases are part of the interval.
  itemsToProcess.clear();
  ASSignpostEnd(RunLoopQueueBatch, self, "count: %d", (int)count);
}

- (void)enqueue:(id)object
{
  if (!object) {
    return;
  }
  
  MutexLocker l(_internalQueueLock);

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
    if (_internalQueue.count == 1) {
      CFRunLoopSourceSignal(_runLoopSource);
      CFRunLoopWakeUp(_runLoop);
    }
  }
}

- (BOOL)isEmpty
{
  MutexLocker l(_internalQueueLock);
  return _internalQueue.count == 0;
}

ASSynthesizeLockingMethodsWithMutex(_internalQueueLock)

@end

#pragma mark - ASCATransactionQueue

@interface ASCATransactionQueue () {
  CFRunLoopSourceRef _runLoopSource;
  CFRunLoopObserverRef _preTransactionObserver;
  CFRunLoopObserverRef _postTransactionObserver;
  
  // Current buffer for new entries, only accessed from within its mutex.
  std::vector<id<ASCATransactionQueueObserving>> _internalQueue;
  
  // No retain, no release, pointer hash, pointer equality.
  // Enforce uniqueness in our queue. std::unordered_set does a heap allocation for each entry – not good.
  CFMutableSetRef _internalQueueHashSet;
  
  // Temporary buffer, only accessed from the main thread in -process.
  std::vector<id<ASCATransactionQueueObserving>> _batchBuffer;
  
  AS::Mutex _internalQueueLock;

  // In order to not pollute the top-level activities, each queue has 1 root activity.
  os_activity_t _rootActivity;

#if ASRunLoopQueueLoggingEnabled
  NSTimer *_runloopQueueLoggingTimer;
#endif
  // We must handle re-entrant transactions. It is perfectly legal, and it does occur, for the
  // run loop to be drained from inside of the transaction, causing another observer pair to fire.
  int _transactionDepth;
}

@end

@implementation ASCATransactionQueue

// CoreAnimation commit order is 2000000, the goal of this is to process shortly beforehand
// but after most other scheduled work on the runloop has processed.
static int const kASCATransactionQueuePreOrder = 1000000;

// CoreAnimation commit order is 2000000, the goal of this is to process immediately after
// but after the run loop sleeps.
static int const kASCATransactionQueuePostOrder = 2000001;

ASCATransactionQueue *_ASSharedCATransactionQueue;
dispatch_once_t _ASSharedCATransactionQueueOnceToken;

- (instancetype)init
{
  if (self = [super init]) {
    _internalQueueHashSet = CFSetCreateMutable(NULL, 0, NULL);
    
    // This is going to be a very busy queue – every node in the preload range will enter this queue.
    // Save some time on first render by reserving space up front.
    static constexpr int kInternalQueueInitialCapacity = 64;
    _internalQueue.reserve(kInternalQueueInitialCapacity);
    _batchBuffer.reserve(kInternalQueueInitialCapacity);

    // We don't want to pollute the top-level app activities with run loop batches, so we create one top-level
    // activity per queue, and each batch activity joins that one instead.
    _rootActivity = as_activity_create("Process run loop queue items", OS_ACTIVITY_NONE, OS_ACTIVITY_FLAG_DEFAULT);
    {
      // Log a message identifying this queue into the queue's root activity.
      as_activity_scope_verbose(_rootActivity);
      as_log_verbose(ASDisplayLog(), "Created run loop queue: %@", self);
    }

    // Self is guaranteed to outlive the observer.  Without the high cost of a weak pointer,
    // unowned(__unsafe_unretained) allows us to avoid flagging the memory cycle detector.
    unowned __typeof__(self) weakSelf = self;
    _preTransactionObserver = CFRunLoopObserverCreateWithHandler(NULL, kCFRunLoopBeforeWaiting, true, kASCATransactionQueuePreOrder, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
      weakSelf->_transactionDepth++;
      while (!weakSelf->_internalQueue.empty()) {
        [weakSelf processQueue];
      }
    });
    CFRunLoopAddObserver(CFRunLoopGetMain(), _preTransactionObserver, kCFRunLoopCommonModes);
    _postTransactionObserver = CFRunLoopObserverCreateWithHandler(NULL, kCFRunLoopBeforeWaiting, true, kASCATransactionQueuePostOrder, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
      ASDisplayNodeCAssert(weakSelf->_transactionDepth > 0, @"Expected to have been in transaction.");
      weakSelf->_transactionDepth--;
      while (!weakSelf->_internalQueue.empty()) {
        [weakSelf processQueue];
      }
    });
    CFRunLoopAddObserver(CFRunLoopGetMain(), _postTransactionObserver, kCFRunLoopCommonModes);

    // It is not guaranteed that the runloop will turn if it has no scheduled work, and this causes processing of
    // the queue to stop. Attaching a custom loop source to the run loop and signal it if new work needs to be done
    CFRunLoopSourceContext sourceContext = {};
    sourceContext.perform = runLoopSourceCallback;
#if ASRunLoopQueueLoggingEnabled
    sourceContext.info = (__bridge void *)self;
#endif
    _runLoopSource = CFRunLoopSourceCreate(NULL, 0, &sourceContext);
    CFRunLoopAddSource(CFRunLoopGetMain(), _runLoopSource, kCFRunLoopCommonModes);

#if ASRunLoopQueueLoggingEnabled
    _runloopQueueLoggingTimer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(checkRunLoop) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_runloopQueueLoggingTimer forMode:NSRunLoopCommonModes];
#endif
  }
  return self;
}

- (void)dealloc
{
  ASDisplayNodeAssertMainThread();
  CFRunLoopRemoveSource(CFRunLoopGetMain(), _runLoopSource, kCFRunLoopCommonModes);
  CFRunLoopObserverInvalidate(_preTransactionObserver);
  CFRunLoopObserverInvalidate(_postTransactionObserver);

  CFRelease(_internalQueueHashSet);
  CFRelease(_runLoopSource);
  CFRelease(_preTransactionObserver);
  CFRelease(_postTransactionObserver);
}

#if ASRunLoopQueueLoggingEnabled
- (void)checkRunLoop
{
  NSLog(@"<%@> - Jobs: %ld", self, _internalQueue.count);
}
#endif

- (void)processQueue
{
  ASDisplayNodeAssertMainThread();

  AS::UniqueLock l(_internalQueueLock);
  NSInteger count = _internalQueue.size();
  // Early-exit if the queue is empty.
  if (count == 0) {
    return;
  }
  as_activity_scope_verbose(as_activity_create("Process run loop queue batch", _rootActivity, OS_ACTIVITY_FLAG_DEFAULT));
  ASSignpostStart(RunLoopQueueBatch, self, "CATransactionQueue");
  
  // Swap buffers, clear our hash table.
  _internalQueue.swap(_batchBuffer);
  CFSetRemoveAllValues(_internalQueueHashSet);
  
  // Unlock early. We are done with internal queue, and batch buffer is main-thread-only so no lock.
  l.unlock();
  
  for (const id<ASCATransactionQueueObserving> &value : _batchBuffer) {
    [value prepareForCATransactionCommit];
    as_log_verbose(ASDisplayLog(), "processed %@", value);
  }
  _batchBuffer.clear();
  as_log_verbose(ASDisplayLog(), "processed %lu items", (unsigned long)count);
  ASSignpostEnd(RunLoopQueueBatch, self, "count: %d", (int)count);
}

+ (BOOL)inTransactionCommit {
  // Note that although the _transactionDepth++ happens within runloop observer of
  // kASCATransactionQueuePreOrder, it's unlikely anything would happen after this runloop observer
  // and before the CATransaction commit.
  return [ASCATransactionQueue sharedQueue]->_transactionDepth > 0;
}

- (void)enqueue:(id<ASCATransactionQueueObserving>)object
{
  ASDisplayNodeAssertMainThread();
  if (!object) {
    return;
  }

  // If we are already in the transaction (say, in a layout method) we need to update now so that
  // any changes join the transaction.
  if (!self.enabled ||
      (_transactionDepth > 0 &&
       !ASActivateExperimentalFeature(ASExperimentalCoalesceRootNodeInTransaction))) {
    [object prepareForCATransactionCommit];
    return;
  }

  MutexLocker l(_internalQueueLock);
  if (CFSetContainsValue(_internalQueueHashSet, (__bridge void *)object)) {
    return;
  }
  CFSetAddValue(_internalQueueHashSet, (__bridge void *)object);
  _internalQueue.emplace_back(object);
  if (_internalQueue.size() == 1) {
    CFRunLoopSourceSignal(_runLoopSource);
    CFRunLoopWakeUp(CFRunLoopGetMain());
  }
}

- (BOOL)isEmpty
{
  MutexLocker l(_internalQueueLock);
  return _internalQueue.empty();
}

- (BOOL)isEnabled
{
  return ASActivateExperimentalFeature(ASExperimentalInterfaceStateCoalescing);
}

+ (ASCATransactionQueue *)sharedQueue
{
  return ASCATransactionQueueGet();
}
@end
