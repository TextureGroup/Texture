//
//  SupplementaryNode.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "SupplementaryNode.h"

#import <AsyncDisplayKit/ASDisplayNode+Subclasses.h>
#import <AsyncDisplayKit/ASInsetLayoutSpec.h>
#import <AsyncDisplayKit/ASCenterLayoutSpec.h>

static CGFloat kInsets = 15.0;

@interface SupplementaryNode ()
@property (nonatomic, strong) ASTextNode *textNode;
@end

@implementation SupplementaryNode

- (instancetype)initWithText:(NSString *)text
{
  self = [super init];
  
  if (self != nil) {
    _textNode = [[ASTextNode alloc] init];
    _textNode.attributedText = [[NSAttributedString alloc] initWithString:text
                                                                 attributes:[self textAttributes]];
    [self addSubnode:_textNode];
  }
  
  return self;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
  ASCenterLayoutSpec *center = [[ASCenterLayoutSpec alloc] init];
  center.centeringOptions = ASCenterLayoutSpecCenteringXY;
  center.child = self.textNode;
  UIEdgeInsets insets = UIEdgeInsetsMake(kInsets, kInsets, kInsets, kInsets);
  
  return [ASInsetLayoutSpec insetLayoutSpecWithInsets:insets child:center];
}

#pragma mark - Text Formatting

- (NSDictionary *)textAttributes
{
  return @{
    NSFontAttributeName: [UIFont systemFontOfSize:18.0],
    NSForegroundColorAttributeName: [UIColor whiteColor],
  };
}

@end
