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
#import <AsyncDisplayKit/ASTextNode+Beta.h>
#import <AsyncDisplayKit/ASTextNode2.h>
#import <AsyncDisplayKit/_ASDisplayViewAccessiblity.h>
#import <AsyncDisplayKit/ASTextLayout.h>

#import "ASTestCase.h"
#import "ASDisplayNodeTestsHelper.h"

@interface ASTextNode2Tests : XCTestCase

@property(nonatomic) ASTextNode2 *textNode;
@property(nonatomic, copy) NSAttributedString *attributedText;

@end

@implementation ASTextNode2Tests

- (void)setUp
{
  [super setUp];

  ASSetEnableTextTruncationVisibleRange(NO);
  // Reset configuration on every setup
  ASConfiguration *config = [[ASConfiguration alloc] initWithDictionary:nil];
  [ASConfigurationManager test_resetWithConfiguration:config];

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

- (void)setUpEnablingExperiments {
  BOOL prevValue = ASGetEnableImprovedTextTruncationVisibleRange();
  ASSetEnableImprovedTextTruncationVisibleRange(YES);
  [self addTeardownBlock:^{
    ASSetEnableImprovedTextTruncationVisibleRange(prevValue);
  }];
  BOOL prevLastLineFixValue = ASGetEnableImprovedTextTruncationVisibleRangeLastLineFix();
  ASSetEnableImprovedTextTruncationVisibleRangeLastLineFix(YES);
  [self addTeardownBlock:^{
    ASSetEnableImprovedTextTruncationVisibleRangeLastLineFix(prevLastLineFixValue);
  }];
}

- (void)testTruncation
{
  XCTAssertTrue([(ASTextNode *)_textNode shouldTruncateForConstrainedSize:ASSizeRangeMake(CGSizeMake(100, 100))], @"Text Node should truncate");

  _textNode.frame = CGRectMake(0, 0, 100, 100);
  XCTAssertTrue(_textNode.isTruncated, @"Text Node should be truncated");
}

- (void)testTruncationWithTruncatedLinkAtTheEnd {
  [self setUpEnablingExperiments];

  NSString *link = @"https://medium.com/pinterest-engineering/"
                   @"introducing-texture-a-new-home-for-asyncdisplaykit-e7c003308f50";
  NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc]
      initWithString:[NSString stringWithFormat:@"A link: %@", link]];
  NSRange linkRange = [attributedText.string rangeOfString:link];
  [attributedText addAttribute:NSLinkAttributeName value:link range:linkRange];

  ASTextNode2 *textNode = [[ASTextNode2 alloc] init];
  textNode.attributedText = attributedText;
  textNode.frame = CGRectMake(0, 0, 100, 50);
  textNode.truncationAttributedText = [[NSAttributedString alloc] initWithString:@"...Read More"];
  // Call calculateSizeThatFits: to enforce _truncationToken to be set on _textContainer
  [textNode calculateSizeThatFits:CGSizeMake(100, 50)];
  // Trigger calculation of layouts on the node manually, otherwise the internal
  // text container will not have any size
  [textNode layoutThatFits:ASSizeRangeMake(CGSizeMake(99, 49), CGSizeMake(100, 50))];

  id linkAttribute = nil;
  linkAttribute = [textNode linkAttributeValueAtPoint:CGPointMake(50.0, 40.0)
                                        attributeName:nil
                                                range:nil];
  XCTAssertTrue(linkAttribute == nil, @"Should not trigger the truncated link!");
}

