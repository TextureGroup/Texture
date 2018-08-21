//
//  WindowWithStatusBarUnderlay.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "WindowWithStatusBarUnderlay.h"
#import "Utilities.h"

@implementation WindowWithStatusBarUnderlay
{
  UIView *_statusBarOpaqueUnderlayView;
}

-(instancetype)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    _statusBarOpaqueUnderlayView                 = [[UIView alloc] init];
    _statusBarOpaqueUnderlayView.backgroundColor = [UIColor darkBlueColor];
    [self addSubview:_statusBarOpaqueUnderlayView];
  }
  return self;
}

-(void)layoutSubviews
{
  [super layoutSubviews];
  
  [self bringSubviewToFront:_statusBarOpaqueUnderlayView];
  
  CGRect statusBarFrame              = CGRectZero;
  statusBarFrame.size.width          = [[UIScreen mainScreen] bounds].size.width;
  statusBarFrame.size.height         = [[UIApplication sharedApplication] statusBarFrame].size.height;
  _statusBarOpaqueUnderlayView.frame = statusBarFrame;
}

@end
