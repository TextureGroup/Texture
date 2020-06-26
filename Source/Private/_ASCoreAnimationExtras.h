//
//  _ASCoreAnimationExtras.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <UIKit/UIKit.h>

#import <AsyncDisplayKit/ASBaseDefines.h>
#import <AsyncDisplayKit/ASDisplayNode.h>

// This protocol defines the core properties that ASDisplayNode and CALayer share, for managing contents.
@protocol ASResizableContents
@required
@property id contents;
@property CGRect contentsRect;
@property CGRect contentsCenter;
@property CGFloat contentsScale;
@property CGFloat rasterizationScale;
@property NSString *contentsGravity;
@end

@interface CALayer (ASResizableContents) <ASResizableContents>
@end
@interface ASDisplayNode (ASResizableContents) <ASResizableContents>
@end

/**
 This function can operate on either an ASDisplayNode (including un-loaded) or CALayer directly. More info about resizing mode: https://github.com/TextureGroup/Texture/issues/439

 @param obj ASDisplayNode, CALayer or object that conforms to `ASResizableContents` protocol
 @param image Image you would like to resize
 */
ASDK_EXTERN void ASDisplayNodeSetResizableContents(id<ASResizableContents> obj, UIImage *image);

/**
 Turns a value of UIViewContentMode to a string for debugging or serialization
 @param contentMode Any of the UIViewContentMode constants
 @return A human-readable representation of the constant, or the integer value of the constant if not recognized.
 */
ASDK_EXTERN NSString *ASDisplayNodeNSStringFromUIContentMode(UIViewContentMode contentMode);

/**
 Turns a string representing a contentMode into a contentMode
 @param string Any of the strings in UIContentModeDescriptionLUT
 @return Any of the UIViewContentMode constants, or an int if the string is a number. If the string is not recognized, UIViewContentModeScaleToFill is returned.
 */
ASDK_EXTERN UIViewContentMode ASDisplayNodeUIContentModeFromNSString(NSString *string);

/**
 Maps a value of UIViewContentMode to a corresponding contentsGravity
 It is worth noting that UIKit and CA have inverse definitions of "top" and "bottom" on iOS, so the corresponding contentsGravity for UIViewContentModeTopLeft is kCAContentsGravityBottomLeft
 @param contentMode A content mode except for UIViewContentModeRedraw, which has no corresponding contentsGravity (it corresponds to needsDisplayOnBoundsChange = YES)
 @return An NSString constant from the documentation, eg kCAGravityCenter... or nil if there is no corresponding contentsGravity. Will assert if contentMode is unknown.
 */
ASDK_EXTERN NSString *const ASDisplayNodeCAContentsGravityFromUIContentMode(UIViewContentMode contentMode);

/**
 Maps a value of contentsGravity to a corresponding UIViewContentMode
 It is worth noting that UIKit and CA have inverse definitions of "top" and "bottom" on iOS, so the corresponding contentMode for kCAContentsGravityBottomLeft is UIViewContentModeTopLeft
 @param contentsGravity A contents gravity
 @return A UIViewContentMode constant from UIView.h, eg UIViewContentModeCenter...,  or UIViewContentModeScaleToFill if contentsGravity is not one of the CA constants. Will assert if the contentsGravity is unknown.
 */
ASDK_EXTERN UIViewContentMode ASDisplayNodeUIContentModeFromCAContentsGravity(NSString *const contentsGravity);

/**
 Use this to create a stretchable appropriate to approximate a filled rectangle, but with antialiasing on the edges when not pixel-aligned. It's best to keep the layer this image is added to with contentsScale equal to the scale of the final transform to screen space so it is able to antialias appropriately even when you shrink or grow the layer.
 @param color the fill color to use in the center of the image
 @param innerSize Unfortunately, 4 seems to be the smallest inner size that works if you're applying this stretchable to a larger box, whereas it does not display correctly for larger boxes. Thus some adjustment is necessary for the size of box you're displaying. If you're showing a 1px horizontal line, pass 1 height and at least 4 width. 2px vertical line: 2px wide, 4px high. Passing an innerSize greater that you desire is wasteful
 */
ASDK_EXTERN UIImage *ASDisplayNodeStretchableBoxContentsWithColor(UIColor *color, CGSize innerSize);

/**
 Checks whether a layer has ongoing animations
 @param layer A layer to check if animations are ongoing
 @return YES if the layer has ongoing animations, otherwise NO
 */
ASDK_EXTERN BOOL ASDisplayNodeLayerHasAnimations(CALayer *layer);

// This function is a less generalized version of ASDisplayNodeSetResizableContents.
ASDK_EXTERN void ASDisplayNodeSetupLayerContentsWithResizableImage(CALayer *layer, UIImage *image) ASDISPLAYNODE_DEPRECATED;
