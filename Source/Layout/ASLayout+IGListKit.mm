//
//  ASLayout+IGListKit.mm
//  AsyncDisplayKit
//
//  Created by Kevin Smith on 7/1/18.
//  Copyright © 2018 Pinterest. All rights reserved.
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
