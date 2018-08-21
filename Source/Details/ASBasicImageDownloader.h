//
//  ASBasicImageDownloader.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASImageProtocols.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @abstract Simple NSURLSession-based image downloader.
 */
@interface ASBasicImageDownloader : NSObject <ASImageDownloaderProtocol>

/**
 * A shared image downloader which can be used by @c ASNetworkImageNodes and @c ASMultiplexImageNodes.
 * The userInfo provided by this downloader is `nil`.
 *
 * This is a very basic image downloader. It does not support caching, progressive downloading and likely
 * isn't something you should use in production. If you'd like something production ready, see @c ASPINRemoteImageDownloader
 *
 * @note It is strongly recommended you include PINRemoteImage and use @c ASPINRemoteImageDownloader instead.
 */
@property (class, readonly) ASBasicImageDownloader *sharedImageDownloader;
+ (ASBasicImageDownloader *)sharedImageDownloader NS_RETURNS_RETAINED;

+ (instancetype)new __attribute__((unavailable("+[ASBasicImageDownloader sharedImageDownloader] must be used.")));
- (instancetype)init __attribute__((unavailable("+[ASBasicImageDownloader sharedImageDownloader] must be used.")));

@end

NS_ASSUME_NONNULL_END
