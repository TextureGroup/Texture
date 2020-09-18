//
//  ASGraphicsContextTests.mm
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//


#import <XCTest/XCTest.h>
#import <AsyncDisplayKit/ASGraphicsContext.h>
#import <AsyncDisplayKit/ASBaseDefines.h>
#import <AsyncDisplayKit/ASAvailability.h>
#import <AsyncDisplayKit/ASConfigurationInternal.h>

@interface ASGraphicsContextTests : XCTestCase
@end

@implementation ASGraphicsContextTests

- (void)setUp
{
  [super setUp];
  ASConfiguration *config = [ASConfiguration new];
  config.experimentalFeatures = ASExperimentalDrawingGlobal;
  [ASConfigurationManager test_resetWithConfiguration:config];
}


#if AS_AT_LEAST_IOS13
- (void)testCanceled
{
  if (AS_AVAILABLE_IOS_TVOS(13, 13)) {
    CGSize size = CGSize{.width=100, .height=100};
    
    XCTestExpectation *expectationCancelled = [self expectationWithDescription:@"canceled"];
    
    asdisplaynode_iscancelled_block_t isCancelledBlock =^BOOL{
      [expectationCancelled fulfill];
      return true;
    };
    
    ASPrimitiveTraitCollection traitCollection = ASPrimitiveTraitCollectionMakeDefault();
    UIImage *canceledImage = ASGraphicsCreateImage(traitCollection, size, false, 0, nil, isCancelledBlock, ^{});
    
    XCTAssertNil(canceledImage);
    
    [self waitForExpectations:@[expectationCancelled] timeout:1];
  }
}

- (void)testCanceledNil
{
  if (AS_AVAILABLE_IOS_TVOS(13, 13)) {
    CGSize size = CGSize{.width=100, .height=100};
    ASPrimitiveTraitCollection traitCollection = ASPrimitiveTraitCollectionMakeDefault();
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"normal"];
    UIImage *image = ASGraphicsCreateImage(traitCollection, size, false, 0, nil, nil, ^{
      [expectation fulfill];
    });
 
    XCTAssert(image);
    
    [self waitForExpectations:@[expectation] timeout:1];
  }
}

- (void)testTraitCollectionPassedToWork
{
  if (AS_AVAILABLE_IOS_TVOS(13, 13)) {
    CGSize size = CGSize{.width=100, .height=100};
    
    XCTestExpectation *expectationDark = [self expectationWithDescription:@"trait collection dark"];
    ASPrimitiveTraitCollection traitCollectionDark = ASPrimitiveTraitCollectionMakeDefault();
    traitCollectionDark.userInterfaceStyle = UIUserInterfaceStyleDark;
    ASGraphicsCreateImage(traitCollectionDark, size, false, 0, nil, nil, ^{
      UITraitCollection *currentTraitCollection = [UITraitCollection currentTraitCollection];
      XCTAssertEqual(currentTraitCollection.userInterfaceStyle, UIUserInterfaceStyleDark);
      [expectationDark fulfill];
    });

    XCTestExpectation *expectationLight = [self expectationWithDescription:@"trait collection light"];
    ASPrimitiveTraitCollection traitCollectionLight = ASPrimitiveTraitCollectionMakeDefault();
    traitCollectionLight.userInterfaceStyle = UIUserInterfaceStyleLight;
    ASGraphicsCreateImage(traitCollectionLight, size, false, 0, nil, nil, ^{
      UITraitCollection *currentTraitCollection = [UITraitCollection currentTraitCollection];
      XCTAssertEqual(currentTraitCollection.userInterfaceStyle, UIUserInterfaceStyleLight);
      [expectationLight fulfill];
    });

    [self waitForExpectations:@[expectationDark, expectationLight] timeout:1];
  }
}
#endif
@end
