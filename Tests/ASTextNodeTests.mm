//
//  ASTextNodeTests.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <CoreText/CoreText.h>

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#import <AsyncDisplayKit/ASAvailability.h>
#import <AsyncDisplayKit/ASLayout.h>
#import <AsyncDisplayKit/ASTextNode.h>
#import <AsyncDisplayKit/ASTextNode+Beta.h>
#import <AsyncDisplayKit/CoreGraphics+ASConvenience.h>

#import "ASTestCase.h"



@interface ASTextNodeTestDelegate : NSObject <ASTextNodeDelegate>

@property (nonatomic, copy, readonly) NSString *tappedLinkAttribute;
@property (nonatomic, readonly) id tappedLinkValue;

@end
@interface ASTextNodeSubclass : ASTextNode
@end
@interface ASTextNodeSecondSubclass : ASTextNodeSubclass
@end

@implementation ASTextNodeTestDelegate

- (void)textNode:(ASTextNode *)textNode tappedLinkAttribute:(NSString *)attribute value:(id)value atPoint:(CGPoint)point textRange:(NSRange)textRange
{
  _tappedLinkAttribute = attribute;
  _tappedLinkValue = value;
}

- (BOOL)textNode:(ASTextNode *)textNode shouldHighlightLinkAttribute:(NSString *)attribute value:(id)value atPoint:(CGPoint)point
{
  return YES;
}

@end

@interface ASTextNodeTests : XCTestCase

@property (nonatomic) ASTextNode *textNode;
@property (nonatomic, copy) NSAttributedString *attributedText;
@property (nonatomic) NSMutableArray *textNodeBucket;

@end

@implementation ASTextNodeTests

- (void)setUp
{
  [super setUp];

  // Reset experimental features to test the first version of ASTextNode.
  ASConfiguration *config = [ASConfiguration new];
  config.experimentalFeatures = kNilOptions;
  [ASConfigurationManager test_resetWithConfiguration:config];
  
  _textNode = [[ASTextNode alloc] init];
  _textNodeBucket = [[NSMutableArray alloc] init];
  
  UIFontDescriptor *desc =
  [UIFontDescriptor fontDescriptorWithName:@"Didot" size:18];
  NSArray *arr =
  @[@{UIFontFeatureTypeIdentifierKey:@(kLetterCaseType),
      UIFontFeatureSelectorIdentifierKey:@(kSmallCapsSelector)}];
  desc =
  [desc fontDescriptorByAddingAttributes:
   @{UIFontDescriptorFeatureSettingsAttribute:arr}];
  UIFont *f = [UIFont fontWithDescriptor:desc size:0];
  NSDictionary *d = @{NSFontAttributeName: f};
  NSMutableAttributedString *mas =
  [[NSMutableAttributedString alloc] initWithString:@"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum." attributes:d];
  NSMutableParagraphStyle *para = [NSMutableParagraphStyle new];
  para.alignment = NSTextAlignmentCenter;
  para.lineSpacing = 1.0;
  [mas addAttribute:NSParagraphStyleAttributeName value:para
              range:NSMakeRange(0, mas.length - 1)];
  
  // Vary the linespacing on the last line
  NSMutableParagraphStyle *lastLinePara = [NSMutableParagraphStyle new];
  lastLinePara.alignment = para.alignment;
  lastLinePara.lineSpacing = 5.0;
  [mas addAttribute:NSParagraphStyleAttributeName value:lastLinePara
              range:NSMakeRange(mas.length - 1, 1)];
  
  _attributedText = mas;
  _textNode.attributedText = _attributedText;
}

#pragma mark - ASTextNode

- (void)testAllocASTextNode
{
  ASTextNode *node = [[ASTextNode alloc] init];
  XCTAssertTrue([[node class] isSubclassOfClass:[ASTextNode class]], @"ASTextNode alloc should return an instance of ASTextNode, instead returned %@", [node class]);
}

#pragma mark - ASTextNode

- (void)testTruncation
{
  XCTAssertTrue([_textNode shouldTruncateForConstrainedSize:ASSizeRangeMake(CGSizeMake(100, 100))], @"");

  _textNode.frame = CGRectMake(0, 0, 100, 100);
  XCTAssertTrue(_textNode.isTruncated, @"Text Node should be truncated");
}

- (void)testSettingTruncationMessage
{
  NSAttributedString *truncation = [[NSAttributedString alloc] initWithString:@"..." attributes:nil];
  _textNode.truncationAttributedText = truncation;
  XCTAssertTrue([_textNode.truncationAttributedText isEqualToAttributedString:truncation], @"Failed to set truncation message");
}

