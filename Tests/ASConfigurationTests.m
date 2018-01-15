//
//  ASConfigurationTests.m
//  AsyncDisplayKitTests
//
//  Created by Adlai on 1/14/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ASTestCase.h"
#import "ASConfiguration.h"
#import "ASConfigurationDelegate.h"
#import "ASConfigurationManager.h"

@interface ASConfigurationTests : XCTestCase <ASConfigurationDelegate>

@end

@implementation ASConfigurationTests {
  void (^onActivate)(ASConfigurationTests *self, ASExperimentalFeatureSet feature);
}

- (void)testExperimentalFeatureConfig
{
  // Set the config
  ASConfiguration *config = [[ASConfiguration alloc] init];
  config.experimentalFeatures = ASExperimentalGraphicsContexts;
  config.delegate = self;
  [ASConfigurationManager test_resetWithConfiguration:config];
  
  // Set an expectation for a callback, and assert we only get one.
  XCTestExpectation *e = [self expectationWithDescription:@"Callback 1 done."];
  onActivate = ^(ASConfigurationTests *self, ASExperimentalFeatureSet feature) {
    XCTAssertEqual(feature, ASExperimentalGraphicsContexts);
    [e fulfill];
    // Next time it's a fail.
    self->onActivate = ^(ASConfigurationTests *self, ASExperimentalFeatureSet feature) {
      XCTFail(@"Too many callbacks.");
    };
  };
  
  // Now activate the graphics experiment and expect it works.
  XCTAssertTrue(ASActivateExperimentalFeature(ASExperimentalGraphicsContexts));
  // We should get a callback here
  // Now activate text node and expect it fails.
  XCTAssertFalse(ASActivateExperimentalFeature(ASExperimentalTextNode));
  [self waitForExpectationsWithTimeout:3 handler:nil];
}

- (void)textureDidActivateExperimentalFeatures:(ASExperimentalFeatureSet)feature
{
  if (onActivate) {
    onActivate(self, feature);
  }
}

@end
