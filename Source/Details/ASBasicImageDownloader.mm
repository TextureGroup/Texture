//
//  ASBasicImageDownloader.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASBasicImageDownloader.h>

#import <objc/runtime.h>

#import <AsyncDisplayKit/ASBasicImageDownloaderInternal.h>
#import <AsyncDisplayKit/ASImageContainerProtocolCategories.h>
#import <AsyncDisplayKit/ASThread.h>


#pragma mark -
/**
 * Collection of properties associated with a download request.
 */

NSString * const kASBasicImageDownloaderContextCallbackQueue = @"kASBasicImageDownloaderContextCallbackQueue";
NSString * const kASBasicImageDownloaderContextProgressBlock = @"kASBasicImageDownloaderContextProgressBlock";
NSString * const kASBasicImageDownloaderContextCompletionBlock = @"kASBasicImageDownloaderContextCompletionBlock";

@interface ASBasicImageDownloaderContext ()
{
  BOOL _invalid;
  ASDN::RecursiveMutex __instanceLock__;
}

@property (nonatomic) NSMutableArray *callbackDatas;

@end

@implementation ASBasicImageDownloaderContext

static NSMutableDictionary *currentRequests = nil;

+ (ASDN::Mutex *)currentRequestLock
{
  static dispatch_once_t onceToken;
  static ASDN::Mutex *currentRequestsLock;
  dispatch_once(&onceToken, ^{
    currentRequestsLock = new ASDN::Mutex();
  });
  return currentRequestsLock;
}

+ (ASBasicImageDownloaderContext *)contextForURL:(NSURL *)URL
{
  ASDN::MutexLocker l(*self.currentRequestLock);
  if (!currentRequests) {
    currentRequests = [[NSMutableDictionary alloc] init];
  }
  ASBasicImageDownloaderContext *context = currentRequests[URL];
  if (!context) {
    context = [[ASBasicImageDownloaderContext alloc] initWithURL:URL];
    currentRequests[URL] = context;
  }
  return context;
}

+ (void)cancelContextWithURL:(NSURL *)URL
{
  ASDN::MutexLocker l(*self.currentRequestLock);
  if (currentRequests) {
    [currentRequests removeObjectForKey:URL];
  }
}

- (instancetype)initWithURL:(NSURL *)URL
{
  if (self = [super init]) {
    _URL = URL;
    _callbackDatas = [NSMutableArray array];
  }
  return self;
}

- (void)cancel
{
  ASDN::MutexLocker l(__instanceLock__);

  NSURLSessionTask *sessionTask = self.sessionTask;
  if (sessionTask) {
    [sessionTask cancel];
    self.sessionTask = nil;
  }

  _invalid = YES;
  [self.class cancelContextWithURL:self.URL];
}

- (BOOL)isCancelled
{
  ASDN::MutexLocker l(__instanceLock__);
  return _invalid;
}

- (void)addCallbackData:(NSDictionary *)callbackData
{
  ASDN::MutexLocker l(__instanceLock__);
  [self.callbackDatas addObject:callbackData];
}

- (void)performProgressBlocks:(CGFloat)progress
{
  ASDN::MutexLocker l(__instanceLock__);
  for (NSDictionary *callbackData in self.callbackDatas) {
    ASImageDownloaderProgress progressBlock = callbackData[kASBasicImageDownloaderContextProgressBlock];
    dispatch_queue_t callbackQueue = callbackData[kASBasicImageDownloaderContextCallbackQueue];

    if (progressBlock) {
      dispatch_async(callbackQueue, ^{
        progressBlock(progress);
      });
    }
  }
}

- (void)completeWithImage:(UIImage *)image error:(NSError *)error
{
  ASDN::MutexLocker l(__instanceLock__);
  for (NSDictionary *callbackData in self.callbackDatas) {
    ASImageDownloaderCompletion completionBlock = callbackData[kASBasicImageDownloaderContextCompletionBlock];
    dispatch_queue_t callbackQueue = callbackData[kASBasicImageDownloaderContextCallbackQueue];

    if (completionBlock) {
      dispatch_async(callbackQueue, ^{
        completionBlock(image, error, nil, nil);
      });
    }
  }

  self.sessionTask = nil;
  [self.callbackDatas removeAllObjects];
}

- (NSURLSessionTask *)createSessionTaskIfNecessaryWithBlock:(NSURLSessionTask *(^)())creationBlock {
  {
    ASDN::MutexLocker l(__instanceLock__);

    if (self.isCancelled) {
      return nil;
    }

    if (self.sessionTask && (self.sessionTask.state == NSURLSessionTaskStateRunning)) {
      return nil;
    }
  }

  NSURLSessionTask *newTask = creationBlock();

  {
    ASDN::MutexLocker l(__instanceLock__);

    if (self.isCancelled) {
      return nil;
    }

    if (self.sessionTask && (self.sessionTask.state == NSURLSessionTaskStateRunning)) {
      return nil;
    }

    self.sessionTask = newTask;
    
    return self.sessionTask;
  }
}

