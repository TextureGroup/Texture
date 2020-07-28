//
//  ASInternalHelpers.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASAvailability.h"

#import <UIKit/UIKit.h>

#import <AsyncDisplayKit/ASBaseDefines.h>
#import <AsyncDisplayKit/ASDisplayNodeExtras.h>
#import <AsyncDisplayKit/ASImageProtocols.h>

NS_ASSUME_NONNULL_BEGIN

ASDK_EXTERN void ASInitializeFrameworkMainThread(void);

ASDK_EXTERN BOOL ASDefaultAllowsGroupOpacity(void);
ASDK_EXTERN BOOL ASDefaultAllowsEdgeAntialiasing(void);

ASDK_EXTERN BOOL ASSubclassOverridesSelector(Class superclass, Class subclass, SEL selector);
ASDK_EXTERN BOOL ASSubclassOverridesClassSelector(Class superclass, Class subclass, SEL selector);

/// Replace a method from the given class with a block and returns the original method IMP
ASDK_EXTERN IMP ASReplaceMethodWithBlock(Class c, SEL origSEL, id block);

/// Dispatches the given block to the main queue if not already running on the main thread
ASDK_EXTERN void ASPerformBlockOnMainThread(void (^block)(void));

/// Dispatches the given block to a background queue with priority of DISPATCH_QUEUE_PRIORITY_DEFAULT if not already run on a background queue
ASDK_EXTERN void ASPerformBlockOnBackgroundThread(void (^block)(void)); // DISPATCH_QUEUE_PRIORITY_DEFAULT

/// For deallocation of objects on a background thread without GCD overhead / thread explosion
ASDK_EXTERN void ASPerformBackgroundDeallocation(id __strong _Nullable * _Nonnull object);

ASDK_EXTERN CGFloat ASScreenScale(void);

ASDK_EXTERN CGSize ASFloorSizeValues(CGSize s);

ASDK_EXTERN CGFloat ASFloorPixelValue(CGFloat f);

ASDK_EXTERN CGPoint ASCeilPointValues(CGPoint p);

ASDK_EXTERN CGSize ASCeilSizeValues(CGSize s);

ASDK_EXTERN CGFloat ASCeilPixelValue(CGFloat f);

ASDK_EXTERN CGFloat ASRoundPixelValue(CGFloat f);

ASDK_EXTERN Class _Nullable ASGetClassFromType(const char * _Nullable type);

ASDISPLAYNODE_INLINE BOOL ASImageAlphaInfoIsOpaque(CGImageAlphaInfo info) {
  switch (info) {
    case kCGImageAlphaNone:
    case kCGImageAlphaNoneSkipLast:
    case kCGImageAlphaNoneSkipFirst:
      return YES;
    default:
      return NO;
  }
}

/**
 @summary Conditionally performs UIView geometry changes in the given block without animation.
 
 Used primarily to circumvent UITableView forcing insertion animations when explicitly told not to via
 `UITableViewRowAnimationNone`. More info: https://github.com/facebook/AsyncDisplayKit/pull/445
 
 @param withoutAnimation Set to `YES` to perform given block without animation
 @param block Perform UIView geometry changes within the passed block
 */
ASDISPLAYNODE_INLINE void ASPerformBlockWithoutAnimation(BOOL withoutAnimation, void (^block)(void)) {
  if (withoutAnimation) {
    [UIView performWithoutAnimation:block];
  } else {
    block();
  }
}

ASDISPLAYNODE_INLINE void ASBoundsAndPositionForFrame(CGRect rect, CGPoint origin, CGPoint anchorPoint, CGRect *bounds, CGPoint *position)
{
  *bounds   = (CGRect){ origin, rect.size };
  *position = CGPointMake(rect.origin.x + rect.size.width * anchorPoint.x,
                          rect.origin.y + rect.size.height * anchorPoint.y);
}

ASDISPLAYNODE_INLINE UIEdgeInsets ASConcatInsets(UIEdgeInsets insetsA, UIEdgeInsets insetsB)
{
  insetsA.top += insetsB.top;
  insetsA.left += insetsB.left;
  insetsA.bottom += insetsB.bottom;
  insetsA.right += insetsB.right;
  return insetsA;
}

ASDISPLAYNODE_INLINE AS_WARN_UNUSED_RESULT ASImageDownloaderPriority ASImageDownloaderPriorityWithInterfaceState(ASInterfaceState interfaceState) {
  if (ASInterfaceStateIncludesVisible(interfaceState)) {
    return ASImageDownloaderPriorityVisible;
  }

  if (ASInterfaceStateIncludesDisplay(interfaceState)) {
    return ASImageDownloaderPriorityImminent;
  }

  if (ASInterfaceStateIncludesPreload(interfaceState)) {
    return ASImageDownloaderPriorityPreload;
  }

  return ASImageDownloaderPriorityPreload;
}

@interface NSIndexPath (ASInverseComparison)
- (NSComparisonResult)asdk_inverseCompare:(NSIndexPath *)otherIndexPath;
@end

/**
 * Create an NSMutableSet that uses pointers for hash & equality.
 */
ASDK_EXTERN NSMutableSet *ASCreatePointerBasedMutableSet(void);

NS_ASSUME_NONNULL_END

#ifndef AS_INITIALIZE_FRAMEWORK_MANUALLY
#define AS_INITIALIZE_FRAMEWORK_MANUALLY 0
#endif
