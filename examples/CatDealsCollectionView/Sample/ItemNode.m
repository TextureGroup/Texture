//
//  ItemNode.m
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

#import "ItemNode.h"
#import "ItemStyles.h"
#import "PlaceholderNetworkImageNode.h"
#import <AsyncDisplayKit/ASDisplayNodeExtras.h>

const CGFloat kFixedLabelsAreaHeight = 96.0;
const CGFloat kDesignWidth = 320.0;
const CGFloat kDesignHeight = 299.0;
const CGFloat kBadgeHeight = 34.0;
const CGFloat kSoldOutGBHeight = 50.0;

@interface ItemNode() <ASNetworkImageNodeDelegate>

@property (nonatomic, strong) ItemViewModel *viewModel;

@property (nonatomic, strong) PlaceholderNetworkImageNode *dealImageView;

@property (nonatomic, strong) ASTextNode *titleLabel;
@property (nonatomic, strong) ASTextNode *firstInfoLabel;
@property (nonatomic, strong) ASTextNode *distanceLabel;
@property (nonatomic, strong) ASTextNode *secondInfoLabel;
@property (nonatomic, strong) ASTextNode *originalPriceLabel;
@property (nonatomic, strong) ASTextNode *finalPriceLabel;
@property (nonatomic, strong) ASTextNode *soldOutLabelFlat;
@property (nonatomic, strong) ASDisplayNode *soldOutLabelBackground;
@property (nonatomic, strong) ASDisplayNode *soldOutOverlay;
@property (nonatomic, strong) ASTextNode *badge;

@end

@implementation ItemNode
@dynamic viewModel;

- (instancetype)initWithViewModel:(ItemViewModel *)viewModel
{
  self = [super init];
  if (self != nil) {
    self.viewModel = viewModel;
    [self setup];
    [self updateLabels];
    [self updateBackgroundColor];
    
    ASSetDebugName(self, @"Item #%zd", viewModel.identifier);
    self.accessibilityIdentifier = viewModel.titleText;
  }
  return self;
}

+ (BOOL)isRTL {
  return [UIApplication sharedApplication].userInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft;
}

