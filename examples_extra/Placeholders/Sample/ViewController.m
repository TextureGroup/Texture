//
//  ViewController.m
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "ViewController.h"

#import <AsyncDisplayKit/AsyncDisplayKit.h>

#import "PostNode.h"
#import "SlowpokeImageNode.h"
#import <AsyncDisplayKit/ASDisplayNode+Subclasses.h>

@interface ViewController ()
{
  PostNode *_postNode;
  SlowpokeImageNode *_imageNode;
  UIButton *_displayButton;
}

@end


@implementation ViewController

#pragma mark -
#pragma mark UIViewController

- (instancetype)init
{
  if (!(self = [super init]))
    return nil;

  _displayButton = [UIButton buttonWithType:UIButtonTypeCustom];
  [_displayButton setTitle:@"Display me!" forState:UIControlStateNormal];
  [_displayButton addTarget:self action:@selector(onDisplayButton:) forControlEvents:UIControlEventTouchUpInside];

  UIColor *tintBlue = [UIColor colorWithRed:0 green:122/255.0 blue:1.0 alpha:1.0];
  [_displayButton setTitleColor:tintBlue forState:UIControlStateNormal];
  [_displayButton setTitleColor:[tintBlue colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
  _displayButton.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];

  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  [self.view addSubview:_displayButton];
}

- (void)viewWillLayoutSubviews
{
  CGFloat padding = 20.0;
  CGRect bounds = self.view.bounds;
  CGFloat constrainedWidth = CGRectGetWidth(bounds);
  CGSize constrainedSize = CGSizeMake(constrainedWidth - 2 * padding, CGFLOAT_MAX);

  CGSize postSize = [_postNode layoutThatFits:ASSizeRangeMake(CGSizeZero, constrainedSize)].size;
  CGSize imageSize = [_imageNode layoutThatFits:ASSizeRangeMake(CGSizeZero, constrainedSize)].size;

  _imageNode.frame = (CGRect){padding, padding, imageSize};
  _postNode.frame = (CGRect){padding, CGRectGetMaxY(_imageNode.frame) + 10.0, postSize};

  CGFloat buttonHeight = 55.0;
  _displayButton.frame = (CGRect){0.0, CGRectGetHeight(bounds) - buttonHeight, CGRectGetWidth(bounds), buttonHeight};
}

// this method is pretty gross and just for demonstration  :]
- (void)createAndDisplayNodes
{
  [_imageNode.view removeFromSuperview];
  [_postNode.view removeFromSuperview];

  // ASImageNode gets placeholders by default
  _imageNode = [[SlowpokeImageNode alloc] init];
  _imageNode.image = [UIImage imageNamed:@"logo"];

  _postNode = [[PostNode alloc] init];

  // change to NO to see text placeholders, change to YES to see the parent placeholder
  // this placeholder will cover all subnodes while they are displaying, just a like a stage curtain!
  _postNode.placeholderEnabled = NO;

  [self.view addSubnode:_imageNode];
  [self.view addSubnode:_postNode];
}


#pragma mark -
#pragma mark Actions

- (void)onDisplayButton:(id)sender
{
  [self createAndDisplayNodes];
}

@end
