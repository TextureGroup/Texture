//
//  ASListTestSection.h
//  Texture
//
//  Created by Adlai Holler on 12/25/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import <IGListKit/IGListKit.h>
#import <AsyncDisplayKit/AsyncDisplayKit.h>

@interface ASListTestSection : IGListSectionController <IGListSectionType, ASSectionController>

@property (nonatomic) NSInteger itemCount;

@property (nonatomic) NSInteger selectedItemIndex;

@end
