//
//  ASInternalHelpers.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASAvailability.h>

#import <UIKit/UIKit.h>

#import <AsyncDisplayKit/ASBaseDefines.h>
#import <AsyncDisplayKit/ASDisplayNodeExtras.h>
#import <AsyncDisplayKit/ASImageProtocols.h>

#ifdef __cplusplus
#include <functional>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface NSAttributedString (ASTextAttachment)

- (BOOL)as_hasAttribute:(NSAttributedStringKey)attributeKey;

@end

ASDK_EXTERN void ASInitializeFrameworkMainThread(void);

ASDK_EXTERN BOOL ASDefaultAllowsGroupOpacity(void);
ASDK_EXTERN BOOL ASDefaultAllowsEdgeAntialiasing(void);

/// ASTraitCollection is probably a better place to look on iOS >= 10
/// This _may not be set_ if AS_INITIALIZE_FRAMEWORK_MANUALLY is not set or we are used by an extension
ASDK_EXTERN NSNumber *ASApplicationUserInterfaceLayoutDirection(void);

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

ASDISPLAYNODE_INLINE CGPoint ASPointAddPoint(CGPoint p1, CGPoint p2) {
  return (CGPoint){p1.x + p2.x, p1.y + p2.y};
}

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
ASDK_EXTERN NSMutableSet *ASCreatePointerBasedMutableSet(void) NS_RETURNS_RETAINED;

/**
 * Create an NSMutableArray that does not retain and release it's objects.
 */
ASDK_EXTERN NSMutableArray *ASCreateNonOwningMutableArray(void) NS_RETURNS_RETAINED;

/**
 * Call from a once block to initialize the given pthread key for use with ASGetTemporary* functions
 * below.
 */
ASDK_EXTERN void ASInitializeTemporaryObjectStorage(pthread_key_t *threadKey);

/**
 * Get a temporary, thread-local, empty, non-owning mutable array associated with the given key.
 *
 * Thread key must have already been set up through ASInitializeTemporaryObjectStorage.
 */
ASDK_EXTERN CFMutableArrayRef ASGetTemporaryNonowningMutableArray(pthread_key_t threadKey);

/**
 * Get a temporary, thread-local, zero-filled CFMutableDataRef instance of the given size.
 *
 * @discussion NSCache is a useful class, but it has the unfortunate property of requiring keys to
 * be Objective-C objects. Key creation adds significant overhead in cache lookups. We would
 * prefer to use C-structs as keys. By using these functions, we can repeatedly reuse a
 * thread-local CFMutableData instance for cache lookups, and then only create a permanent copy
 * of the data for cache insertions.
 *
 * @note The size argument must be constant across each call.
 *
 * This allows for cache lookups with amortized zero heap allocations or object creations.
 *
 * Example:
 *
 * - (id)myExpensiveMethodWithX:(int)x y:(CGFloat)y {
 *   static pthread_key_t threadKey;
 *   static NSCache<NSData *, id> *cache;
 *   static dispatch_once_t onceToken;
 *   dispatch_once(&onceToken, ^{
 *     ASInitializeTemporaryObjectStorage(&threadKey);
 *     cache = [[NSCache alloc] init];
 *   });
 *
 *   typedef struct {
 *     int x;
 *     CGFloat y;
 *   } CacheKey;
 *
 *   CFMutableDataRef keyBuffer = ASGetTemporaryMutableData(threadKey, sizeof(CacheKey));
 *   CacheKey *key = (CacheKey *)CFDataGetMutableBytePtr(keyBuffer);
 *   if (!key) {
 *     // This should be impossible but this code has not been proven in production yet.
 *     ASDisplayNodeFailAssert(@"Failed to get key pointer: %@", keyBuffer);
 *     return nil; // Or some other "fatal error" fallback. Or continue & ignore cache.
 *   }
 *   key->x = x;
 *   key->y = y;
 *   id cached = [cache objectForKey:(__bridge id)keyBuffer];
 *   if (cached) {
 *     return cached;
 *   }
 *   id result = ExpensiveLogicInvolvingXAndY(x, y);
 *   if (CFDataRef copiedKey = CFDataCreateCopy(NULL, buffer)) {
 *     [cache setObject:result forKey:(__bridge_transfer id)copiedKey];
 *   } else {
 *     // This should not be possible but this code has not been proven in production yet.
 *     ASDisplayNodeFailAssert(@"Failed to copy key: %@", keyBuffer);
 *   }
 *   return result;
 * }
 */
ASDK_EXTERN CFMutableDataRef ASGetTemporaryMutableData(pthread_key_t threadKey, NSUInteger keySize);

/**
 * Returns a singleton empty immutable attributed string. Use at your leisure.
 */
ASDK_EXTERN NSAttributedString *ASGetZeroAttributedString(void);

#ifdef __cplusplus

namespace AS {

/**
 * RAII container to execute a function at end of scope.
 */
class Cleanup {
 public:
  Cleanup(std::function<void()> f) : f_(std::move(f)) {}
  ~Cleanup() { f_(); }

  /** Release without calling. Use release()() to execute early. */
  std::function<void()> release() {
    auto f = std::move(f_);
    f_ = [] {};
    return f;
  }

  // Move yes, copy no.
  Cleanup(const Cleanup &) = delete;
  Cleanup &operator=(const Cleanup &) = delete;
  Cleanup(Cleanup &&) = default;
  Cleanup &operator=(Cleanup &&) = default;

 private:
  std::function<void()> f_;
};

}  // namespace AS

#endif  // __cplusplus

NS_ASSUME_NONNULL_END

#ifndef AS_INITIALIZE_FRAMEWORK_MANUALLY
#define AS_INITIALIZE_FRAMEWORK_MANUALLY 0
#endif