@end


#pragma mark -
/**
 * NSURLSessionDownloadTask lacks a `userInfo` property, so add this association ourselves.
 */
@interface NSURLRequest (ASBasicImageDownloader)
@property (nonatomic) ASBasicImageDownloaderContext *asyncdisplaykit_context;
@end

@implementation NSURLRequest (ASBasicImageDownloader)

static const void *ContextKey() {
  return @selector(asyncdisplaykit_context);
}

- (void)setAsyncdisplaykit_context:(ASBasicImageDownloaderContext *)asyncdisplaykit_context
{
  objc_setAssociatedObject(self, ContextKey(), asyncdisplaykit_context, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (ASBasicImageDownloader *)asyncdisplaykit_context
{
  return objc_getAssociatedObject(self, ContextKey());
}
@end


#pragma mark -
@interface ASBasicImageDownloader () <NSURLSessionDownloadDelegate>
{
  NSOperationQueue *_sessionDelegateQueue;
  NSURLSession *_session;
}

@end

@implementation ASBasicImageDownloader

+ (ASBasicImageDownloader *)sharedImageDownloader
{
  static ASBasicImageDownloader *sharedImageDownloader = nil;
  static dispatch_once_t once = 0;
  dispatch_once(&once, ^{
    sharedImageDownloader = [[ASBasicImageDownloader alloc] _init];
  });
  return sharedImageDownloader;
}

#pragma mark Lifecycle.

- (instancetype)_init
{
  if (!(self = [super init]))
    return nil;

  _sessionDelegateQueue = [[NSOperationQueue alloc] init];
  _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                           delegate:self
                                      delegateQueue:_sessionDelegateQueue];

  return self;
}


#pragma mark ASImageDownloaderProtocol.

- (id)downloadImageWithURL:(NSURL *)URL
             callbackQueue:(dispatch_queue_t)callbackQueue
          downloadProgress:(nullable ASImageDownloaderProgress)downloadProgress
                completion:(ASImageDownloaderCompletion)completion
{
  ASBasicImageDownloaderContext *context = [ASBasicImageDownloaderContext contextForURL:URL];

  // NSURLSessionDownloadTask will do file I/O to create a temp directory. If called on the main thread this will
  // cause significant performance issues.
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    // associate metadata with it
    const auto callbackData = [[NSMutableDictionary alloc] init];
    callbackData[kASBasicImageDownloaderContextCallbackQueue] = callbackQueue ? : dispatch_get_main_queue();

    if (downloadProgress) {
      callbackData[kASBasicImageDownloaderContextProgressBlock] = [downloadProgress copy];
    }

    if (completion) {
      callbackData[kASBasicImageDownloaderContextCompletionBlock] = [completion copy];
    }

    [context addCallbackData:[[NSDictionary alloc] initWithDictionary:callbackData]];

    // Create new task if necessary
    NSURLSessionDownloadTask *task = (NSURLSessionDownloadTask *)[context createSessionTaskIfNecessaryWithBlock:^(){return [_session downloadTaskWithURL:URL];}];

    if (task) {
      task.originalRequest.asyncdisplaykit_context = context;

      // start downloading
      [task resume];
    }
  });

  return context;
}

- (void)cancelImageDownloadForIdentifier:(id)downloadIdentifier
{
  ASDisplayNodeAssert([downloadIdentifier isKindOfClass:ASBasicImageDownloaderContext.class], @"unexpected downloadIdentifier");
  ASBasicImageDownloaderContext *context = (ASBasicImageDownloaderContext *)downloadIdentifier;

  [context cancel];
}


#pragma mark NSURLSessionDownloadDelegate.

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
                                           didWriteData:(int64_t)bytesWritten
                                      totalBytesWritten:(int64_t)totalBytesWritten
                              totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
  ASBasicImageDownloaderContext *context = downloadTask.originalRequest.asyncdisplaykit_context;
  [context performProgressBlocks:(CGFloat)totalBytesWritten / (CGFloat)totalBytesExpectedToWrite];
}

// invoked if the download succeeded with no error
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
                              didFinishDownloadingToURL:(NSURL *)location
{
  ASBasicImageDownloaderContext *context = downloadTask.originalRequest.asyncdisplaykit_context;
  if ([context isCancelled]) {
    return;
  }

  if (context) {
    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:location]];
    [context completeWithImage:image error:nil];
  }
}

// invoked unconditionally
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionDownloadTask *)task
                           didCompleteWithError:(NSError *)error
{
  ASBasicImageDownloaderContext *context = task.originalRequest.asyncdisplaykit_context;
  if (context && error) {
    [context completeWithImage:nil error:error];
  }
}

@end
