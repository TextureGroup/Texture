//
//  ASLayoutManager.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASLayoutManager.h>

@implementation ASLayoutManager

- (void)showCGGlyphs:(const CGGlyph *)glyphs
           positions:(const CGPoint *)positions
               count:(NSUInteger)glyphCount
                font:(UIFont *)font
              matrix:(CGAffineTransform)textMatrix
          attributes:(NSDictionary *)attributes
           inContext:(CGContextRef)graphicsContext
{

  // NSLayoutManager has a hard coded internal color for hyperlinks which ignores
  // NSForegroundColorAttributeName. To get around this, we force the fill color
  // in the current context to match NSForegroundColorAttributeName.
  UIColor *foregroundColor = attributes[NSForegroundColorAttributeName];
  
  if (foregroundColor)
  {
    CGContextSetFillColorWithColor(graphicsContext, foregroundColor.CGColor);
  }
  
  [super showCGGlyphs:glyphs
            positions:positions
                count:glyphCount
                 font:font
               matrix:textMatrix
           attributes:attributes
            inContext:graphicsContext];
}

@end
