//
//  ASTextNode2Tests.mm
//  TextureTests
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <CoreText/CoreText.h>

#import <XCTest/XCTest.h>

#import <AsyncDisplayKit/ASDisplayNode+Beta.h>
#import <AsyncDisplayKit/ASTextNode2.h>
#import <AsyncDisplayKit/ASTextNode+Beta.h>

#import "ASTestCase.h"

@interface ASTextNode2(Beta)
@property (nullable, nonatomic, copy) NSArray<NSNumber *> *pointSizeScaleFactors;
@end

@interface ASTextNode2Tests : XCTestCase

@property(nonatomic) ASTextNode2 *textNode;
@property(nonatomic, copy) NSAttributedString *attributedText;

@end

@implementation ASTextNode2Tests

- (void)setUp
{
  [super setUp];
  _textNode = [[ASTextNode2 alloc] init];

  UIFontDescriptor *desc = [UIFontDescriptor fontDescriptorWithName:@"Didot" size:18];
  NSArray *arr = @[ @{
                      UIFontFeatureTypeIdentifierKey : @(kLetterCaseType),
                      UIFontFeatureSelectorIdentifierKey : @(kSmallCapsSelector)
                      } ];
  desc = [desc fontDescriptorByAddingAttributes:@{UIFontDescriptorFeatureSettingsAttribute : arr}];
  UIFont *f = [UIFont fontWithDescriptor:desc size:0];
  NSDictionary *d = @{NSFontAttributeName : f};
  NSMutableAttributedString *mas = [[NSMutableAttributedString alloc]
                                    initWithString:
                                    @"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor "
                                    @"incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud "
                                    @"exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure "
                                    @"dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. "
                                    @"Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt "
                                    @"mollit anim id est laborum."
                                    attributes:d];
  NSMutableParagraphStyle *para = [NSMutableParagraphStyle new];
  para.alignment = NSTextAlignmentCenter;
  para.lineSpacing = 1.0;
  [mas addAttribute:NSParagraphStyleAttributeName value:para range:NSMakeRange(0, mas.length - 1)];

  // Vary the linespacing on the last line
  NSMutableParagraphStyle *lastLinePara = [NSMutableParagraphStyle new];
  lastLinePara.alignment = para.alignment;
  lastLinePara.lineSpacing = 5.0;
  [mas addAttribute:NSParagraphStyleAttributeName
              value:lastLinePara
              range:NSMakeRange(mas.length - 1, 1)];

  _attributedText = mas;
  _textNode.attributedText = _attributedText;
}

- (void)testTruncation
{
  XCTAssertTrue([(ASTextNode *)_textNode shouldTruncateForConstrainedSize:ASSizeRangeMake(CGSizeMake(100, 100))], @"Text Node should truncate");

  _textNode.frame = CGRectMake(0, 0, 100, 100);
  XCTAssertTrue(_textNode.isTruncated, @"Text Node should be truncated");
}

- (void)testAccessibility
{
  XCTAssertTrue(_textNode.isAccessibilityElement, @"Should be an accessibility element");
  XCTAssertTrue(_textNode.accessibilityTraits == UIAccessibilityTraitStaticText,
                @"Should have static text accessibility trait, instead has %llu",
                _textNode.accessibilityTraits);
  XCTAssertTrue(_textNode.defaultAccessibilityTraits == UIAccessibilityTraitStaticText,
                @"Default accessibility traits should return static text accessibility trait, "
                @"instead returns %llu",
                _textNode.defaultAccessibilityTraits);

  XCTAssertTrue([_textNode.accessibilityLabel isEqualToString:_attributedText.string],
                @"Accessibility label is incorrectly set to \n%@\n when it should be \n%@\n",
                _textNode.accessibilityLabel, _attributedText.string);
  XCTAssertTrue([_textNode.defaultAccessibilityLabel isEqualToString:_attributedText.string],
                @"Default accessibility label incorrectly returns \n%@\n when it should be \n%@\n",
                _textNode.defaultAccessibilityLabel, _attributedText.string);
}

- (void)testRespectingAccessibilitySetting
{
  ASTextNode2 *textNode = [[ASTextNode2 alloc] init];
  textNode.attributedText = _attributedText;
  textNode.isAccessibilityElement = NO;
  
  textNode.attributedText = [[NSAttributedString alloc] initWithString:@"new string"];
  XCTAssertFalse(textNode.isAccessibilityElement);
  
  // Ensure removing string on an accessible text node updates the setting.
  ASTextNode2 *accessibleTextNode = [ASTextNode2 new];
  accessibleTextNode.attributedText = _attributedText;
  accessibleTextNode.attributedText = nil;
  XCTAssertFalse(accessibleTextNode.isAccessibilityElement);
}

