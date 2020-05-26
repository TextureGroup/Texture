//
//  VideoContentCell.m
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "VideoContentCell.h"

#import <AsyncDisplayKit/ASVideoPlayerNode.h>

#import "Utilities.h"

#define AVATAR_IMAGE_HEIGHT     30
#define HORIZONTAL_BUFFER       10
#define VERTICAL_BUFFER         5

@interface VideoContentCell () <ASVideoPlayerNodeDelegate>

@end

@implementation VideoContentCell
{
  VideoModel *_videoModel;
  ASTextNode *_titleNode;
  ASNetworkImageNode *_avatarNode;
  ASVideoPlayerNode *_videoPlayerNode;
  ASControlNode *_likeButtonNode;
  ASButtonNode *_muteButtonNode;
}

- (instancetype)initWithVideoObject:(VideoModel *)video
{
  self = [super init];
  if (self) {
    _videoModel = video;

    _titleNode = [[ASTextNode alloc] init];
    _titleNode.attributedText = [[NSAttributedString alloc] initWithString:_videoModel.title attributes:[self titleNodeStringOptions]];
    _titleNode.style.flexGrow = 1.0;
    [self addSubnode:_titleNode];

    _avatarNode = [[ASNetworkImageNode alloc] init];
    _avatarNode.URL = _videoModel.avatarUrl;

    [_avatarNode setImageModificationBlock:^UIImage *(UIImage *image, ASPrimitiveTraitCollection traitCollection) {
      CGSize profileImageSize = CGSizeMake(AVATAR_IMAGE_HEIGHT, AVATAR_IMAGE_HEIGHT);
      return [image makeCircularImageWithSize:profileImageSize];
    }];

    [self addSubnode:_avatarNode];

    _likeButtonNode = [[ASControlNode alloc] init];
    _likeButtonNode.backgroundColor = [UIColor redColor];
    [self addSubnode:_likeButtonNode];

    _muteButtonNode = [[ASButtonNode alloc] init];
    _muteButtonNode.style.width = ASDimensionMakeWithPoints(16.0);
    _muteButtonNode.style.height = ASDimensionMakeWithPoints(22.0);
    [_muteButtonNode addTarget:self action:@selector(didTapMuteButton) forControlEvents:ASControlNodeEventTouchUpInside];

    _videoPlayerNode = [[ASVideoPlayerNode alloc] initWithURL:_videoModel.url];
    _videoPlayerNode.delegate = self;
    _videoPlayerNode.backgroundColor = [UIColor blackColor];
    [self addSubnode:_videoPlayerNode];

    [self setMuteButtonIcon];
  }
  return self;
}

- (NSDictionary*)titleNodeStringOptions
{
  return @{
     NSFontAttributeName : [UIFont systemFontOfSize:14.0],
     NSForegroundColorAttributeName: [UIColor blackColor]
  };
}

- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
  CGFloat fullWidth = [UIScreen mainScreen].bounds.size.width;
  
  _videoPlayerNode.style.width = ASDimensionMakeWithPoints(fullWidth);
  _videoPlayerNode.style.height = ASDimensionMakeWithPoints(fullWidth * 9 / 16);
  
  _avatarNode.style.width = ASDimensionMakeWithPoints(AVATAR_IMAGE_HEIGHT);
  _avatarNode.style.height = ASDimensionMakeWithPoints(AVATAR_IMAGE_HEIGHT);
  
  _likeButtonNode.style.width = ASDimensionMakeWithPoints(50.0);
  _likeButtonNode.style.height = ASDimensionMakeWithPoints(26.0);

  ASStackLayoutSpec *headerStack  = [ASStackLayoutSpec horizontalStackLayoutSpec];
  headerStack.spacing = HORIZONTAL_BUFFER;
  headerStack.alignItems = ASStackLayoutAlignItemsCenter;
  [headerStack setChildren:@[ _avatarNode, _titleNode]];

  UIEdgeInsets headerInsets      = UIEdgeInsetsMake(HORIZONTAL_BUFFER, HORIZONTAL_BUFFER, HORIZONTAL_BUFFER, HORIZONTAL_BUFFER);
  ASInsetLayoutSpec *headerInset = [ASInsetLayoutSpec insetLayoutSpecWithInsets:headerInsets child:headerStack];

  ASStackLayoutSpec *bottomControlsStack  = [ASStackLayoutSpec horizontalStackLayoutSpec];
  bottomControlsStack.spacing = HORIZONTAL_BUFFER;
  bottomControlsStack.alignItems = ASStackLayoutAlignItemsCenter;
  bottomControlsStack.children = @[_likeButtonNode];

  UIEdgeInsets bottomControlsInsets = UIEdgeInsetsMake(HORIZONTAL_BUFFER, HORIZONTAL_BUFFER, HORIZONTAL_BUFFER, HORIZONTAL_BUFFER);
  ASInsetLayoutSpec *bottomControlsInset  = [ASInsetLayoutSpec insetLayoutSpecWithInsets:bottomControlsInsets child:bottomControlsStack];


  ASStackLayoutSpec *verticalStack = [ASStackLayoutSpec verticalStackLayoutSpec];
  verticalStack.alignItems = ASStackLayoutAlignItemsStretch;
  verticalStack.children = @[headerInset, _videoPlayerNode, bottomControlsInset];
  return verticalStack;
}

