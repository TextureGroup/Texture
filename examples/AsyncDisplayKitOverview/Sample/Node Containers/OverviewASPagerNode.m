//
//  OverviewASPagerNode.m
//  Sample
//
//  Created by Michael Schneider on 4/17/16.
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
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//  FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
//  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "OverviewASPagerNode.h"

#pragma mark - Helper

static UIColor *OverViewASPagerNodeRandomColor() {
    CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
}


#pragma mark - OverviewASPageNode

@interface OverviewASPageNode : ASCellNode @end

@implementation OverviewASPageNode

- (ASLayout *)calculateLayoutThatFits:(ASSizeRange)constrainedSize
{
    return [ASLayout layoutWithLayoutElement:self size:constrainedSize.max];
}

@end


#pragma mark - OverviewASPagerNode

@interface OverviewASPagerNode () <ASPagerDataSource, ASPagerDelegate>
@property (nonatomic, strong) ASPagerNode *node;
@property (nonatomic, copy) NSArray *data;
@end

@implementation OverviewASPagerNode

- (instancetype)init
{
    self = [super init];
    if (self == nil) { return self; }
    
    _node = [ASPagerNode new];
    _node.dataSource = self;
    _node.delegate = self;
    [self addSubnode:_node];
    
    return self;
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
    // 100% of container
    _node.style.width = ASDimensionMakeWithFraction(1.0);
    _node.style.height = ASDimensionMakeWithFraction(1.0);
    return [ASWrapperLayoutSpec wrapperWithLayoutElement:_node];
}

- (NSInteger)numberOfPagesInPagerNode:(ASPagerNode *)pagerNode
{
    return 4;
}

- (ASCellNodeBlock)pagerNode:(ASPagerNode *)pagerNode nodeBlockAtIndex:(NSInteger)index
{
    return ^{
        ASCellNode *cellNode = [OverviewASPageNode new];
        cellNode.backgroundColor = OverViewASPagerNodeRandomColor();
        return cellNode;
    };
}


@end
