//
//  ASDisplayNodeLayout.mm
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASDisplayNodeLayout.h>

BOOL ASDisplayNodeLayout::isValid(NSUInteger versionArg)
{
  return layout != nil && version >= versionArg;
}

BOOL ASDisplayNodeLayout::isValid(ASSizeRange theConstrainedSize, CGSize theParentSize, NSUInteger versionArg)
{
  return isValid(versionArg)
      && CGSizeEqualToSize(parentSize, theParentSize)
      && ASSizeRangeEqualToSizeRange(constrainedSize, theConstrainedSize);
}