- (void)setMuteButtonIcon
{
  if (_videoPlayerNode.muted) {
    [_muteButtonNode setImage:[UIImage imageNamed:@"ico-mute"] forState:UIControlStateNormal];
  } else {
    [_muteButtonNode setImage:[UIImage imageNamed:@"ico-unmute"] forState:UIControlStateNormal];
  }
}

- (void)didTapMuteButton
{
  _videoPlayerNode.muted = !_videoPlayerNode.muted;
  [self setMuteButtonIcon];
}

#pragma mark - ASVideoPlayerNodeDelegate
- (void)didTapVideoPlayerNode:(ASVideoPlayerNode *)videoPlayer
{
  if (_videoPlayerNode.playerState == ASVideoNodePlayerStatePlaying) {
    _videoPlayerNode.controlsDisabled = !_videoPlayerNode.controlsDisabled;
    [_videoPlayerNode pause];
  } else {
    [_videoPlayerNode play];
  }
}

- (NSDictionary *)videoPlayerNodeCustomControls:(ASVideoPlayerNode *)videoPlayer
{
  return @{
    @"muteControl" : _muteButtonNode
  };
}

- (NSArray *)controlsForControlBar:(NSDictionary *)availableControls
{
  NSMutableArray *controls = [[NSMutableArray alloc] init];

  if (availableControls[ @(ASVideoPlayerNodeControlTypePlaybackButton) ]) {
    [controls addObject:availableControls[ @(ASVideoPlayerNodeControlTypePlaybackButton) ]];
  }

  if (availableControls[ @(ASVideoPlayerNodeControlTypeElapsedText) ]) {
    [controls addObject:availableControls[ @(ASVideoPlayerNodeControlTypeElapsedText) ]];
  }

  if (availableControls[ @(ASVideoPlayerNodeControlTypeScrubber) ]) {
    [controls addObject:availableControls[ @(ASVideoPlayerNodeControlTypeScrubber) ]];
  }

  if (availableControls[ @(ASVideoPlayerNodeControlTypeDurationText) ]) {
    [controls addObject:availableControls[ @(ASVideoPlayerNodeControlTypeDurationText) ]];
  }

  return controls;
}

#pragma mark - Layout
- (ASLayoutSpec*)videoPlayerNodeLayoutSpec:(ASVideoPlayerNode *)videoPlayer forControls:(NSDictionary *)controls forMaximumSize:(CGSize)maxSize
{
  ASLayoutSpec *spacer = [[ASLayoutSpec alloc] init];
  spacer.style.flexGrow = 1.0;

  UIEdgeInsets insets = UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0);

  if (controls[ @(ASVideoPlayerNodeControlTypeScrubber) ]) {
    ASDisplayNode *scrubber = controls[ @(ASVideoPlayerNodeControlTypeScrubber) ];
    scrubber.style.height = ASDimensionMakeWithPoints(44.0);
    scrubber.style.minWidth = ASDimensionMakeWithPoints(0.0);
    scrubber.style.maxWidth = ASDimensionMakeWithPoints(maxSize.width);
    scrubber.style.flexGrow = 1.0;
  }

  NSArray *controlBarControls = [self controlsForControlBar:controls];
  NSMutableArray *topBarControls = [[NSMutableArray alloc] init];

  //Our custom control
  if (controls[@"muteControl"]) {
    [topBarControls addObject:controls[@"muteControl"]];
  }


  ASStackLayoutSpec *topBarSpec = [ASStackLayoutSpec stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
                                                                          spacing:10.0
                                                                   justifyContent:ASStackLayoutJustifyContentStart
                                                                       alignItems:ASStackLayoutAlignItemsCenter
                                                                         children:topBarControls];

  ASInsetLayoutSpec *topBarInsetSpec = [ASInsetLayoutSpec insetLayoutSpecWithInsets:insets child:topBarSpec];

  ASStackLayoutSpec *controlbarSpec = [ASStackLayoutSpec stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
                                                                              spacing:10.0
                                                                       justifyContent:ASStackLayoutJustifyContentStart
                                                                           alignItems:ASStackLayoutAlignItemsCenter
                                                                             children: controlBarControls ];
  controlbarSpec.style.alignSelf = ASStackLayoutAlignSelfStretch;



  ASInsetLayoutSpec *controlbarInsetSpec = [ASInsetLayoutSpec insetLayoutSpecWithInsets:insets child:controlbarSpec];

  controlbarInsetSpec.style.alignSelf = ASStackLayoutAlignSelfStretch;

  ASStackLayoutSpec *mainVerticalStack = [ASStackLayoutSpec stackLayoutSpecWithDirection:ASStackLayoutDirectionVertical
                                                                                 spacing:0.0
                                                                          justifyContent:ASStackLayoutJustifyContentStart
                                                                              alignItems:ASStackLayoutAlignItemsStart
                                                                                children:@[topBarInsetSpec, spacer, controlbarInsetSpec]];

  return mainVerticalStack;

}
@end
