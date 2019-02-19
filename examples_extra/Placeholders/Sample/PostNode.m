//
//  PostNode.m
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "PostNode.h"

#import "SlowpokeShareNode.h"
#import "SlowpokeTextNode.h"
#import <AsyncDisplayKit/ASDisplayNode+Subclasses.h>

@interface PostNode ()
{
  SlowpokeTextNode *_textNode;
  SlowpokeShareNode *_needyChildNode; // this node slows down display
}

@end

@implementation PostNode

// turn on to demo that the parent displays a placeholder even if it takes the longest
//+ (void)drawRect:(CGRect)bounds withParameters:(id<NSObject>)parameters isCancelled:(asdisplaynode_iscancelled_block_t)isCancelledBlock isRasterizing:(BOOL)isRasterizing
//{
//  usleep( (long)(1.2 * USEC_PER_SEC) ); // artificial delay of 1.2s
//
//  // demonstrates that the parent node should also adhere to the placeholder
//  [[UIColor colorWithWhite:0.95 alpha:1.0] setFill];
//  UIRectFill(bounds);
//}

- (instancetype)init
{
  if (!(self = [super init]))
    return nil;

  _textNode = [[SlowpokeTextNode alloc] init];
  _textNode.placeholderInsets = UIEdgeInsetsMake(3.0, 0.0, 3.0, 0.0);
  _textNode.placeholderEnabled = YES;

  NSString *text = @"Etiam porta sem malesuada magna mollis euismod. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh, ut fermentum massa justo sit amet risus. Etiam porta sem malesuada magna mollis euismod. Duis mollis, est non commodo luctus, nisi erat porttitor ligula, eget lacinia odio sem nec elit. Fusce dapibus, tellus ac cursus commodo, tortor mauris condimentum nibh.";
  NSDictionary *attributes = @{ NSFontAttributeName: [UIFont systemFontOfSize:17.0] };
  _textNode.attributedText = [[NSAttributedString alloc] initWithString:text attributes:attributes];

  _needyChildNode = [[SlowpokeShareNode alloc] init];
  _needyChildNode.opaque = NO;

  [self addSubnode:_textNode];
  [self addSubnode:_needyChildNode];

  return self;
}

- (UIImage *)placeholderImage
{
  CGSize size = self.calculatedSize;
  if (CGSizeEqualToSize(size, CGSizeZero)) {
    return nil;
  }
  
  UIGraphicsBeginImageContext(size);
  [[UIColor colorWithWhite:0.9 alpha:1] setFill];
  UIRectFill((CGRect){CGPointZero, size});
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

- (CGSize)calculateSizeThatFits:(CGSize)constrainedSize
{
  CGSize textSize = [_textNode layoutThatFits:ASSizeRangeMake(CGSizeZero, constrainedSize)].size;
  CGSize shareSize = [_needyChildNode layoutThatFits:ASSizeRangeMake(CGSizeZero, constrainedSize)].size;

  return CGSizeMake(constrainedSize.width, textSize.height + 10.0 + shareSize.height);
}

- (void)layout
{
  [super layout];
  
  CGSize textSize = _textNode.calculatedSize;
  CGSize needyChildSize = _needyChildNode.calculatedSize;

  _textNode.frame = (CGRect){CGPointZero, textSize};
  _needyChildNode.frame = (CGRect){0.0, CGRectGetMaxY(_textNode.frame) + 10.0, needyChildSize};
}

@end
