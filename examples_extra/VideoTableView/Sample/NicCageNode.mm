//
//  NicCageNode.mm
//  Texture
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

#import "NicCageNode.h"
#import "AppDelegate.h"

#import <AsyncDisplayKit/ASDisplayNode+Subclasses.h>

#import <AsyncDisplayKit/ASDisplayNode+Beta.h>
#import <AsyncDisplayKit/ASStackLayoutSpec.h>
#import <AsyncDisplayKit/ASInsetLayoutSpec.h>
#import <AsyncDisplayKit/ASVideoNode.h>

static const CGFloat kImageSize = 80.0f;
static const CGFloat kOuterPadding = 16.0f;
static const CGFloat kInnerPadding = 10.0f;

#define kVideoURL @"https://www.w3schools.com/html/mov_bbb.mp4"
#define kVideoStreamURL @"http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8"

@interface NicCageNode ()
{
  CGSize _kittenSize;

//  ASNetworkImageNode *_imageNode;
  ASVideoNode *_videoNode;
  ASTextNode *_textNode;
  ASDisplayNode *_divider;
  BOOL _isImageEnlarged;
  BOOL _swappedTextAndImage;
}

@end


@implementation NicCageNode

// lorem ipsum text courtesy https://kittyipsum.com/ <3
+ (NSArray *)placeholders
{
  static NSArray *placeholders = nil;

  static dispatch_once_t once;
  dispatch_once(&once, ^{
    placeholders = @[
                     @"Kitty ipsum dolor sit amet, purr sleep on your face lay down in your way biting, sniff tincidunt a etiam fluffy fur judging you stuck in a tree kittens.",
                     @"Lick tincidunt a biting eat the grass, egestas enim ut lick leap puking climb the curtains lick.",
                     @"Lick quis nunc toss the mousie vel, tortor pellentesque sunbathe orci turpis non tail flick suscipit sleep in the sink.",
                     @"Orci turpis litter box et stuck in a tree, egestas ac tempus et aliquam elit.",
                     @"Hairball iaculis dolor dolor neque, nibh adipiscing vehicula egestas dolor aliquam.",
                     @"Sunbathe fluffy fur tortor faucibus pharetra jump, enim jump on the table I don't like that food catnip toss the mousie scratched.",
                     @"Quis nunc nam sleep in the sink quis nunc purr faucibus, chase the red dot consectetur bat sagittis.",
                     @"Lick tail flick jump on the table stretching purr amet, rhoncus scratched jump on the table run.",
                     @"Suspendisse aliquam vulputate feed me sleep on your keyboard, rip the couch faucibus sleep on your keyboard tristique give me fish dolor.",
                     @"Rip the couch hiss attack your ankles biting pellentesque puking, enim suspendisse enim mauris a.",
                     @"Sollicitudin iaculis vestibulum toss the mousie biting attack your ankles, puking nunc jump adipiscing in viverra.",
                     @"Nam zzz amet neque, bat tincidunt a iaculis sniff hiss bibendum leap nibh.",
                     @"Chase the red dot enim puking chuf, tristique et egestas sniff sollicitudin pharetra enim ut mauris a.",
                     @"Sagittis scratched et lick, hairball leap attack adipiscing catnip tail flick iaculis lick.",
                     @"Neque neque sleep in the sink neque sleep on your face, climb the curtains chuf tail flick sniff tortor non.",
                     @"Ac etiam kittens claw toss the mousie jump, pellentesque rhoncus litter box give me fish adipiscing mauris a.",
                     @"Pharetra egestas sunbathe faucibus ac fluffy fur, hiss feed me give me fish accumsan.",
                     @"Tortor leap tristique accumsan rutrum sleep in the sink, amet sollicitudin adipiscing dolor chase the red dot.",
                     @"Knock over the lamp pharetra vehicula sleep on your face rhoncus, jump elit cras nec quis quis nunc nam.",
                     @"Sollicitudin feed me et ac in viverra catnip, nunc eat I don't like that food iaculis give me fish.",
                     ];
  });

  return placeholders;
}

- (instancetype)initWithKittenOfSize:(CGSize)size
{
  if (!(self = [super init]))
    return nil;

  _kittenSize = size;
  
  u_int32_t videoInitMethod = arc4random_uniform(3);
  u_int32_t autoPlay = arc4random_uniform(2);
  NSArray* methodArray = @[@"AVAsset", @"File URL", @"HLS URL"];
  NSArray* autoPlayArray = @[@"paused", @"auto play"];
  
  switch (videoInitMethod) {
    case 0:
      // Construct an AVAsset from a URL
      _videoNode = [[ASVideoNode alloc] init];
      _videoNode.asset = [AVAsset assetWithURL:[NSURL URLWithString:kVideoURL]];
      break;
      
    case 1:
      // Construct the video node directly from the .mp4 URL
      _videoNode = [[ASVideoNode alloc] init];
      _videoNode.asset = [AVAsset assetWithURL:[NSURL URLWithString:kVideoURL]];
      break;
      
    case 2:
      // Construct the video node from an HTTP Live Streaming URL
      // URL from https://developer.apple.com/library/ios/documentation/AudioVideo/Conceptual/AVFoundationPG/Articles/02_Playback.html
      _videoNode = [[ASVideoNode alloc] init];
      _videoNode.asset = [AVAsset assetWithURL:[NSURL URLWithString:kVideoStreamURL]];
      break;
  }
  
  if (autoPlay == 1)
    _videoNode.shouldAutoplay = YES;
  
  _videoNode.shouldAutorepeat = YES;
  _videoNode.backgroundColor = ASDisplayNodeDefaultPlaceholderColor();

  [self addSubnode:_videoNode];

  _textNode = [[ASTextNode alloc] init];
  _textNode.attributedText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@ %@", methodArray[videoInitMethod], autoPlayArray[autoPlay], [self kittyIpsum]]
                                                               attributes:[self textStyle]];
  [self addSubnode:_textNode];

  // hairline cell separator
  _divider = [[ASDisplayNode alloc] init];
  _divider.backgroundColor = [UIColor lightGrayColor];
  [self addSubnode:_divider];

  return self;
}

