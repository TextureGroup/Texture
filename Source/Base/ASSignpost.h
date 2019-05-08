//
//  ASSignpost.h
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

/// The signposts we use. Signposts are grouped by color. The SystemTrace.tracetemplate file
/// should be kept up-to-date with these values.
typedef NS_ENUM(uint32_t, ASSignpostName) {
  // Collection/Table
  ASSignpostDataControllerBatch = 300,    // Alloc/layout nodes before collection update.
  ASSignpostRangeControllerUpdate,        // Ranges update pass.
  
  // Rendering
  ASSignpostLayerDisplay = 325,           // Client display callout.
  ASSignpostRunLoopQueueBatch,            // One batch of ASRunLoopQueue.
  
  // Layout
  ASSignpostCalculateLayout = 350,        // Start of calculateLayoutThatFits to end. Max 1 per thread.
  
  // Misc
  ASSignpostDeallocQueueDrain = 375,      // One chunk of dealloc queue work. arg0 is count.
  ASSignpostOrientationChange,            // From WillChangeStatusBarOrientation to animation end.
};

#ifdef PROFILE
  #define AS_SIGNPOST_ENABLE 1
#else
  #define AS_SIGNPOST_ENABLE 0
#endif

#if AS_SIGNPOST_ENABLE

#import <sys/kdebug_signpost.h>
#if AS_HAS_OS_SIGNPOST
#import <os/signpost.h>
#endif

// These definitions are required to build the backward-compatible kdebug trace
// on the iOS 10 SDK.  The kdebug_trace function crashes if run on iOS 9 and earlier.
// It's valuable to support trace signposts on iOS 9, because A5 devices don't support iOS 10.
#ifndef DBG_MACH_CHUD
#define DBG_MACH_CHUD 0x0A
#define DBG_FUNC_NONE 0
#define DBG_FUNC_START 1
#define DBG_FUNC_END 2
#define DBG_APPS 33
#define SYS_kdebug_trace 180
#define KDBG_CODE(Class, SubClass, code) (((Class & 0xff) << 24) | ((SubClass & 0xff) << 16) | ((code & 0x3fff)  << 2))
#define APPSDBG_CODE(SubClass,code) KDBG_CODE(DBG_APPS, SubClass, code)
#endif

#if AS_HAS_OS_SIGNPOST

#define ASSignpostStart(name, identifier, format, ...) ({\
  if (AS_AVAILABLE_IOS_TVOS(12, 12)) { \
    unowned os_log_t log = ASPointsOfInterestLog(); \
    os_signpost_id_t spid = os_signpost_id_make_with_id(log, identifier); \
    os_signpost_interval_begin(log, spid, #name, format, ##__VA_ARGS__); \
  } else if (AS_AVAILABLE_IOS_TVOS(10, 10)) { \
    kdebug_signpost_start(ASSignpost##name, (uintptr_t)identifier, 0, 0, 0); \
  } else { \
    syscall(SYS_kdebug_trace, APPSDBG_CODE(DBG_MACH_CHUD, ASSignpost##name) | DBG_FUNC_START, (uintptr_t)identifier, 0, 0, 0); \
  } \
})

#define ASSignpostEnd(name, identifier, format, ...) ({\
  if (AS_AVAILABLE_IOS_TVOS(12, 12)) { \
    unowned os_log_t log = ASPointsOfInterestLog(); \
    os_signpost_id_t spid = os_signpost_id_make_with_id(log, identifier); \
    os_signpost_interval_end(log, spid, #name, format, ##__VA_ARGS__); \
  } else if (AS_AVAILABLE_IOS_TVOS(10, 10)) { \
    kdebug_signpost_end(ASSignpost##name, (uintptr_t)identifier, 0, 0, 0); \
  } else { \
    syscall(SYS_kdebug_trace, APPSDBG_CODE(DBG_MACH_CHUD, ASSignpost##name) | DBG_FUNC_END, (uintptr_t)identifier, 0, 0, 0); \
  } \
})

#else // !AS_HAS_OS_SIGNPOST

#define ASSignpostStart(name, identifier, format, ...) ({\
  if (AS_AVAILABLE_IOS_TVOS(10, 10)) { \
    kdebug_signpost_start(ASSignpost##name, (uintptr_t)identifier, 0, 0, 0); \
  } else { \
    syscall(SYS_kdebug_trace, APPSDBG_CODE(DBG_MACH_CHUD, ASSignpost##name) | DBG_FUNC_START, (uintptr_t)identifier, 0, 0, 0); \
  } \
})

#define ASSignpostEnd(name, identifier, format, ...) ({\
  if (AS_AVAILABLE_IOS_TVOS(10, 10)) { \
    kdebug_signpost_end(ASSignpost##name, (uintptr_t)identifier, 0, 0, 0); \
  } else { \
    syscall(SYS_kdebug_trace, APPSDBG_CODE(DBG_MACH_CHUD, ASSignpost##name) | DBG_FUNC_END, (uintptr_t)identifier, 0, 0, 0); \
  } \
})

#endif

#else // !AS_SIGNPOST_ENABLE

#define ASSignpostStart(name, identifier, format, ...)
#define ASSignpostEnd(name, identifier, format, ...)

#endif
