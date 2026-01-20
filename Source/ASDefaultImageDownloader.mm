//
//  ASDefaultImageDownloader.m
//  Texture
//
//  Created by Andrew Finnell on 5/14/25.
//  Copyright © 2025 Pinterest. All rights reserved.
//

#import "ASDefaultImageDownloader.h"
#import <AsyncDisplayKit/ASThread.h>
#import <AsyncDisplayKit/ASBasicImageDownloader.h>
#if AS_PIN_REMOTE_IMAGE
#import <AsyncDisplayKit/ASPINRemoteImageDownloader.h>
#endif

using AS::MutexLocker;

@interface ASDefaultImageDownloader () {
  AS::Mutex *_lock;
  ASImageDownloaderProvider _downloaderProvider;
  ASImageCacheProvider _cacheProvider;
}

+ (instancetype)sharedInstance;

@end

@implementation ASDefaultImageDownloader

- (instancetype)init
{
  self = [super init];
  if (self != nil) {
    _lock = new AS::Mutex();
    _downloaderProvider = ^id<ASImageDownloaderProtocol>(void) {
#if AS_PIN_REMOTE_IMAGE
      return [ASPINRemoteImageDownloader sharedDownloader];
#else
      return [ASBasicImageDownloader sharedImageDownloader];
#endif
    };
     _cacheProvider = ^id<ASImageCacheProtocol>(void) {
#if AS_PIN_REMOTE_IMAGE
  return [ASPINRemoteImageDownloader sharedDownloader];
#else
  return nil;
#endif
    };
  }
  return self;
}

+ (instancetype)sharedInstance;
{
  static dispatch_once_t onceToken;
  static ASDefaultImageDownloader *sharedInstance = nil;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[ASDefaultImageDownloader alloc] init];
  });
  return sharedInstance;
}

- (nullable id<ASImageDownloaderProtocol>)defaultDownloader
{
  MutexLocker l(*self->_lock);
  return self->_downloaderProvider();
}

- (nullable id<ASImageCacheProtocol>)defaultCache
{
  MutexLocker l(*self->_lock);
  return self->_cacheProvider();
}

- (void)setDefaultDownloaderProvider:(ASImageDownloaderProvider _Nonnull)downloaderProvider
                       cacheProvider:(ASImageCacheProvider _Nonnull)cacheProvider
{
  MutexLocker l(*self->_lock);
  _downloaderProvider = [downloaderProvider copy];
  _cacheProvider = [cacheProvider copy];
}

+ (nullable id<ASImageDownloaderProtocol>)defaultDownloader
{
  return [[ASDefaultImageDownloader sharedInstance] defaultDownloader];
}

+ (nullable id<ASImageCacheProtocol>)defaultCache
{
  return [[ASDefaultImageDownloader sharedInstance] defaultCache];
}

+ (void)setDefaultDownloaderProvider:(ASImageDownloaderProvider _Nonnull)downloaderProvider
                       cacheProvider:(ASImageCacheProvider _Nonnull)cacheProvider
{
  [[ASDefaultImageDownloader sharedInstance] setDefaultDownloaderProvider:downloaderProvider
                                                            cacheProvider:cacheProvider];
}

@end
