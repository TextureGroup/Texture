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

@end

@implementation ViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    CGSize screenSize = self.view.bounds.size;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ASTextNode *node = [[ASTextNode alloc] init];
        node.attributedText = [[NSAttributedString alloc] initWithString:@"hello world"];
        [node layoutThatFits:ASSizeRangeMake(CGSizeZero, (CGSize){.width = screenSize.width, .height = CGFLOAT_MAX})];
        node.frame = (CGRect) {.origin = (CGPoint){.x = 100, .y = 100}, .size = node.calculatedSize };
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view addSubview:node.view];
        });
    });
}

@end
