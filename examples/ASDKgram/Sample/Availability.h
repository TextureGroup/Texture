//
//  Availability.h
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASAvailability.h>

/**
 * Enable Yoga layout engine in Texture cells 
 */
#define YOGA_LAYOUT 0
#if !AS_ENABLE_LAYOUTSPECS
  #undef YOGA_LAYOUT
  #define YOGA_LAYOUT 1
#endif

/**
 * There are many ways to format ASLayoutSpec code.  In this example, we offer two different formats:
 * A flatter, more ordinary Objective-C style; or a more structured, "visually" declarative style.
 */
#define FLAT_LAYOUT 0
