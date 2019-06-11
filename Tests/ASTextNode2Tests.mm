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

// Node (isAccessibilityContainer = YES / NO)
//  - Node (layerBacked = YES, isAccessibilityContainer = YES)
//    - ASTextNode (layerBacked = YES)
//    - ASTextNode (layerBacked = YES, accessibilityTraits = UIAccessibilityTraitButton)
// Result??:
// The fix would be within _ASDisplayViewAccessibility

- (void)testAccessibilityLayerBackedSubContainerWithinContainer
{
  ASDisplayNode *container = [[ASDisplayNode alloc] init];
  container.frame = CGRectMake(50, 50, 200, 600);

  ASDisplayNode *subContainer = [[ASDisplayNode alloc] init];
  subContainer.frame = CGRectMake(50, 50, 200, 600);

  // SubContainer is explicitly layerBacked
  subContainer.layerBacked = YES;
  subContainer.isAccessibilityContainer = YES;
  [container addSubnode:subContainer];

  ASTextNode *text1 = [[ASTextNode alloc] init];
  text1.attributedText = [[NSAttributedString alloc] initWithString:@"hello"];
  text1.frame = CGRectMake(50, 100, 200, 200);
  text1.layerBacked = YES;
  [subContainer addSubnode:text1];

  // This is a text that acts like a button
  ASTextNode *text2 = [[ASTextNode alloc] init];
  text2.accessibilityTraits = UIAccessibilityTraitButton;
  text2.attributedText = [[NSAttributedString alloc] initWithString:@"world"];
  text2.frame = CGRectMake(50, 300, 200, 200);
  text2.layerBacked = YES;
  [subContainer addSubnode:text2];

  // Setting the container explicitly as no accessibility container
  container.isAccessibilityContainer = NO;

  // TODO(maicki): I this the right output??
  // TODO(maicki): Should this return an accessibility custom actions somewhere?
  // TODO(maicki): This needs to be newly handled: a container that is not layer backed and not an accessiblity container and a subcontainer that is layer backed and a accessibiilty container

  // This should be fine as the accessibility element represents the accessibility container
  NSArray<UIAccessibilityElement *> *accessibilityElements = nil;
//  NSArray<UIAccessibilityElement *> *accessibilityElements = container.view.accessibilityElements;

  // UIAccessibilityElement (accessibilityLabel = "hello")
  //  - UIAccessibilityCustomAction (name = "world")

  // We have one element that represents the subContainer
//  XCTAssertEqual(accessibilityElements.count, 1);

  // The sub container element has the flattened text of hello
//  XCTAssertEqualObjects(accessibilityElements[0].accessibilityLabel, @"hello");

  // The sub container element has the custom action for the other text node
//  NSArray<UIAccessibilityCustomAction *> *accessibilityCustomActions = accessibilityElements[0].accessibilityCustomActions;
//  XCTAssertEqual(accessibilityCustomActions.count, 1);
//  XCTAssertEqualObjects(accessibilityCustomActions[0].name, @"world");

  // Change container settings
  container.isAccessibilityContainer = YES;
  container.view.accessibilityElements = nil; // Clear accessibilityElements elements cache
  accessibilityElements = container.view.accessibilityElements; // Requery elements

  // TODO(maicki): Should the first a11y element be optimized away?
  // UIAccessibilityElement (accessibilityLabel = nil, accessibilityCustomActions = [])
  // UIAccessibilityElement (accessibilityLabel = "hello")
  //  - UIAccessibilityCustomAction (name = "world")

  // We have two elements one that represents the subContainer and one that is the text node
  XCTAssertEqual(accessibilityElements.count, 2);
  XCTAssertEqualObjects(accessibilityElements[1].accessibilityLabel, @"hello");

  // Sub container representation has the custom action set on it
  NSArray<UIAccessibilityCustomAction *> *firstAccessibilityElementCustomActions = accessibilityElements[1].accessibilityCustomActions;
  XCTAssertEqual(firstAccessibilityElementCustomActions.count, 1);
  XCTAssertEqualObjects(firstAccessibilityElementCustomActions[0].name, @"world");
}

@end
