//
//  CommentsNode.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "CommentsNode.h"
#import "TextStyles.h"

@interface CommentsNode ()
@property (nonatomic, strong) ASImageNode *iconNode;
@property (nonatomic, strong) ASTextNode *countNode;
@property (nonatomic, assign) NSInteger commentsCount;
@end

@implementation CommentsNode

- (instancetype)initWithCommentsCount:(NSInteger)comentsCount
{
    self = [super init];
    if (self) {
        _commentsCount = comentsCount;
        
        _iconNode = [[ASImageNode alloc] init];
        _iconNode.image = [UIImage imageNamed:@"icon_comment.png"];
        [self addSubnode:_iconNode];
        
        _countNode = [[ASTextNode alloc] init];
        if (_commentsCount > 0) {
           _countNode.attributedText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%zd", _commentsCount] attributes:[TextStyles cellControlStyle]];
        }
        [self addSubnode:_countNode];
        
        // make it tappable easily
        self.hitTestSlop = UIEdgeInsetsMake(-10, -10, -10, -10);
    }
    
    return self;
    
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
    ASStackLayoutSpec *mainStack =
    [ASStackLayoutSpec
     stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
     spacing:6.0
     justifyContent:ASStackLayoutJustifyContentStart
     alignItems:ASStackLayoutAlignItemsCenter
     children:@[_iconNode, _countNode]];
    
    // Adjust size
    mainStack.style.minWidth = ASDimensionMakeWithPoints(60.0);
    mainStack.style.maxHeight = ASDimensionMakeWithPoints(40.0);
    
    return mainStack;
}

@end
