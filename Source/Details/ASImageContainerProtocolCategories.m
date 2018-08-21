//
//  ASImageContainerProtocolCategories.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASImageContainerProtocolCategories.h>

@implementation UIImage (ASImageContainerProtocol)

- (UIImage *)asdk_image
{
    return self;
}

- (NSData *)asdk_animatedImageData
{
    return nil;
}

@end

@implementation NSData (ASImageContainerProtocol)

- (UIImage *)asdk_image
{
    return nil;
}

- (NSData *)asdk_animatedImageData
{
    return self;
}

@end
