//
//  ASTextKitTruncationTests.mm
//  Texture
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the /ASDK-Licenses directory of this source tree. An additional
//  grant of patent rights can be found in the PATENTS file in the same directory.
//
//  Modifications to this file made after 4/13/2017 are: Copyright (c) 2017-present,
//  Pinterest, Inc.  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <AsyncDisplayKit/ASTextKitContext.h>
#import <AsyncDisplayKit/ASTextKitTailTruncater.h>

@interface ASTextKitTruncationTests : XCTestCase

@end

@implementation ASTextKitTruncationTests

- (NSString *)_sentenceString
{
  return @"90's cray photo booth tote bag bespoke Carles. Plaid wayfarers Odd Future master cleanse tattooed four dollar toast small batch kale chips leggings meh photo booth occupy irony.";
}

- (NSAttributedString *)_sentenceAttributedString
{
  return [[NSAttributedString alloc] initWithString:[self _sentenceString] attributes:@{}];
}

- (NSAttributedString *)_simpleTruncationAttributedString
{
  return [[NSAttributedString alloc] initWithString:@"..." attributes:@{}];
}

- (void)testEmptyTruncationStringSameAsStraightTextKitTailTruncation
{
  CGSize constrainedSize = CGSizeMake(100, 50);
  NSAttributedString *attributedString = [self _sentenceAttributedString];
  ASTextKitContext *context = [[ASTextKitContext alloc] initWithAttributedString:attributedString
                                                                   lineBreakMode:NSLineBreakByWordWrapping
                                                            maximumNumberOfLines:0
                                                                  exclusionPaths:nil
                                                                 constrainedSize:constrainedSize];
  __block NSRange textKitVisibleRange;
  [context performBlockWithLockedTextKitComponents:^(NSLayoutManager *layoutManager, NSTextStorage *textStorage, NSTextContainer *textContainer) {
    textKitVisibleRange = [layoutManager characterRangeForGlyphRange:[layoutManager glyphRangeForTextContainer:textContainer]
                                                    actualGlyphRange:NULL];
  }];
  ASTextKitTailTruncater *tailTruncater = [[ASTextKitTailTruncater alloc] initWithContext:context
                                                               truncationAttributedString:nil
                                                                   avoidTailTruncationSet:nil];
  [tailTruncater truncate];
  XCTAssert(NSEqualRanges(textKitVisibleRange, tailTruncater.visibleRanges[0]));
  XCTAssert(NSEqualRanges(textKitVisibleRange, tailTruncater.firstVisibleRange));
}

- (void)testSimpleTailTruncation
{
  CGSize constrainedSize = CGSizeMake(100, 60);
  NSAttributedString *attributedString = [self _sentenceAttributedString];
  ASTextKitContext *context = [[ASTextKitContext alloc] initWithAttributedString:attributedString
                                                                   lineBreakMode:NSLineBreakByWordWrapping
                                                            maximumNumberOfLines:0
                                                                  exclusionPaths:nil
                                                                 constrainedSize:constrainedSize];
  ASTextKitTailTruncater *tailTruncater = [[ASTextKitTailTruncater alloc] initWithContext:context
                                                               truncationAttributedString:[self _simpleTruncationAttributedString]
                                                                   avoidTailTruncationSet:[NSCharacterSet characterSetWithCharactersInString:@""]];
  [tailTruncater truncate];
  __block NSString *drawnString;
  [context performBlockWithLockedTextKitComponents:^(NSLayoutManager *layoutManager, NSTextStorage *textStorage, NSTextContainer *textContainer) {
    drawnString = textStorage.string;
  }];
  NSString *expectedString = @"90's cray photo booth tote bag bespoke Carles. Plaid wayfarers...";
  XCTAssertEqualObjects(expectedString, drawnString);
  XCTAssert(NSEqualRanges(NSMakeRange(0, 62), tailTruncater.visibleRanges[0]));
  XCTAssert(NSEqualRanges(NSMakeRange(0, 62), tailTruncater.firstVisibleRange));
}

