//
//  BlurbNode.m
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "BlurbNode.h"
#import "AppDelegate.h"

#import <AsyncDisplayKit/ASDisplayNode+Subclasses.h>
#import <AsyncDisplayKit/ASHighlightOverlayLayer.h>

#import <AsyncDisplayKit/ASInsetLayoutSpec.h>
#import <AsyncDisplayKit/ASCenterLayoutSpec.h>

static CGFloat kTextPadding = 10.0f;
static NSString *kLinkAttributeName = @"PlaceKittenNodeLinkAttributeName";

@interface BlurbNode () <ASTextNodeDelegate>
{
  ASTextNode *_textNode;
}

@end


@implementation BlurbNode

#pragma mark -
#pragma mark ASCellNode.

- (instancetype)init
{
  if (!(self = [super init]))
    return nil;

  // create a text node
  _textNode = [[ASTextNode alloc] init];

  // configure the node to support tappable links
  _textNode.delegate = self;
  _textNode.userInteractionEnabled = YES;
  _textNode.linkAttributeNames = @[ kLinkAttributeName ];

  // generate an attributed string using the custom link attribute specified above
  NSString *blurb = @"Nic Cage courtesy of himself.";
  NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:blurb];
  _textNode.attributedText = string;

  // add it as a subnode, and we're done
  [self addSubnode:_textNode];

  return self;
}

- (void)didLoad
{
  // enable highlighting now that self.layer has loaded -- see ASHighlightOverlayLayer.h
  self.layer.as_allowsHighlightDrawing = YES;

  [super didLoad];
}

#if UseAutomaticLayout
- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
  ASCenterLayoutSpec *centerSpec = [[ASCenterLayoutSpec alloc] init];
  centerSpec.centeringOptions = ASCenterLayoutSpecCenteringX;
  centerSpec.sizingOptions = ASCenterLayoutSpecSizingOptionMinimumY;
  centerSpec.child = _textNode;
  
  UIEdgeInsets padding =UIEdgeInsetsMake(kTextPadding, kTextPadding, kTextPadding, kTextPadding);
  return [ASInsetLayoutSpec insetLayoutSpecWithInsets:padding child:centerSpec];
}
#else
- (CGSize)calculateSizeThatFits:(CGSize)constrainedSize
{
  // called on a background thread.  custom nodes must call -measure: on their subnodes in -calculateSizeThatFits:
  CGSize measuredSize = [_textNode measure:CGSizeMake(constrainedSize.width - 2 * kTextPadding,
                                                      constrainedSize.height - 2 * kTextPadding)];
  return CGSizeMake(constrainedSize.width, measuredSize.height + 2 * kTextPadding);
}

- (void)layout
{
  // called on the main thread.  we'll use the stashed size from above, instead of blocking on text sizing
  CGSize textNodeSize = _textNode.calculatedSize;
  _textNode.frame = CGRectMake(roundf((self.calculatedSize.width - textNodeSize.width) / 2.0f),
                               kTextPadding,
                               textNodeSize.width,
                               textNodeSize.height);
}
#endif

#pragma mark -
#pragma mark ASTextNodeDelegate methods.

- (BOOL)textNode:(ASTextNode *)richTextNode shouldHighlightLinkAttribute:(NSString *)attribute value:(id)value atPoint:(CGPoint)point
{
  // opt into link highlighting -- tap and hold the link to try it!  must enable highlighting on a layer, see -didLoad
  return YES;
}

- (void)textNode:(ASTextNode *)richTextNode tappedLinkAttribute:(NSString *)attribute value:(NSURL *)URL atPoint:(CGPoint)point textRange:(NSRange)textRange
{
  // the node tapped a link, open it
  [[UIApplication sharedApplication] openURL:URL];
}

@end
