//
//  ASCenterLayoutSpec.mm
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASCenterLayoutSpec.h>

#import <AsyncDisplayKit/ASLayout.h>

@implementation ASCenterLayoutSpec
{
  ASCenterLayoutSpecCenteringOptions _centeringOptions;
  ASCenterLayoutSpecSizingOptions _sizingOptions;
}

- (instancetype)initWithCenteringOptions:(ASCenterLayoutSpecCenteringOptions)centeringOptions
                           sizingOptions:(ASCenterLayoutSpecSizingOptions)sizingOptions
                                   child:(id<ASLayoutElement>)child;
{
  ASRelativeLayoutSpecPosition verticalPosition = [self verticalPositionFromCenteringOptions:centeringOptions];
  ASRelativeLayoutSpecPosition horizontalPosition = [self horizontalPositionFromCenteringOptions:centeringOptions];
  
  if (!(self = [super initWithHorizontalPosition:horizontalPosition verticalPosition:verticalPosition sizingOption:sizingOptions child:child])) {
    return nil;
  }
  _centeringOptions = centeringOptions;
  _sizingOptions = sizingOptions;
  return self;
}

+ (instancetype)centerLayoutSpecWithCenteringOptions:(ASCenterLayoutSpecCenteringOptions)centeringOptions
                                       sizingOptions:(ASCenterLayoutSpecSizingOptions)sizingOptions
                                               child:(id<ASLayoutElement>)child NS_RETURNS_RETAINED
{
  return [[self alloc] initWithCenteringOptions:centeringOptions sizingOptions:sizingOptions child:child];
}

- (void)setCenteringOptions:(ASCenterLayoutSpecCenteringOptions)centeringOptions
{
  ASDisplayNodeAssert(self.isMutable, @"Cannot set properties when layout spec is not mutable");
  _centeringOptions = centeringOptions;
  
  [self setHorizontalPosition:[self horizontalPositionFromCenteringOptions:centeringOptions]];
  [self setVerticalPosition:[self verticalPositionFromCenteringOptions:centeringOptions]];
}

- (void)setSizingOptions:(ASCenterLayoutSpecSizingOptions)sizingOptions
{
  ASDisplayNodeAssert(self.isMutable, @"Cannot set properties when layout spec is not mutable");
  _sizingOptions = sizingOptions;
  [self setSizingOption:sizingOptions];
}

- (ASRelativeLayoutSpecPosition)horizontalPositionFromCenteringOptions:(ASCenterLayoutSpecCenteringOptions)centeringOptions
{
  if ((centeringOptions & ASCenterLayoutSpecCenteringX) != 0) {
    return ASRelativeLayoutSpecPositionCenter;
  } else {
    return ASRelativeLayoutSpecPositionNone;
  }
}

- (ASRelativeLayoutSpecPosition)verticalPositionFromCenteringOptions:(ASCenterLayoutSpecCenteringOptions)centeringOptions
{
  if ((centeringOptions & ASCenterLayoutSpecCenteringY) != 0) {
    return ASRelativeLayoutSpecPositionCenter;
  } else {
    return ASRelativeLayoutSpecPositionNone;
  }
}

@end
