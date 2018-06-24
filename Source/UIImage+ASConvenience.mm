//
//  UIImage+ASConvenience.m
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

#import <AsyncDisplayKit/UIImage+ASConvenience.h>
#import <AsyncDisplayKit/ASGraphicsContext.h>
#import <AsyncDisplayKit/ASInternalHelpers.h>
#import <AsyncDisplayKit/ASAssert.h>
#import <AsyncDisplayKit/CoreGraphics+ASConvenience.h>

#pragma mark - ASDKFastImageNamed

@implementation UIImage (ASDKFastImageNamed)

UIImage *cachedImageNamed(NSString *imageName, UITraitCollection *traitCollection) NS_RETURNS_RETAINED
{
  static NSCache *imageCache = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    // Because NSCache responds to memory warnings, we do not need an explicit limit.
    // all of these objects contain compressed image data and are relatively small
    // compared to the backing stores of text and image views.
    imageCache = [[NSCache alloc] init];
  });

  UIImage *image = nil;
  if ([imageName length] > 0) {
    NSString *imageKey = imageName;
    if (traitCollection) {
      char imageKeyBuffer[256];
      snprintf(imageKeyBuffer, sizeof(imageKeyBuffer), "%s|%ld|%ld", imageName.UTF8String, (long)traitCollection.horizontalSizeClass, (long)traitCollection.verticalSizeClass);
      imageKey = [NSString stringWithUTF8String:imageKeyBuffer];
    }

    image = [imageCache objectForKey:imageKey];
    if (!image) {
      image =  [UIImage imageNamed:imageName inBundle:nil compatibleWithTraitCollection:traitCollection];
      if (image) {
        [imageCache setObject:image forKey:imageKey];
      }
    }
  }
  return image;
}

+ (UIImage *)as_imageNamed:(NSString *)imageName NS_RETURNS_RETAINED
{
  return cachedImageNamed(imageName, nil);
}

+ (UIImage *)as_imageNamed:(NSString *)imageName compatibleWithTraitCollection:(UITraitCollection *)traitCollection NS_RETURNS_RETAINED
{
  return cachedImageNamed(imageName, traitCollection);
}

@end

#pragma mark - ASDKResizableRoundedRects

@implementation UIImage (ASDKResizableRoundedRects)

+ (UIImage *)as_resizableRoundedImageWithCornerRadius:(CGFloat)cornerRadius
                                          cornerColor:(UIColor *)cornerColor
                                            fillColor:(UIColor *)fillColor NS_RETURNS_RETAINED
{
  return [self as_resizableRoundedImageWithCornerRadius:cornerRadius
                                            cornerColor:cornerColor
                                              fillColor:fillColor
                                            borderColor:nil
                                            borderWidth:1.0
                                         roundedCorners:UIRectCornerAllCorners
                                                  scale:0.0];
}

+ (UIImage *)as_resizableRoundedImageWithCornerRadius:(CGFloat)cornerRadius
                                          cornerColor:(UIColor *)cornerColor
                                            fillColor:(UIColor *)fillColor
                                          borderColor:(UIColor *)borderColor
                                          borderWidth:(CGFloat)borderWidth NS_RETURNS_RETAINED
{
  return [self as_resizableRoundedImageWithCornerRadius:cornerRadius
                                            cornerColor:cornerColor
                                              fillColor:fillColor
                                            borderColor:borderColor
                                            borderWidth:borderWidth
                                         roundedCorners:UIRectCornerAllCorners
                                                  scale:0.0];
}

+ (UIImage *)as_resizableRoundedImageWithCornerRadius:(CGFloat)cornerRadius
                                          cornerColor:(UIColor *)cornerColor
                                            fillColor:(UIColor *)fillColor
                                          borderColor:(UIColor *)borderColor
                                          borderWidth:(CGFloat)borderWidth
                                       roundedCorners:(UIRectCorner)roundedCorners
                                                scale:(CGFloat)scale NS_RETURNS_RETAINED
{
  static NSCache *__pathCache = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    __pathCache = [[NSCache alloc] init];
    // UIBezierPath objects are fairly small and these are equally sized. 20 should be plenty for many different parameters.
    __pathCache.countLimit = 20;
  });

  // Treat clear background color as no background color
  if (CGColorGetAlpha(cornerColor.CGColor) == 0) {
    cornerColor = nil;
  }
  
  CGFloat dimension = (cornerRadius * 2) + 1;
  CGRect bounds = CGRectMake(0, 0, dimension, dimension);
  
  typedef struct {
    UIRectCorner corners;
    CGFloat radius;
  } PathKey;
  PathKey key = { roundedCorners, cornerRadius };
  NSValue *pathKeyObject = [[NSValue alloc] initWithBytes:&key objCType:@encode(PathKey)];

  CGSize cornerRadii = CGSizeMake(cornerRadius, cornerRadius);
  UIBezierPath *path = [__pathCache objectForKey:pathKeyObject];
  if (path == nil) {
    path = [UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:roundedCorners cornerRadii:cornerRadii];
    [__pathCache setObject:path forKey:pathKeyObject];
  }
  
  // We should probably check if the background color has any alpha component but that
  // might be expensive due to needing to check mulitple color spaces.
  ASGraphicsBeginImageContextWithOptions(bounds.size, cornerColor != nil, scale);

  CGContextRef context = UIGraphicsGetCurrentContext();

  // Draw Corners
  BOOL contextIsClean = YES;
  if (cornerColor) {
    contextIsClean = NO;

    CGContextSetFillColorWithColor(context, cornerColor.CGColor);
    // Copy "blend" mode is extra fast because it disregards any value currently in the buffer and overrides directly.
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    CGContextFillRect(context, bounds);
  }

  // Draw fill
  BOOL canUseCopy = contextIsClean || (CGColorGetAlpha(fillColor.CGColor) == 1);
  CGContextSetFillColorWithColor(context, fillColor.CGColor);
  CGContextSetBlendMode(context, canUseCopy ? kCGBlendModeCopy : kCGBlendModeNormal);
  CGContextSetAlpha(context, 1.0);
  CGContextAddPath(context, path.CGPath);
  CGContextFillPath(context);

  // Add a border
  if (borderColor) {
    // Inset border fully inside filled path (not halfway on each side of path)
    CGRect strokeRect = CGRectInset(bounds, borderWidth / 2.0, borderWidth / 2.0);

    // It is rarer to have a stroke path, and our cache key only handles rounded rects for the exact-stretchable
    // size calculated by cornerRadius, so we won't bother caching this path.  Profiling validates this decision.
    CGPathRef strokePath = ASCGRoundedPathCreate(strokeRect, roundedCorners, cornerRadii);

    CGContextSetStrokeColorWithColor(context, borderColor.CGColor);
    CGContextSetLineWidth(context, borderWidth);
    CGContextSetAlpha(context, 1.0);
    BOOL canUseCopy = (CGColorGetAlpha(borderColor.CGColor) == 1);
    CGContextSetBlendMode(context, (canUseCopy ? kCGBlendModeCopy : kCGBlendModeNormal));
    CGContextAddPath(context, strokePath);
    CGContextStrokePath(context);

    CGPathRelease(strokePath);
  }
  
  UIImage *result = ASGraphicsGetImageAndEndCurrentContext();
  
  UIEdgeInsets capInsets = UIEdgeInsetsMake(cornerRadius, cornerRadius, cornerRadius, cornerRadius);
  result = [result resizableImageWithCapInsets:capInsets resizingMode:UIImageResizingModeStretch];
  
  return result;
}

@end
