//
//  ASVisibilityProtocols.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASVisibilityProtocols.h>

ASLayoutRangeMode ASLayoutRangeModeForVisibilityDepth(NSUInteger visibilityDepth)
{
  if (visibilityDepth == 0) {
    return ASLayoutRangeModeFull;
  } else if (visibilityDepth == 1) {
    return ASLayoutRangeModeMinimum;
  } else if (visibilityDepth == 2) {
    return ASLayoutRangeModeVisibleOnly;
  }
  return ASLayoutRangeModeLowMemory;
}
