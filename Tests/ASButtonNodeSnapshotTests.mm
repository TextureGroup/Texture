//
//  ASButtonNodeSnapshotTests.mm
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "ASSnapshotTestCase.h"

@interface ASButtonNodeSnapshotTests : ASSnapshotTestCase

@end


@implementation ASButtonNodeSnapshotTests

- (void)setUp
{
  [super setUp];
  self.recordMode = NO;
}

- (UIImage *)testImage
{
  NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"logo-square"
                                                                    ofType:@"png"
                                                               inDirectory:@"TestResources"];
  return [[UIImage imageWithContentsOfFile:path] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (void)testTintColor
{

  ASButtonNode *node = [[ASButtonNode alloc] init];
  node.tintColor = UIColor.redColor;
  [node setImage:[self testImage] forState:UIControlStateNormal];
  [node setTitle:@"Press Me"
        withFont:[UIFont systemFontOfSize:48]
       withColor:nil
        forState:UIControlStateNormal];
  node.imageNode.style.width = ASDimensionMake(200);
  node.imageNode.style.height = ASDimensionMake(200);
  ASDisplayNodeSizeToFitSize(node, CGSizeMake(1000, 1000));
  ASSnapshotVerifyNode(node, nil);
}

- (void)testChangingTintColor
{
  ASButtonNode *node = [[ASButtonNode alloc] init];
  node.tintColor = UIColor.redColor;
  [node setImage:[self testImage] forState:UIControlStateNormal];
  [node setTitle:@"Press Me"
        withFont:[UIFont systemFontOfSize:48]
       withColor:nil
        forState:UIControlStateNormal];
  node.imageNode.style.width = ASDimensionMake(200);
  node.imageNode.style.height = ASDimensionMake(200);
  ASDisplayNodeSizeToFitSize(node, CGSizeMake(1000, 1000));
  ASSnapshotVerifyNode(node, nil);

  node.tintColor = UIColor.blueColor;
  ASSnapshotVerifyNode(node, @"modified_tint");
}


- (void)testTintColorWithForegroundColorSet
{
  ASButtonNode *node = [[ASButtonNode alloc] init];
  node.tintColor = UIColor.redColor;
  [node setImage:[self testImage] forState:UIControlStateNormal];
  [node setTitle:@"Press Me"
        withFont:[UIFont systemFontOfSize:48]
       withColor:[UIColor blueColor]
        forState:UIControlStateNormal];
  node.imageNode.style.width = ASDimensionMake(200);
  node.imageNode.style.height = ASDimensionMake(200);
  ASDisplayNodeSizeToFitSize(node, CGSizeMake(1000, 1000));
  ASSnapshotVerifyNode(node, nil);
}

- (void)testTintColorWithInheritedTintColor
{
  ASDisplayNode *container = [[ASDisplayNode alloc] init];
  container.tintColor = UIColor.redColor;

  // Add to hierarchy, assert new tint is picked up
  ASButtonNode *node = [[ASButtonNode alloc] init];
  [container addSubnode:node];
  [node setImage:[[self testImage] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
  [node setTitle:@"Press Me"
        withFont:[UIFont systemFontOfSize:48]
       withColor:nil
        forState:UIControlStateNormal];
  node.imageNode.style.width = ASDimensionMake(200);
  node.imageNode.style.height = ASDimensionMake(200);
  container.style.preferredSize = CGSizeMake(1000,1000);
  ASDisplayNodeSizeToFitSize(node, CGSizeMake(1000, 1000));
  // Force load so the superview is set for the button _ASDisplayView
  __unused UIView *v = container.view;
  ASSnapshotVerifyNode(node, @"red_inherited_tint");

  // Change hierarchy, assert new tint is picked up
  ASDisplayNode *container2 = [[ASDisplayNode alloc] init];
  container2.tintColor = UIColor.greenColor;
  container2.style.preferredSize = CGSizeMake(1000,1000);
  [container2 addSubnode:node];
  ASDisplayNodeSizeToFitSize(node, CGSizeMake(1000, 1000));
  // Force load so the superview is set for the button _ASDisplayView
  __unused UIView *v2 = container2.view; // Force load
  ASSnapshotVerifyNode(node, @"green_inherited_tint");
}

@end
