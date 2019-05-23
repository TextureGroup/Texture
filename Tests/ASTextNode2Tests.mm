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

@interface ASTextNode2Tests : XCTestCase

@property(nonatomic) ASTextNode2 *textNode;
@property(nonatomic, copy) NSAttributedString *attributedText;

@end

@implementation ASTextNode2Tests

- (void)setUp
{
  [super setUp];

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

- (void)setUpEnablingExperiments
{
  ASConfiguration *config = [[ASConfiguration alloc] initWithDictionary:nil];
  config.experimentalFeatures = ASExperimentalTextNode2A11YContainer | ASExperimentalExposeTextLinksForA11Y;
  [ASConfigurationManager test_resetWithConfiguration:config];
}

- (void)testTruncation
{
  XCTAssertTrue([(ASTextNode *)_textNode shouldTruncateForConstrainedSize:ASSizeRangeMake(CGSizeMake(100, 100))], @"Text Node should truncate");

  _textNode.frame = CGRectMake(0, 0, 100, 100);
  XCTAssertTrue(_textNode.isTruncated, @"Text Node should be truncated");
}

- (void)testBasicAccessibility
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

- (void)testBasicAccessibilityWithExperiments
{
  [self setUpEnablingExperiments];

  XCTAssertFalse(_textNode.isAccessibilityElement, @"Is not an accessiblity element as it's a UIAccessibilityContainer");
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

  XCTAssertTrue(_textNode.accessibilityElements.count == 1, @"Accessibility elements should exist");
  XCTAssertTrue([[_textNode.accessibilityElements[0] accessibilityLabel] isEqualToString:_attributedText.string],
                @"First accessibility element incorrectly returns \n%@\n when it should be \n%@\n",
                [_textNode.accessibilityElements[0] accessibilityLabel], _textNode.accessibilityLabel);
  XCTAssertTrue([[_textNode.accessibilityElements[0] accessibilityLabel] isEqualToString:_attributedText.string],
                @"First accessibility element incorrectly returns \n%@\n when it should be \n%@\n",
                [_textNode.accessibilityElements[0] accessibilityLabel], _textNode.accessibilityLabel);
}

- (void)testAccessibilityLayerBackedContainerAndTextNode2
{
  ASDisplayNode *container = [[ASDisplayNode alloc] init];
  container.frame = CGRectMake(50, 50, 200, 600);
  container.backgroundColor = [UIColor grayColor];

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
  XCTAssertTrue(elements.count == 2);
  XCTAssertTrue([[elements[0] accessibilityLabel] isEqualToString:@"hello"]);
  XCTAssertTrue([[elements[1] accessibilityLabel] isEqualToString:@"world"]);
}

- (void)testBasicAccessibilityWithExperimentsWithExperiments
{
  [self setUpEnablingExperiments];
  [self testAccessibilityLayerBackedContainerAndTextNode2];
}

- (void)testAccessibilityLayerBackedTextNode2WithExperiments
{
  [self setUpEnablingExperiments];

  ASDisplayNode *container = [[ASDisplayNode alloc] init];
  container.frame = CGRectMake(50, 50, 200, 600);
  container.backgroundColor = [UIColor grayColor];

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
  XCTAssertTrue(elements.count == 1);

  UIAccessibilityElement *firstElement = elements.firstObject;
  XCTAssertTrue([firstElement.accessibilityLabel isEqualToString:@"hello"]);
  XCTAssertTrue(CGRectEqualToRect(CGRectMake(50, 102, 26, 13), CGRectIntegral(firstElement.accessibilityFrame)));
}

- (void)testThatASTextNode2SubnodeAccessibilityLabelAggregationWorks
{
  // Setup nodes
  ASDisplayNode *node = [[ASDisplayNode alloc] init];
  ASTextNode2 *innerNode1 = [[ASTextNode2 alloc] init];
  ASTextNode2 *innerNode2 = [[ASTextNode2 alloc] init];

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
  [self setUpEnablingExperiments];
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
  [self setUpEnablingExperiments];
  [self testThatLayeredBackedASTextNode2SubnodeAccessibilityLabelAggregationWorks];
}

- (void)testThatASTextNode2SubnodeCustomActionsAreWorking
{
  ASDisplayNode *node = [[ASDisplayNode alloc] init];
  ASTextNode2 *innerNode1 = [[ASTextNode2 alloc] init];
  innerNode1.accessibilityTraits = UIAccessibilityTraitButton;
  ASTextNode2 *innerNode2 = [[ASTextNode2 alloc] init];
  innerNode2.accessibilityTraits = UIAccessibilityTraitButton;

  // Initialize nodes with relevant accessibility data
  node.isAccessibilityContainer = YES;
  innerNode1.attributedText = [[NSAttributedString alloc] initWithString:@"hello"];
  innerNode2.attributedText = [[NSAttributedString alloc] initWithString:@"world"];

  // Attach the subnodes to the parent node, then ensure their accessibility labels have been'
  // aggregated to the parent's accessibility label
  [node addSubnode:innerNode1];
  [node addSubnode:innerNode2];

  NSArray<UIAccessibilityElement *> *accessibilityElements = node.view.accessibilityElements;
  XCTAssertTrue(accessibilityElements.count == 1, @"Container node should have one accessibility element for custom actions");

  NSArray<UIAccessibilityCustomAction *> *accessibilityCustomActions = accessibilityElements.firstObject.accessibilityCustomActions;
  XCTAssertTrue(accessibilityCustomActions.count == 2, @"Text nodes should be exposed as a11y custom actions.");
}

- (void)testThatASTextNode2SubnodeCustomActionsAreWorkingWithExperiments
{
  [self setUpEnablingExperiments];
  [self testThatASTextNode2SubnodeCustomActionsAreWorking];
}

- (void)testAccessibilityExposeA11YLinksWithExperiments
{
  [self setUpEnablingExperiments];

  NSString *link = @"https://texturegroup.com";
  NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"Texture Website: %@", link]];
  NSRange linkRange = [attributedText.string rangeOfString:link];
  [attributedText addAttribute:NSLinkAttributeName value:link range:linkRange];

  _textNode.attributedText = attributedText;

  NSArray<UIAccessibilityElement *> *accessibilityElements = _textNode.accessibilityElements;
  XCTAssertTrue(accessibilityElements.count == 2, @"Link should be exposed as accessibility element");

  XCTAssertTrue([[accessibilityElements[0] accessibilityLabel] isEqualToString:attributedText.string], @"First accessibility element should be the full text");
  XCTAssertTrue([[accessibilityElements[1] accessibilityLabel] isEqualToString:link], @"Second accessibility element should be the link");
}

@end
