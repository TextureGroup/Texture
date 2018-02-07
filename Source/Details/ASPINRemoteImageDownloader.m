//
//  ASPINRemoteImageDownloader.m
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

#if AS_PIN_REMOTE_IMAGE
#import <AsyncDisplayKit/ASPINRemoteImageDownloader.h>

#import <AsyncDisplayKit/ASAssert.h>
#import <AsyncDisplayKit/ASThread.h>
#import <AsyncDisplayKit/ASImageContainerProtocolCategories.h>

#if __has_include (<PINRemoteImage/PINGIFAnimatedImage.h>)
#define PIN_ANIMATED_AVAILABLE 1
#import <PINRemoteImage/PINCachedAnimatedImage.h>
#import <PINRemoteImage/PINAlternateRepresentationProvider.h>
#else
#define PIN_ANIMATED_AVAILABLE 0
#endif

#if __has_include(<webp/decode.h>)
#define PIN_WEBP_AVAILABLE  1
#else
#define PIN_WEBP_AVAILABLE  0
#endif

#import <PINRemoteImage/PINRemoteImageManager.h>
#import <PINRemoteImage/NSData+ImageDetectors.h>
#import <PINRemoteImage/PINRemoteImageCaching.h>

#if PIN_ANIMATED_AVAILABLE

@interface ASPINRemoteImageDownloader () <PINRemoteImageManagerAlternateRepresentationProvider>

@end

@interface PINCachedAnimatedImage (ASPINRemoteImageDownloader) <ASAnimatedImageProtocol>

@end

@implementation PINCachedAnimatedImage (ASPINRemoteImageDownloader)

- (BOOL)isDataSupported:(NSData *)data
{
    if ([data pin_isGIF]) {
        return YES;
    }
#if PIN_WEBP_AVAILABLE
    else if ([data pin_isAnimatedWebP]) {
        return YES;
    }
#endif
  return NO;
}

@end
#endif

// Declare two key methods on PINCache objects, avoiding a direct dependency on PINCache.h
@protocol ASPINCache
- (id)diskCache;
@end

@protocol ASPINDiskCache
@property (assign) NSUInteger byteLimit;
@end

@interface ASPINRemoteImageManager : PINRemoteImageManager
@end

@implementation ASPINRemoteImageManager

//Share image cache with sharedImageManager image cache.
- (id <PINRemoteImageCaching>)defaultImageCache
{
  static dispatch_once_t onceToken;
  static id <PINRemoteImageCaching> cache = nil;
  dispatch_once(&onceToken, ^{
    cache = [[PINRemoteImageManager sharedImageManager] cache];
    if ([cache respondsToSelector:@selector(diskCache)]) {
      id diskCache = [(id <ASPINCache>)cache diskCache];
      if ([diskCache respondsToSelector:@selector(setByteLimit:)]) {
        // Set a default byteLimit. PINCache recently implemented a 50MB default (PR #201).
        // Ensure that older versions of PINCache also have a byteLimit applied.
        // NOTE: Using 20MB limit while large cache initialization is being optimized (Issue #144).
        ((id <ASPINDiskCache>)diskCache).byteLimit = 20 * 1024 * 1024;
      }
    }
  });
  return cache;
}

@end


static ASPINRemoteImageDownloader *sharedDownloader = nil;

@interface ASPINRemoteImageDownloader ()
@end

@implementation ASPINRemoteImageDownloader

+ (ASPINRemoteImageDownloader *)sharedDownloader
{

  static dispatch_once_t onceToken = 0;
  dispatch_once(&onceToken, ^{
    sharedDownloader = [[ASPINRemoteImageDownloader alloc] init];
  });
  return sharedDownloader;
}

+ (void)setSharedImageManagerWithConfiguration:(nullable NSURLSessionConfiguration *)configuration
{
  NSAssert(sharedDownloader == nil, @"Singleton has been created and session can no longer be configured.");
  __unused PINRemoteImageManager *sharedManager = [self sharedPINRemoteImageManagerWithConfiguration:configuration];
}