- (void)testClickOnTruncationTokenWithUntruncatedLinkAtTheEnd {
  [self setUpEnablingExperiments];

  // The truncation token is appended to the third line text directly without truncation on the
  // original text.
  NSString *link = @"l1\n l2\n l3\n l4";
  NSMutableAttributedString *attributedText =
      [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", link]];
  NSRange linkRange = [attributedText.string rangeOfString:link];
  [attributedText addAttribute:NSLinkAttributeName value:link range:linkRange];

  ASTextNode2 *textNode = [[ASTextNode2 alloc] init];
  textNode.attributedText = attributedText;
  textNode.frame = CGRectMake(0, 0, 100, 50);
  textNode.truncationAttributedText = [[NSAttributedString alloc] initWithString:@"more"];
  // Call calculateSizeThatFits: to enforce _truncationToken to be set on _textContainer
  [textNode calculateSizeThatFits:CGSizeMake(100, 50)];
  // Trigger calculation of layouts on the node manually, otherwise the internal
  // text container will not have any size
  [textNode layoutThatFits:ASSizeRangeMake(CGSizeMake(99, 49), CGSizeMake(100, 50))];

  // Click on the truncation token.
  id linkAttribute = nil;
  linkAttribute = [textNode linkAttributeValueAtPoint:CGPointMake(30.0, 40.0)
                                        attributeName:nil
                                                range:nil];
  XCTAssertTrue(linkAttribute == nil, @"Should not trigger the link!");

  // Click on the link.
  linkAttribute = nil;
  linkAttribute = [textNode linkAttributeValueAtPoint:CGPointMake(10.0, 40.0)
                                        attributeName:nil
                                                range:nil];
  XCTAssertFalse(linkAttribute == nil, @"Should trigger the link!");
}

- (void)testClickNearBordersOfTruncationToken {
  [self setUpEnablingExperiments];

  NSString *link = @"https://medium.com/pinterest-engineering/"
                   @"introducing-texture-a-new-home-for-asyncdisplaykit-e7c003308f50";
  NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc]
      initWithString:[NSString stringWithFormat:@"A link: %@", link]];
  NSRange linkRange = [attributedText.string rangeOfString:link];
  [attributedText addAttribute:NSLinkAttributeName value:link range:linkRange];

  ASTextNode2 *textNode = [[ASTextNode2 alloc] init];
  textNode.attributedText = attributedText;
  textNode.frame = CGRectMake(0, 0, 100, 50);
  textNode.truncationAttributedText = [[NSAttributedString alloc] initWithString:@"...Read More"];
  // Call calculateSizeThatFits: to enforce _truncationToken to be set on _textContainer
  [textNode calculateSizeThatFits:CGSizeMake(100, 50)];
  // Trigger calculation of layouts on the node manually, otherwise the internal
  // text container will not have any size
  [textNode layoutThatFits:ASSizeRangeMake(CGSizeMake(99, 49), CGSizeMake(100, 50))];

  // The bounds of the last line before the truncation token is:
  // origin: (x = 0, y = 32.76)  size: (width = 30.02, height = 12)

  id linkAttribute = nil;
  linkAttribute = [textNode linkAttributeValueAtPoint:CGPointMake(31.0, 40.0)
                                        attributeName:nil
                                                range:nil];

  XCTAssertNil(linkAttribute, @"Should not trigger the truncated link, since the click is "
                              @"inside the truncation token bounds!");

  linkAttribute = nil;
  linkAttribute = [textNode linkAttributeValueAtPoint:CGPointMake(30.0, 40.0)
                                        attributeName:nil
                                                range:nil];
  XCTAssertNotNil(
      linkAttribute,
      @"Should trigger the truncated link, since the click is left to the truncation token!");

  linkAttribute = nil;
  linkAttribute = [textNode linkAttributeValueAtPoint:CGPointMake(40.0, 33.0)
                                        attributeName:nil
                                                range:nil];
  XCTAssertNil(linkAttribute, @"Should not trigger the truncated link, since the click is "
                              @"inside the truncation token bounds!");

  linkAttribute = nil;
  linkAttribute = [textNode linkAttributeValueAtPoint:CGPointMake(40.0, 32.0)
                                        attributeName:nil
                                                range:nil];
  XCTAssertNotNil(
      linkAttribute,
      @"Should trigger the truncated link, since the click is above the truncation token!");
}

