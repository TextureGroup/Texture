//
//  TextCellNode.m
//  Texture
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the /ASDK-Licenses directory of this source tree. An additional
//  grant of patent rights can be found in the PATENTS file in the same directory.
//
//  Modifications to this file made after 4/13/2017 are: Copyright (c) 2017-present,
//  Pinterest, Inc.  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "TextCellNode.h"
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import <AsyncDisplayKit/ASDisplayNode+Beta.h>

@interface TextCellNode() {
  ASTextNode2 *_label1;
  ASTextNode2 *_label2;
}

@end

@implementation TextCellNode

- initWithText1:(NSString*)text1 text2:(NSString*)text2 {
  self = [super init];
  if (self) {
    self.automaticallyManagesSubnodes = YES;
    self.clipsToBounds = YES;
    _label1 = [[ASTextNode2 alloc] init];
    _label1.attributedText = [[NSAttributedString alloc] initWithString:text1];
    _label2 = [[ASTextNode2 alloc] init];
    _label2.attributedText = [[NSAttributedString alloc] initWithString:text2];

    _label1.maximumNumberOfLines = 1;
    _label1.truncationMode = NSLineBreakByTruncatingTail;
    _label2.maximumNumberOfLines = 1;
    _label2.truncationMode = NSLineBreakByTruncatingTail;

    [self simpleSetupYogaLayout];
  }
  return self;
}

-(void)didLoad {
  [super didLoad];

}

-(void)nodeDidLayout {
  [super nodeDidLayout];

}

-(void)simpleSetupYogaLayout {
  [self.style yogaNodeCreateIfNeeded];
  [_label1.style yogaNodeCreateIfNeeded];
  [_label2.style yogaNodeCreateIfNeeded];

  _label1.style.flexGrow = 0;
  _label1.style.flexShrink = 1;
  _label1.backgroundColor = [UIColor lightGrayColor];

  _label2.style.flexGrow = 0;
  _label2.style.flexShrink = 0; //!!!

    ASDisplayNode* l1Container = [ASDisplayNode yogaVerticalStack];
    l1Container.style.alignItems = ASStackLayoutAlignItemsCenter;
    _label1.style.alignSelf = ASStackLayoutAlignSelfStart;

    l1Container.style.flexShrink = 1;
    l1Container.style.flexGrow = 0;

    l1Container.yogaChildren = @[_label1];

  self.style.justifyContent = ASStackLayoutJustifyContentSpaceBetween;
  self.style.alignItems = ASStackLayoutAlignItemsStart;
  self.style.flexDirection = ASStackLayoutDirectionHorizontal;
  self.yogaChildren = @[l1Container, _label2];
}

@end
