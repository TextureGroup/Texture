//
//  ASDefaultPlaybackButton.m
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

#import <AsyncDisplayKit/ASDefaultPlaybackButton.h>
#import <AsyncDisplayKit/_ASDisplayLayer.h>

@interface ASDefaultPlaybackButton()
{
  ASDefaultPlaybackButtonType _buttonType;
}
@end

@implementation ASDefaultPlaybackButton
- (instancetype)init
{
  if (!(self = [super init])) {
    return nil;
  }

  self.opaque = NO;

  return self;
}

- (void)setButtonType:(ASDefaultPlaybackButtonType)buttonType
{
  ASDefaultPlaybackButtonType oldType = _buttonType;
  _buttonType = buttonType;

  if (oldType != _buttonType) {
    [self setNeedsDisplay];
  }
}

- (nullable NSDictionary *)drawParametersForAsyncLayer:(_ASDisplayLayer *)layer
{
  return @{
    @"buttonType" : @(self.buttonType),
    @"color" : self.tintColor
  };
}

+ (void)drawRect:(CGRect)bounds withParameters:(NSDictionary *)parameters isCancelled:(asdisplaynode_iscancelled_block_t)isCancelledBlock isRasterizing:(BOOL)isRasterizing
{
  ASDefaultPlaybackButtonType buttonType = (ASDefaultPlaybackButtonType)[parameters[@"buttonType"] intValue];
  UIColor *color = parameters[@"color"];

  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSaveGState(context);
  UIBezierPath* bezierPath = [UIBezierPath bezierPath];
  if (buttonType == ASDefaultPlaybackButtonTypePlay) {
    [bezierPath moveToPoint: CGPointMake(0, 0)];
    [bezierPath addLineToPoint: CGPointMake(0, bounds.size.height)];
    [bezierPath addLineToPoint: CGPointMake(bounds.size.width, bounds.size.height/2)];
    [bezierPath addLineToPoint: CGPointMake(0, 0)];
    [bezierPath closePath];
  } else if (buttonType == ASDefaultPlaybackButtonTypePause) {
    CGFloat pauseSingleLineWidth = bounds.size.width / 3.0;
    [bezierPath moveToPoint: CGPointMake(0, bounds.size.height)];
    [bezierPath addLineToPoint: CGPointMake(pauseSingleLineWidth, bounds.size.height)];
    [bezierPath addLineToPoint: CGPointMake(pauseSingleLineWidth, 0)];
    [bezierPath addLineToPoint: CGPointMake(0, 0)];
    [bezierPath addLineToPoint: CGPointMake(0, bounds.size.height)];
    [bezierPath closePath];
    [bezierPath moveToPoint: CGPointMake(pauseSingleLineWidth * 2, 0)];
    [bezierPath addLineToPoint: CGPointMake(pauseSingleLineWidth * 2, bounds.size.height)];
    [bezierPath addLineToPoint: CGPointMake(bounds.size.width, bounds.size.height)];
    [bezierPath addLineToPoint: CGPointMake(bounds.size.width, 0)];
    [bezierPath addLineToPoint: CGPointMake(pauseSingleLineWidth * 2, 0)];
    [bezierPath closePath];
  }

  [color setFill];
  [bezierPath fill];

  CGContextRestoreGState(context);
}
@end