- (void)setup {
  self.dealImageView = [[PlaceholderNetworkImageNode alloc] init];
  self.dealImageView.delegate = self;
  self.dealImageView.placeholderEnabled = YES;
  self.dealImageView.placeholderImageOverride = [ItemStyles placeholderImage];
  self.dealImageView.defaultImage = [ItemStyles placeholderImage];
  self.dealImageView.contentMode = UIViewContentModeScaleToFill;
  self.dealImageView.placeholderFadeDuration = 0.0;
  self.dealImageView.layerBacked = YES;
  
  self.titleLabel = [[ASTextNode alloc] init];
  self.titleLabel.maximumNumberOfLines = 2;
  self.titleLabel.style.alignSelf = ASStackLayoutAlignSelfStart;
  self.titleLabel.style.flexGrow = 1.0;
  self.titleLabel.layerBacked = YES;
  
  self.firstInfoLabel = [[ASTextNode alloc] init];
  self.firstInfoLabel.maximumNumberOfLines = 1;
  self.firstInfoLabel.layerBacked = YES;
  
  self.secondInfoLabel = [[ASTextNode alloc] init];
  self.secondInfoLabel.maximumNumberOfLines = 1;
  self.secondInfoLabel.layerBacked = YES;
  
  self.distanceLabel = [[ASTextNode alloc] init];
  self.distanceLabel.maximumNumberOfLines = 1;
  self.distanceLabel.layerBacked = YES;
  
  self.originalPriceLabel = [[ASTextNode alloc] init];
  self.originalPriceLabel.maximumNumberOfLines = 1;
  self.originalPriceLabel.layerBacked = YES;
  
  self.finalPriceLabel = [[ASTextNode alloc] init];
  self.finalPriceLabel.maximumNumberOfLines = 1;
  self.finalPriceLabel.layerBacked = YES;
  
  self.badge = [[ASTextNode alloc] init];
  self.badge.hidden = YES;
  self.badge.layerBacked = YES;
  
  self.soldOutLabelFlat = [[ASTextNode alloc] init];
  self.soldOutLabelFlat.layerBacked = YES;

  self.soldOutLabelBackground = [[ASDisplayNode alloc] init];
  self.soldOutLabelBackground.style.width = ASDimensionMakeWithFraction(1.0);
  self.soldOutLabelBackground.style.height = ASDimensionMakeWithPoints(kSoldOutGBHeight);
  self.soldOutLabelBackground.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.9];
  self.soldOutLabelBackground.style.flexGrow = 1.0;
  self.soldOutLabelBackground.layerBacked = YES;
  
  self.soldOutOverlay = [[ASDisplayNode alloc] init];
  self.soldOutOverlay.style.flexGrow = 1.0;
  self.soldOutOverlay.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
  self.soldOutOverlay.layerBacked = YES;
  
  [self addSubnode:self.dealImageView];
  [self addSubnode:self.titleLabel];
  [self addSubnode:self.firstInfoLabel];
  [self addSubnode:self.secondInfoLabel];
  [self addSubnode:self.originalPriceLabel];
  [self addSubnode:self.finalPriceLabel];
  [self addSubnode:self.distanceLabel];
  [self addSubnode:self.badge];
  
  [self addSubnode:self.soldOutLabelBackground];
  [self addSubnode:self.soldOutLabelFlat];
  [self addSubnode:self.soldOutOverlay];
  self.soldOutOverlay.hidden = YES;
  self.soldOutLabelBackground.hidden = YES;
  self.soldOutLabelFlat.hidden = YES;
  
  if ([ItemNode isRTL]) {
    self.titleLabel.style.alignSelf = ASStackLayoutAlignSelfEnd;
    self.firstInfoLabel.style.alignSelf = ASStackLayoutAlignSelfEnd;
    self.distanceLabel.style.alignSelf = ASStackLayoutAlignSelfEnd;
    self.secondInfoLabel.style.alignSelf = ASStackLayoutAlignSelfEnd;
    self.originalPriceLabel.style.alignSelf = ASStackLayoutAlignSelfStart;
    self.finalPriceLabel.style.alignSelf = ASStackLayoutAlignSelfStart;
  } else {
    self.firstInfoLabel.style.alignSelf = ASStackLayoutAlignSelfStart;
    self.distanceLabel.style.alignSelf = ASStackLayoutAlignSelfStart;
    self.secondInfoLabel.style.alignSelf = ASStackLayoutAlignSelfStart;
    self.originalPriceLabel.style.alignSelf = ASStackLayoutAlignSelfEnd;
    self.finalPriceLabel.style.alignSelf = ASStackLayoutAlignSelfEnd;
  }
}

- (void)updateLabels {
  // Set Title text
  if (self.viewModel.titleText) {
    self.titleLabel.attributedText = [[NSAttributedString alloc] initWithString:self.viewModel.titleText attributes:[ItemStyles titleStyle]];
  }
  if (self.viewModel.firstInfoText) {
    self.firstInfoLabel.attributedText = [[NSAttributedString alloc] initWithString:self.viewModel.firstInfoText attributes:[ItemStyles subtitleStyle]];
  }
  
  if (self.viewModel.secondInfoText) {
    self.secondInfoLabel.attributedText = [[NSAttributedString alloc] initWithString:self.viewModel.secondInfoText attributes:[ItemStyles secondInfoStyle]];
  }
  if (self.viewModel.originalPriceText) {
    self.originalPriceLabel.attributedText = [[NSAttributedString alloc] initWithString:self.viewModel.originalPriceText attributes:[ItemStyles originalPriceStyle]];
  }
  if (self.viewModel.finalPriceText) {
        self.finalPriceLabel.attributedText = [[NSAttributedString alloc] initWithString:self.viewModel.finalPriceText attributes:[ItemStyles finalPriceStyle]];
  }
  if (self.viewModel.distanceLabelText) {
    NSString *format = [ItemNode isRTL] ? @"%@ •" : @"• %@";
    NSString *distanceText = [NSString stringWithFormat:format, self.viewModel.distanceLabelText];
    
    self.distanceLabel.attributedText = [[NSAttributedString alloc] initWithString:distanceText attributes:[ItemStyles distanceStyle]];
  }
  
  BOOL isSoldOut = self.viewModel.soldOutText != nil;
  
  if (isSoldOut) {
    NSString *soldOutText = self.viewModel.soldOutText;
    self.soldOutLabelFlat.attributedText = [[NSAttributedString alloc] initWithString:soldOutText attributes:[ItemStyles soldOutStyle]];
  }
  self.soldOutOverlay.hidden = !isSoldOut;
  self.soldOutLabelFlat.hidden = !isSoldOut;
  self.soldOutLabelBackground.hidden = !isSoldOut;
  
  BOOL hasBadge = self.viewModel.badgeText != nil;
  if (hasBadge) {
    self.badge.attributedText = [[NSAttributedString alloc] initWithString:self.viewModel.badgeText attributes:[ItemStyles badgeStyle]];
    self.badge.backgroundColor = [ItemStyles badgeColor];
  }
  self.badge.hidden = !hasBadge;
}