- (void)testUntruncatedLinkWithTruncationAttributedTextSet {
  [self setUpEnablingExperiments];

  NSString *link = @"https://texturegroup.org/";
  NSMutableAttributedString *attributedText =
      [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", link]];
  NSRange linkRange = [attributedText.string rangeOfString:link];
  [attributedText addAttribute:NSLinkAttributeName value:link range:linkRange];

  ASTextNode2 *textNode = [[ASTextNode2 alloc] init];
  textNode.attributedText = attributedText;
  textNode.frame = CGRectMake(0, 0, 100, 100);
  textNode.truncationAttributedText = [[NSAttributedString alloc] initWithString:@"...Read More"];
  // Call calculateSizeThatFits: to enforce _truncationToken to be set on _textContainer
  [textNode calculateSizeThatFits:CGSizeMake(100, 100)];
  // Trigger calculation of layouts on the node manually, otherwise the internal
  // text container will not have any size
  [textNode layoutThatFits:ASSizeRangeMake(CGSizeMake(99, 99), CGSizeMake(100, 100))];

  id linkAttribute = nil;
  linkAttribute = [textNode linkAttributeValueAtPoint:CGPointMake(15.0, 10.0)
                                        attributeName:nil
                                                range:nil];
  XCTAssertTrue(
      ![textNode isTruncated],
      @"The text node should not be truncated even when truncationAttributedText is set!");
  XCTAssertTrue(linkAttribute != nil, @"Should trigger the untruncated link at this point!");
}

- (void)testBasicAccessibility
{
  XCTAssertFalse(_textNode.isAccessibilityElement, @"Should not be an accessibility element");
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

- (void)testBasicAccessibilityWithExperiments
{
  // Create text node explicitly as using the _textNode it's too late for the experiment setup
  ASTextNode2 *textNode = [[ASTextNode2 alloc] init];
  textNode.attributedText = _attributedText;
  XCTAssertFalse(textNode.isAccessibilityElement, @"Is not an accessiblity element as it's a UIAccessibilityContainer");
  XCTAssertTrue(textNode.accessibilityTraits == UIAccessibilityTraitStaticText,
                @"Should have static text accessibility trait, instead has %llu",
                textNode.accessibilityTraits);
  XCTAssertTrue(textNode.defaultAccessibilityTraits == UIAccessibilityTraitStaticText,
                @"Default accessibility traits should return static text accessibility trait, "
                @"instead returns %llu",
                textNode.defaultAccessibilityTraits);

  XCTAssertTrue([textNode.accessibilityLabel isEqualToString:_attributedText.string],
                @"Accessibility label is incorrectly set to \n%@\n when it should be \n%@\n",
                textNode.accessibilityLabel, _attributedText.string);
  XCTAssertTrue([textNode.defaultAccessibilityLabel isEqualToString:_attributedText.string],
                @"Default accessibility label incorrectly returns \n%@\n when it should be \n%@\n",
                textNode.defaultAccessibilityLabel, _attributedText.string);

  XCTAssertTrue(textNode.accessibilityElements.count == 1, @"Accessibility elements should exist");
  XCTAssertTrue([[textNode.accessibilityElements[0] accessibilityLabel] isEqualToString:_attributedText.string],
                @"First accessibility element incorrectly returns \n%@\n when it should be \n%@\n",
                [textNode.accessibilityElements[0] accessibilityLabel], textNode.accessibilityLabel);
  XCTAssertTrue([[textNode.accessibilityElements[0] accessibilityLabel] isEqualToString:_attributedText.string],
                @"First accessibility element incorrectly returns \n%@\n when it should be \n%@\n",
                [textNode.accessibilityElements[0] accessibilityLabel], textNode.accessibilityLabel);
}

- (void)testAccessibilityLayerBackedContainerAndTextNode2
{
  ASDisplayNode *container = [[ASDisplayNode alloc] init];
  container.frame = CGRectMake(50, 50, 200, 600);
  container.backgroundColor = [UIColor grayColor];
  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 560)];
  [window addSubnode:container];
  [window makeKeyAndVisible];
  ASDisplayNode *layerBackedContainer = [[ASDisplayNode alloc] init];
  layerBackedContainer.layerBacked = YES;
  layerBackedContainer.frame = CGRectMake(50, 50, 200, 600);
  layerBackedContainer.backgroundColor = [UIColor grayColor];
  [container addSubnode:layerBackedContainer];

  ASTextNode2 *text = [[ASTextNode2 alloc] init];
  text.layerBacked = YES;
  text.attributedText = [[NSAttributedString alloc] initWithString:@"hello"];
  text.frame = CGRectMake(50, 100, 200, 200);
  [layerBackedContainer addSubnode:text];

  ASTextNode2 *text2 = [[ASTextNode2 alloc] init];
  text2.layerBacked = YES;
  text2.attributedText = [[NSAttributedString alloc] initWithString:@"world"];
  text2.frame = CGRectMake(50, 100, 200, 200);
  [layerBackedContainer addSubnode:text2];

  NSArray<UIAccessibilityElement *> *elements = container.view.accessibilityElements;
  XCTAssertEqual(elements.count, 2);
  XCTAssertEqualObjects([elements[0] accessibilityLabel], @"hello");
  XCTAssertEqualObjects([elements[1] accessibilityLabel], @"world");
}

- (void)testAccessibilityLayerBackedContainerAndTextNode2WithExperiments
{
  [self testAccessibilityLayerBackedContainerAndTextNode2];
}

- (void)testAccessibilityLayerBackedTextNode2WithExperiments
{
  ASDisplayNode *container = [[ASDisplayNode alloc] init];
  container.frame = CGRectMake(0, 0, 200, 600);
  container.backgroundColor = [UIColor grayColor];
  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 560)];
  [window addSubnode:container];
  [window makeKeyAndVisible];
  ASTextNode2 *text = [[ASTextNode2 alloc] init];
  text.layerBacked = YES;
  text.attributedText = [[NSAttributedString alloc] initWithString:@"hello"];
  text.frame = CGRectMake(50, 100, 200, 200);
  [container addSubnode:text];

  // Trigger calculation of layouts on both nodes manually otherwise the internal
  // text container will not have any size and the accessibility elements are not layed out
  // properly
  (void)[text layoutThatFits:ASSizeRangeMake(CGSizeZero, container.frame.size)];
  (void)[container layoutThatFits:ASSizeRangeMake(CGSizeZero, container.frame.size)];
  [container layoutIfNeeded];
  [container.layer displayIfNeeded];

  NSArray<UIAccessibilityElement *> *elements = container.view.accessibilityElements;
  XCTAssertEqual(elements.count, 1);

  UIAccessibilityElement *firstElement = elements.firstObject;
  XCTAssertEqualObjects(firstElement.accessibilityLabel, @"hello");
  XCTAssertEqual(YES, CGRectEqualToRect(CGRectMake(50, 102, 26, 13), CGRectIntegral(firstElement.accessibilityFrame)));
}


