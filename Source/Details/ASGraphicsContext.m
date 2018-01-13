//
//  ASGraphicsContext.m
//  AsyncDisplayKit
//
//  Created by Adlai on 1/12/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "ASGraphicsContext.h"
#import <AsyncDisplayKit/ASAssert.h>
#import <UIKit/UIGraphics.h>
#import <UIKit/UIImage.h>
#import <objc/runtime.h>

#if AS_ENABLE_NO_COPY_RENDERING

/**
 * We need to store the scale information for each context, for when we go
 * to create a UIImage from the CGImage.
 *
 * These functions access a thread-local stack of scales..
 */
void ASPushScale(CGFloat scale);
CGFloat ASPopScale(void);

extern void ASGraphicsBeginImageContextWithOptions(CGSize size, BOOL opaque, CGFloat scale)
{
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
  if (scale == 0) {
    scale = defaultScale;
  }
  CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host | (opaque ? kCGImageAlphaNoneSkipFirst : kCGImageAlphaPremultipliedFirst);
  
  size_t intWidth = (size_t)ceil(size.width * scale);
  size_t intHeight = (size_t)ceil(size.height * scale);
  size_t bytesPerPixel = 4;
  size_t bytesPerRow = bytesPerPixel * intWidth;
  size_t bufferSize = bytesPerRow * intHeight;

  // We create our own buffer, and wrap the context around that. This way we can prevent
  // the copy that usually gets made when you form a CGImage from the context.
  void *buf = malloc(bufferSize);
  CGContextRef context = CGBitmapContextCreate(buf, intWidth, intHeight, 8, bytesPerRow, deviceRGB, bitmapInfo);
  
  // Set the CTM to account for iOS orientation & specified scale.
  // If only we could use CGContextSetBaseCTM. It doesn't
  // seem like there are any consequences for our use case
  // but we'll be on the look out. The internet hinted that it
  // affects shadowing but I tested and shadowing works.
  CGContextTranslateCTM(context, 0, intHeight);
  CGContextScaleCTM(context, scale, -scale);
  
  UIGraphicsPushContext(context);
  ASPushScale(scale);
}

extern UIImage * _Nullable ASGraphicsGetImageAndEndCurrentContext()
{
  // Pop the context and make sure we have one.
  CGContextRef context = UIGraphicsGetCurrentContext();
  if (context == NULL) {
    ASDisplayNodeCFailAssert(@"Can't end image context without having begun one.");
    return nil;
  }
  UIGraphicsPopContext();
  CGFloat scale = ASPopScale();
  
  // Do some math to get the image properties.
  size_t width = CGBitmapContextGetWidth(context);
  size_t height = CGBitmapContextGetHeight(context);
  size_t bitsPerPixel = CGBitmapContextGetBitsPerPixel(context);
  size_t bytesPerRow = CGBitmapContextGetBytesPerRow(context);
  size_t bufferSize = bytesPerRow * height;
  
  // This is the buf that we malloc'd above.
  void *buf = CGBitmapContextGetData(context);
  
  
  // Wrap it in an NSData, and wrap that in a CGImageProvider.
  NSData *data = [NSData dataWithBytesNoCopy:buf length:bufferSize freeWhenDone:YES];
  CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
  
  // Options taken from CGBitmapContextCreateImage
  CGImageRef cgImg = CGImageCreate(width, height, CGBitmapContextGetBitsPerComponent(context), bitsPerPixel, bytesPerRow, CGBitmapContextGetColorSpace(context), CGBitmapContextGetBitmapInfo(context), provider, NULL, true, kCGRenderingIntentDefault);
  CGContextRelease(context);
  CGDataProviderRelease(provider);
  
  UIImage *result = [[UIImage alloc] initWithCGImage:cgImg scale:scale orientation:UIImageOrientationUp];
  CGImageRelease(cgImg);
  return result;
}

extern void ASGraphicsEndImageContext()
{
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextRelease(context);
  UIGraphicsPopContext();
  ASPopScale();
}

typedef struct {
  NSUInteger count;
  CGFloat scales[32];
} ASContextStack;

pthread_key_t ASContextStackKey;

ASContextStack *ASGetContextStack(BOOL create)
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    pthread_key_create(&ASContextStackKey, free);
  });
  ASContextStack *stack = pthread_getspecific(ASContextStackKey);
  if (stack == NULL && create) {
    stack = malloc(sizeof(ASContextStack));
    stack->count = 0;
    pthread_setspecific(ASContextStackKey, stack);
  }
  return stack;
}

CGFloat ASPopScale()
{
  ASContextStack *stack = ASGetContextStack(NO);
  if (stack && stack->count > 0) {
    CGFloat scale = stack->scales[stack->count];
    stack->count -= 1;
    return scale;
  } else {
    ASDisplayNodeCFailAssert(@"No context to pop.");
    return 0;
  }
}

void ASPushScale(CGFloat scale)
{
  ASContextStack *stack = ASGetContextStack(YES);
  stack->scales[stack->count] = scale;
  stack->count += 1;
}

#else

// No-copy rendering is disabled. Just pass through.

extern void ASGraphicsBeginImageContextWithOptions(CGSize size, BOOL opaque, CGFloat scale)
{
  UIGraphicsBeginImageContextWithOptions(size, opaque, scale);
}

extern UIImage *ASGraphicsGetImageAndEndCurrentContext()
{
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

extern void ASGraphicsEndImageContext()
{
  UIGraphicsEndImageContext();
}

#endif // AS_ENABLE_NO_COPY_RENDERING
