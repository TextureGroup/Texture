//
//  ASInternalHelpers.h
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

#import "ASAvailability.h"

#import <UIKit/UIKit.h>

#import <AsyncDisplayKit/ASBaseDefines.h>

NS_ASSUME_NONNULL_BEGIN

ASDISPLAYNODE_EXTERN_C_BEGIN

BOOL ASSubclassOverridesSelector(Class superclass, Class subclass, SEL selector);
BOOL ASSubclassOverridesClassSelector(Class superclass, Class subclass, SEL selector);

/// Replace a method from the given class with a block and returns the original method IMP
IMP ASReplaceMethodWithBlock(Class c, SEL origSEL, id block);

/// Dispatches the given block to the main queue if not already running on the main thread
void ASPerformBlockOnMainThread(void (^block)(void));

/// Dispatches the given block to a background queue with priority of DISPATCH_QUEUE_PRIORITY_DEFAULT if not already run on a background queue
void ASPerformBlockOnBackgroundThread(void (^block)(void)); // DISPATCH_QUEUE_PRIORITY_DEFAULT

/// For deallocation of objects on a background thread without GCD overhead / thread explosion
void ASPerformBackgroundDeallocation(id __strong _Nullable * _Nonnull object);

CGFloat ASScreenScale(void);

CGSize ASFloorSizeValues(CGSize s);

CGFloat ASFloorPixelValue(CGFloat f);

CGPoint ASCeilPointValues(CGPoint p);

CGSize ASCeilSizeValues(CGSize s);

CGFloat ASCeilPixelValue(CGFloat f);

CGFloat ASRoundPixelValue(CGFloat f);

BOOL ASClassRequiresMainThreadDeallocation(Class _Nullable c);

Class _Nullable ASGetClassFromType(const char * _Nullable type);

ASDISPLAYNODE_EXTERN_C_END

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

@interface NSIndexPath (ASInverseComparison)
- (NSComparisonResult)asdk_inverseCompare:(NSIndexPath *)otherIndexPath;
@end

NS_ASSUME_NONNULL_END
