//
//  CoreGraphics+ASConvenience.m
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

#import <AsyncDisplayKit/CoreGraphics+ASConvenience.h>

AS_OVERLOADABLE CGPathRef ASCGRoundedPathCreate(CGRect rect, UIRectCorner corners, CGSize cornerRadii) {
  CGMutablePathRef path = CGPathCreateMutable();
  
  const CGPoint topLeft = rect.origin;
  const CGPoint topRight = CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect));
  const CGPoint bottomRight = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
  const CGPoint bottomLeft = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect));
  
  if (corners & UIRectCornerTopLeft) {
    CGPathMoveToPoint(path, NULL, topLeft.x+cornerRadii.width, topLeft.y);
  } else {
    CGPathMoveToPoint(path, NULL, topLeft.x, topLeft.y);
  }
  
  if (corners & UIRectCornerTopRight) {
    CGPathAddLineToPoint(path, NULL, topRight.x-cornerRadii.width, topRight.y);
    CGPathAddCurveToPoint(path, NULL, topRight.x, topRight.y, topRight.x, topRight.y+cornerRadii.height, topRight.x, topRight.y+cornerRadii.height);
  } else {
    CGPathAddLineToPoint(path, NULL, topRight.x, topRight.y);
  }
  
  if (corners & UIRectCornerBottomRight) {
    CGPathAddLineToPoint(path, NULL, bottomRight.x, bottomRight.y-cornerRadii.height);
    CGPathAddCurveToPoint(path, NULL, bottomRight.x, bottomRight.y, bottomRight.x-cornerRadii.width, bottomRight.y, bottomRight.x-cornerRadii.width, bottomRight.y);
  } else {
    CGPathAddLineToPoint(path, NULL, bottomRight.x, bottomRight.y);
  }
  
  if (corners & UIRectCornerBottomLeft) {
    CGPathAddLineToPoint(path, NULL, bottomLeft.x+cornerRadii.width, bottomLeft.y);
    CGPathAddCurveToPoint(path, NULL, bottomLeft.x, bottomLeft.y, bottomLeft.x, bottomLeft.y-cornerRadii.height, bottomLeft.x, bottomLeft.y-cornerRadii.height);
  } else {
    CGPathAddLineToPoint(path, NULL, bottomLeft.x, bottomLeft.y);
  }
  
  if (corners & UIRectCornerTopLeft) {
    CGPathAddLineToPoint(path, NULL, topLeft.x, topLeft.y+cornerRadii.height);
    CGPathAddCurveToPoint(path, NULL, topLeft.x, topLeft.y, topLeft.x+cornerRadii.width, topLeft.y, topLeft.x+cornerRadii.width, topLeft.y);
  } else {
    CGPathAddLineToPoint(path, NULL, topLeft.x, topLeft.y);
  }
  
  CGPathCloseSubpath(path);
  return path;
}