- (void)testThatASTextNode2SubnodeAccessibilityLabelAggregationWorks
{
  // Setup nodes
  ASDisplayNode *node = [[ASDisplayNode alloc] init];
  ASTextNode2 *innerNode1 = [[ASTextNode2 alloc] init];
  ASTextNode2 *innerNode2 = [[ASTextNode2 alloc] init];
  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 560)];
  [window addSubnode:node];
  [window makeKeyAndVisible];
  // Initialize nodes with relevant accessibility data
  node.isAccessibilityContainer = YES;
  innerNode1.attributedText = [[NSAttributedString alloc] initWithString:@"hello"];
  innerNode2.attributedText = [[NSAttributedString alloc] initWithString:@"world"];

  // Attach the subnodes to the parent node, then ensure their accessibility labels have been'
  // aggregated to the parent's accessibility label
  [node addSubnode:innerNode1];
  [node addSubnode:innerNode2];
  XCTAssertEqualObjects([node.view.accessibilityElements.firstObject accessibilityLabel],
                        @"hello, world", @"Subnode accessibility label aggregation broken %@",
                        [node.view.accessibilityElements.firstObject accessibilityLabel]);
}

- (void)testThatASTextNode2SubnodeAccessibilityLabelAggregationWorksWithExperiments
{
  [self testThatASTextNode2SubnodeAccessibilityLabelAggregationWorks];
}

- (void)testThatLayeredBackedASTextNode2SubnodeAccessibilityLabelAggregationWorks
{
  // Setup nodes
  ASDisplayNode *node = [[ASDisplayNode alloc] init];
  ASTextNode2 *innerNode1 = [[ASTextNode2 alloc] init];
  innerNode1.layerBacked = YES;
  ASTextNode2 *innerNode2 = [[ASTextNode2 alloc] init];
  innerNode2.layerBacked = YES;
  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 560)];
  [window addSubnode:node];
  [window makeKeyAndVisible];
  // Initialize nodes with relevant accessibility data
  node.isAccessibilityContainer = YES;
  innerNode1.attributedText = [[NSAttributedString alloc] initWithString:@"hello"];
  innerNode2.attributedText = [[NSAttributedString alloc] initWithString:@"world"];

  // Attach the subnodes to the parent node, then ensure their accessibility labels have been'
  // aggregated to the parent's accessibility label
  [node addSubnode:innerNode1];
  [node addSubnode:innerNode2];
  XCTAssertEqualObjects([node.view.accessibilityElements.firstObject accessibilityLabel],
                        @"hello, world", @"Subnode accessibility label aggregation broken %@",
                        [node.view.accessibilityElements.firstObject accessibilityLabel]);

}

- (void)testThatLayeredBackedASTextNode2SubnodeAccessibilityLabelAggregationWorksWithExperiments
{
  [self testThatLayeredBackedASTextNode2SubnodeAccessibilityLabelAggregationWorks];
}

- (void)testThatASTextNode2SubnodeCustomActionsAreWorking
{
  ASDisplayNode *node = [[ASDisplayNode alloc] init];
  ASTextNode2 *innerNode1 = [[ASTextNode2 alloc] init];
  innerNode1.accessibilityTraits = UIAccessibilityTraitButton;
  ASTextNode2 *innerNode2 = [[ASTextNode2 alloc] init];
  innerNode2.accessibilityTraits = UIAccessibilityTraitButton;
  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 560)];
  [window addSubnode:node];
  [window makeKeyAndVisible];
  // Initialize nodes with relevant accessibility data
  node.isAccessibilityContainer = YES;
  innerNode1.attributedText = [[NSAttributedString alloc] initWithString:@"hello"];
  innerNode2.attributedText = [[NSAttributedString alloc] initWithString:@"world"];

  // Attach the subnodes to the parent node, then ensure their accessibility labels have been'
  // aggregated to the parent's accessibility label
  [node addSubnode:innerNode1];
  [node addSubnode:innerNode2];

  NSArray<UIAccessibilityElement *> *accessibilityElements = node.view.accessibilityElements;
  XCTAssertEqual(accessibilityElements.count, 1, @"Container node should have one accessibility element for custom actions");

  NSArray<UIAccessibilityCustomAction *> *accessibilityCustomActions = accessibilityElements.firstObject.accessibilityCustomActions;
  XCTAssertEqual(accessibilityCustomActions.count, 2, @"Text nodes should be exposed as a11y custom actions.");
}

- (void)testThatASTextNode2SubnodeCustomActionsAreWorkingWithExperiments
{
  [self testThatASTextNode2SubnodeCustomActionsAreWorking];
}

- (void)testAccessibilityExposeA11YLinksWithExperiments
{
  NSString *link = @"https://texturegroup.com";
  NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Texture Website: %@", link]];
  NSRange linkRange = [attributedText.string rangeOfString:link];
  [attributedText addAttribute:NSLinkAttributeName value:link range:linkRange];

  _textNode.attributedText = attributedText;

  NSArray<UIAccessibilityElement *> *accessibilityElements = _textNode.accessibilityElements;
  XCTAssertEqual(accessibilityElements.count, 2, @"Link should be exposed as accessibility element");

  XCTAssertEqualObjects([accessibilityElements[0] accessibilityLabel], attributedText.string, @"First accessibility element should be the full text");
  XCTAssertEqualObjects([accessibilityElements[1] accessibilityLabel], link, @"Second accessibility element should be the link");
}

