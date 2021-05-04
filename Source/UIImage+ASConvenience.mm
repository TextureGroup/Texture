//
//  UIImage+ASConvenience.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/UIImage+ASConvenience.h>
#import <AsyncDisplayKit/ASGraphicsContext.h>
#import <AsyncDisplayKit/ASInternalHelpers.h>

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
      if (@available(iOS 12.0, tvOS 10.0, *)) {
        snprintf(imageKeyBuffer, sizeof(imageKeyBuffer), "%s|%ld|%ld|%ld", imageName.UTF8String, (long)traitCollection.horizontalSizeClass, (long)traitCollection.verticalSizeClass, (long)traitCollection.userInterfaceStyle);
      } else {
        // Fallback on earlier versions
        snprintf(imageKeyBuffer, sizeof(imageKeyBuffer), "%s|%ld|%ld", imageName.UTF8String, (long)traitCollection.horizontalSizeClass, (long)traitCollection.verticalSizeClass);
      }
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
                                      traitCollection:(ASPrimitiveTraitCollection) traitCollection NS_RETURNS_RETAINED
{
  return [self as_resizableRoundedImageWithCornerRadius:cornerRadius
                                            cornerColor:cornerColor
                                              fillColor:fillColor
                                            borderColor:nil
                                            borderWidth:1.0
                                         roundedCorners:UIRectCornerAllCorners
                                                  scale:0.0
                                        traitCollection:traitCollection];
}