+ (PINRemoteImageManager *)sharedPINRemoteImageManagerWithConfiguration:(NSURLSessionConfiguration *)configuration
{
  static ASPINRemoteImageManager *sharedPINRemoteImageManager;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{

#if PIN_ANIMATED_AVAILABLE
    // Check that Carthage users have linked both PINRemoteImage & PINCache by testing for one file each
    if (!(NSClassFromString(@"PINRemoteImageManager"))) {
      NSException *e = [NSException
                        exceptionWithName:@"FrameworkSetupException"
                        reason:@"Missing the path to the PINRemoteImage framework."
                        userInfo:nil];
      @throw e;
    }
    if (!(NSClassFromString(@"PINCache"))) {
      NSException *e = [NSException
                        exceptionWithName:@"FrameworkSetupException"
                        reason:@"Missing the path to the PINCache framework."
                        userInfo:nil];
      @throw e;
    }
    sharedPINRemoteImageManager = [[ASPINRemoteImageManager alloc] initWithSessionConfiguration:configuration
                                                              alternativeRepresentationProvider:[self sharedDownloader]];
#else
    sharedPINRemoteImageManager = [[ASPINRemoteImageManager alloc] initWithSessionConfiguration:configuration];
#endif
  });
  return sharedPINRemoteImageManager;
}

- (PINRemoteImageManager *)sharedPINRemoteImageManager
{
  return [ASPINRemoteImageDownloader sharedPINRemoteImageManagerWithConfiguration:nil];
}

- (BOOL)sharedImageManagerSupportsMemoryRemoval
{
  static BOOL sharedImageManagerSupportsMemoryRemoval = NO;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedImageManagerSupportsMemoryRemoval = [[[self sharedPINRemoteImageManager] cache] respondsToSelector:@selector(removeObjectForKeyFromMemory:)];
  });
  return sharedImageManagerSupportsMemoryRemoval;
}

#pragma mark ASImageProtocols

#if PIN_ANIMATED_AVAILABLE
- (nullable id <ASAnimatedImageProtocol>)animatedImageWithData:(NSData *)animatedImageData
{
  return [[PINCachedAnimatedImage alloc] initWithAnimatedImageData:animatedImageData];
}
#endif

- (id <ASImageContainerProtocol>)synchronouslyFetchedCachedImageWithURL:(NSURL *)URL;
{
  PINRemoteImageManager *manager = [self sharedPINRemoteImageManager];
  PINRemoteImageManagerResult *result = [manager synchronousImageFromCacheWithURL:URL processorKey:nil options:PINRemoteImageManagerDownloadOptionsSkipDecode];
  
#if PIN_ANIMATED_AVAILABLE
  if (result.alternativeRepresentation) {
    return result.alternativeRepresentation;
  }
#endif
  return result.image;
}

- (void)cachedImageWithURL:(NSURL *)URL
             callbackQueue:(dispatch_queue_t)callbackQueue
                completion:(ASImageCacherCompletion)completion
{
  [[self sharedPINRemoteImageManager] imageFromCacheWithURL:URL processorKey:nil options:PINRemoteImageManagerDownloadOptionsSkipDecode completion:^(PINRemoteImageManagerResult * _Nonnull result) {
    [ASPINRemoteImageDownloader _performWithCallbackQueue:callbackQueue work:^{
      completion(result.image);
    }];
  }];
}

- (void)clearFetchedImageFromCacheWithURL:(NSURL *)URL
{
  if ([self sharedImageManagerSupportsMemoryRemoval]) {
    PINRemoteImageManager *manager = [self sharedPINRemoteImageManager];
    NSString *key = [manager cacheKeyForURL:URL processorKey:nil];
    [[manager cache] removeObjectForKeyFromMemory:key];
  }
}

- (nullable id)downloadImageWithURL:(NSURL *)URL
                      callbackQueue:(dispatch_queue_t)callbackQueue
                   downloadProgress:(ASImageDownloaderProgress)downloadProgress
                         completion:(ASImageDownloaderCompletion)completion;
{
  PINRemoteImageManagerProgressDownload progressDownload = ^(int64_t completedBytes, int64_t totalBytes) {
    if (downloadProgress == nil) { return; }

    [ASPINRemoteImageDownloader _performWithCallbackQueue:callbackQueue work:^{
      downloadProgress(completedBytes / (CGFloat)totalBytes);
    }];
  };

  PINRemoteImageManagerImageCompletion imageCompletion = ^(PINRemoteImageManagerResult * _Nonnull result) {
    [ASPINRemoteImageDownloader _performWithCallbackQueue:callbackQueue work:^{
#if PIN_ANIMATED_AVAILABLE
      if (result.alternativeRepresentation) {
        completion(result.alternativeRepresentation, result.error, result.UUID, result);
      } else {
        completion(result.image, result.error, result.UUID, result);
      }
#else
      completion(result.image, result.error, result.UUID, result);
#endif
    }];
  };

  // add "IgnoreCache" option since we have a caching API so we already checked it, not worth checking again.
  // PINRemoteImage is responsible for coalescing downloads, and even if it wasn't, the tiny probability of
  // extra downloads isn't worth the effort of rechecking caches every single time. In order to provide
  // feedback to the consumer about whether images are cached, we can't simply make the cache a no-op and
  // check the cache as part of this download.
  return [[self sharedPINRemoteImageManager] downloadImageWithURL:URL
                                                          options:PINRemoteImageManagerDownloadOptionsSkipDecode | PINRemoteImageManagerDownloadOptionsIgnoreCache
                                                    progressImage:nil
                                                 progressDownload:progressDownload
                                                       completion:imageCompletion];
}