- (void)testAccessibilityNonLayerbackedNodesOperationInNonContainer
{
  ASDisplayNode *container = [[ASDisplayNode alloc] init];
  container.frame = CGRectMake(50, 50, 200, 600);
  container.backgroundColor = [UIColor grayColor];
  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 560)];
  [window addSubnode:container];
  [window makeKeyAndVisible];
  // Do any additional setup after loading the view, typically from a nib.
  ASTextNode2 *text1 = [[ASTextNode2 alloc] init];
  text1.attributedText = [[NSAttributedString alloc] initWithString:@"hello"];
  text1.frame = CGRectMake(50, 100, 200, 200);
  [container addSubnode:text1];
  [container layoutIfNeeded];
  [container.layer displayIfNeeded];
  NSArray<UIAccessibilityElement *> *elements = container.view.accessibilityElements;
  XCTAssertEqual(elements.count, 1);
  XCTAssertEqualObjects([elements.firstObject accessibilityLabel], @"hello");
  ASTextNode2 *text2 = [[ASTextNode2 alloc] init];
  text2.attributedText = [[NSAttributedString alloc] initWithString:@"world"];
  text2.frame = CGRectMake(50, 300, 200, 200);
  [container addSubnode:text2];
  [container layoutIfNeeded];
  [container.layer displayIfNeeded];
  NSArray<UIAccessibilityElement *> *updatedElements = container.view.accessibilityElements;
  XCTAssertEqual(updatedElements.count, 2);
  XCTAssertEqualObjects([updatedElements.firstObject accessibilityLabel], @"hello");
  XCTAssertEqualObjects([updatedElements.lastObject accessibilityLabel], @"world");
  ASTextNode2 *text3 = [[ASTextNode2 alloc] init];
  text3.attributedText = [[NSAttributedString alloc] initWithString:@"!!!!"];
  text3.frame = CGRectMake(50, 400, 200, 100);
  [text2 addSubnode:text3];
  [container layoutIfNeeded];
  [container.layer displayIfNeeded];
  NSArray<UIAccessibilityElement *> *updatedElements2 = container.view.accessibilityElements;
  //text3 won't be read out cause it's overshadowed by text2
  XCTAssertEqual(updatedElements2.count, 2);
  XCTAssertEqualObjects([updatedElements2.firstObject accessibilityLabel], @"hello");
  XCTAssertEqualObjects([updatedElements2.lastObject accessibilityLabel], @"world");
}

- (void)testAccessibilityNonLayerbackedNodesOperationInNonContainerWithExperiment
{
  [self testAccessibilityNonLayerbackedNodesOperationInNonContainer];
}

- (void)testAccessibilityNonLayerbackedNodesOperationInNonContainerWithWindow
{
  ASDisplayNode *container = [[ASDisplayNode alloc] init];
  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 560)];
  [window addSubnode:container];
  [window makeKeyAndVisible];

  container.frame = CGRectMake(50, 50, 200, 600);
  container.backgroundColor = [UIColor grayColor];
  // Do any additional setup after loading the view, typically from a nib.
  ASTextNode2 *text1 = [[ASTextNode2 alloc] init];
  text1.attributedText = [[NSAttributedString alloc] initWithString:@"hello"];
  text1.frame = CGRectMake(50, 100, 200, 200);
  [container addSubnode:text1];
  [container layoutIfNeeded];
  [container.layer displayIfNeeded];
  NSArray<UIAccessibilityElement *> *elements = container.view.accessibilityElements;
  XCTAssertEqual(elements.count, 1);
  XCTAssertEqualObjects([elements.firstObject accessibilityLabel], @"hello");
  ASTextNode2 *text2 = [[ASTextNode2 alloc] init];
  text2.attributedText = [[NSAttributedString alloc] initWithString:@"world"];
  text2.frame = CGRectMake(50, 300, 200, 200);
  [container addSubnode:text2];
  [container layoutIfNeeded];
  [container.layer displayIfNeeded];
  ASCATransactionQueueWait(nil);
  NSArray<UIAccessibilityElement *> *updatedElements = container.view.accessibilityElements;
  XCTAssertEqual(updatedElements.count, 2);
  XCTAssertEqualObjects([updatedElements.firstObject accessibilityLabel], @"hello");
  XCTAssertEqualObjects([updatedElements.lastObject accessibilityLabel], @"world");
  ASTextNode2 *text3 = [[ASTextNode2 alloc] init];
  text3.attributedText = [[NSAttributedString alloc] initWithString:@"!!!!"];
  text3.frame = CGRectMake(50, 400, 200, 100);
  [text2 addSubnode:text3];
  [container layoutIfNeeded];
  [container.layer displayIfNeeded];
  ASCATransactionQueueWait(nil);
  NSArray<UIAccessibilityElement *> *updatedElements2 = container.view.accessibilityElements;
  //text3 won't be read out cause it's overshadowed by text2
  XCTAssertEqual(updatedElements2.count, 2);
  XCTAssertEqualObjects([updatedElements2.firstObject accessibilityLabel], @"hello");
  XCTAssertEqualObjects([updatedElements2.lastObject accessibilityLabel], @"world");
}