- (void)testSupportsLayerBacking
{
  ASTextNode2 *textNode = [[ASTextNode2 alloc] init];
  textNode.attributedText = [[NSAttributedString alloc] initWithString:@"new string"];
  XCTAssertTrue(textNode.supportsLayerBacking);

  NSString *link = @"https://texturegroup.com";
  NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Texture Website: %@", link]];
  NSRange linkRange = [attributedText.string rangeOfString:link];
  [attributedText addAttribute:NSLinkAttributeName value:link range:linkRange];
  textNode.attributedText = attributedText;
  XCTAssertFalse(textNode.supportsLayerBacking);
}

- (void)testEmptyStringSize
{
  CGSize constrainedSize = CGSizeMake(100, CGFLOAT_MAX);
  _textNode.attributedText = [[NSAttributedString alloc] initWithString:@""];
  CGSize sizeWithEmptyString = [_textNode layoutThatFits:ASSizeRangeMake(CGSizeZero, constrainedSize)].size;
  XCTAssertTrue(ASIsCGSizeValidForSize(sizeWithEmptyString));
  XCTAssertTrue(sizeWithEmptyString.width == 0);
}

- (void)testCenterAlignedTruncation
{
  ASTextContainer *container = [[ASTextContainer alloc] init];
  container.maximumNumberOfRows = 3;
  container.size = CGSizeMake(400, 800);
  container.truncationType = ASTextTruncationTypeEnd;
  container.truncationToken = [[NSAttributedString alloc] initWithString:@"\u2026"];

  NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
  paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
  paragraphStyle.alignment = NSTextAlignmentCenter;

  NSAttributedString *attributedText = self.textNode.attributedText;

  ASTextLayout *layout = [ASTextLayout layoutWithContainer:container text:attributedText];
  XCTAssertTrue(layout.lines.count == 3);

  CGRect expectedBounds = CGRectMake(3.5060000000000286, 46.061999999999998, 392.98799999999994, 22.32);
  CGRect bounds = layout.truncatedLine.bounds;
  
  XCTAssertTrue(fabs(bounds.origin.x - expectedBounds.origin.x) < FLT_EPSILON);
  XCTAssertTrue(fabs(bounds.origin.y - expectedBounds.origin.y) < FLT_EPSILON);
  XCTAssertTrue(fabs(bounds.size.width - expectedBounds.size.width) < FLT_EPSILON);
  XCTAssertTrue(fabs(bounds.size.height - expectedBounds.size.height) < FLT_EPSILON);  
}

- (void)testPointSizeScaleFactors
{
  ASTextContainer *container = [[ASTextContainer alloc] init];
  container.maximumNumberOfRows = 1;
  container.size = CGSizeMake(300, 800);
  container.truncationType = ASTextTruncationTypeEnd;
  container.truncationToken = [[NSAttributedString alloc] initWithString:@"\u2026"];
  container.pointSizeScaleFactors = @[@0.9, @0.75];
  
  NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:@"This is a string that won't fit in the space that I'm giving it. Poor string. Do you think it hurts when a string gets truncated? I hope not." attributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:16] }];;
  
  ASTextLayout *layout = [ASTextLayout layoutWithContainer:container text:attributedText];
  [layout.text enumerateAttribute:NSFontAttributeName inRange:NSMakeRange(0, layout.text.length) options:0 usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
    // there should only be one font size for the entire string
    XCTAssertTrue(range.length == layout.text.length);
    XCTAssertTrue([(UIFont *)value pointSize] == 12.0);
    XCTAssertTrue(CGSizeEqualToSize(layout.textBoundingSize, CGSizeMake(299, 14)));
  }];
}

- (void)testNonTruncatedCenteredText
{
  CGSize constrainedSize = CGSizeMake(100, 50);
  
  NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
  paragraph.alignment = NSTextAlignmentCenter;
  
  // test that the centered text uses the entire container width
  ASTextNode2 *textNode = [[ASTextNode2 alloc] init];
  textNode.attributedText = [[NSAttributedString alloc] initWithString:@"hi" attributes:@{ NSParagraphStyleAttributeName : paragraph }];
  CGSize size = [textNode layoutThatFits:ASSizeRangeMake(CGSizeZero, constrainedSize)].size;
  XCTAssertTrue(size.width == 100);

  // non centered text should not use the entire container width
  textNode.attributedText = [[NSAttributedString alloc] initWithString:@"hi"];
  size = [textNode layoutThatFits:ASSizeRangeMake(CGSizeZero, constrainedSize)].size;
  XCTAssertTrue(size.width < 20);
}

@end