- (void)cancelImageDownloadForIdentifier:(id)downloadIdentifier
{
  ASDisplayNodeAssert([downloadIdentifier isKindOfClass:[NSUUID class]], @"downloadIdentifier must be NSUUID");
  [[self sharedPINRemoteImageManager] cancelTaskWithUUID:downloadIdentifier storeResumeData:NO];
}

- (void)cancelImageDownloadWithResumePossibilityForIdentifier:(id)downloadIdentifier
{
  ASDisplayNodeAssert([downloadIdentifier isKindOfClass:[NSUUID class]], @"downloadIdentifier must be NSUUID");
  [[self sharedPINRemoteImageManager] cancelTaskWithUUID:downloadIdentifier storeResumeData:YES];
}

- (void)setProgressImageBlock:(ASImageDownloaderProgressImage)progressBlock callbackQueue:(dispatch_queue_t)callbackQueue withDownloadIdentifier:(id)downloadIdentifier
{
  ASDisplayNodeAssert([downloadIdentifier isKindOfClass:[NSUUID class]], @"downloadIdentifier must be NSUUID");

  if (progressBlock) {
    [[self sharedPINRemoteImageManager] setProgressImageCallback:^(PINRemoteImageManagerResult * _Nonnull result) {
      dispatch_async(callbackQueue, ^{
        progressBlock(result.image, result.renderedImageQuality, result.UUID);
      });
    } ofTaskWithUUID:downloadIdentifier];
  } else {
    [[self sharedPINRemoteImageManager] setProgressImageCallback:nil ofTaskWithUUID:downloadIdentifier];
  }
}

- (void)setPriority:(ASImageDownloaderPriority)priority withDownloadIdentifier:(id)downloadIdentifier
{
  ASDisplayNodeAssert([downloadIdentifier isKindOfClass:[NSUUID class]], @"downloadIdentifier must be NSUUID");

  PINRemoteImageManagerPriority pi_priority = PINRemoteImageManagerPriorityDefault;
  switch (priority) {
    case ASImageDownloaderPriorityPreload:
      pi_priority = PINRemoteImageManagerPriorityLow;
      break;

    case ASImageDownloaderPriorityImminent:
      pi_priority = PINRemoteImageManagerPriorityDefault;
      break;

    case ASImageDownloaderPriorityVisible:
      pi_priority = PINRemoteImageManagerPriorityHigh;
      break;
  }
  [[self sharedPINRemoteImageManager] setPriority:pi_priority ofTaskWithUUID:downloadIdentifier];
}

#pragma mark - PINRemoteImageManagerAlternateRepresentationProvider

- (id)alternateRepresentationWithData:(NSData *)data options:(PINRemoteImageManagerDownloadOptions)options
{
#if PIN_ANIMATED_AVAILABLE
  if ([data pin_isGIF]) {
    return data;
  }
#if PIN_WEBP_AVAILABLE
  else if ([data pin_isAnimatedWebP]) {
      return data;
  }
#endif
    
#endif
  return nil;
}

#pragma mark - Private

/**
 * If on main thread and queue is main, perform now.
 * If queue is nil, assert and perform now.
 * Otherwise, dispatch async to queue.
 */
+ (void)_performWithCallbackQueue:(dispatch_queue_t)queue work:(void (^)(void))work
{
  if (work == nil) {
    // No need to assert here, really. We aren't expecting any feedback from this method.
    return;
  }

  if (ASDisplayNodeThreadIsMain() && queue == dispatch_get_main_queue()) {
    work();
  } else if (queue == nil) {
    ASDisplayNodeFailAssert(@"Callback queue should not be nil.");
    work();
  } else {
    dispatch_async(queue, work);
  }
}

@end
#endif
