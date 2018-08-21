//
//  ImageViewController.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//


#import "ImageViewController.h"

@interface ImageViewController ()
@property (nonatomic) UIImageView *imageView;
@end

@implementation ImageViewController

- (instancetype)initWithImage:(UIImage *)image {
  if (!(self = [super init])) { return nil; }
  
  self.imageView = [[UIImageView alloc] initWithImage:image];
  
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self.view addSubview:self.imageView];
  
  UIGestureRecognizer *tap = [[UIGestureRecognizer alloc] initWithTarget:self action:@selector(tapped)];
  [self.view addGestureRecognizer:tap];

  self.imageView.contentMode = UIViewContentModeScaleAspectFill;
}

- (void)tapped;
{
  NSLog(@"tapped!");
}

- (void)viewWillLayoutSubviews
{
  self.imageView.frame = self.view.bounds;
}

@end