+ (UIImage *)as_resizableRoundedImageWithCornerRadius:(CGFloat)cornerRadius
                                          cornerColor:(UIColor *)cornerColor
                                            fillColor:(UIColor *)fillColor
                                          borderColor:(UIColor *)borderColor
                                          borderWidth:(CGFloat)borderWidth
                                      traitCollection:(ASPrimitiveTraitCollection) traitCollection NS_RETURNS_RETAINED {
  return [self as_resizableRoundedImageWithCornerRadius:cornerRadius
                                            cornerColor:cornerColor
                                              fillColor:fillColor
                                            borderColor:borderColor
                                            borderWidth:borderWidth
                                         roundedCorners:UIRectCornerAllCorners
                                                  scale:0.0
                                        traitCollection:traitCollection];
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
                                                scale:(CGFloat)scale NS_RETURNS_RETAINED {

  return [self as_resizableRoundedImageWithCornerRadius:cornerRadius
                                            cornerColor:cornerColor
                                              fillColor:fillColor
                                            borderColor:borderColor
                                            borderWidth:borderWidth
                                         roundedCorners:roundedCorners
                                                  scale:scale
                                        traitCollection:ASPrimitiveTraitCollectionMakeDefault()];
}


+ (UIImage *)as_resizableRoundedImageWithCornerRadius:(CGFloat)cornerRadius
                                          cornerColor:(UIColor *)cornerColor
                                            fillColor:(UIColor *)fillColor
                                          borderColor:(UIColor *)borderColor
                                          borderWidth:(CGFloat)borderWidth
                                       roundedCorners:(UIRectCorner)roundedCorners
                                                scale:(CGFloat)scale
                                      traitCollection:(ASPrimitiveTraitCollection) traitCollection NS_RETURNS_RETAINED
{
  static NSCache<NSData *, UIImage *> *imageCache;
  static pthread_key_t threadKey;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    ASInitializeTemporaryObjectStorage(&threadKey);
    imageCache = [[NSCache alloc] init];
    imageCache.name = @"Texture.roundedImageCache";
  });

  // Treat clear background color as no background color
  if ([cornerColor isEqual:[UIColor clearColor]]) {
    cornerColor = nil;
  }

  typedef struct {
    CGFloat cornerRadius;
    CGFloat cornerColor[4];
    CGFloat fillColor[4];
    CGFloat borderColor[4];
    CGFloat borderWidth;
    UIRectCorner roundedCorners;
    CGFloat scale;
  } CacheKey;

  CFMutableDataRef keyBuffer = ASGetTemporaryMutableData(threadKey, sizeof(CacheKey));
  CacheKey *key = (CacheKey *)CFDataGetMutableBytePtr(keyBuffer);
  if (!key) {
    ASDisplayNodeFailAssert(@"Failed to get byte pointer. Data: %@", keyBuffer);
    return [[UIImage alloc] init];
  }
  key->cornerRadius = cornerRadius;
  [cornerColor getRed:&key->cornerColor[0]
                green:&key->cornerColor[1]
                 blue:&key->cornerColor[2]
                alpha:&key->cornerColor[3]];
  [fillColor getRed:&key->fillColor[0]
              green:&key->fillColor[1]
               blue:&key->fillColor[2]
              alpha:&key->fillColor[3]];
  [borderColor getRed:&key->borderColor[0]
                green:&key->borderColor[1]
                 blue:&key->borderColor[2]
                alpha:&key->borderColor[3]];
  key->borderWidth = borderWidth;
  key->roundedCorners = roundedCorners;
  key->scale = scale;

  if (UIImage *cached = [imageCache objectForKey:(__bridge id)keyBuffer]) {
    return cached;
  }
  CGFloat capInset = MAX(borderWidth, cornerRadius);
  NSAssert(capInset >= 0, @"borderWidth and cornerRadius must >=0");
  CGFloat dimension = (capInset * 2) + 1;
  CGRect bounds = CGRectMake(0, 0, dimension, dimension);

  CGSize cornerRadii = CGSizeMake(cornerRadius, cornerRadius);
  UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:roundedCorners cornerRadii:cornerRadii];

  // We should probably check if the background color has any alpha component but that
  // might be expensive due to needing to check mulitple color spaces.
  UIImage *result = ASGraphicsCreateImage(traitCollection, bounds.size, cornerColor != nil, scale, nil, nil, ^{
    BOOL contextIsClean = YES;
    if (cornerColor) {
      contextIsClean = NO;
      [cornerColor setFill];
      // Copy "blend" mode is extra fast because it disregards any value currently in the buffer and overrides directly.
      UIRectFillUsingBlendMode(bounds, kCGBlendModeCopy);
    }

    BOOL canUseCopy = contextIsClean || (CGColorGetAlpha(fillColor.CGColor) == 1);
    [fillColor setFill];
    [path fillWithBlendMode:(canUseCopy ? kCGBlendModeCopy : kCGBlendModeNormal) alpha:1];

    if (borderColor) {
      [borderColor setStroke];

      // Inset border fully inside filled path (not halfway on each side of path)
      CGRect strokeRect = CGRectInset(bounds, borderWidth / 2.0, borderWidth / 2.0);

      UIBezierPath *strokePath;
      if (cornerRadius == 0) {
        // When cornerRadii is CGSizeZero, the stroke result will have extra square on top left
        // that is not covered using bezierPathWithRoundedRect:byRoundingCorners:cornerRadii:.
        // Seems a bug from iOS runtime.
        strokePath = [UIBezierPath bezierPathWithRect:strokeRect];
      } else {
        strokePath = [UIBezierPath bezierPathWithRoundedRect:strokeRect
                                           byRoundingCorners:roundedCorners
                                                 cornerRadii:cornerRadii];
      }
      [strokePath setLineWidth:borderWidth];
      BOOL canUseCopy = (CGColorGetAlpha(borderColor.CGColor) == 1);
      [strokePath strokeWithBlendMode:(canUseCopy ? kCGBlendModeCopy : kCGBlendModeNormal) alpha:1];
    }
    // Refill the center area with fillColor since it may be contaminated by the sub pixel
    // rendering.
    if (borderWidth > 0) {
      CGRect rect = CGRectMake(capInset, capInset, 1, 1);
      CGContextRef context = UIGraphicsGetCurrentContext();
      CGContextClearRect(context, rect);
      CGContextSetFillColorWithColor(context, [fillColor CGColor]);
      CGContextFillRect(context, rect);
    }
  });

  UIEdgeInsets capInsets = UIEdgeInsetsMake(capInset, capInset, capInset, capInset);
  result = [result resizableImageWithCapInsets:capInsets resizingMode:UIImageResizingModeStretch];

  // Be sure to copy keyBuffer when inserting to cache.
  if (CFDataRef copiedKey = CFDataCreateCopy(NULL, keyBuffer)) {
    [imageCache setObject:result forKey:(__bridge_transfer id)copiedKey];
  } else {
    ASDisplayNodeFailAssert(@"Failed to copy key: %@", keyBuffer);
  }
  return result;
}

@end
