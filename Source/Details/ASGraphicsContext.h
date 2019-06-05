//
//  ASGraphicsContext.h
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <UIKit/UIKit.h>
#import <AsyncDisplayKit/ASBaseDefines.h>
#import <AsyncDisplayKit/ASBlockTypes.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A wrapper for the UIKit drawing APIs. If you are in ASExperimentalDrawingGlobal, and you have iOS >= 10, we will create
 * a UIGraphicsRenderer with an appropriate format. Otherwise, we will use UIGraphicsBeginImageContext et al.
 *
 * @param size The size of the context.
 * @param opaque Whether the context should be opaque or not.
 * @param scale The scale of the context. 0 uses main screen scale.
 * @param sourceImage If you are planning to render a UIImage into this context, provide it here and we will use its
 *   preferred renderer format if we are using UIGraphicsImageRenderer.
 * @param isCancelled An optional block for canceling the drawing before forming the image. Only takes effect under
 *   the legacy code path, as UIGraphicsRenderer does not support cancellation.
 * @param work A block, wherein the current UIGraphics context is set based on the arguments.
 *
 * @return The rendered image. You can also render intermediary images using UIGraphicsGetImageFromCurrentImageContext.
 */
AS_EXTERN UIImage *ASGraphicsCreateImageWithOptions(CGSize size, BOOL opaque, CGFloat scale, UIImage * _Nullable sourceImage, asdisplaynode_iscancelled_block_t NS_NOESCAPE _Nullable isCancelled, void (NS_NOESCAPE ^work)());

NS_ASSUME_NONNULL_END
