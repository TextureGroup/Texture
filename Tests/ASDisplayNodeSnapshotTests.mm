//
//  ASDisplayNodeSnapshotTests.mm
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASSnapshotTestCase.h"
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import <AsyncDisplayKit/ASDisplayNodeInternal.h>

@interface ASDisplayNodeSnapshotTests : ASSnapshotTestCase

@end

@implementation ASDisplayNodeSnapshotTests

- (void)testBasicHierarchySnapshotTesting
{
  ASDisplayNode *node = [[ASDisplayNode alloc] init];
  node.backgroundColor = [UIColor blueColor];
  
  ASTextNode *subnode = [[ASTextNode alloc] init];
  subnode.backgroundColor = [UIColor whiteColor];
  
  subnode.attributedText = [[NSAttributedString alloc] initWithString:@"Hello"];
  node.automaticallyManagesSubnodes = YES;
  node.layoutSpecBlock = ^(ASDisplayNode * _Nonnull node, ASSizeRange constrainedSize) {
    return [ASInsetLayoutSpec insetLayoutSpecWithInsets:UIEdgeInsetsMake(5, 5, 5, 5) child:subnode];
  };

  ASDisplayNodeSizeToFitSizeRange(node, ASSizeRangeMake(CGSizeZero, CGSizeMake(INFINITY, INFINITY)));
  ASSnapshotVerifyNode(node, nil);
}

NS_INLINE UIImage *BlueImageMake(CGRect bounds)
{
  UIGraphicsBeginImageContextWithOptions(bounds.size, YES, 0);
  [[UIColor blueColor] setFill];
  UIRectFill(bounds);
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return image;
}

- (void)testPrecompositedCornerRounding
{
  for (CACornerMask c = 1; c <= kASCACornerAllCorners; c |= (c << 1)) {
    auto node = [[ASImageNode alloc] init];
    auto bounds = CGRectMake(0, 0, 100, 100);
    node.image = BlueImageMake(bounds);
    node.frame = bounds;
    node.cornerRoundingType = ASCornerRoundingTypePrecomposited;
    node.backgroundColor = UIColor.greenColor;
    node.maskedCorners = c;
    node.cornerRadius = 15;
    ASSnapshotVerifyNode(node, ([NSString stringWithFormat:@"%d", (int)c]));
  }
}

- (void)testClippingCornerRounding
{
  for (CACornerMask c = 1; c <= kASCACornerAllCorners; c |= (c << 1)) {
    auto node = [[ASImageNode alloc] init];
    auto bounds = CGRectMake(0, 0, 100, 100);
    node.image = BlueImageMake(bounds);
    node.frame = bounds;
    node.cornerRoundingType = ASCornerRoundingTypeClipping;
    node.backgroundColor = UIColor.greenColor;
    node.maskedCorners = c;
    node.cornerRadius = 15;
    // A layout pass is required, because that's where we lay out the clip layers.
    [node.layer layoutIfNeeded];
    ASSnapshotVerifyNode(node, ([NSString stringWithFormat:@"%d", (int)c]));
  }
}

@end