- (void)testAccessibilityNonLayerbackedNodesOperationInNonContainerWithWindowWithExperiment
{
  [self testAccessibilityNonLayerbackedNodesOperationInNonContainerWithWindow];
}

- (void)testTextNode2AccessibilityTraits
{
  ASDisplayNode *container = [[ASDisplayNode alloc] init];
  container.accessibilityTraits = UIAccessibilityTraitButton;
  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 560)];
  [window addSubnode:container];
  [window makeKeyAndVisible];
  ASTextNode2 *text1 = [[ASTextNode2 alloc] init];
  text1.layerBacked = YES;
  text1.attributedText = [[NSAttributedString alloc] initWithString:@"hello"];
  text1.frame = CGRectMake(50, 100, 200, 200);
  text1.accessibilityTraits = UIAccessibilityTraitButton;
  [container addSubnode:text1];
  NSArray<UIAccessibilityElement *> *elements = container.view.accessibilityElements;

  XCTAssertTrue(elements.count == 1);
  XCTAssertTrue([[elements objectAtIndex:0] accessibilityTraits] & UIAccessibilityTraitButton);
}

- (void)testTextNode2AccessibilityTraitsWithExperiments
{
  [self testTextNode2AccessibilityTraits];
}

- (void)testExposingLinkCustomActionsForAccessibilityContainer
{
  ASDisplayNode *container = [[ASDisplayNode alloc] init];

  // Set container as accessibility container to expose the links as accessibility custom actions
  container.isAccessibilityContainer = YES;
  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 560)];
  [window addSubnode:container];
  [window makeKeyAndVisible];
  ASTextNode2 *text1 = [[ASTextNode2 alloc] init];
  [container addSubnode:text1];

  // This text node is explicitly marked as not layer backed as links are existing
  text1.layerBacked = NO;

  NSString *link = @"https://texturegroup.com";
  NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Texture Website: %@", link]];
  NSRange linkRange = [attributedText.string rangeOfString:link];
  [attributedText addAttribute:NSLinkAttributeName value:link range:linkRange];

  text1.attributedText = attributedText;

  NSArray<UIAccessibilityElement *> *elements = container.view.accessibilityElements;
  XCTAssertEqual(elements.count, 1, @"First element should be a representation of the ASTextNode");
  XCTAssertEqualObjects(elements.firstObject.accessibilityLabel, attributedText.string);

  NSArray<UIAccessibilityCustomAction *> *accessibilityActions = elements.firstObject.accessibilityCustomActions;
  XCTAssertEqual(accessibilityActions.count, 1, @"Link should be exposed as accessibility custom action on the ASTextNode accessibility element");
  XCTAssertEqualObjects(accessibilityActions.firstObject.name, link);
  XCTAssertTrue([accessibilityActions[0] isKindOfClass:[ASAccessibilityCustomAction class]]);
  XCTAssertEqualObjects(((ASAccessibilityCustomAction*)accessibilityActions[0]).value, link);
}

- (void)testExposingLinkAccessibleElementsForNonAccessibilityContainer
{
  ASDisplayNode *container = [[ASDisplayNode alloc] init];

  // This container is explicitly no accessibility container to expose the links within the
  // text node as UIAccessibilityElement
  container.isAccessibilityContainer = NO;
  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 560)];
  [window addSubnode:container];
  [window makeKeyAndVisible];
  ASTextNode2 *text = [[ASTextNode2 alloc] init];
  [container addSubnode:text];

  // This text node is explicitly marked as not layer backed as links are existing
  text.layerBacked = NO;

  NSString *link = @"https://texturegroup.com";
  NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Texture Website: %@", link]];
  NSRange linkRange = [attributedText.string rangeOfString:link];
  [attributedText addAttribute:NSLinkAttributeName value:link range:linkRange];
  text.attributedText = attributedText;

  NSArray<UIAccessibilityElement *> *elements = container.view.accessibilityElements;
  XCTAssertEqual(elements.count, 1, @"TBD");

  NSArray<UIAccessibilityElement *> *textElements = elements.firstObject.accessibilityElements;
  XCTAssertEqual(textElements.count, 2, @"Link should be exposed as accessibility element");

  // First one should be whole text node
  XCTAssertEqualObjects(textElements.firstObject.accessibilityLabel, attributedText.string);

  // Second should represent the link
  XCTAssertEqualObjects(textElements[1].accessibilityLabel, link);
  XCTAssertEqual(textElements[1].accessibilityTraits, UIAccessibilityTraitLink);
}

