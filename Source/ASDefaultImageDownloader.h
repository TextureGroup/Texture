//
//  ASDefaultImageDownloader.h
//  Texture
//
//  Created by Andrew Finnell on 5/14/25.
//  Copyright © 2025 Pinterest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/ASImageProtocols.h>

NS_ASSUME_NONNULL_BEGIN

typedef id<ASImageDownloaderProtocol>_Nullable(^ASImageDownloaderProvider)(void);
typedef id<ASImageCacheProtocol>_Nullable(^ASImageCacheProvider)(void);

@interface ASDefaultImageDownloader : NSObject

+ (nullable id<ASImageDownloaderProtocol>)defaultDownloader;
+ (nullable id<ASImageCacheProtocol>)defaultCache;

+ (void)setDefaultDownloaderProvider:(ASImageDownloaderProvider _Nonnull)downloaderProvider
                       cacheProvider:(ASImageCacheProvider _Nonnull)cacheProvider;

@end

NS_ASSUME_NONNULL_END
