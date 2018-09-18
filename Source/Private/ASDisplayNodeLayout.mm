//
//  ASDisplayNodeLayout.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
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
