//
//  ASLayout+IGListKit.mm
//  Texture
//
//  Copyright (c) 2018-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
#import <AsyncDisplayKit/ASAvailability.h>
#if AS_IG_LIST_KIT
#import "ASLayout+IGListKit.h"
#import <AsyncDisplayKit/ASLayout.h>
#import <IGListKit/IGListKit.h>
#import <AsyncDisplayKit/ASEqualityHelpers.h>

@implementation ASLayout(IGListKit)
- (nonnull id <NSObject>)diffIdentifier
{
  return @([self.layoutElement hash]);
}

- (BOOL)isEqualToDiffableObject:(nullable id <IGListDiffable>)other
{
  if (other == self) return YES;

  ASLayout *otherLayout = ASDynamicCast(other, ASLayout);
  if (!otherLayout) return NO;

  return [otherLayout.layoutElement isEqual:self.layoutElement];
}
@end
#endif // AS_IG_LIST_KIT
