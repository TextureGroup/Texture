//
//  ViewController.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "ViewController.h"

#import <AsyncDisplayKit/AsyncDisplayKit.h>

@interface ViewController ()
@property (nonatomic, strong) ASTextNode *textNode;
@end

@implementation ViewController

- (void)viewDidLoad
{
  self.textNode = [[ASTextNode alloc] init];
  self.textNode.attributedText = [[NSAttributedString alloc] initWithString:@"Testing, testing." attributes:@{ NSForegroundColorAttributeName: [UIColor redColor] }];
  [self.textNode layoutThatFits:ASSizeRangeMake(CGSizeZero, self.view.bounds.size)];
  self.textNode.frame = (CGRect){ .origin = CGPointZero, .size = self.textNode.calculatedSize };
  [self.view addSubnode:self.textNode];
}

@end
