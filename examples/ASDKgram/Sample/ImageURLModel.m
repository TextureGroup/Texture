//
//  ImageURLModel.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "ImageURLModel.h"

@implementation ImageURLModel

+ (NSString *)imageParameterForClosestImageSize:(CGSize)size
{
  BOOL squareImageRequested = (size.width == size.height) ? YES : NO;
  
  if (squareImageRequested) {
    NSUInteger imageParameterID = [self imageParameterForSquareCroppedSize:size];
    return [NSString stringWithFormat:@"&image_size=%lu", (long)imageParameterID];
  } else {
    return @"";
  }
}

// 500px standard cropped image sizes
+ (NSUInteger)imageParameterForSquareCroppedSize:(CGSize)size
{
  NSUInteger imageParameterID;
  
  if (size.height <= 70) {
    imageParameterID = 1;
  } else if (size.height <= 100) {
    imageParameterID = 100;
  } else if (size.height <= 140) {
    imageParameterID = 2;
  } else if (size.height <= 200) {
    imageParameterID = 200;
  } else if (size.height <= 280) {
    imageParameterID = 3;
  } else if (size.height <= 400) {
    imageParameterID = 400;
  } else {
    imageParameterID = 600;
  }
  
  return imageParameterID;
}

@end
