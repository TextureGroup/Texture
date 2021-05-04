//
//  ASInternalHelpers.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASInternalHelpers.h>

#import <UIKit/UIKit.h>

#import <objc/runtime.h>
#import <cmath>
#import <pthread.h>

#import <AsyncDisplayKit/ASConfigurationInternal.h>
#import <AsyncDisplayKit/ASRunLoopQueue.h>
#import <AsyncDisplayKit/ASSignpost.h>
#import <AsyncDisplayKit/ASThread.h>

AS_ASSUME_NORETAIN_BEGIN

static NSNumber *allowsGroupOpacityFromUIKitOrNil;
static NSNumber *allowsEdgeAntialiasingFromUIKitOrNil;
static NSNumber *applicationUserInterfaceLayoutDirection = nil;

@implementation NSAttributedString (ASTextAttachment)

- (BOOL)as_hasAttribute:(NSAttributedStringKey)attributeKey {
  NSUInteger length = self.length;
  if (length == 0) {
    return NO;
  }
  NSRange range;
  id result = [self attribute:attributeKey
                      atIndex:0
        longestEffectiveRange:&range
                      inRange:NSMakeRange(0, length)];
  return result || range.length != length;
}

@end

BOOL ASDefaultAllowsGroupOpacity()
{
  static BOOL groupOpacity;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSNumber *groupOpacityObj = allowsGroupOpacityFromUIKitOrNil ?: [NSBundle.mainBundle objectForInfoDictionaryKey:@"UIViewGroupOpacity"];
    groupOpacity = groupOpacityObj ? groupOpacityObj.boolValue : YES;
  });
  return groupOpacity;
}

BOOL ASDefaultAllowsEdgeAntialiasing()
{
  static BOOL edgeAntialiasing;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSNumber *antialiasingObj = allowsEdgeAntialiasingFromUIKitOrNil ?: [NSBundle.mainBundle objectForInfoDictionaryKey:@"UIViewEdgeAntialiasing"];
    edgeAntialiasing = antialiasingObj ? antialiasingObj.boolValue : NO;
  });
  return edgeAntialiasing;
}

NSNumber *ASApplicationUserInterfaceLayoutDirection() {
  return applicationUserInterfaceLayoutDirection;
}

#if AS_SIGNPOST_ENABLE
void _ASInitializeSignpostObservers(void)
{
  // Orientation changes. Unavailable on tvOS.
#if !TARGET_OS_TV
  [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationWillChangeStatusBarOrientationNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
    UIInterfaceOrientation orientation = (UIInterfaceOrientation)[note.userInfo[UIApplicationStatusBarOrientationUserInfoKey] integerValue];
    ASSignpostStart(OrientationChange, (id)nil, "from %s", UIInterfaceOrientationIsPortrait(orientation) ? "portrait" : "landscape");
    [CATransaction begin];
  }];
  [NSNotificationCenter.defaultCenter addObserverForName:UIApplicationDidChangeStatusBarOrientationNotification object:nil queue:nil usingBlock:^(NSNotification *note) {
    // When profiling, go ahead and commit the transaction early so that it happens as part of our interval.
    UIInterfaceOrientation orientation = (UIInterfaceOrientation)[note.userInfo[UIApplicationStatusBarOrientationUserInfoKey] integerValue];
    [CATransaction setCompletionBlock:^{
      ASSignpostEnd(OrientationChange, (id)nil, "to %s", UIInterfaceOrientationIsPortrait(orientation) ? "portrait" : "landscape");
    }];
    [CATransaction commit];
  }];
#endif  // TARGET_OS_TV
}
#endif  // AS_SIGNPOST_ENABLE

void ASInitializeFrameworkMainThread(void)
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    ASDisplayNodeCAssertMainThread();
    applicationUserInterfaceLayoutDirection = @([UIApplication sharedApplication].userInterfaceLayoutDirection);
    // Ensure these values are cached on the main thread before needed in the background.
    if (ASActivateExperimentalFeature(ASExperimentalLayerDefaults)) {
      // Nop. We will gather default values on-demand in ASDefaultAllowsGroupOpacity and ASDefaultAllowsEdgeAntialiasing
    } else {
      CALayer *layer = [[[UIView alloc] init] layer];
      allowsGroupOpacityFromUIKitOrNil = @(layer.allowsGroupOpacity);
      allowsEdgeAntialiasingFromUIKitOrNil = @(layer.allowsEdgeAntialiasing);
    }
    ASNotifyInitialized();
#if AS_SIGNPOST_ENABLE
    _ASInitializeSignpostObservers();
#endif
  });
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

NSMutableSet *ASCreatePointerBasedMutableSet() NS_RETURNS_RETAINED
{
  static CFSetCallBacks callbacks;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    callbacks = kCFTypeSetCallBacks;
    callbacks.equal = nullptr;
    callbacks.hash = nullptr;
  });
  return (__bridge_transfer NSMutableSet *)CFSetCreateMutable(NULL, 0, &callbacks);
}

NSMutableArray *ASCreateNonOwningMutableArray() NS_RETURNS_RETAINED {
  static CFArrayCallBacks callbacks;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    callbacks = kCFTypeArrayCallBacks;
    callbacks.retain = nullptr;
    callbacks.release = nullptr;
  });
  return (__bridge_transfer NSMutableArray *)CFArrayCreateMutable(NULL, 0, &callbacks);
}

/**
 * Note: we intentionally choose pthread keys instead of the thread_local storage classifier.
 * The latter is not as efficient in current implementations (Xcode 10) as it relies on tlv_atExit
 * which performs its own heap allocations.
 */
void ASInitializeTemporaryObjectStorage(pthread_key_t *keyPtr) {
  pthread_key_create(keyPtr, [](void *ptr) {
    if (ptr) CFRelease((CFTypeRef)ptr);
  });
}

CFMutableArrayRef ASGetTemporaryNonowningMutableArray(pthread_key_t key) {
  CFMutableArrayRef obj = (CFMutableArrayRef)pthread_getspecific(key);
  if (!obj) {
    obj = (__bridge_retained CFMutableArrayRef)ASCreateNonOwningMutableArray();
    pthread_setspecific(key, obj);
  } else {
    CFArrayRemoveAllValues(obj);
  }
  return obj;
}

CFMutableDataRef ASGetTemporaryMutableData(pthread_key_t key, NSUInteger size) {
  CFMutableDataRef md = (CFMutableDataRef)pthread_getspecific(key);
  if (!md) {
    md = CFDataCreateMutable(NULL, size);
    CFDataSetLength(md, size);
    pthread_setspecific(key, md);
  } else if (UInt8 *buf = CFDataGetMutableBytePtr(md)) {
    // We clear the data on every subsequent access. Subtle downstream bugs are likely and have been
    // observed if the remnants of old entries are left around.
    memset(buf, 0, size);
  } else {
    ASDisplayNodeCFailAssert(@"Have mutable data but failed to get byte ptr. ???");
  }

  ASDisplayNodeCAssert(size == CFDataGetLength(md), @"Size changed across calls.");
  return md;
}

NSAttributedString *ASGetZeroAttributedString(void) {
  static NSAttributedString *str;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    str = [[NSAttributedString alloc] init];
  });
  return str;
}

AS_ASSUME_NORETAIN_END