- (NSString *)kittyIpsum
{
  NSArray *placeholders = [NicCageNode placeholders];
  u_int32_t ipsumCount = (u_int32_t)[placeholders count];
  u_int32_t location = arc4random_uniform(ipsumCount);
  u_int32_t length = arc4random_uniform(ipsumCount - location);

  NSMutableString *string = [placeholders[location] mutableCopy];
  for (u_int32_t i = location + 1; i < location + length; i++) {
    [string appendString:(i % 2 == 0) ? @"\n" : @"  "];
    [string appendString:placeholders[i]];
  }

  return string;
}

- (NSDictionary *)textStyle
{
  UIFont *font = [UIFont fontWithName:@"HelveticaNeue" size:12.0f];

  NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
  style.paragraphSpacing = 0.5 * font.lineHeight;
  style.hyphenationFactor = 1.0;

  return @{ NSFontAttributeName: font,
            NSParagraphStyleAttributeName: style };
}

#if UseAutomaticLayout
- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
  CGSize videoNodeSize = _isImageEnlarged ? CGSizeMake(2.0 * kImageSize, 2.0 * kImageSize)
                                          : CGSizeMake(kImageSize, kImageSize);
  
  [_videoNode.style setPreferredSize:videoNodeSize];
  
  _textNode.style.flexShrink = 1.0;
  
  ASStackLayoutSpec *stackSpec = [[ASStackLayoutSpec alloc] init];
  stackSpec.direction = ASStackLayoutDirectionHorizontal;
  stackSpec.spacing = kInnerPadding;
  [stackSpec setChildren:!_swappedTextAndImage ? @[_videoNode, _textNode] : @[_textNode, _videoNode]];
  
  ASInsetLayoutSpec *insetSpec = [[ASInsetLayoutSpec alloc] init];
  insetSpec.insets = UIEdgeInsetsMake(kOuterPadding, kOuterPadding, kOuterPadding, kOuterPadding);
  insetSpec.child = stackSpec;
  
  return insetSpec;
}

// With box model, you don't need to override this method, unless you want to add custom logic.
- (void)layout
{
  [super layout];
  
  // Manually layout the divider.
  CGFloat pixelHeight = 1.0f / [[UIScreen mainScreen] scale];
  _divider.frame = CGRectMake(0.0f, 0.0f, self.calculatedSize.width, pixelHeight);
}
#else
- (CGSize)calculateSizeThatFits:(CGSize)constrainedSize
{
  CGSize imageSize = CGSizeMake(kImageSize, kImageSize);
  CGSize textSize = [_textNode measure:CGSizeMake(constrainedSize.width - kImageSize - 2 * kOuterPadding - kInnerPadding,
                                                  constrainedSize.height)];

  // ensure there's room for the text
  CGFloat requiredHeight = MAX(textSize.height, imageSize.height);
  return CGSizeMake(constrainedSize.width, requiredHeight + 2 * kOuterPadding);
}

- (void)layout
{
  CGFloat pixelHeight = 1.0f / [[UIScreen mainScreen] scale];
  _divider.frame = CGRectMake(0.0f, 0.0f, self.calculatedSize.width, pixelHeight);

  _imageNode.frame = CGRectMake(kOuterPadding, kOuterPadding, kImageSize, kImageSize);

  CGSize textSize = _textNode.calculatedSize;
  _textNode.frame = CGRectMake(kOuterPadding + kImageSize + kInnerPadding, kOuterPadding, textSize.width, textSize.height);
}
#endif

- (void)toggleImageEnlargement
{
  _isImageEnlarged = !_isImageEnlarged;
  [self setNeedsLayout];
}

- (void)toggleNodesSwap
{
  _swappedTextAndImage = !_swappedTextAndImage;
  
  [UIView animateWithDuration:0.15 animations:^{
    self.alpha = 0;
  } completion:^(BOOL finished) {
    [self setNeedsLayout];
    [self.view layoutIfNeeded];
    
    [UIView animateWithDuration:0.15 animations:^{
      self.alpha = 1;
    }];
  }];
}

- (void)updateBackgroundColor
{
  if (self.highlighted) {
    self.backgroundColor = [UIColor lightGrayColor];
  } else if (self.selected) {
    self.backgroundColor = [UIColor blueColor];
  } else {
    self.backgroundColor = [UIColor whiteColor];
  }
}

- (void)setSelected:(BOOL)selected
{
  [super setSelected:selected];
  [self updateBackgroundColor];
}

- (void)setHighlighted:(BOOL)highlighted
{
  [super setHighlighted:highlighted];
  [self updateBackgroundColor];
}

@end
