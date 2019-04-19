//
//  ASSignpost.h
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <sys/kdebug_signpost.h>

#ifdef PROFILE
static constexpr bool kASSignpostsEnabled = true;
#else
static constexpr bool kASSignpostsEnabled = false;
#endif

/// The signposts we use. Signposts are grouped by color. The SystemTrace.tracetemplate file
/// should be kept up-to-date with these values.
typedef NS_ENUM(uint32_t, ASSignpostName) {
  // Collection/Table (Blue)
  ASSignpostDataControllerBatch = 300,    // Alloc/layout nodes before collection update.
  ASSignpostRangeControllerUpdate,        // Ranges update pass.
  ASSignpostCollectionUpdate,             // Entire update process, from -endUpdates to [super perform…]
  
  // Rendering (Green)
  ASSignpostLayerDisplay = 325,           // Client display callout.
  ASSignpostRunLoopQueueBatch,            // One batch of ASRunLoopQueue.
  
  // Layout (Purple)
  ASSignpostCalculateLayout = 350,        // Start of calculateLayoutThatFits to end. Max 1 per thread.
  
  // Misc (Orange)
  ASSignpostDeallocQueueDrain = 375,      // One chunk of dealloc queue work. arg0 is count.
  ASSignpostCATransactionLayout,          // The CA transaction commit layout phase.
  ASSignpostCATransactionCommit           // The CA transaction commit post-layout phase.
};

typedef NS_ENUM(uintptr_t, ASSignpostColor) {
  ASSignpostColorBlue,
  ASSignpostColorGreen,
  ASSignpostColorPurple,
  ASSignpostColorOrange,
  ASSignpostColorRed,
  ASSignpostColorDefault
};

NS_INLINE ASSignpostColor ASSignpostGetColor(ASSignpostName name, ASSignpostColor colorPref) {
  if (colorPref == ASSignpostColorDefault) {
    return (ASSignpostColor)((name / 25) % 4);
  } else {
    return colorPref;
  }
}

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
#endif  // !defined(DBG_MACH_CHUD)

// Currently we'll reserve arg3.
NS_INLINE void ASSignpost(ASSignpostName name, uintptr_t identifier = 0, uintptr_t arg2 = 0, ASSignpostColor preferred_color = ASSignpostColorDefault)
{
  if (kASSignpostsEnabled) {
    if (AS_AVAILABLE_IOS_TVOS(10, 10)) {
      kdebug_signpost(name, identifier, arg2, 0, ASSignpostGetColor(name, preferred_color));
    } else {
      syscall(SYS_kdebug_trace, APPSDBG_CODE(DBG_MACH_CHUD, name) | DBG_FUNC_NONE, identifier, arg2, 0, ASSignpostGetColor(name, preferred_color));
    }
  }
}

NS_INLINE void ASSignpostStart(ASSignpostName name, uintptr_t identifier = 0, uintptr_t arg2 = 0)
{
  if (kASSignpostsEnabled) {
    if (AS_AVAILABLE_IOS_TVOS(10, 10)) {
      kdebug_signpost_start(name, identifier, arg2, 0, 0);
    } else {
      syscall(SYS_kdebug_trace, APPSDBG_CODE(DBG_MACH_CHUD, name) | DBG_FUNC_START, (uintptr_t)identifier, (uintptr_t)arg2, 0, 0);
    }
  }
}

NS_INLINE void ASSignpostEnd(ASSignpostName name, uintptr_t identifier = 0, uintptr_t arg2 = 0, ASSignpostColor preferred_color = ASSignpostColorDefault)
{
  if (kASSignpostsEnabled) {
    if (AS_AVAILABLE_IOS_TVOS(10, 10)) {
      kdebug_signpost_end(name, identifier, arg2, 0, 0);
    } else {
      syscall(SYS_kdebug_trace, APPSDBG_CODE(DBG_MACH_CHUD, name) | DBG_FUNC_END, identifier, arg2, 0, ASSignpostGetColor(name, preferred_color));
    }
  }
}