// Please note: This test is disabled as it needs to be run with the Accessibility Inspector started
// at least once. This is most of the time not the case for CIs
- (void)disabled_testAccessibilityTwoTextNodesAndOneLayerBackedAndOneWithLinks
{
  ASDisplayNode *container = [[ASDisplayNode alloc] init];
  container.frame = CGRectMake(50, 50, 200, 600);
  container.isAccessibilityContainer = NO;

  ASDisplayNode *subContainer = [[ASDisplayNode alloc] init];
  // As text has a link this node can not be layer backed
  subContainer.frame = CGRectMake(50, 50, 200, 600);
  subContainer.layerBacked = NO;
  subContainer.isAccessibilityContainer = NO;
  [container addSubnode:subContainer];

  ASTextNode2 *text = [[ASTextNode2 alloc] init];
  [subContainer addSubnode:text];

  // This text node is explicitly marked as not layer backed as links are existing
  text.layerBacked = NO;

  NSString *link = @"https://texturegroup.com";
  NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Texture Website: %@", link]];
  NSRange linkRange = [attributedText.string rangeOfString:link];
  [attributedText addAttribute:NSLinkAttributeName value:link range:linkRange];

  text.attributedText = attributedText;

  ASTextNode2 *text2 = [[ASTextNode2 alloc] init];
  text2.layerBacked = YES;
  text2.attributedText = [[NSAttributedString alloc] initWithString:@"world"];
  [subContainer addSubnode:text2];

  NSArray<UIAccessibilityElement *> *elements = container.view.accessibilityElements;
  // The first element will be the view of the subContainer
  XCTAssertEqual(elements.count, 1);

  elements = [elements.firstObject accessibilityElements];
  // The first element will be the view of the text1, the second is the UIAccessibilityElement representation of the text2
  XCTAssertEqual(elements.count, 2);
  XCTAssertEqualObjects([elements[1] accessibilityLabel], @"world");

  elements = [elements.firstObject accessibilityElements];
  // The first element will be the UIAccessibilityElement for the whole text of text, the second element will be the UIAccessibilityElement representation for the link
  XCTAssertEqual(elements.count, 2);
  XCTAssertEqualObjects([elements[0] accessibilityLabel], attributedText.string);
  XCTAssertEqualObjects([elements[1] accessibilityLabel], link);
  XCTAssertTrue(([elements[1] accessibilityTraits] & UIAccessibilityTraitLink), @"Accessibility elements need to have an element with a UIAccessibilityTraitLink trait set on");
}

- (void)testAccessibilityContainerTwoTextNodesAndOneLayerBackedAndOneWithLinks
{
  ASDisplayNode *container = [[ASDisplayNode alloc] init];

  // Main container is an accessibility container
  container.isAccessibilityContainer = YES;
  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 560)];
  [window addSubnode:container];
  [window makeKeyAndVisible];
  ASDisplayNode *subContainer = [[ASDisplayNode alloc] init];
  // As text has a link this node can not be layer backed
  subContainer.layerBacked = NO;
  subContainer.backgroundColor = [UIColor grayColor];
  subContainer.isAccessibilityContainer = NO;
  [container addSubnode:subContainer];

  ASTextNode2 *text = [[ASTextNode2 alloc] init];
  [subContainer addSubnode:text];

  // This text node is explicitly marked as not layer backed as links are existing
  text.layerBacked = NO;

  NSString *link = @"https://texturegroup.com";
  NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Texture Website: %@", link]];
  NSRange linkRange = [attributedText.string rangeOfString:link];
  [attributedText addAttribute:NSLinkAttributeName value:link range:linkRange];

  text.attributedText = attributedText;

  ASTextNode2 *text2 = [[ASTextNode2 alloc] init];
  text2.layerBacked = YES;
  text2.attributedText = [[NSAttributedString alloc] initWithString:@"world"];
  [subContainer addSubnode:text2];

  NSArray<UIAccessibilityElement *> *elements = container.view.accessibilityElements;
  // The first element will be ASAccessibilityElement representation of the container with the aggregated accessibilityLabels
  XCTAssertEqual(elements.count, 1);
  XCTAssertEqualObjects([elements[0] accessibilityLabel], @"Texture Website: https://texturegroup.com, world");

  NSArray<UIAccessibilityCustomAction *> *elementCustomActions = elements.firstObject.accessibilityCustomActions;

  // The first action represents the link of text
  XCTAssertEqual(elementCustomActions.count, 1);
  XCTAssertEqualObjects(elementCustomActions[0].name, link);
  XCTAssertTrue([elementCustomActions[0] isKindOfClass:[ASAccessibilityCustomAction class]]);
  XCTAssertEqualObjects(((ASAccessibilityCustomAction*)elementCustomActions[0]).value, link);
}