- (void)testSettingAdditionalTruncationMessage
{
  NSAttributedString *additionalTruncationMessage = [[NSAttributedString alloc] initWithString:@"read more" attributes:nil];
  _textNode.additionalTruncationMessage = additionalTruncationMessage;
  XCTAssertTrue([_textNode.additionalTruncationMessage isEqualToAttributedString:additionalTruncationMessage], @"Failed to set additionalTruncationMessage message");
}

- (void)testCalculatedSizeIsGreaterThanOrEqualToConstrainedSize
{
  for (NSInteger i = 10; i < 500; i += 50) {
    CGSize constrainedSize = CGSizeMake(i, i);
    CGSize calculatedSize = [_textNode layoutThatFits:ASSizeRangeMake(CGSizeZero, constrainedSize)].size;
    XCTAssertTrue(calculatedSize.width <= constrainedSize.width, @"Calculated width (%f) should be less than or equal to constrained width (%f)", calculatedSize.width, constrainedSize.width);
    XCTAssertTrue(calculatedSize.height <= constrainedSize.height, @"Calculated height (%f) should be less than or equal to constrained height (%f)", calculatedSize.height, constrainedSize.height);
  }
}

- (void)testRecalculationOfSizeIsSameAsOriginallyCalculatedSize
{
  for (NSInteger i = 10; i < 500; i += 50) {
    CGSize constrainedSize = CGSizeMake(i, i);
    CGSize calculatedSize = [_textNode layoutThatFits:ASSizeRangeMake(CGSizeZero, constrainedSize)].size;
    CGSize recalculatedSize = [_textNode layoutThatFits:ASSizeRangeMake(CGSizeZero, constrainedSize)].size;
    
    XCTAssertTrue(CGSizeEqualToSizeWithIn(calculatedSize, recalculatedSize, 4.0), @"Recalculated size %@ should be same as original size %@", NSStringFromCGSize(recalculatedSize), NSStringFromCGSize(calculatedSize));
  }
}

- (void)testRecalculationOfSizeIsSameAsOriginallyCalculatedFloatingPointSize
{
  for (CGFloat i = 10; i < 500; i *= 1.3) {
    CGSize constrainedSize = CGSizeMake(i, i);
    CGSize calculatedSize = [_textNode layoutThatFits:ASSizeRangeMake(CGSizeZero, constrainedSize)].size;
    CGSize recalculatedSize = [_textNode layoutThatFits:ASSizeRangeMake(CGSizeZero, constrainedSize)].size;

    XCTAssertTrue(CGSizeEqualToSizeWithIn(calculatedSize, recalculatedSize, 11.0), @"Recalculated size %@ should be same as original size %@", NSStringFromCGSize(recalculatedSize), NSStringFromCGSize(calculatedSize));
  }
}

- (void)testMeasureWithZeroSizeAndPlaceholder
{
  _textNode.placeholderEnabled = YES;
  
  XCTAssertNoThrow([_textNode layoutThatFits:ASSizeRangeMake(CGSizeZero, CGSizeZero)], @"Measure with zero size and placeholder enabled should not throw an exception");
  XCTAssertNoThrow([_textNode layoutThatFits:ASSizeRangeMake(CGSizeZero, CGSizeMake(0, 100))], @"Measure with zero width and placeholder enabled should not throw an exception");
  XCTAssertNoThrow([_textNode layoutThatFits:ASSizeRangeMake(CGSizeZero, CGSizeMake(100, 0))], @"Measure with zero height and placeholder enabled should not throw an exception");
}

- (void)testAccessibility
{
  _textNode.attributedText = _attributedText;
  XCTAssertTrue(_textNode.isAccessibilityElement, @"Should be an accessibility element");
  XCTAssertTrue(_textNode.accessibilityTraits == UIAccessibilityTraitStaticText, @"Should have static text accessibility trait, instead has %llu", _textNode.accessibilityTraits);

  XCTAssertTrue([_textNode.accessibilityLabel isEqualToString:_attributedText.string], @"Accessibility label is incorrectly set to \n%@\n when it should be \n%@\n", _textNode.accessibilityLabel, _attributedText.string);
}

- (void)testRespectingAccessibilitySetting
{
  ASTextNode *textNode = [ASTextNode new];
  
  textNode.attributedText = _attributedText;
  textNode.isAccessibilityElement = NO;
  
  textNode.attributedText = [[NSAttributedString alloc] initWithString:@"new string"];
  XCTAssertFalse(textNode.isAccessibilityElement);
  
  // Ensure removing string on an accessible text node updates the setting.
  ASTextNode *accessibleTextNode = [ASTextNode new];
  accessibleTextNode.attributedText = _attributedText;
  accessibleTextNode.attributedText = nil;
  XCTAssertFalse(accessibleTextNode.isAccessibilityElement);
}

