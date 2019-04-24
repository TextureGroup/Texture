//
//  ASPendingStateTests.m
//  AsyncDisplayKitTests
//
//  Created by Garrett Moon on 3/27/19.
//  Copyright © 2019 Pinterest. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import <OCMock/OCMock.h>


#import <AsyncDisplayKit/_ASPendingState.h>

@interface ASPendingStateTests : XCTestCase

@end

@implementation ASPendingStateTests

- (void)setUp {
  // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (NSSet<NSString *>*)properties {
  static dispatch_once_t onceToken;
  static NSMutableSet <NSString *>*allProperties;
  dispatch_once(&onceToken, ^{
    allProperties = [[NSMutableSet alloc] init];
    NSMutableSet *protocols = [[NSMutableSet alloc] init];
    Protocol *pendingStateProtocol = objc_getProtocol("_ASPendingState");
    [protocols addObject:pendingStateProtocol];
    
    while (protocols.count > 0) {
      // Get protocol to process
      Protocol *protocol = [protocols anyObject];
      [protocols removeObject:protocol];
      
      // Add in any super protocols
      unsigned int outCount;
      Protocol __unsafe_unretained **protocolCArray;
      protocolCArray = protocol_copyProtocolList(protocol, &outCount);
      for (NSUInteger count = 0; count < outCount; count++) {
        [protocols addObject:protocolCArray[count]];
      }
      if (outCount > 0) {
        free(protocolCArray);
      }
      
      // Add properties to property list
      objc_property_t *properties = protocol_copyPropertyList(protocol, &outCount);
      for (NSUInteger count = 0; count < outCount; count++) {
        NSString *propertyName = [NSString stringWithUTF8String:property_getName(properties[count])];
        if ([propertyName isEqualToString:@"description"]) {
          continue;
        }
        if ([propertyName isEqualToString:@"hash"]) {
          continue;
        }
        if ([propertyName isEqualToString:@"debugDescription"]) {
          continue;
        }
        [allProperties addObject:propertyName];
      }
      
      if (outCount > 0) {
        free(properties);
      }
    }
  });
  
  [allProperties addObject:@"isAccessibilityElement"];
  
  // Add accessibility protocol
  [allProperties addObject:@"isAccessibilityElement"];
  [allProperties addObject:@"accessibilityLabel"];
  [allProperties addObject:@"accessibilityAttributedLabel"];
  [allProperties addObject:@"accessibilityHint"];
  [allProperties addObject:@"accessibilityAttributedHint"];
  [allProperties addObject:@"accessibilityValue"];
  [allProperties addObject:@"accessibilityAttributedValue"];
  [allProperties addObject:@"accessibilityTraits"];
  [allProperties addObject:@"accessibilityFrame"];
  [allProperties addObject:@"accessibilityLanguage"];
  [allProperties addObject:@"accessibilityElementsHidden"];
  [allProperties addObject:@"accessibilityViewIsModal"];
  [allProperties addObject:@"shouldGroupAccessibilityChildren"];
  
  return allProperties;
}

- (BOOL)pendingStatesEqual:(NSObject <_ASPendingState>*)pendingStateOne toPendingState:(NSObject <_ASPendingState>*)pendingStateTwo {
  NSSet<NSString *> *properties = [self properties];
  BOOL isEqual = YES;
  for (NSString *propertyName in properties) {
    // Special case non KVO properties
    if ([propertyName isEqualToString:@"borderColor"]) {
      XCTAssert(CGColorEqualToColor(pendingStateOne.borderColor, pendingStateTwo.borderColor));
      continue;
    } else if ([propertyName isEqualToString:@"backgroundColor"]) {
      XCTAssert(CGColorEqualToColor(pendingStateOne.backgroundColor, pendingStateTwo.backgroundColor));
      continue;
    } else if ([propertyName isEqualToString:@"shadowColor"]) {
      XCTAssert(CGColorEqualToColor(pendingStateOne.shadowColor, pendingStateTwo.shadowColor));
      continue;
    } else if ([propertyName isEqualToString:@"asyncdisplaykit_asyncTransactionContainer"]) {
      XCTAssertEqual(pendingStateOne.asyncdisplaykit_asyncTransactionContainer, pendingStateTwo.asyncdisplaykit_asyncTransactionContainer);
      continue;
    }
    
    id valueOne = [pendingStateOne valueForKey:propertyName];
    id valueTwo = [pendingStateTwo valueForKey:propertyName];
    
    NSLog(@"Checking equality on %@ one value: %@", propertyName, valueOne);
    BOOL propertyEqual;
    if ([valueOne isKindOfClass:[NSObject class]]) {
      propertyEqual = [valueOne isEqual:valueTwo];
    } else {
      propertyEqual = valueOne == valueTwo;
    }
    isEqual &= propertyEqual;
  }
  
  NSLog(@"Checking equality on hasLayoutIfNeeded");
  XCTAssertEqual(pendingStateOne.hasLayoutIfNeeded, pendingStateTwo.hasLayoutIfNeeded);
  
  return isEqual;
}