- (void)updateBackgroundColor
{
  if (self.highlighted) {
    self.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.3];
  } else if (self.selected) {
    self.backgroundColor = [UIColor lightGrayColor];
  } else {
    self.backgroundColor = [UIColor whiteColor];
  }
}

- (void)imageNode:(ASNetworkImageNode *)imageNode didLoadImage:(UIImage *)image {
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

#pragma mark - superclass

- (void)displayWillStart {
  [super displayWillStart];
  [self didEnterPreloadState];
}

- (void)didEnterPreloadState {
  [super didEnterPreloadState];
  if (self.viewModel) {
    [self loadImage];
  }
}


- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize {

  ASLayoutSpec *textSpec = [self textSpec];
  ASLayoutSpec *imageSpec = [self imageSpecWithSize:constrainedSize];
  ASOverlayLayoutSpec *soldOutOverImage = [ASOverlayLayoutSpec overlayLayoutSpecWithChild:imageSpec overlay:[self soldOutLabelSpec]];
  
  NSArray *stackChildren = @[soldOutOverImage, textSpec];
  
  ASStackLayoutSpec *mainStack = [ASStackLayoutSpec stackLayoutSpecWithDirection:ASStackLayoutDirectionVertical spacing:0.0 justifyContent:ASStackLayoutJustifyContentStart alignItems:ASStackLayoutAlignItemsStretch children:stackChildren];
  
  ASOverlayLayoutSpec *soldOutOverlay = [ASOverlayLayoutSpec overlayLayoutSpecWithChild:mainStack overlay:self.soldOutOverlay];
  
  return soldOutOverlay;
}

- (ASLayoutSpec *)textSpec {
  CGFloat kInsetHorizontal = 16.0;
  CGFloat kInsetTop = 6.0;
  CGFloat kInsetBottom = 0.0;
  
  UIEdgeInsets textInsets = UIEdgeInsetsMake(kInsetTop, kInsetHorizontal, kInsetBottom, kInsetHorizontal);
  
  ASLayoutSpec *verticalSpacer = [[ASLayoutSpec alloc] init];
  verticalSpacer.style.flexGrow = 1.0;
  
  ASLayoutSpec *horizontalSpacer1 = [[ASLayoutSpec alloc] init];
  horizontalSpacer1.style.flexGrow = 1.0;
  
  ASLayoutSpec *horizontalSpacer2 = [[ASLayoutSpec alloc] init];
  horizontalSpacer2.style.flexGrow = 1.0;
  
  NSArray *info1Children = @[self.firstInfoLabel, self.distanceLabel, horizontalSpacer1, self.originalPriceLabel];
  NSArray *info2Children = @[self.secondInfoLabel, horizontalSpacer2, self.finalPriceLabel];
  if ([ItemNode isRTL]) {
    info1Children = [[info1Children reverseObjectEnumerator] allObjects];
    info2Children = [[info2Children reverseObjectEnumerator] allObjects];
  }
  
  ASStackLayoutSpec *info1Stack = [ASStackLayoutSpec stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal spacing:1.0 justifyContent:ASStackLayoutJustifyContentStart alignItems:ASStackLayoutAlignItemsBaselineLast children:info1Children];
  
  ASStackLayoutSpec *info2Stack = [ASStackLayoutSpec stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal spacing:0.0 justifyContent:ASStackLayoutJustifyContentCenter alignItems:ASStackLayoutAlignItemsBaselineLast children:info2Children];
  
  ASStackLayoutSpec *textStack = [ASStackLayoutSpec stackLayoutSpecWithDirection:ASStackLayoutDirectionVertical spacing:0.0 justifyContent:ASStackLayoutJustifyContentEnd alignItems:ASStackLayoutAlignItemsStretch children:@[self.titleLabel, verticalSpacer, info1Stack, info2Stack]];
  
  ASInsetLayoutSpec *textWrapper = [ASInsetLayoutSpec insetLayoutSpecWithInsets:textInsets child:textStack];
  textWrapper.style.flexGrow = 1.0;
  
  return textWrapper;
}

- (ASLayoutSpec *)imageSpecWithSize:(ASSizeRange)constrainedSize {
  CGFloat imageRatio = [self imageRatioFromSize:constrainedSize.max];
  
  ASRatioLayoutSpec *imagePlace = [ASRatioLayoutSpec ratioLayoutSpecWithRatio:imageRatio child:self.dealImageView];
  
  self.badge.style.layoutPosition = CGPointMake(0, constrainedSize.max.height - kFixedLabelsAreaHeight - kBadgeHeight);
  self.badge.style.height = ASDimensionMakeWithPoints(kBadgeHeight);
  ASAbsoluteLayoutSpec *badgePosition = [ASAbsoluteLayoutSpec absoluteLayoutSpecWithChildren:@[self.badge]];
  
  ASOverlayLayoutSpec *badgeOverImage = [ASOverlayLayoutSpec overlayLayoutSpecWithChild:imagePlace overlay:badgePosition];
  badgeOverImage.style.flexGrow = 1.0;
  
  return badgeOverImage;
}

- (ASLayoutSpec *)soldOutLabelSpec {
  ASCenterLayoutSpec *centerSoldOutLabel = [ASCenterLayoutSpec centerLayoutSpecWithCenteringOptions:ASCenterLayoutSpecCenteringXY sizingOptions:ASCenterLayoutSpecSizingOptionMinimumXY child:self.soldOutLabelFlat];
  ASCenterLayoutSpec *centerSoldOut = [ASCenterLayoutSpec centerLayoutSpecWithCenteringOptions:ASCenterLayoutSpecCenteringXY sizingOptions:ASCenterLayoutSpecSizingOptionDefault child:self.soldOutLabelBackground];
  ASBackgroundLayoutSpec *soldOutLabelOverBackground = [ASBackgroundLayoutSpec backgroundLayoutSpecWithChild:centerSoldOutLabel background:centerSoldOut];
  return soldOutLabelOverBackground;
}


+ (CGSize)sizeForWidth:(CGFloat)width {
  CGFloat height = [self scaledHeightForPreferredSize:[self preferredViewSize] scaledWidth:width];
  return CGSizeMake(width, height);
}


+ (CGSize)preferredViewSize {
  return CGSizeMake(kDesignWidth, kDesignHeight);
}

+ (CGFloat)scaledHeightForPreferredSize:(CGSize)preferredSize scaledWidth:(CGFloat)scaledWidth {
  CGFloat scale = scaledWidth / kDesignWidth;
  CGFloat scaledHeight = ceilf(scale * (kDesignHeight - kFixedLabelsAreaHeight)) + kFixedLabelsAreaHeight;
  
  return scaledHeight;
}

#pragma mark - view operations

- (CGFloat)imageRatioFromSize:(CGSize)size {
  CGFloat imageHeight = size.height - kFixedLabelsAreaHeight;
  CGFloat imageRatio = imageHeight / size.width;
  
  return imageRatio;
}

- (CGSize)imageSize {
  if (!CGSizeEqualToSize(self.dealImageView.frame.size, CGSizeZero)) {
    return self.dealImageView.frame.size;
  } else if (!CGSizeEqualToSize(self.calculatedSize, CGSizeZero)) {
    CGFloat imageRatio = [self imageRatioFromSize:self.calculatedSize];
    CGFloat imageWidth = self.calculatedSize.width;
    return CGSizeMake(imageWidth, imageRatio * imageWidth);
  } else {
    return CGSizeZero;
  }
}

- (void)loadImage {
  CGSize imageSize = [self imageSize];
  if (CGSizeEqualToSize(CGSizeZero, imageSize)) {
    return;
  }
  
  NSURL *url = [self.viewModel imageURLWithSize:imageSize];
  
  // if we're trying to set the deal image to what it already was, skip the work
  if ([[url absoluteString] isEqualToString:[self.dealImageView.URL absoluteString]]) {
    return;
  }
  
  // Clear the flag that says we've loaded our image
  [self.dealImageView setURL:url];
}

@end
