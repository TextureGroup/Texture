//
//  ASImageNode+CGExtras.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASImageNode+CGExtras.h>

// TODO rewrite these to be closer to the intended use -- take UIViewContentMode as param, CGRect destinationBounds, CGSize sourceSize.
static CGSize _ASSizeFillWithAspectRatio(CGFloat aspectRatio, CGSize constraints);
static CGSize _ASSizeFitWithAspectRatio(CGFloat aspectRatio, CGSize constraints);

static CGSize _ASSizeFillWithAspectRatio(CGFloat sizeToScaleAspectRatio, CGSize destinationSize)
{
  CGFloat destinationAspectRatio = destinationSize.width / destinationSize.height;
  if (sizeToScaleAspectRatio > destinationAspectRatio) {
    return CGSizeMake(destinationSize.height * sizeToScaleAspectRatio, destinationSize.height);
  } else {
    return CGSizeMake(destinationSize.width, round(destinationSize.width / sizeToScaleAspectRatio));
  }
}

static CGSize _ASSizeFitWithAspectRatio(CGFloat aspectRatio, CGSize constraints)
{
  CGFloat constraintAspectRatio = constraints.width / constraints.height;
  if (aspectRatio > constraintAspectRatio) {
    return CGSizeMake(constraints.width, constraints.width / aspectRatio);
  } else {
    return CGSizeMake(constraints.height * aspectRatio, constraints.height);
  }
}

void ASCroppedImageBackingSizeAndDrawRectInBounds(CGSize sourceImageSize,
                                                  CGSize boundsSize,
                                                  UIViewContentMode contentMode,
                                                  CGRect cropRect,
                                                  BOOL forceUpscaling,
                                                  CGSize forcedSize,
                                                  CGSize *outBackingSize,
                                                  CGRect *outDrawRect
                                                  )
{

  size_t destinationWidth = boundsSize.width;
  size_t destinationHeight = boundsSize.height;

  // Often, an image is too low resolution to completely fill the width and height provided.
  // Per the API contract as commented in the header, we will adjust input parameters (destinationWidth, destinationHeight) to ensure that the image is not upscaled on the CPU.
  CGFloat boundsAspectRatio = (CGFloat)destinationWidth / (CGFloat)destinationHeight;

  CGSize minimumDestinationSize = sourceImageSize;
  BOOL cropToRectDimensions = !CGRectIsEmpty(cropRect);

  // Given image size and container ratio, calculate minimum container size for the image under different contentMode
  if (cropToRectDimensions) {
    minimumDestinationSize = CGSizeMake(boundsSize.width / cropRect.size.width, boundsSize.height / cropRect.size.height);
  } else {
    if (contentMode == UIViewContentModeScaleAspectFill)
      minimumDestinationSize = _ASSizeFitWithAspectRatio(boundsAspectRatio, sourceImageSize);
    else if (contentMode == UIViewContentModeScaleAspectFit)
      minimumDestinationSize = _ASSizeFillWithAspectRatio(boundsAspectRatio, sourceImageSize);
  }

  // If fitting the desired aspect ratio to the image size actually results in a larger buffer, use the input values.
  // However, if there is a pixel savings (e.g. we would have to upscale the image), override the function arguments.
  if (CGSizeEqualToSize(CGSizeZero, forcedSize) == NO) {
    destinationWidth = (size_t)round(forcedSize.width);
    destinationHeight = (size_t)round(forcedSize.height);
  } else if (forceUpscaling == NO && (minimumDestinationSize.width * minimumDestinationSize.height) < (destinationWidth * destinationHeight)) {
    destinationWidth = (size_t)round(minimumDestinationSize.width);
    destinationHeight = (size_t)round(minimumDestinationSize.height);
    if (destinationWidth == 0 || destinationHeight == 0) {
      *outBackingSize = CGSizeZero;
      *outDrawRect = CGRectZero;
      return;
    }
  }

  // Figure out the scaled size within the destination bounds.
  CGFloat sourceImageAspectRatio = sourceImageSize.width / sourceImageSize.height;
  CGSize scaledSizeForImage = CGSizeMake(destinationWidth, destinationHeight);

  if (cropToRectDimensions) {
    scaledSizeForImage = CGSizeMake(boundsSize.width / cropRect.size.width, boundsSize.height / cropRect.size.height);
  } else {
    if (contentMode == UIViewContentModeScaleAspectFill)
      scaledSizeForImage = _ASSizeFillWithAspectRatio(sourceImageAspectRatio, scaledSizeForImage);
    else if (contentMode == UIViewContentModeScaleAspectFit)
      scaledSizeForImage = _ASSizeFitWithAspectRatio(sourceImageAspectRatio, scaledSizeForImage);
  }

  // Figure out the rectangle into which to draw the image.
  CGRect drawRect = CGRectZero;
  if (cropToRectDimensions) {
    drawRect = CGRectMake(-cropRect.origin.x * scaledSizeForImage.width,
                          -cropRect.origin.y * scaledSizeForImage.height,
                          scaledSizeForImage.width,
                          scaledSizeForImage.height);
  } else {
    // We want to obey the origin of cropRect in aspect-fill mode.
    if (contentMode == UIViewContentModeScaleAspectFill) {
      drawRect = CGRectMake(((destinationWidth - scaledSizeForImage.width) * cropRect.origin.x),
                            ((destinationHeight - scaledSizeForImage.height) * cropRect.origin.y),
                            scaledSizeForImage.width,
                            scaledSizeForImage.height);

    }
    // And otherwise just center it.
    else {
      drawRect = CGRectMake(((destinationWidth - scaledSizeForImage.width) / 2.0),
                            ((destinationHeight - scaledSizeForImage.height) / 2.0),
                            scaledSizeForImage.width,
                            scaledSizeForImage.height);
    }
  }

  *outDrawRect = drawRect;
  *outBackingSize = CGSizeMake(destinationWidth, destinationHeight);
}
