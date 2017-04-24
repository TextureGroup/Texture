//
//  LayoutExampleViewController.m
//  Sample
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

#import "LayoutExampleViewController.h"
#import "LayoutExampleNodes.h"

@interface LayoutExampleViewController ()
@property (nonatomic, strong) LayoutExampleNode *customNode;
@end

@implementation LayoutExampleViewController

- (instancetype)initWithLayoutExampleClass:(Class)layoutExampleClass
{
  NSAssert([layoutExampleClass isSubclassOfClass:[LayoutExampleNode class]], @"Must pass a subclass of LayoutExampleNode.");
  
  self = [super initWithNode:[ASDisplayNode new]];
  
  if (self) {
    self.title = @"Layout Example";
    
    _customNode = [layoutExampleClass new];
    [self.node addSubnode:_customNode];
    
    BOOL needsOnlyYCentering = [layoutExampleClass isEqual:[HeaderWithRightAndLeftItems class]] ||
                               [layoutExampleClass isEqual:[FlexibleSeparatorSurroundingContent class]];
                               
    self.node.backgroundColor = needsOnlyYCentering ? [UIColor lightGrayColor] : [UIColor whiteColor];
    
    __weak __typeof(self) weakself = self;
    self.node.layoutSpecBlock = ^ASLayoutSpec*(__kindof ASDisplayNode * _Nonnull node, ASSizeRange constrainedSize) {
      return [ASCenterLayoutSpec centerLayoutSpecWithCenteringOptions:needsOnlyYCentering ? ASCenterLayoutSpecCenteringY : ASCenterLayoutSpecCenteringXY
                                                        sizingOptions:ASCenterLayoutSpecSizingOptionMinimumXY
                                                                child:weakself.customNode];
      };
  }
  
  return self;
}

@end
