//
//  UIImage+ASConvenienceTests.m
//  AsyncDisplayKitTests
//
//  Created by Vladimir Solomenchuk on 5/22/20.
//  Copyright © 2020 Pinterest. All rights reserved.
//

#import <AsyncDisplayKit/ASImageNode.h>
#import <AsyncDisplayKit/UIImage+ASConvenience.h>
#import "ASSnapshotTestCase.h"

@interface UIImage_ASConvenienceTests : ASSnapshotTestCase

@end

@implementation UIImage_ASConvenienceTests
- (UIImage*) imageWithColor:(UIColor *)color {
  UIGraphicsBeginImageContext(CGSizeMake(100, 100));
  [color setFill];
  UIRectFill(CGRectMake(0, 0, 100, 100));
  UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return result;
}

- (void)testRoundedPartial {
  ASImageNode *node = [[ASImageNode alloc] init];
  UIImage *image = [UIImage as_resizableRoundedImageWithCornerRadius:50.0
                                                              cornerColor:UIColor.redColor
                                                                fillColor:UIColor.greenColor
                                                              borderColor:UIColor.blueColor
                                                              borderWidth:4.0
                                                           roundedCorners:UIRectCornerTopLeft | UIRectCornerBottomRight
                                                                    scale:2.0
                                                          traitCollection:ASPrimitiveTraitCollectionMakeDefault()];
  
  node.image = image;
  ASDisplayNodeSizeToFitSize(node, CGSizeMake(1000, 1000));
  ASSnapshotVerifyNode(node, nil);
}

- (void)testRoundedAllCorners {
  ASImageNode *node = [[ASImageNode alloc] init];
  UIImage *image = [UIImage as_resizableRoundedImageWithCornerRadius:50.0
                                                              cornerColor:UIColor.redColor
                                                                fillColor:UIColor.greenColor
                                                              borderColor:UIColor.blueColor
                                                              borderWidth:4.0
                                                          traitCollection:ASPrimitiveTraitCollectionMakeDefault()];
  
  node.image = image;
  ASDisplayNodeSizeToFitSize(node, CGSizeMake(1000, 1000));
  ASSnapshotVerifyNode(node, nil);
}

- (void)testRoundedBorderless {
  ASImageNode *node = [[ASImageNode alloc] init];
  UIImage *image = [UIImage as_resizableRoundedImageWithCornerRadius:50.0
                                                              cornerColor:UIColor.redColor
                                                                fillColor:UIColor.greenColor
                                                          traitCollection:ASPrimitiveTraitCollectionMakeDefault()];
  
  node.image = image;
  ASDisplayNodeSizeToFitSize(node, CGSizeMake(1000, 1000));
  ASSnapshotVerifyNode(node, nil);
}
@end
