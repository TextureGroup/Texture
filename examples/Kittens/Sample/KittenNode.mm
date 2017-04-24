//
//  KittenNode.mm
//  Sample
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the root directory of this source tree. An additional grant
//  of patent rights can be found in the PATENTS file in the same directory.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//  FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
//  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "KittenNode.h"
#import "AppDelegate.h"

#import <AsyncDisplayKit/ASDisplayNode+Subclasses.h>

#import <AsyncDisplayKit/ASStackLayoutSpec.h>
#import <AsyncDisplayKit/ASInsetLayoutSpec.h>
#import <AsyncDisplayKit/ASTextNodeTypes.h>

static const CGFloat kImageSize = 80.0f;
static const CGFloat kOuterPadding = 16.0f;
static const CGFloat kInnerPadding = 10.0f;


@interface KittenNode ()
{
  CGSize _kittenSize;
  
  ASNetworkImageNode *_imageNode;
  ASTextNode *_textNode;
  ASDisplayNode *_divider;
  BOOL _isImageEnlarged;
  BOOL _swappedTextAndImage;
}

@end


@implementation KittenNode

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
  
  // kitten image, with a solid background colour serving as placeholder
  _imageNode = [[ASNetworkImageNode alloc] init];
  _imageNode.URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://placekitten.com/%zd/%zd",
                                         (NSInteger)roundl(_kittenSize.width),
                                         (NSInteger)roundl(_kittenSize.height)]];
  _imageNode.placeholderFadeDuration = .5;
  _imageNode.placeholderColor = ASDisplayNodeDefaultPlaceholderColor();
  //  _imageNode.contentMode = UIViewContentModeCenter;
  [_imageNode addTarget:self action:@selector(toggleNodesSwap) forControlEvents:ASControlNodeEventTouchUpInside];
  [self addSubnode:_imageNode];
  
  // lorem ipsum text, plus some nice styling
  _textNode = [[ASTextNode alloc] init];
  _textNode.attributedText = [[NSAttributedString alloc] initWithString:[self kittyIpsum] attributes:[self textStyle]];
  [self addSubnode:_textNode];
  
  // hairline cell separator
  _divider = [[ASDisplayNode alloc] init];
  _divider.backgroundColor = [UIColor lightGrayColor];
  [self addSubnode:_divider];
  
  return self;
}

- (NSString *)kittyIpsum
{
  NSArray *placeholders = [KittenNode placeholders];
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
  
  return @{
    NSFontAttributeName: font,
    NSParagraphStyleAttributeName: style,
    ASTextNodeWordKerningAttributeName : @.5
  };
}

#if UseAutomaticLayout
- (ASLayoutSpec *)layoutSpecThatFits:(ASSizeRange)constrainedSize
{
  // Set an intrinsic size for the image node
  CGSize imageSize = _isImageEnlarged ? CGSizeMake(2.0 * kImageSize, 2.0 * kImageSize) : CGSizeMake(kImageSize, kImageSize);
  _imageNode.style.preferredSize = imageSize;
  
  // Shrink the text node in case the image + text gonna be too wide
  _textNode.style.flexShrink = 1.0;

  // Configure stack
  ASStackLayoutSpec *stackLayoutSpec =
  [ASStackLayoutSpec
   stackLayoutSpecWithDirection:ASStackLayoutDirectionHorizontal
   spacing:kInnerPadding
   justifyContent:ASStackLayoutJustifyContentStart
   alignItems:ASStackLayoutAlignItemsStart
   children:_swappedTextAndImage ? @[_textNode, _imageNode] : @[_imageNode, _textNode]];
  
  // Add inset
  return [ASInsetLayoutSpec
          insetLayoutSpecWithInsets:UIEdgeInsetsMake(kOuterPadding, kOuterPadding, kOuterPadding, kOuterPadding)
          child:stackLayoutSpec];
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
