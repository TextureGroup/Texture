//
//  OverviewCellNode.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "OverviewCellNode.h"
#import "LayoutExampleNodes.h"
#import "Utilities.h"

@interface OverviewCellNode ()
@property (nonatomic, strong) ASTextNode *titleNode;
@property (nonatomic, strong) ASTextNode *descriptionNode;
@end

@implementation OverviewCellNode

- (instancetype)initWithLayoutExampleClass:(Class)layoutExampleClass
{
    self = [super init];
    if (self) {
      self.automaticallyManagesSubnodes = YES;
      
      _layoutExampleClass = layoutExampleClass;
      
      _titleNode = [[ASTextNode alloc] init];
      _titleNode.attributedText = [NSAttributedString attributedStringWithString:[layoutExampleClass title]
                                                                  fontSize:16
                                                                     color:[UIColor blackColor]];
  
      _descriptionNode = [[ASTextNode alloc] init];
      _descriptionNode.attributedText = [NSAttributedString attributedStringWithString:[layoutExampleClass descriptionTitle]
                                                                              fontSize:12
                                                                                 color:[UIColor lightGrayColor]];
   }
    return self;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
    ASStackLayoutSpec *verticalStackSpec = [ASStackLayoutSpec verticalStackLayoutSpec];
    verticalStackSpec.alignItems = ASStackLayoutAlignItemsStart;
    verticalStackSpec.spacing = 5.0;
    verticalStackSpec.children = @[self.titleNode, self.descriptionNode];
    
    return [ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsMake(10, 16, 10, 10) child:verticalStackSpec];
}

@end
