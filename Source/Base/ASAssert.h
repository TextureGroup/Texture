//
//  ASAssert.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASBaseDefines.h>

#import <Foundation/Foundation.h>
#import <pthread.h>
#import <dispatch/dispatch.h>

AS_ASSUME_NORETAIN_BEGIN
NS_ASSUME_NONNULL_BEGIN

#if !defined(NS_BLOCK_ASSERTIONS)
  #define ASDISPLAYNODE_ASSERTIONS_ENABLED 1
#else
  #define ASDISPLAYNODE_ASSERTIONS_ENABLED 0
#endif

/**
 * Check a precondition in production and return the given value if it fails.
 * Note that this hides an early return! So always use cleanups or RAII objects
 * rather than manual cleanup.
 */
#define AS_PRECONDITION(expr, __return_value, ...) \
  if (!AS_EXPECT(expr, 1)) {                       \
    ASDisplayNodeFailAssert(__VA_ARGS__);          \
    return __return_value;                         \
  }

#define AS_C_PRECONDITION(expr, __return_value, ...) \
  if (!AS_EXPECT(expr, 1)) {                         \
    ASDisplayNodeCFailAssert(__VA_ARGS__);           \
    return __return_value;                           \
  }

/**
 * Note: In some cases it would be sufficient to do e.g.:
 *  ASDisplayNodeAssert(...) NSAssert(__VA_ARGS__)
 * but we prefer not to, because we want to match the autocomplete behavior of NSAssert.
 * The construction listed above does not show the user what arguments are required and what are optional.
 */

#define ASDisplayNodeAssert(condition, desc, ...) NSAssert(condition, desc, ##__VA_ARGS__)
#define ASDisplayNodeCAssert(condition, desc, ...) NSCAssert(condition, desc, ##__VA_ARGS__)

#define ASDisplayNodeAssertNil(condition, desc, ...) ASDisplayNodeAssert((condition) == nil, desc, ##__VA_ARGS__)
#define ASDisplayNodeCAssertNil(condition, desc, ...) ASDisplayNodeCAssert((condition) == nil, desc, ##__VA_ARGS__)

#define ASDisplayNodeAssertNotNil(condition, desc, ...) ASDisplayNodeAssert((condition) != nil, desc, ##__VA_ARGS__)
#define ASDisplayNodeCAssertNotNil(condition, desc, ...) ASDisplayNodeCAssert((condition) != nil, desc, ##__VA_ARGS__)

#define ASDisplayNodeAssertImplementedBySubclass() ASDisplayNodeAssert(NO, @"This method must be implemented by subclass %@", [self class]);
#define ASDisplayNodeAssertNotInstantiable() ASDisplayNodeAssert(NO, nil, @"This class is not instantiable.");
#define ASDisplayNodeAssertNotSupported() ASDisplayNodeAssert(NO, nil, @"This method is not supported by class %@", [self class]);

#define ASDisplayNodeAssertMainThread() ASDisplayNodeAssert(ASMainThreadAssertionsAreDisabled() || 0 != pthread_main_np(), @"This method must be called on the main thread")
#define ASDisplayNodeCAssertMainThread() ASDisplayNodeCAssert(ASMainThreadAssertionsAreDisabled() || 0 != pthread_main_np(), @"This function must be called on the main thread")

#define ASDisplayNodeAssertNotMainThread() ASDisplayNodeAssert(0 == pthread_main_np(), @"This method must be called off the main thread")
#define ASDisplayNodeCAssertNotMainThread() ASDisplayNodeCAssert(0 == pthread_main_np(), @"This function must be called off the main thread")

#define ASDisplayNodeAssertFlag(X, desc, ...) ASDisplayNodeAssert((1 == __builtin_popcount(X)), desc, ##__VA_ARGS__)
#define ASDisplayNodeCAssertFlag(X, desc, ...) ASDisplayNodeCAssert((1 == __builtin_popcount(X)), desc, ##__VA_ARGS__)

