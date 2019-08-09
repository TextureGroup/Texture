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

@end