- (void)testLinkAttribute
{
  NSString *linkAttributeName = @"MockLinkAttributeName";
  NSString *linkAttributeValue = @"MockLinkAttributeValue";
  NSString *linkString = @"Link";
  NSRange linkRange = NSMakeRange(0, linkString.length);
  NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:linkString attributes:@{ linkAttributeName : linkAttributeValue}];
  _textNode.attributedText = attributedString;
  _textNode.linkAttributeNames = @[linkAttributeName];

  ASTextNodeTestDelegate *delegate = [ASTextNodeTestDelegate new];
  _textNode.delegate = delegate;

  ASLayout *layout = [_textNode layoutThatFits:ASSizeRangeMake(CGSizeZero, CGSizeMake(100, 100))];
  _textNode.frame = CGRectMake(0, 0, layout.size.width, layout.size.height);
  
  NSRange returnedLinkRange;
  NSString *returnedAttributeName;
  NSString *returnedLinkAttributeValue = [_textNode linkAttributeValueAtPoint:CGPointMake(3, 3) attributeName:&returnedAttributeName range:&returnedLinkRange];
  XCTAssertTrue([linkAttributeName isEqualToString:returnedAttributeName], @"Expecting a link attribute name of %@, returned %@", linkAttributeName, returnedAttributeName);
  XCTAssertTrue([linkAttributeValue isEqualToString:returnedLinkAttributeValue], @"Expecting a link attribute value of %@, returned %@", linkAttributeValue, returnedLinkAttributeValue);
  XCTAssertTrue(NSEqualRanges(linkRange, returnedLinkRange), @"Expected a range of %@, got a link range of %@", NSStringFromRange(linkRange), NSStringFromRange(returnedLinkRange));
}

- (void)testTapNotOnALinkAttribute
{
  NSString *linkAttributeName = @"MockLinkAttributeName";
  NSString *linkAttributeValue = @"MockLinkAttributeValue";
  NSString *linkString = @"Link notalink";
  NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:linkString];
  [attributedString addAttribute:linkAttributeName value:linkAttributeValue range:NSMakeRange(0, 4)];
  _textNode.attributedText = attributedString;
  _textNode.linkAttributeNames = @[linkAttributeName];

  ASTextNodeTestDelegate *delegate = [ASTextNodeTestDelegate new];
  _textNode.delegate = delegate;

  CGSize calculatedSize = [_textNode layoutThatFits:ASSizeRangeMake(CGSizeZero, CGSizeMake(100, 100))].size;
  NSRange returnedLinkRange = NSMakeRange(NSNotFound, 0);
  NSRange expectedRange = NSMakeRange(NSNotFound, 0);
  NSString *returnedAttributeName;
  CGPoint pointNearEndOfString = CGPointMake(calculatedSize.width - 3, calculatedSize.height / 2);
  NSString *returnedLinkAttributeValue = [_textNode linkAttributeValueAtPoint:pointNearEndOfString attributeName:&returnedAttributeName range:&returnedLinkRange];
  XCTAssertFalse(returnedAttributeName, @"Expecting no link attribute name, returned %@", returnedAttributeName);
  XCTAssertFalse(returnedLinkAttributeValue, @"Expecting no link attribute value, returned %@", returnedLinkAttributeValue);
  XCTAssertTrue(NSEqualRanges(expectedRange, returnedLinkRange), @"Expected a range of %@, got a link range of %@", NSStringFromRange(expectedRange), NSStringFromRange(returnedLinkRange));

  XCTAssertFalse(delegate.tappedLinkAttribute, @"Expected the delegate to be told that %@ was tapped, instead it thinks the tapped attribute is %@", linkAttributeName, delegate.tappedLinkAttribute);
  XCTAssertFalse(delegate.tappedLinkValue, @"Expected the delegate to be told that the value %@ was tapped, instead it thinks the tapped attribute value is %@", linkAttributeValue, delegate.tappedLinkValue);
}

#pragma mark exclusion Paths

- (void)testSettingExclusionPaths
{
  NSArray *exclusionPaths = @[[UIBezierPath bezierPathWithRect:CGRectMake(10, 20, 30, 40)]];
  _textNode.exclusionPaths = exclusionPaths;
  XCTAssertTrue([_textNode.exclusionPaths isEqualToArray:exclusionPaths], @"Failed to set exclusion paths");
}

