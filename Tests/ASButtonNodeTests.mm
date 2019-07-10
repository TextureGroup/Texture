//
//  ASButtonNodeTests.mm
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <XCTest/XCTest.h>

#import <AsyncDisplayKit/ASButtonNode.h>
#import <AsyncDisplayKit/ASDisplayNode+Beta.h>
#import <AsyncDisplayKit/ASTextNode.h>

@interface ASButtonNodeTests : XCTestCase
@end

@implementation ASButtonNodeTests

- (void)testAccessibility
{
  // Setup a button with some title.
  ASButtonNode *buttonNode = nil;
  buttonNode = [[ASButtonNode alloc] init];
  NSString *title = @"foo";
  [buttonNode setTitle:title withFont:nil withColor:nil forState:UIControlStateNormal];

  // Verify accessibility properties.
  XCTAssertTrue(buttonNode.accessibilityTraits == UIAccessibilityTraitButton,
                @"Should have button accessibility trait, instead has %llu",
                buttonNode.accessibilityTraits);
  XCTAssertTrue(buttonNode.defaultAccessibilityTraits == UIAccessibilityTraitButton,
                @"Default accessibility traits should return button accessibility trait, instead "
                @"returns %llu",
                buttonNode.defaultAccessibilityTraits);
  XCTAssertTrue([buttonNode.accessibilityLabel isEqualToString:title],
                @"Accessibility label is incorrectly set to \n%@\n when it should be \n%@\n",
                buttonNode.accessibilityLabel, title);
  XCTAssertTrue([buttonNode.defaultAccessibilityLabel isEqualToString:title],
                @"Default accessibility label incorrectly returns \n%@\n when it should be \n%@\n",
                buttonNode.defaultAccessibilityLabel, title);

  // Disable the button and verify that accessibility traits has been updated correctly.
  buttonNode.enabled = NO;
  UIAccessibilityTraits disabledButtonTrait = UIAccessibilityTraitButton | UIAccessibilityTraitNotEnabled;
  XCTAssertTrue(buttonNode.accessibilityTraits == disabledButtonTrait,
                @"Should have disabled button accessibility trait, instead has %llu",
                buttonNode.accessibilityTraits);
  XCTAssertTrue(buttonNode.defaultAccessibilityTraits == disabledButtonTrait,
                @"Default accessibility traits should return disabled button accessibility trait, "
                @"instead returns %llu",
                buttonNode.defaultAccessibilityTraits);
}

/// Test the accessbility label consistency for buttons that do not have a title
/// In this test case, the button is empty but its titleNode is not nil.
/// If we give this button an accessibility label and then change its state,
/// we still want the accessbility unchanged, instead of going back to the default accessibility label.
- (void)testAccessibilityWithoutATitle
{
  ASButtonNode *buttonNode = [[ASButtonNode alloc] init];
  buttonNode.accessibilityLabel = @"My Test";
  // Make sure the title node is not nil.
  buttonNode.titleNode.placeholderColor = [UIColor whiteColor];
  buttonNode.selected = YES;
  XCTAssertTrue([buttonNode.accessibilityLabel isEqualToString:@"My Test"]);
}

- (void)testUpdateTitle
{
  NSAttributedString *title = [[NSAttributedString alloc] initWithString:@"MyTitle"];
  ASButtonNode *buttonNode = [[ASButtonNode alloc] init];
  [buttonNode setAttributedTitle:title forState:UIControlStateNormal];
  XCTAssertTrue([[buttonNode attributedTitleForState:UIControlStateNormal] isEqualToAttributedString:title]);
  XCTAssert([buttonNode.titleNode.attributedText isEqualToAttributedString:title]);
}

@end
