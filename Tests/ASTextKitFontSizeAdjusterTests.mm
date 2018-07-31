//
//  ASTextKitFontSizeAdjusterTests.mm
//  Texture
//
//  Copyright (c) 2018-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASTextKitFontSizeAdjuster.h>
#import <XCTest/XCTest.h>

@interface ASFontSizeAdjusterTests : XCTestCase

@end

@implementation ASFontSizeAdjusterTests

- (void)testFontSizeAdjusterAttributes
{
  NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
  paragraphStyle.lineHeightMultiple = 2.0;
  paragraphStyle.lineSpacing = 2.0;
  paragraphStyle.paragraphSpacing = 4.0;
  paragraphStyle.firstLineHeadIndent = 6.0;
  paragraphStyle.headIndent = 8.0;
  paragraphStyle.tailIndent = 10.0;
  paragraphStyle.minimumLineHeight = 12.0;
  paragraphStyle.maximumLineHeight = 14.0;

  NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"Lorem ipsum dolor sit amet"
                                                                             attributes:@{ NSParagraphStyleAttributeName: paragraphStyle }];

  [ASTextKitFontSizeAdjuster adjustFontSizeForAttributeString:string withScaleFactor:0.5];

  NSParagraphStyle *adjustedParagraphStyle = [string attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:nil];

  XCTAssertEqual(adjustedParagraphStyle.lineHeightMultiple, 2.0);
  XCTAssertEqual(adjustedParagraphStyle.lineSpacing, 1.0);
  XCTAssertEqual(adjustedParagraphStyle.paragraphSpacing, 2.0);
  XCTAssertEqual(adjustedParagraphStyle.firstLineHeadIndent, 3.0);
  XCTAssertEqual(adjustedParagraphStyle.headIndent, 4.0);
  XCTAssertEqual(adjustedParagraphStyle.tailIndent, 5.0);
  XCTAssertEqual(adjustedParagraphStyle.minimumLineHeight, 6.0);
  XCTAssertEqual(adjustedParagraphStyle.maximumLineHeight, 7.0);
}

@end