- (void)testAddingExclusionPathsShouldInvalidateAndIncreaseTheSize
{
  CGSize constrainedSize = CGSizeMake(100, CGFLOAT_MAX);
  CGSize sizeWithoutExclusionPaths = [_textNode layoutThatFits:ASSizeRangeMake(CGSizeZero, constrainedSize)].size;
  _textNode.exclusionPaths = @[[UIBezierPath bezierPathWithRect:CGRectMake(50, 20, 30, 40)]];
  CGSize sizeWithExclusionPaths = [_textNode layoutThatFits:ASSizeRangeMake(CGSizeZero, constrainedSize)].size;

  XCTAssertGreaterThan(sizeWithExclusionPaths.height, sizeWithoutExclusionPaths.height, @"Setting exclusions paths should invalidate the calculated size and return a greater size");
}

- (void)testEmptyStringSize
{
  CGSize constrainedSize = CGSizeMake(100, CGFLOAT_MAX);
  _textNode.attributedText = [[NSAttributedString alloc] initWithString:@""];
  CGSize sizeWithEmptyString = [_textNode layoutThatFits:ASSizeRangeMake(CGSizeZero, constrainedSize)].size;
  XCTAssertTrue(ASIsCGSizeValidForSize(sizeWithEmptyString));
  XCTAssertTrue(sizeWithEmptyString.width == 0);
}

#if AS_ENABLE_TEXTNODE
- (void)testThatTheExperimentWorksCorrectly
{
  ASConfiguration *config = [ASConfiguration new];
  config.experimentalFeatures = ASExperimentalTextNode;
  [ASConfigurationManager test_resetWithConfiguration:config];
  
  ASTextNode *plainTextNode = [[ASTextNode alloc] init];
  XCTAssertEqualObjects(plainTextNode.class, [ASTextNode2 class]);
  
  ASTextNodeSecondSubclass *sc2 = [[ASTextNodeSecondSubclass alloc] init];
  XCTAssertEqualObjects([ASTextNodeSubclass superclass], [ASTextNode2 class]);
  XCTAssertEqualObjects(sc2.superclass, [ASTextNodeSubclass class]);
}

- (void)testTextNodeSwitchWorksInMultiThreadEnvironment
{
  ASConfiguration *config = [ASConfiguration new];
  config.experimentalFeatures = ASExperimentalTextNode;
  [ASConfigurationManager test_resetWithConfiguration:config];
  XCTestExpectation *exp = [self expectationWithDescription:@"wait for full bucket"];

  dispatch_queue_t queue = dispatch_queue_create("com.texture.AsyncDisplayKit.ASTextNodeTestsQueue", DISPATCH_QUEUE_CONCURRENT);
  dispatch_group_t g = dispatch_group_create();
  for (int i = 0; i < 20; i++) {
    dispatch_group_async(g, queue, ^{
      ASTextNode *textNode = [[ASTextNodeSecondSubclass alloc] init];
      XCTAssert([textNode isKindOfClass:[ASTextNode2 class]]);
      @synchronized(self.textNodeBucket) {
        [self.textNodeBucket addObject:textNode];
        if (self.textNodeBucket.count == 20) {
          [exp fulfill];
        }
      }
    });
  }
  [self waitForExpectations:@[exp] timeout:3];
  exp = nil;
  [self.textNodeBucket removeAllObjects];
}

- (void)testTextNodeSwitchWorksInMultiThreadEnvironment2
{
  ASConfiguration *config = [ASConfiguration new];
  config.experimentalFeatures = ASExperimentalTextNode;
  [ASConfigurationManager test_resetWithConfiguration:config];
  XCTestExpectation *exp = [self expectationWithDescription:@"wait for full bucket"];
 
  NSLock *lock = [[NSLock alloc] init];
  NSMutableArray *textNodeBucket = [[NSMutableArray alloc] init];
  
  dispatch_queue_t queue = dispatch_queue_create("com.texture.AsyncDisplayKit.ASTextNodeTestsQueue", DISPATCH_QUEUE_CONCURRENT);
  dispatch_group_t g = dispatch_group_create();
  for (int i = 0; i < 20; i++) {
    dispatch_group_async(g, queue, ^{
      ASTextNode *textNode = [[ASTextNodeSecondSubclass alloc] init];
      XCTAssert([textNode isKindOfClass:[ASTextNode2 class]]);
      [lock lock];
      [textNodeBucket addObject:textNode];
      if (textNodeBucket.count == 20) {
        [exp fulfill];
      }
      [lock unlock];
    });
  }
  [self waitForExpectations:@[exp] timeout:3];
  exp = nil;
  [textNodeBucket removeAllObjects];
}
#endif

@end

@implementation ASTextNodeSubclass
@end
@implementation ASTextNodeSecondSubclass
@end
