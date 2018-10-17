//
//  SlowpokeImageNode.m
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "SlowpokeImageNode.h"

#import <AsyncDisplayKit/ASDisplayNode+Subclasses.h>

static CGFloat const kASDKLogoAspectRatio = 2.79;

@interface ASImageNode (ForwardWorkaround)
// This is a workaround until subclass overriding of custom drawing class methods is fixed
- (UIImage *)displayWithParameters:(id<NSObject>)parameters isCancelled:(asdisplaynode_iscancelled_block_t)isCancelledBlock;
@end

@implementation SlowpokeImageNode

- (UIImage *)displayWithParameters:(id<NSObject>)parameters isCancelled:(asdisplaynode_iscancelled_block_t)isCancelledBlock
{
  usleep( (long)(0.5 * USEC_PER_SEC) ); // artificial delay of 0.5s
  
  return [super displayWithParameters:parameters isCancelled:isCancelledBlock];
}

- (instancetype)init
{
  if (self = [super init]) {
    self.placeholderEnabled = YES;
    self.placeholderFadeDuration = 0.1;
  }
  return self;
}

- (CGSize)calculateSizeThatFits:(CGSize)constrainedSize
{
  if (constrainedSize.width > 0.0) {
    return CGSizeMake(constrainedSize.width, constrainedSize.width / kASDKLogoAspectRatio);
  } else if (constrainedSize.height > 0.0) {
    return CGSizeMake(constrainedSize.height * kASDKLogoAspectRatio, constrainedSize.height);
  }
  return CGSizeZero;
}

- (UIImage *)placeholderImage
{
  CGSize size = self.calculatedSize;
  if (CGSizeEqualToSize(size, CGSizeZero)) {
    return nil;
  }

  UIGraphicsBeginImageContext(size);
  [[UIColor whiteColor] setFill];
  [[UIColor colorWithWhite:0.9 alpha:1] setStroke];

  UIRectFill((CGRect){CGPointZero, size});

  UIBezierPath *path = [UIBezierPath bezierPath];
  [path moveToPoint:CGPointZero];
  [path addLineToPoint:(CGPoint){size.width, size.height}];
  [path stroke];

  [path moveToPoint:(CGPoint){size.width, 0.0}];
  [path addLineToPoint:(CGPoint){0.0, size.height}];
  [path stroke];

  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

@end