- (void)testAvoidedCharTailWordBoundaryTruncation
{
  CGSize constrainedSize = CGSizeMake(100, 50);
  NSAttributedString *attributedString = [self _sentenceAttributedString];
  ASTextKitContext *context = [[ASTextKitContext alloc] initWithAttributedString:attributedString
                                                                   lineBreakMode:NSLineBreakByWordWrapping
                                                            maximumNumberOfLines:0
                                                                  exclusionPaths:nil
                                                                 constrainedSize:constrainedSize];
  ASTextKitTailTruncater *tailTruncater = [[ASTextKitTailTruncater alloc] initWithContext:context
                                                               truncationAttributedString:[self _simpleTruncationAttributedString]
                                                                   avoidTailTruncationSet:[NSCharacterSet characterSetWithCharactersInString:@"."]];
  [tailTruncater truncate];
  __block NSString *drawnString;
  [context performBlockWithLockedTextKitComponents:^(NSLayoutManager *layoutManager, NSTextStorage *textStorage, NSTextContainer *textContainer) {
    drawnString = textStorage.string;
  }];
  // This should have removed the additional "." in the string right after Carles.
  NSString *expectedString = @"90's cray photo booth tote bag bespoke Carles...";
  XCTAssertEqualObjects(expectedString, drawnString);
}

- (void)testAvoidedCharTailCharBoundaryTruncation
{
  CGSize constrainedSize = CGSizeMake(50, 50);
  NSAttributedString *attributedString = [self _sentenceAttributedString];
  ASTextKitContext *context = [[ASTextKitContext alloc] initWithAttributedString:attributedString
                                                                   lineBreakMode:NSLineBreakByCharWrapping
                                                            maximumNumberOfLines:0
                                                                  exclusionPaths:nil
                                                                 constrainedSize:constrainedSize];
  ASTextKitTailTruncater *tailTruncater = [[ASTextKitTailTruncater alloc] initWithContext:context
                                                               truncationAttributedString:[self _simpleTruncationAttributedString]
                                                                   avoidTailTruncationSet:[NSCharacterSet characterSetWithCharactersInString:@"."]];
  [tailTruncater truncate];
  __block NSString *drawnString;
  [context performBlockWithLockedTextKitComponents:^(NSLayoutManager *layoutManager, NSTextStorage *textStorage, NSTextContainer *textContainer) {
    drawnString = textStorage.string;
  }];
  // This should have removed the additional "." in the string right after Carles.
  NSString *expectedString = @"90's cray photo booth t...";
  XCTAssertEqualObjects(expectedString, drawnString);
}

- (void)testHandleZeroSizeConstrainedSize
{
  CGSize constrainedSize = CGSizeZero;
  NSAttributedString *attributedString = [self _sentenceAttributedString];
  
  ASTextKitContext *context = [[ASTextKitContext alloc] initWithAttributedString:attributedString
                                                                 lineBreakMode:NSLineBreakByWordWrapping
                                                          maximumNumberOfLines:0
                                                                exclusionPaths:nil
                                                               constrainedSize:constrainedSize];
  ASTextKitTailTruncater *tailTruncater = [[ASTextKitTailTruncater alloc] initWithContext:context
                                                               truncationAttributedString:[self _simpleTruncationAttributedString]
                                                                   avoidTailTruncationSet:nil];
  XCTAssertNoThrow([tailTruncater truncate]);
  XCTAssert(tailTruncater.visibleRanges.size() == 0);
  NSEqualRanges(NSMakeRange(0, 0), tailTruncater.firstVisibleRange);
}

- (void)testHandleZeroHeightConstrainedSize
{
  CGSize constrainedSize = CGSizeMake(50, 0);
  NSAttributedString *attributedString = [self _sentenceAttributedString];
  ASTextKitContext *context = [[ASTextKitContext alloc] initWithAttributedString:attributedString
                                                                   lineBreakMode:NSLineBreakByCharWrapping
                                                            maximumNumberOfLines:0
                                                                  exclusionPaths:nil
                                                                 constrainedSize:constrainedSize];

  ASTextKitTailTruncater *tailTruncater = [[ASTextKitTailTruncater alloc] initWithContext:context
                                                               truncationAttributedString:[self _simpleTruncationAttributedString]
                                                                   avoidTailTruncationSet:[NSCharacterSet characterSetWithCharactersInString:@"."]];
  XCTAssertNoThrow([tailTruncater truncate]);
}

@end