- (void)testAccessibilityMultipleContainerTwoTextNodesAndOneLayerBackedAndOneWithLinks
{
  ASDisplayNode *container = [[ASDisplayNode alloc] init];

  // Main container is an accessibility container
  container.isAccessibilityContainer = YES;
  UIWindow *window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 320, 560)];
  [window addSubnode:container];
  [window makeKeyAndVisible];
  ASDisplayNode *subContainer = [[ASDisplayNode alloc] init];
  // As text has a link this node can not be layer backed
  subContainer.layerBacked = NO;
  subContainer.backgroundColor = [UIColor grayColor];
  [container addSubnode:subContainer];

  // Sub container is an accessibility container
  subContainer.isAccessibilityContainer = YES;

  ASTextNode2 *text = [[ASTextNode2 alloc] init];
  [subContainer addSubnode:text];

  // This text node is explicitly marked as not layer backed as links are existing
  text.layerBacked = NO;

  NSString *link = @"https://texturegroup.com";
  NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Texture Website: %@", link]];
  NSRange linkRange = [attributedText.string rangeOfString:link];
  [attributedText addAttribute:NSLinkAttributeName value:link range:linkRange];

  text.attributedText = attributedText;

  ASTextNode2 *text2 = [[ASTextNode2 alloc] init];
  text2.layerBacked = YES;
  text2.attributedText = [[NSAttributedString alloc] initWithString:@"world"];
  [subContainer addSubnode:text2];

  NSArray<UIAccessibilityElement *> *elements = container.view.accessibilityElements;

  // Everything is promoted to the container
  XCTAssertEqual(elements.count, 2);
  XCTAssertEqualObjects([elements[0] accessibilityLabel], @"Texture Website: https://texturegroup.com, world");

  NSArray<UIAccessibilityCustomAction *> *elementCustomActions = elements[0].accessibilityCustomActions;
  // The first action represents the link of text
  XCTAssertEqual(elementCustomActions.count, 1);
  XCTAssertEqualObjects(elementCustomActions[0].name, link);
  XCTAssertEqualObjects(((ASAccessibilityCustomAction*)elementCustomActions[0]).value, link);
}

- (void)testTappingLinkAtTheBeginningSingleline
{
  NSString *link = @"https://texturegroup.com";
  NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ - Texture Website", link]];
  NSRange linkRange = [attributedText.string rangeOfString:link];
  [attributedText addAttribute:NSLinkAttributeName value:link range:linkRange];

  ASTextNode2 *textNode = [[ASTextNode2 alloc] init];
  textNode.attributedText = attributedText;
  [textNode layoutThatFits:ASSizeRangeMake(CGSizeZero, CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];

  id linkAttribute = nil;

  linkAttribute = [textNode linkAttributeValueAtPoint:CGPointMake(2.0, 5.0) attributeName:nil range:nil];
  XCTAssertTrue(linkAttribute != nil);

  linkAttribute = [textNode linkAttributeValueAtPoint:CGPointMake(200.0, 5.0) attributeName:nil range:nil];
  XCTAssertTrue(linkAttribute == nil);
}

- (void)testTappingLinkAtTheBeginningMultiline
{
  NSString *link = @"https://texturegroup.com";
  NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ - Texture Website"
                       @"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor "
                       @"incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud", link]];
  NSRange linkRange = [attributedText.string rangeOfString:link];
  [attributedText addAttribute:NSLinkAttributeName value:link range:linkRange];

  ASTextNode2 *textNode = [[ASTextNode2 alloc] init];
  textNode.attributedText = attributedText;
  [textNode layoutThatFits:ASSizeRangeMake(CGSizeZero, CGSizeMake(200.0, CGFLOAT_MAX))];

  XCTAssertTrue(textNode.lineCount > 1);

  id linkAttribute = nil;

  linkAttribute = [textNode linkAttributeValueAtPoint:CGPointMake(2.0, 5.0) attributeName:nil range:nil];
  XCTAssertTrue(linkAttribute != nil);

  linkAttribute = [textNode linkAttributeValueAtPoint:CGPointMake(200.0, 2.0) attributeName:nil range:nil];
  XCTAssertTrue(linkAttribute == nil);
}

- (void)testTappingLinkInTheMiddleSingleline
{
  NSString *link = @"https://texturegroup.com";
  NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Texture %@ Website", link]];
  NSRange linkRange = [attributedText.string rangeOfString:link];
  [attributedText addAttribute:NSLinkAttributeName value:link range:linkRange];

  ASTextNode2 *textNode = [[ASTextNode2 alloc] init];
  textNode.attributedText = attributedText;
  [textNode layoutThatFits:ASSizeRangeMake(CGSizeZero, CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX))];

  id linkAttribute = nil;

  linkAttribute = [textNode linkAttributeValueAtPoint:CGPointMake(40.0, 5.0) attributeName:nil range:nil];
  XCTAssertTrue(linkAttribute != nil);

  linkAttribute = [textNode linkAttributeValueAtPoint:CGPointMake(2.0, 5.0) attributeName:nil range:nil];
  XCTAssertTrue(linkAttribute == nil);
}

- (void)testTappingNonLinkAfterFirstLine
{
  NSString *link = @"https://texturegroup.com";
  NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ - Texture Website"
                       @"Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor "
                       @"incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud", link]];
  NSRange linkRange = [attributedText.string rangeOfString:link];
  [attributedText addAttribute:NSLinkAttributeName value:link range:linkRange];

  ASTextNode2 *textNode = [[ASTextNode2 alloc] init];
  textNode.attributedText = attributedText;
  [textNode layoutThatFits:ASSizeRangeMake(CGSizeZero, CGSizeMake(200.0, CGFLOAT_MAX))];

  XCTAssertTrue(textNode.lineCount > 1);

  id linkAttribute = nil;

  linkAttribute = [textNode linkAttributeValueAtPoint:CGPointMake(2.0, 50.0) attributeName:nil range:nil];
  XCTAssertTrue(linkAttribute == nil);
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

@end
