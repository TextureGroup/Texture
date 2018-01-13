//
//  ASGraphicsContext.h
//  AsyncDisplayKit
//
//  Created by Adlai on 1/12/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/ASBaseDefines.h>
#import <CoreGraphics/CoreGraphics.h>

@class UIImage;

// A flag to enable this beta feature. See below.
#ifndef AS_ENABLE_NO_COPY_RENDERING
#define AS_ENABLE_NO_COPY_RENDERING 0
#endif

/**
 * Functions for creating one-shot graphics contexts that do not have to copy
 * their contents when an image is generated from them. This is efficient
 * for our use, since we do not reuse graphics contexts.
 *
 * The API mirrors the UIGraphics API, with the exception that forming an image
 * ends the context as well.
 */

NS_ASSUME_NONNULL_BEGIN
ASDISPLAYNODE_EXTERN_C_BEGIN

/**
 * Creates a one-shot context.
 *
 * Behavior is the same as UIGraphicsBeginImageContextWithOptions.
 */
extern void ASGraphicsBeginImageContextWithOptions(CGSize size, BOOL opaque, CGFloat scale);

/**
 * Generates and image and ends the current one-shot context.
 *
 * Behavior is the same as UIGraphicsGetImageFromCurrentImageContext followed by UIGraphicsEndImageContext.
 */
extern UIImage * _Nullable ASGraphicsGetImageAndEndCurrentContext(void);

/**
 * Call this if you want to end the current context without making an image.
 *
 * Behavior is the same as UIGraphicsEndImageContext.
 */
extern void ASGraphicsEndImageContext(void);

ASDISPLAYNODE_EXTERN_C_END
NS_ASSUME_NONNULL_END
