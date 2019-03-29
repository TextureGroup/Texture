//
//  ASImageNodeBackingSizeTests.mm
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0

#import <XCTest/XCTest.h>
#import <AsyncDisplayKit/ASImageNode+CGExtras.h>

static CGSize _FitSizeWithAspectRatio(CGFloat imageRatio, CGSize backingSize);
static CGSize _FillSizeWithAspectRatio(CGFloat imageRatio, CGSize backingSize);

static CGSize _FitSizeWithAspectRatio(CGFloat imageRatio, CGSize backingSize)
{
  CGFloat backingRatio = backingSize.width / backingSize.height;
  // fit size should be constrained in backing size
  if (imageRatio > backingRatio) {
    return CGSizeMake(backingSize.width, backingSize.width / imageRatio);
  } else {
    return CGSizeMake(backingSize.height * imageRatio, backingSize.height);
  }
}

static CGSize _FillSizeWithAspectRatio(CGFloat imageRatio, CGSize backingSize)
{
  CGFloat backingRatio = backingSize.width / backingSize.height;
  // backing size should be constrained in fill size
  if (imageRatio > backingRatio) {
    return CGSizeMake(backingSize.height * imageRatio, backingSize.height);
  } else {
    return CGSizeMake(backingSize.width, backingSize.width / imageRatio);
  }
}

@interface ASImageNodeBackingSizeTests : XCTestCase

@end

@implementation ASImageNodeBackingSizeTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

// ScaleAspectFit mode calculation.
- (void)testScaleAspectFitModeBackingSizeCalculation {
  CGSize imageSize     = CGSizeMake(100, 100);
  CGSize boundsSize    = CGSizeMake(200, 400);
  
  CGSize backingSize   = CGSizeZero;
  CGRect imageDrawRect = CGRectZero;
  
  ASCroppedImageBackingSizeAndDrawRectInBounds(imageSize, boundsSize, UIViewContentModeScaleAspectFit, CGRectZero, false, CGSizeZero, &backingSize, &imageDrawRect);
  CGSize backingSizeShouldBe = _FillSizeWithAspectRatio(boundsSize.width / boundsSize.height, imageSize);
  CGSize drawRectSizeShouldBe = _FitSizeWithAspectRatio(imageSize.width / imageSize.height, backingSizeShouldBe);
  XCTAssertTrue(CGSizeEqualToSize(backingSizeShouldBe, backingSize));
  XCTAssertTrue(CGSizeEqualToSize(drawRectSizeShouldBe, imageDrawRect.size));
}

// ScaleAspectFill mode calculation.
- (void)testScaleAspectFillModeBackingSizeCalculation {
  CGSize imageSize     = CGSizeMake(100, 100);
  CGSize boundsSize    = CGSizeMake(200, 400);
  
  CGSize backingSize   = CGSizeZero;
  CGRect imageDrawRect = CGRectZero;
  
  ASCroppedImageBackingSizeAndDrawRectInBounds(imageSize, boundsSize, UIViewContentModeScaleAspectFill, CGRectZero, false, CGSizeZero, &backingSize, &imageDrawRect);
  CGSize backingSizeShouldBe = _FitSizeWithAspectRatio(boundsSize.width / boundsSize.height, imageSize);
  CGSize drawRectSizeShouldBe = _FillSizeWithAspectRatio(imageSize.width / imageSize.height, backingSizeShouldBe);
  XCTAssertTrue(CGSizeEqualToSize(backingSizeShouldBe, backingSize));
  XCTAssertTrue(CGSizeEqualToSize(drawRectSizeShouldBe, imageDrawRect.size));
}

@end