- (void)testInequalitySanity {
  _ASPendingStateCompressed *compressed = [[_ASPendingStateCompressed alloc] init];
  _ASPendingStateInflated *inflated = [[_ASPendingStateInflated alloc] init];
  inflated.frame = CGRectMake(10, 10, 10, 10);
  XCTAssertFalse([self pendingStatesEqual:compressed toPendingState:inflated]);
}

- (void)testDefaultEquality {
  XCTAssert([self pendingStatesEqual:[[_ASPendingStateInflated alloc] init] toPendingState:[[_ASPendingStateCompressed alloc] init]]);
}

- (void)testCompressedMultipleSet {
  _ASPendingStateCompressed *compressed = [[_ASPendingStateCompressed alloc] init];
  _ASPendingStateInflated *inflated = [[_ASPendingStateInflated alloc] init];
  compressed.position = CGPointMake(10, 10);
  compressed.position = CGPointMake(11, 11);
  compressed.position = CGPointMake(12, 12);
  inflated.position = CGPointMake(12, 12);
  XCTAssert([self pendingStatesEqual:compressed toPendingState:inflated]);
}

- (void)testAllPropertiesSetEquality {
  UIGraphicsBeginImageContext(CGSizeMake(1, 1));
  [[UIColor redColor] setFill];
  CGContextFillRect(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, 1, 1));
  UIImage *solidColorImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  CATransform3D transform = CATransform3DIdentity;
  transform.m11 = 10;
  transform.m42 = 10;
  
  _ASPendingStateCompressed *compressed = [[_ASPendingStateCompressed alloc] init];
  _ASPendingStateInflated *inflated = [[_ASPendingStateInflated alloc] init];
  
  inflated.position = CGPointMake(10, -10);
  compressed.position = CGPointMake(10, -10);
  inflated.zPosition = 10;
  compressed.zPosition = 10;
  inflated.anchorPoint = CGPointMake(10, -10);
  compressed.anchorPoint = CGPointMake(10, -10);
  inflated.cornerRadius = 1.1;
  compressed.cornerRadius = 1.1;
  inflated.contents = (__bridge id)solidColorImage.CGImage;
  compressed.contents = (__bridge id)solidColorImage.CGImage;
  inflated.contentsGravity = kCAGravityResize;
  compressed.contentsGravity = kCAGravityResize;
  inflated.contentsRect = CGRectMake(10, 10, 10, 10);
  compressed.contentsRect = CGRectMake(10, 10, 10, 10);
  inflated.contentsRect = CGRectMake(10, 10, 10, 10);
  compressed.contentsRect = CGRectMake(10, 10, 10, 10);
  inflated.contentsCenter = CGRectMake(10, 10, 10, 10);
  compressed.contentsCenter = CGRectMake(10, 10, 10, 10);
  inflated.contentsScale = 10;
  compressed.contentsScale = 10;
  inflated.rasterizationScale = 10;
  compressed.rasterizationScale = 10;
  inflated.transform = transform;
  compressed.transform = transform;
  inflated.sublayerTransform = transform;
  compressed.sublayerTransform = transform;
  inflated.needsDisplayOnBoundsChange = YES;
  compressed.needsDisplayOnBoundsChange = YES;
  inflated.shadowColor = [[UIColor redColor] CGColor];
  compressed.shadowColor = [[UIColor redColor] CGColor];
  inflated.shadowOpacity = 0.7;
  compressed.shadowOpacity = 0.7;
  inflated.shadowOffset = CGSizeMake(10, 10);
  compressed.shadowOffset = CGSizeMake(10, 10);
  inflated.borderWidth = 0.4;
  compressed.borderWidth = 0.4;
  inflated.opaque = YES;
  compressed.opaque = YES;
  inflated.borderColor = [[UIColor blueColor] CGColor];
  compressed.borderColor = [[UIColor blueColor] CGColor];
  inflated.backgroundColor = [[UIColor yellowColor] CGColor];
  compressed.backgroundColor = [[UIColor yellowColor] CGColor];
  inflated.allowsGroupOpacity = YES;
  compressed.allowsGroupOpacity = YES;
  inflated.allowsEdgeAntialiasing = YES;
  compressed.allowsEdgeAntialiasing = YES;
  [inflated setNeedsLayout];
  [compressed setNeedsLayout];
  [inflated setNeedsDisplay];
  [compressed setNeedsDisplay];
  [inflated layoutIfNeeded];
  [compressed layoutIfNeeded];
  inflated.clipsToBounds = YES;
  compressed.clipsToBounds = YES;
  inflated.hidden = YES;
  compressed.hidden = YES;
  inflated.autoresizesSubviews = YES;
  compressed.autoresizesSubviews = YES;
  inflated.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
  compressed.autoresizingMask = inflated.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
  inflated.tintColor = [UIColor greenColor];
  compressed.tintColor = [UIColor greenColor];
  inflated.alpha = 0.5;
  compressed.alpha = 0.5;
  inflated.bounds = CGRectMake(10, 10, 10, 10);
  compressed.bounds = CGRectMake(10, 10, 10, 10);
  inflated.frame = CGRectMake(10, 10, 10, 10);
  compressed.frame = CGRectMake(10, 10, 10, 10);
  inflated.contentMode = UIViewContentModeScaleAspectFit;
  compressed.contentMode = UIViewContentModeScaleAspectFit;
  inflated.semanticContentAttribute = UISemanticContentAttributePlayback;
  compressed.semanticContentAttribute = UISemanticContentAttributePlayback;
  inflated.userInteractionEnabled = YES;
  compressed.userInteractionEnabled = YES;
  inflated.exclusiveTouch = YES;
  compressed.exclusiveTouch = YES;
  [inflated asyncdisplaykit_setAsyncTransactionContainer:YES];
  [compressed asyncdisplaykit_setAsyncTransactionContainer:YES];
  inflated.layoutMargins = UIEdgeInsetsMake(10, 10, 10, 10);
  compressed.layoutMargins = UIEdgeInsetsMake(10, 10, 10, 10);
  inflated.preservesSuperviewLayoutMargins = YES;
  compressed.preservesSuperviewLayoutMargins = YES;
  inflated.insetsLayoutMarginsFromSafeArea = YES;
  compressed.insetsLayoutMarginsFromSafeArea = YES;
  inflated.isAccessibilityElement = YES;
  compressed.isAccessibilityElement = YES;
  inflated.accessibilityLabel = @"Accessibility label";
  compressed.accessibilityLabel = @"Accessibility label";
  inflated.accessibilityHint = @"Accessibility hint";
  compressed.accessibilityHint = @"Accessibility hint";
  inflated.accessibilityValue = @"Accessibility value";
  compressed.accessibilityValue = @"Accessibility value";
  inflated.accessibilityTraits = UIAccessibilityTraitImage;
  compressed.accessibilityTraits = UIAccessibilityTraitImage;
  inflated.accessibilityFrame = CGRectMake(10, 10, 10, 10);
  compressed.accessibilityFrame = CGRectMake(10, 10, 10, 10);
  inflated.accessibilityLanguage = @"Accessibility language";
  compressed.accessibilityLanguage = @"Accessibility language";
  inflated.accessibilityElementsHidden = YES;
  compressed.accessibilityElementsHidden = YES;
  inflated.accessibilityViewIsModal = YES;
  compressed.accessibilityViewIsModal = YES;
  inflated.shouldGroupAccessibilityChildren = YES;
  compressed.shouldGroupAccessibilityChildren = YES;
  
  // iOS 11
  if (@available(iOS 11.0, *)) {
    inflated.accessibilityAttributedLabel = [[NSAttributedString alloc] initWithString:@"Accessibility attributed label"];
    compressed.accessibilityAttributedLabel = [[NSAttributedString alloc] initWithString:@"Accessibility attributed label"];
    inflated.accessibilityAttributedHint = [[NSAttributedString alloc] initWithString:@"Accessibility attributed hint"];
    compressed.accessibilityAttributedHint = [[NSAttributedString alloc] initWithString:@"Accessibility attributed hint"];
    inflated.accessibilityAttributedValue = [[NSAttributedString alloc] initWithString:@"Accessibility attributed value"];
    compressed.accessibilityAttributedValue = [[NSAttributedString alloc] initWithString:@"Accessibility attributed value"];
  }

  XCTAssert([self pendingStatesEqual:inflated toPendingState:compressed]);
}

@end
