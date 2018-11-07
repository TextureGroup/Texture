//
//  ASLayoutElementStyleTests.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <XCTest/XCTest.h>
#import "ASXCTExtensions.h"
#import <AsyncDisplayKit/ASLayoutElement.h>

#pragma mark - ASLayoutElementStyleTestsDelegate

@interface ASLayoutElementStyleTestsDelegate : NSObject<ASLayoutElementStyleDelegate>
@property (copy, nonatomic) NSString *propertyNameChanged;
@end

@implementation ASLayoutElementStyleTestsDelegate

- (void)style:(id)style propertyDidChange:(NSString *)propertyName
{
  self.propertyNameChanged = propertyName;
}

@end

#pragma mark - ASLayoutElementStyleTests

@interface ASLayoutElementStyleTests : XCTestCase

@end

@implementation ASLayoutElementStyleTests

- (void)testSettingSize
{
  ASLayoutElementStyle *style = [ASLayoutElementStyle new];
  
  style.width = ASDimensionMake(100);
  style.height = ASDimensionMake(100);
  XCTAssertTrue(ASDimensionEqualToDimension(style.width, ASDimensionMake(100)));
  XCTAssertTrue(ASDimensionEqualToDimension(style.height, ASDimensionMake(100)));
  
  style.minWidth = ASDimensionMake(100);
  style.minHeight = ASDimensionMake(100);
  XCTAssertTrue(ASDimensionEqualToDimension(style.width, ASDimensionMake(100)));
  XCTAssertTrue(ASDimensionEqualToDimension(style.height, ASDimensionMake(100)));
  
  style.maxWidth = ASDimensionMake(100);
  style.maxHeight = ASDimensionMake(100);
  XCTAssertTrue(ASDimensionEqualToDimension(style.width, ASDimensionMake(100)));
  XCTAssertTrue(ASDimensionEqualToDimension(style.height, ASDimensionMake(100)));
}

- (void)testSettingSizeViaCGSize
{
  ASLayoutElementStyle *style = [ASLayoutElementStyle new];
  
  ASXCTAssertEqualSizes(style.preferredSize, CGSizeZero);
  
  CGSize size = CGSizeMake(100, 100);
  
  style.preferredSize = size;
  ASXCTAssertEqualSizes(style.preferredSize, size);
  XCTAssertTrue(ASDimensionEqualToDimension(style.width, ASDimensionMakeWithPoints(size.width)));
  XCTAssertTrue(ASDimensionEqualToDimension(style.height, ASDimensionMakeWithPoints(size.height)));
  
  style.minSize = size;
  XCTAssertTrue(ASDimensionEqualToDimension(style.minWidth, ASDimensionMakeWithPoints(size.width)));
  XCTAssertTrue(ASDimensionEqualToDimension(style.minHeight, ASDimensionMakeWithPoints(size.height)));
  
  style.maxSize = size;
  XCTAssertTrue(ASDimensionEqualToDimension(style.maxWidth, ASDimensionMakeWithPoints(size.width)));
  XCTAssertTrue(ASDimensionEqualToDimension(style.maxHeight, ASDimensionMakeWithPoints(size.height)));
}

- (void)testReadingInvalidSizeForPreferredSize
{
  ASLayoutElementStyle *style = [ASLayoutElementStyle new];
  
  XCTAssertNoThrow(style.preferredSize);
  
  style.width = ASDimensionMake(ASDimensionUnitFraction, 0.5);
  XCTAssertThrows(style.preferredSize);
  
  style.preferredSize = CGSizeMake(100, 100);
  XCTAssertNoThrow(style.preferredSize);
}

- (void)testSettingSizeViaLayoutSize
{
  ASLayoutElementStyle *style = [ASLayoutElementStyle new];
  
  ASLayoutSize layoutSize = ASLayoutSizeMake(ASDimensionMake(100), ASDimensionMake(100));
  
  style.preferredLayoutSize = layoutSize;
  XCTAssertTrue(ASDimensionEqualToDimension(style.width, layoutSize.width));
  XCTAssertTrue(ASDimensionEqualToDimension(style.height, layoutSize.height));
  XCTAssertTrue(ASDimensionEqualToDimension(style.preferredLayoutSize.width, layoutSize.width));
  XCTAssertTrue(ASDimensionEqualToDimension(style.preferredLayoutSize.height, layoutSize.height));
  
  style.minLayoutSize = layoutSize;
  XCTAssertTrue(ASDimensionEqualToDimension(style.minWidth, layoutSize.width));
  XCTAssertTrue(ASDimensionEqualToDimension(style.minHeight, layoutSize.height));
  XCTAssertTrue(ASDimensionEqualToDimension(style.minLayoutSize.width, layoutSize.width));
  XCTAssertTrue(ASDimensionEqualToDimension(style.minLayoutSize.height, layoutSize.height));
  
  style.maxLayoutSize = layoutSize;
  XCTAssertTrue(ASDimensionEqualToDimension(style.maxWidth, layoutSize.width));
  XCTAssertTrue(ASDimensionEqualToDimension(style.maxHeight, layoutSize.height));
  XCTAssertTrue(ASDimensionEqualToDimension(style.maxLayoutSize.width, layoutSize.width));
  XCTAssertTrue(ASDimensionEqualToDimension(style.maxLayoutSize.height, layoutSize.height));
}
  
- (void)testSettingPropertiesWillCallDelegate
{
  ASLayoutElementStyleTestsDelegate *delegate = [ASLayoutElementStyleTestsDelegate new];
  ASLayoutElementStyle *style = [[ASLayoutElementStyle alloc] initWithDelegate:delegate];
  XCTAssertTrue(ASDimensionEqualToDimension(style.width, ASDimensionAuto));
  style.width = ASDimensionMake(100);
  XCTAssertTrue(ASDimensionEqualToDimension(style.width, ASDimensionMake(100)));
  XCTAssertTrue([delegate.propertyNameChanged isEqualToString:ASLayoutElementStyleWidthProperty]);
}

@end
