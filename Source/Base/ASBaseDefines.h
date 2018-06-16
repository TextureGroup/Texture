//
//  ASBaseDefines.h
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

#import <AvailabilityMacros.h>
#import <CoreFoundation/CFBase.h>
#import <Foundation/NSObjCRuntime.h>

#define AS_EXTERN FOUNDATION_EXTERN
#define AS_INLINE NS_INLINE

#ifndef ASDISPLAYNODE_WARN_DEPRECATED
# define ASDISPLAYNODE_WARN_DEPRECATED 1
#endif

#if ASDISPLAYNODE_WARN_DEPRECATED
# define AS_DEPRECATED          DEPRECATED_ATTRIBUTE
# define AS_DEPRECATED_MSG(msg) DEPRECATED_MSG_ATTRIBUTE(msg)
#else
# define AS_DEPRECATED
# define AS_DEPRECATED_MSG(msg)
#endif

#ifndef AS_ENABLE_TIPS
#define AS_ENABLE_TIPS 0
#endif

/**
 * The event backtraces take a static 2KB of memory
 * and retain all objects present in all the registers
 * of the stack frames. The memory consumption impact
 * is too significant even to be enabled during general
 * development.
 */
#ifndef AS_SAVE_EVENT_BACKTRACES
# define AS_SAVE_EVENT_BACKTRACES 0
#endif

#if __has_attribute(unavailable)
# define AS_UNAVAILABLE_MSG(message) __attribute__((unavailable(message)))
#else
# define AS_UNAVAILABLE_MSG(message)
#endif

#if __has_attribute(warn_unused_result)
# define AS_WARN_UNUSED_RESULT __attribute__((warn_unused_result))
#else
# define AS_WARN_UNUSED_RESULT
#endif

#if __has_attribute(overloadable)
# define AS_OVERLOADABLE __attribute__((overloadable))
#else
# define AS_OVERLOADABLE
#endif

#if __has_attribute(objc_subclassing_restricted)
#define AS_SUBCLASSING_RESTRICTED __attribute__((objc_subclassing_restricted))
#else
#define AS_SUBCLASSING_RESTRICTED
#endif

#define ASCreateOnce(expr) ({ \
  static dispatch_once_t onceToken; \
  static __typeof__(expr) staticVar; \
  dispatch_once(&onceToken, ^{ \
    staticVar = expr; \
  }); \
  staticVar; \
})

/// Ensure that class is of certain kind
#define ASDynamicCast(x, c) ({ \
  id __val = x;\
  ((c *) ([__val isKindOfClass:[c class]] ? __val : nil));\
})

/// Ensure that class is of certain kind, assuming it is subclass restricted
#define ASDynamicCastStrict(x, c) ({ \
  id __val = x;\
  ((c *) ([__val class] == [c class] ? __val : nil));\
})

// Compare two primitives, assign if different. Returns whether the assignment happened.
#define ASCompareAssign(lvalue, newValue) ({  \
  BOOL result = (lvalue != newValue);         \
  if (result) { lvalue = newValue; }          \
  result;                                     \
})

#define ASCompareAssignObjects(lvalue, newValue) \
  ASCompareAssignCustom(lvalue, newValue, ASObjectIsEqual)

// e.g. ASCompareAssignCustom(_myInsets, insets, UIEdgeInsetsEqualToEdgeInsets)
#define ASCompareAssignCustom(lvalue, newValue, isequal) ({  \
  BOOL result = !(isequal(lvalue, newValue));                \
  if (result) { lvalue = newValue; }                         \
  result;                                                    \
})

#define ASCompareAssignCopy(lvalue, newValue) ({           \
  BOOL result = !ASObjectIsEqual(lvalue, newValue);        \
  if (result) { lvalue = [newValue copyWithZone:NULL]; }   \
  result;                                                  \
})

/**
 * Create a new set by mapping `collection` over `work`, ignoring nil.
 */
#define ASSetByFlatMapping(collection, decl, work) ({ \
  NSMutableSet *s = [[NSMutableSet alloc] init]; \
  for (decl in collection) {\
    id result = work; \
    if (result != nil) { \
      [s addObject:result]; \
    } \
  } \
  s; \
})

/**
 * Create a new ObjectPointerPersonality NSHashTable by mapping `collection` over `work`, ignoring nil.
 *
 * capacity: 0 is taken from +hashTableWithOptions.
 */
#define ASPointerTableByFlatMapping(collection, decl, work) ({ \
  NSHashTable *t = [[NSHashTable alloc] initWithOptions:NSHashTableObjectPointerPersonality capacity:0]; \
  for (decl in collection) {\
    id result = work; \
    if (result != nil) { \
      [t addObject:result]; \
    } \
  } \
  t; \
})

/**
 * Create a new array by mapping `collection` over `work`, ignoring nil.
 */
#define ASArrayByFlatMapping(collection, decl, work) ({ \
  NSMutableArray *a = [[NSMutableArray alloc] init]; \
  for (decl in collection) {\
    id result = work; \
    if (result != nil) { \
      [a addObject:result]; \
    } \
  } \
  a; \
})
