//
//  ASGraphicsContext.m
//  Texture
//
//  Copyright (c) 2018-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASGraphicsContext.h"
#import <AsyncDisplayKit/ASAssert.h>
#import <AsyncDisplayKit/ASConfigurationManager.h>
#import <UIKit/UIGraphics.h>
#import <UIKit/UIImage.h>
#import <stdatomic.h>

#pragma mark - Callbacks

void _ASReleaseCGDataProviderData(__unused void *info, const void *data, __unused size_t size)
{
  free((void *)data);
}

#pragma mark - Graphics Contexts

extern void ASGraphicsBeginImageContextWithOptions(CGSize size, BOOL opaque, CGFloat scale)
{
  if (!ASActivateExperimentalFeature(ASExperimentalGraphicsContexts)) {
    UIGraphicsBeginImageContextWithOptions(size, opaque, scale);
    return;
  }
  
  // Only create device RGB color space once. UIGraphics actually doesn't do this but it's safe.
  static dispatch_once_t onceToken;
  static CGFloat defaultScale;
  static CGColorSpaceRef deviceRGB;
  dispatch_once(&onceToken, ^{
    deviceRGB = CGColorSpaceCreateDeviceRGB();
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 1), NO, 0);
    CGContextRef uikitContext = UIGraphicsGetCurrentContext();
    defaultScale = CGContextGetCTM(uikitContext).a;
    UIGraphicsEndImageContext();
  });
  
  // These options are taken from UIGraphicsBeginImageContext.
  CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host | (opaque ? kCGImageAlphaNoneSkipFirst : kCGImageAlphaPremultipliedFirst);
  
  if (scale == 0) {
    scale = defaultScale;
  }
  size_t intWidth = (size_t)ceil(size.width * scale);
  size_t intHeight = (size_t)ceil(size.height * scale);
  size_t bytesPerPixel = 4;
  size_t bytesPerRow = bytesPerPixel * intWidth;
  size_t bufferSize = bytesPerRow * intHeight;

  // We create our own buffer, and wrap the context around that. This way we can prevent
  // the copy that usually gets made when you form a CGImage from the context.
  void *buf = calloc(bufferSize, 1);
  CGContextRef context = CGBitmapContextCreate(buf, intWidth, intHeight, 8, bytesPerRow, deviceRGB, bitmapInfo);
  
  // Set the CTM to account for iOS orientation & specified scale.
  // If only we could use CGContextSetBaseCTM. It doesn't
  // seem like there are any consequences for our use case
  // but we'll be on the look out. The internet hinted that it
  // affects shadowing but I tested and shadowing works.
  CGContextTranslateCTM(context, 0, intHeight);
  CGContextScaleCTM(context, scale, -scale);
  
  // Save the state so we can restore it and recover our scale in GetImageAndEnd
  CGContextSaveGState(context);
  
  UIGraphicsPushContext(context);
}

extern UIImage * _Nullable ASGraphicsGetImageAndEndCurrentContext()
{
  if (!ASActivateExperimentalFeature(ASExperimentalGraphicsContexts)) {
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
  }
  
  // Pop the context and make sure we have one.
  CGContextRef context = UIGraphicsGetCurrentContext();
  if (context == NULL) {
    ASDisplayNodeCFailAssert(@"Can't end image context without having begun one.");
    return nil;
  }
  UIGraphicsPopContext();
  
  // Do some math to get the image properties.
  size_t width = CGBitmapContextGetWidth(context);
  size_t height = CGBitmapContextGetHeight(context);
  size_t bitsPerPixel = CGBitmapContextGetBitsPerPixel(context);
  size_t bytesPerRow = CGBitmapContextGetBytesPerRow(context);
  size_t bufferSize = bytesPerRow * height;
  
  // This is the buf that we malloc'd above.
  void *buf = CGBitmapContextGetData(context);
  
  // Wrap it in a CGDataProvider, passing along our release callback for when the CGImage dies.
  CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buf, bufferSize, _ASReleaseCGDataProviderData);
  
  // Create the CGImage. Options taken from CGBitmapContextCreateImage.
  CGImageRef cgImg = CGImageCreate(width, height, CGBitmapContextGetBitsPerComponent(context), bitsPerPixel, bytesPerRow, CGBitmapContextGetColorSpace(context), CGBitmapContextGetBitmapInfo(context), provider, NULL, true, kCGRenderingIntentDefault);
  CGDataProviderRelease(provider);
  
  // We saved our GState right after setting the CTM so that we could restore it
  // here and get the original scale back.
  CGContextRestoreGState(context);
  CGFloat scale = CGContextGetCTM(context).a;
  CGContextRelease(context);
  
  UIImage *result = [[UIImage alloc] initWithCGImage:cgImg scale:scale orientation:UIImageOrientationUp];
  CGImageRelease(cgImg);
  return result;
}

extern void ASGraphicsEndImageContext()
{
  if (!ASActivateExperimentalFeature(ASExperimentalGraphicsContexts)) {
    UIGraphicsEndImageContext();
    return;
  }
  
  CGContextRef context = UIGraphicsGetCurrentContext();
  if (context) {
    // We manually allocated this buffer so we need to free it.
    free(CGBitmapContextGetData(context));
    CGContextRelease(context);
    UIGraphicsPopContext();
  }
}
