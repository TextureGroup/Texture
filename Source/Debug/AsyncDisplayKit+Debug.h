//
//  AsyncDisplayKit+Debug.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASControlNode.h"
#import "ASImageNode.h"

NS_ASSUME_NONNULL_BEGIN

@interface ASImageNode (Debugging)

/**
 * Enables an ASImageNode debug label that shows the ratio of pixels in the source image to those in
 * the displayed bounds (including cropRect).  This helps detect excessive image fetching / downscaling,
 * as well as upscaling (such as providing a URL not suitable for a Retina device).  For dev purposes only.
 * Specify YES to show the label on all ASImageNodes with non-1.0x source-to-bounds pixel ratio.
 */
@property (class, nonatomic) BOOL shouldShowImageScalingOverlay;

@end

@interface ASControlNode (Debugging)

/**
 * Class method to enable a visualization overlay of the tappable area on the ASControlNode. For app debugging purposes only.
 * NOTE: GESTURE RECOGNIZERS, (including tap gesture recognizers on a control node) WILL NOT BE VISUALIZED!!!
 * Overlay = translucent GREEN color,
 * edges that are clipped by the tappable area of any parent (their bounds + hitTestSlop) in the hierarchy = DARK GREEN BORDERED EDGE,
 * edges that are clipped by clipToBounds = YES of any parent in the hierarchy = ORANGE BORDERED EDGE (may still receive touches beyond
 * overlay rect, but can't be visualized).
 * Specify YES to make this debug feature enabled when messaging the ASControlNode class.
 */
@property (class, nonatomic) BOOL enableHitTestDebug;

@end

@interface ASDisplayNode (RangeDebugging)

/**
 * Enable a visualization overlay of the all table/collection tuning parameters. For dev purposes only.
 * To use, set this in the AppDelegate --> ASDisplayNode.shouldShowRangeDebugOverlay = YES
 */
@property (class, nonatomic) BOOL shouldShowRangeDebugOverlay;

@end


NS_ASSUME_NONNULL_END
