//
//  PDDOMTypes+UIKit.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASAvailability.h>

#if AS_TEXTURE_DEBUGGER

#import "PDDOMTypes+UIKit.h"

@implementation NSDictionary (PDDOMRGBA)

- (UIColor *)UIColor
{
  return [UIColor colorWithRed:[[self valueForKey:@"r"] floatValue] / 255.0
                         green:[[self valueForKey:@"g"] floatValue] / 255.0
                          blue:[[self valueForKey:@"b"] floatValue] / 255.0
                         alpha:[[self valueForKey:@"a"] floatValue]];
}

@end

@implementation NSDictionary (PDDOMHighlightConfig)

- (UIColor *)contentUIColor
{
    return ((NSDictionary *)[self valueForKey:@"contentColor"]).UIColor;
}

- (UIColor *)paddingUIColor
{
    return ((NSDictionary *)[self valueForKey:@"paddingColor"]).UIColor;
}

- (UIColor *)borderUIColor
{
    return ((NSDictionary *)[self valueForKey:@"borderColor"]).UIColor;
}

- (UIColor *)marginUIColor
{
    return ((NSDictionary *)[self valueForKey:@"marginColor"]).UIColor;
}

@end

#endif