#define ASDisplayNodeAssertTrue(condition) ASDisplayNodeAssert((condition), @"Expected %s to be true.", #condition)
#define ASDisplayNodeCAssertTrue(condition) ASDisplayNodeCAssert((condition), @"Expected %s to be true.", #condition)

#define ASDisplayNodeAssertFalse(condition) ASDisplayNodeAssert(!(condition), @"Expected %s to be false.", #condition)
#define ASDisplayNodeCAssertFalse(condition) ASDisplayNodeCAssert(!(condition), @"Expected %s to be false.", #condition)

#define ASDisplayNodeFailAssert(desc, ...) ASDisplayNodeAssert(NO, desc, ##__VA_ARGS__)
#define ASDisplayNodeCFailAssert(desc, ...) ASDisplayNodeCAssert(NO, desc, ##__VA_ARGS__)

#define ASDisplayNodeConditionalAssert(shouldTestCondition, condition, desc, ...) ASDisplayNodeAssert((!(shouldTestCondition) || (condition)), desc, ##__VA_ARGS__)
#define ASDisplayNodeConditionalCAssert(shouldTestCondition, condition, desc, ...) ASDisplayNodeCAssert((!(shouldTestCondition) || (condition)), desc, ##__VA_ARGS__)

#define ASDisplayNodeCAssertPositiveReal(description, num) ASDisplayNodeCAssert(num >= 0 && num <= CGFLOAT_MAX, @"%@ must be a real positive integer: %f.", description, (CGFloat)num)
#define ASDisplayNodeCAssertInfOrPositiveReal(description, num) ASDisplayNodeCAssert(isinf(num) || (num >= 0 && num <= CGFLOAT_MAX), @"%@ must be infinite or a real positive integer: %f.", description, (CGFloat)num)

#define ASDisplayNodeCAssertPermanent(object) ASDisplayNodeCAssert(CFGetRetainCount((__bridge CFTypeRef)(object)) == CFGetRetainCount(kCFNull), @"Expected %s to be a permanent object.", #object)
#define ASDisplayNodeErrorDomain @"ASDisplayNodeErrorDomain"
#define ASDisplayNodeNonFatalErrorCode 1

NS_INLINE void ASAssertOnQueueIfIOS10(dispatch_queue_t q) {
#ifndef NS_BLOCK_ASSERTIONS
  if (@available(iOS 10, tvOS 10, *)) {
    dispatch_assert_queue(q);
  }
#endif
}

/**
 * In debug methods, it can be useful to disable main thread assertions to get valuable information,
 * even if it means violating threading requirements. These functions are used in -debugDescription and let
 * threads decide to suppress/re-enable main thread assertions.
 */
#pragma mark - Main Thread Assertions Disabling

ASDK_EXTERN BOOL ASMainThreadAssertionsAreDisabled(void);

ASDK_EXTERN void ASPushMainThreadAssertionsDisabled(void);

ASDK_EXTERN void ASPopMainThreadAssertionsDisabled(void);

#pragma mark - Non-Fatal Assertions

/// Returns YES if assertion passed, NO otherwise.
#define ASDisplayNodeAssertNonFatal(condition, desc, ...) ({                                                                      \
  BOOL __evaluated = condition;                                                                                                   \
  if (__evaluated == NO) {                                                                                                        \
    ASDisplayNodeFailAssert(desc, ##__VA_ARGS__);                                                                                 \
    ASDisplayNodeNonFatalErrorBlock block = [ASDisplayNode nonFatalErrorBlock];                                                   \
    if (block != nil) {                                                                                                           \
      NSDictionary *userInfo = nil;                                                                                               \
      if (desc.length > 0) {                                                                                                      \
        userInfo = @{ NSLocalizedDescriptionKey : desc };                                                                         \
      }                                                                                                                           \
      NSError *error = [NSError errorWithDomain:ASDisplayNodeErrorDomain code:ASDisplayNodeNonFatalErrorCode userInfo:userInfo];  \
      block(error);                                                                                                               \
    }                                                                                                                             \
  }                                                                                                                               \
  __evaluated;                                                                                                                    \
})                                                                                                                                \

NS_ASSUME_NONNULL_END
AS_ASSUME_NORETAIN_END
