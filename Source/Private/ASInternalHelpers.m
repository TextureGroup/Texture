//
//  ASInternalHelpers.m
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

#import <AsyncDisplayKit/ASInternalHelpers.h>

#import <UIKit/UIKit.h>

#import <objc/runtime.h>
#import <tgmath.h>

#import <AsyncDisplayKit/ASRunLoopQueue.h>
#import <AsyncDisplayKit/ASThread.h>

static BOOL defaultAllowsGroupOpacity = YES;
static BOOL defaultAllowsEdgeAntialiasing = NO;

void ASInitializeFrameworkMainThread(void)
{
  ASDisplayNodeThreadIsMain();
  // Ensure these values are cached on the main thread before needed in the background.
  CALayer *layer = [[[UIView alloc] init] layer];
  defaultAllowsGroupOpacity = layer.allowsGroupOpacity;
  defaultAllowsEdgeAntialiasing = layer.allowsEdgeAntialiasing;
}

BOOL ASDefaultAllowsGroupOpacity(void)
{
  return defaultAllowsGroupOpacity;
}

BOOL ASDefaultAllowsEdgeAntialiasing(void)
{
  return defaultAllowsEdgeAntialiasing;
}

BOOL ASSubclassOverridesSelector(Class superclass, Class subclass, SEL selector)
{
  if (superclass == subclass) return NO; // Even if the class implements the selector, it doesn't override itself.
  Method superclassMethod = class_getInstanceMethod(superclass, selector);
  Method subclassMethod = class_getInstanceMethod(subclass, selector);
  return (superclassMethod != subclassMethod);
}

BOOL ASSubclassOverridesClassSelector(Class superclass, Class subclass, SEL selector)
{
  if (superclass == subclass) return NO; // Even if the class implements the selector, it doesn't override itself.
  Method superclassMethod = class_getClassMethod(superclass, selector);
  Method subclassMethod = class_getClassMethod(subclass, selector);
  return (superclassMethod != subclassMethod);
}

IMP ASReplaceMethodWithBlock(Class c, SEL origSEL, id block)
{
  NSCParameterAssert(block);
  
  // Get original method
  Method origMethod = class_getInstanceMethod(c, origSEL);
  NSCParameterAssert(origMethod);
  
  // Convert block to IMP trampoline and replace method implementation
  IMP newIMP = imp_implementationWithBlock(block);
  
  // Try adding the method if not yet in the current class
  if (!class_addMethod(c, origSEL, newIMP, method_getTypeEncoding(origMethod))) {
    return method_setImplementation(origMethod, newIMP);
  } else {
    return method_getImplementation(origMethod);
  }
}

void ASPerformBlockOnMainThread(void (^block)(void))
{
  if (block == nil){
    return;
  }
  if (ASDisplayNodeThreadIsMain()) {
    block();
  } else {
    dispatch_async(dispatch_get_main_queue(), block);
  }
}

void ASPerformBlockOnBackgroundThread(void (^block)(void))
{
  if (block == nil){
    return;
  }
  if (ASDisplayNodeThreadIsMain()) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
  } else {
    block();
  }
}

void ASPerformBackgroundDeallocation(id __strong _Nullable * _Nonnull object)
{
  [[ASDeallocQueue sharedDeallocationQueue] releaseObjectInBackground:object];
}

BOOL ASClassRequiresMainThreadDeallocation(Class c)
{
  // Specific classes
  if (c == [UIImage class] || c == [UIColor class]) {
    return NO;
  }
  
  if ([c isSubclassOfClass:[UIResponder class]]
      || [c isSubclassOfClass:[CALayer class]]
      || [c isSubclassOfClass:[UIGestureRecognizer class]]) {
    return YES;
  }

  // Apple classes with prefix
  const char *name = class_getName(c);
  if (strncmp(name, "UI", 2) == 0 || strncmp(name, "AV", 2) == 0 || strncmp(name, "CA", 2) == 0) {
    return YES;
  }
  
  // Specific Texture classes
  if (strncmp(name, "ASTextKitComponents", 19) == 0) {
    return YES;
  }

  return NO;
}

Class _Nullable ASGetClassFromType(const char  * _Nullable type)
{
  // Class types all start with @"
  if (type == NULL || strncmp(type, "@\"", 2) != 0) {
    return Nil;
  }

  // Ensure length >= 3
  size_t typeLength = strlen(type);
  if (typeLength < 3) {
    ASDisplayNodeCFailAssert(@"Got invalid type-encoding: %s", type);
    return Nil;
  }

  // Copy type[2..(end-1)]. So @"UIImage" -> UIImage
  size_t resultLength = typeLength - 3;
  char className[resultLength + 1];
  strncpy(className, type + 2, resultLength);
  className[resultLength] = '\0';
  return objc_getClass(className);
}

CGFloat ASScreenScale()
{
  static CGFloat __scale = 0.0;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 1), YES, 0);
    __scale = CGContextGetCTM(UIGraphicsGetCurrentContext()).a;
    UIGraphicsEndImageContext();
  });
  return __scale;
}

CGSize ASFloorSizeValues(CGSize s)
{
  return CGSizeMake(ASFloorPixelValue(s.width), ASFloorPixelValue(s.height));
}

// See ASCeilPixelValue for a more thoroguh explanation of (f + FLT_EPSILON),
// but here is some quick math:
//
// Imagine a layout that comes back with a height of 100.66666666663
// for a 3x deice:
// 100.66666666663 * 3 = 301.99999999988995
// floor(301.99999999988995) = 301
// 301 / 3 = 100.333333333
//
// If we add FLT_EPSILON to normalize the garbage at the end we get:
// po (100.66666666663 + FLT_EPSILON) * 3 = 302.00000035751782
// floor(302.00000035751782) = 302
// 302/3 = 100.66666666
CGFloat ASFloorPixelValue(CGFloat f)
{
  CGFloat scale = ASScreenScale();
  return floor((f + FLT_EPSILON) * scale) / scale;
}

CGPoint ASCeilPointValues(CGPoint p)
{
  return CGPointMake(ASCeilPixelValue(p.x), ASCeilPixelValue(p.y));
}

CGSize ASCeilSizeValues(CGSize s)
{
  return CGSizeMake(ASCeilPixelValue(s.width), ASCeilPixelValue(s.height));
}

// With 3x devices layouts will often to compute to pixel bounds but
// include garbage values beyond the precision of a float/double.
// This garbage can result in a pixel value being rounded up when it isn't
// necessary.
//
// For example, imagine a layout that comes back with a height of 100.666666666669
// for a 3x device:
// 100.666666666669 * 3 = 302.00000000000699
// ceil(302.00000000000699) = 303
// 303/3 = 101
//
// If we use FLT_EPSILON to get rid of the garbage at the end of the value,
// things work as expected:
// (100.666666666669 - FLT_EPSILON) * 3 = 301.99999964237912
// ceil(301.99999964237912) = 302
// 302/3 = 100.666666666
//
// For even more conversation around this, see:
// https://github.com/TextureGroup/Texture/issues/838
CGFloat ASCeilPixelValue(CGFloat f)
{
  CGFloat scale = ASScreenScale();
  return ceil((f - FLT_EPSILON) * scale) / scale;
}

CGFloat ASRoundPixelValue(CGFloat f)
{
  CGFloat scale = ASScreenScale();
  return round(f * scale) / scale;
}

@implementation NSIndexPath (ASInverseComparison)

- (NSComparisonResult)asdk_inverseCompare:(NSIndexPath *)otherIndexPath
{
  return [otherIndexPath compare:self];
}

@end
