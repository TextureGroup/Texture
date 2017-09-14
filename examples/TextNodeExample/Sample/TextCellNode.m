//
//  TextCellNode.m
//  Sample
//
//  Created by Max Wang on 9/11/17.
//  Copyright © 2017 Max Wang. All rights reserved.
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
