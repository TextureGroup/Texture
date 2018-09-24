//
//  TECellNode.m
//  Sample
//
//  Created by Adlai Holler on 9/21/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "TECellNode.h"

@implementation TECellNode {
  ASTextNode *_titleNode;
}

- (instancetype)init {
  if (self = [super init]) {
    _titleNode = [[ASTextNode alloc] init];
    self.automaticallyManagesSubnodes = YES;
  }
  return self;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize {
  return [ASStackLayoutSpec stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal spacing:5 justifyContent:ASStackLayoutJustifyContentSpaceBetween alignItems:ASStackLayoutAlignItemsCenter children:@[ _titleNode ]];
}

- (void)setItem:(const Item &)item {
  auto textPtr = item.text();
  auto nsstr = [[NSString alloc] initWithBytes:textPtr->c_str() length:textPtr->size() encoding:NSUTF8StringEncoding];
  _titleNode.attributedText = [[NSAttributedString alloc] initWithString:nsstr];
}

@end
