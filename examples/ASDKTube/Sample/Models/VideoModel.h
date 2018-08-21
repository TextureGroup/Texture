//
//  VideoModel.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>

@interface VideoModel : NSObject
@property (nonatomic, strong, readonly) NSString* title;
@property (nonatomic, strong, readonly) NSURL *url;
@property (nonatomic, strong, readonly) NSString *userName;
@property (nonatomic, strong, readonly) NSURL *avatarUrl;
@end
