//
//  ASMultiplexImageNodeTests.m
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

#import <OCMock/OCMock.h>
#import <OCMock/NSInvocation+OCMAdditions.h>

#import <AsyncDisplayKit/ASImageProtocols.h>
#import <AsyncDisplayKit/ASMultiplexImageNode.h>
#import <AsyncDisplayKit/ASImageContainerProtocolCategories.h>

#import <libkern/OSAtomic.h>

#import <XCTest/XCTest.h>

@interface ASMultiplexImageNodeTests : XCTestCase
{
@private
  id _mockCache;
  id _mockDownloader;
}

@end


@implementation ASMultiplexImageNodeTests

#pragma mark -
#pragma mark Helpers.

- (NSURL *)_testImageURL
{
  return [[NSBundle bundleForClass:[self class]] URLForResource:@"logo-square"
                                                  withExtension:@"png"
                                                   subdirectory:@"TestResources"];
}

- (UIImage *)_testImage
{
  return [UIImage imageWithContentsOfFile:[self _testImageURL].path];
}

#pragma mark -
#pragma mark Unit tests.

// TODO:  add tests for delegate display notifications

- (void)setUp
{
  [super setUp];

  _mockCache = [OCMockObject mockForProtocol:@protocol(ASImageCacheProtocol)];
  _mockDownloader = [OCMockObject mockForProtocol:@protocol(ASImageDownloaderProtocol)];
}

- (void)tearDown
{
  _mockCache = nil;
  _mockDownloader = nil;
  [super tearDown];
}

- (void)testDataSourceImageMethod
{
  ASMultiplexImageNode *imageNode = [[ASMultiplexImageNode alloc] initWithCache:_mockCache downloader:_mockDownloader];

  // Mock the data source.
  // Note that we're not using a niceMock because we want to assert if the URL data-source method gets hit, as the image
  // method should be hit first and exclusively if it successfully returns an image.
  id mockDataSource = [OCMockObject mockForProtocol:@protocol(ASMultiplexImageNodeDataSource)];
  imageNode.dataSource = mockDataSource;

  NSNumber *imageIdentifier = @1;

  // Expect the image method to be hit, and have it return our test image.
  UIImage *testImage = [self _testImage];
  [[[mockDataSource expect] andReturn:testImage] multiplexImageNode:imageNode imageForImageIdentifier:imageIdentifier];

  imageNode.imageIdentifiers = @[imageIdentifier];
  [imageNode reloadImageIdentifierSources];

  [mockDataSource verify];

  // Also expect it to be loaded immediately.
  XCTAssertEqualObjects(imageNode.loadedImageIdentifier, imageIdentifier, @"imageIdentifier was not loaded");
  // And for the image to be equivalent to the image we provided.
  XCTAssertEqualObjects(UIImagePNGRepresentation(imageNode.image),
                        UIImagePNGRepresentation(testImage),
                        @"Loaded image isn't the one we provided");

  imageNode.delegate = nil;
  imageNode.dataSource = nil;
}

- (void)testDataSourceURLMethod
{
  ASMultiplexImageNode *imageNode = [[ASMultiplexImageNode alloc] initWithCache:_mockCache downloader:_mockDownloader];

  NSNumber *imageIdentifier = @1;

  // Mock the data source such that we...
  id mockDataSource = [OCMockObject niceMockForProtocol:@protocol(ASMultiplexImageNodeDataSource)];
  imageNode.dataSource = mockDataSource;
  // (a) first expect to be hit for the image directly, and fail to return it.
  [mockDataSource setExpectationOrderMatters:YES];
  [[[mockDataSource expect] andReturn:nil] multiplexImageNode:imageNode imageForImageIdentifier:imageIdentifier];
  // (b) and then expect to be hit for the URL, which we'll return.
  [[[mockDataSource expect] andReturn:[self _testImageURL]] multiplexImageNode:imageNode URLForImageIdentifier:imageIdentifier];

  // Mock the cache to do a cache-hit for the test image URL.
  [[[_mockCache stub] andDo:^(NSInvocation *inv) {
    // Params are URL, callbackQueue, completion
    NSArray *URL = [inv getArgumentAtIndexAsObject:2];

    ASImageCacherCompletion completionBlock = [inv getArgumentAtIndexAsObject:4];

    // Call the completion block with our test image and URL.
    NSURL *testImageURL = [self _testImageURL];
    XCTAssertEqualObjects(URL, testImageURL, @"Fetching URL other than test image");
    completionBlock([self _testImage]);
  }] cachedImageWithURL:[OCMArg any] callbackQueue:[OCMArg any] completion:[OCMArg any]];

  imageNode.imageIdentifiers = @[imageIdentifier];
  // Kick off loading.
  [imageNode reloadImageIdentifierSources];

  // Verify the data source.
  [mockDataSource verify];
  // Also expect it to be loaded immediately.
  XCTAssertEqualObjects(imageNode.loadedImageIdentifier, imageIdentifier, @"imageIdentifier was not loaded");
  // And for the image to be equivalent to the image we provided.
  XCTAssertEqualObjects(UIImagePNGRepresentation(imageNode.image),
                        UIImagePNGRepresentation([self _testImage]),
                        @"Loaded image isn't the one we provided");
}

- (void)testAddLowerQualityImageIdentifier
{
  // Adding a lower quality image identifier should not cause any loading.
  ASMultiplexImageNode *imageNode = [[ASMultiplexImageNode alloc] initWithCache:_mockCache downloader:_mockDownloader];

  NSNumber *highResIdentifier = @2;

  // Mock the data source such that we: (a) return the test image, and log whether we get hit for the lower-quality image.
  id mockDataSource = [OCMockObject mockForProtocol:@protocol(ASMultiplexImageNodeDataSource)];
  imageNode.dataSource = mockDataSource;
  __block int dataSourceHits = 0;
  [[[mockDataSource stub] andDo:^(NSInvocation *inv) {
    dataSourceHits++;

    // Return the test image.
    [inv setReturnValue:(void *)[self _testImage]];
  }] multiplexImageNode:[OCMArg any] imageForImageIdentifier:[OCMArg any]];

  imageNode.imageIdentifiers = @[highResIdentifier];
  [imageNode reloadImageIdentifierSources];

  // At this point, we should have the high-res identifier loaded and the DS should have been hit once.
  XCTAssertEqualObjects(imageNode.loadedImageIdentifier, highResIdentifier, @"High res identifier should be loaded.");
  XCTAssertTrue(dataSourceHits == 1, @"Unexpected DS hit count");

  // Add the low res identifier.
  NSNumber *lowResIdentifier = @1;
  imageNode.imageIdentifiers = @[highResIdentifier, lowResIdentifier];
  [imageNode reloadImageIdentifierSources];

  // At this point the high-res should still be loaded, and the data source should have been hit again
  XCTAssertEqualObjects(imageNode.loadedImageIdentifier, highResIdentifier, @"High res identifier should be loaded.");
  XCTAssertTrue(dataSourceHits == 2, @"Unexpected DS hit count");
}

- (void)testAddHigherQualityImageIdentifier
{
  // Adding a higher quality image identifier should cause loading.
  ASMultiplexImageNode *imageNode = [[ASMultiplexImageNode alloc] initWithCache:_mockCache downloader:_mockDownloader];

  NSNumber *lowResIdentifier = @1;

  // Mock the data source such that we: (a) return the test image, and log how many times the DS gets hit.
  id mockDataSource = [OCMockObject mockForProtocol:@protocol(ASMultiplexImageNodeDataSource)];
  imageNode.dataSource = mockDataSource;
  __block int dataSourceHits = 0;
  [[[mockDataSource stub] andDo:^(NSInvocation *inv) {
    dataSourceHits++;

    // Return the test image.
    [inv setReturnValue:(void *)[self _testImage]];
  }] multiplexImageNode:[OCMArg any] imageForImageIdentifier:[OCMArg any]];

  imageNode.imageIdentifiers = @[lowResIdentifier];
  [imageNode reloadImageIdentifierSources];

  // At this point, we should have the low-res identifier loaded and the DS should have been hit once.
  XCTAssertEqualObjects(imageNode.loadedImageIdentifier, lowResIdentifier, @"Low res identifier should be loaded.");
  XCTAssertTrue(dataSourceHits == 1, @"Unexpected DS hit count");

  // Add the low res identifier.
  NSNumber *highResIdentifier = @2;
  imageNode.imageIdentifiers = @[highResIdentifier, lowResIdentifier];
  [imageNode reloadImageIdentifierSources];

  // At this point the high-res should be loaded, and the data source should been hit twice.
  XCTAssertEqualObjects(imageNode.loadedImageIdentifier, highResIdentifier, @"High res identifier should be loaded.");
  XCTAssertTrue(dataSourceHits == 2, @"Unexpected DS hit count");
}

- (void)testProgressiveDownloading
{
  ASMultiplexImageNode *imageNode = [[ASMultiplexImageNode alloc] initWithCache:_mockCache downloader:_mockDownloader];
  imageNode.downloadsIntermediateImages = YES;

  // Set up a few identifiers to load.
  NSInteger identifierCount = 5;
  NSMutableArray *imageIdentifiers = [NSMutableArray array];
  for (NSInteger identifierIndex = 0; identifierIndex < identifierCount; identifierIndex++)
    [imageIdentifiers insertObject:@(identifierIndex + 1) atIndex:0];

  // Mock the data source to only make the images available progressively.
  // This is necessary because ASMultiplexImageNode will try to grab the best image immediately, regardless of
  // `downloadsIntermediateImages`.
  id mockDataSource = [OCMockObject niceMockForProtocol:@protocol(ASMultiplexImageNodeDataSource)];
  imageNode.dataSource = mockDataSource;
  __block NSUInteger loadedImageCount = 0;
  [[[mockDataSource stub] andDo:^(NSInvocation *inv) {
    id requestedIdentifier = [inv getArgumentAtIndexAsObject:3];

    NSInteger requestedIdentifierValue = [requestedIdentifier intValue];

    // If no images are loaded, bail on trying to load anything but the worst image.
    if (!imageNode.loadedImageIdentifier && requestedIdentifierValue != [[imageIdentifiers lastObject] integerValue])
      return;

    // Bail if it's trying to load an identifier that's more than one step than what's loaded.
    NSInteger nextImageIdentifier = [(NSNumber *)imageNode.loadedImageIdentifier integerValue] + 1;
    if (requestedIdentifierValue != nextImageIdentifier)
      return;

    // Return the test image.
    loadedImageCount++;
    [inv setReturnValue:(void *)[self _testImage]];
  }] multiplexImageNode:[OCMArg any] imageForImageIdentifier:[OCMArg any]];

  imageNode.imageIdentifiers = imageIdentifiers;
  [imageNode reloadImageIdentifierSources];

  XCTAssertTrue(loadedImageCount == identifierCount, @"Expected to load the same number of identifiers we supplied");
}

- (void)testUncachedDownload
{
  // Mock a cache miss.
  id mockCache = [OCMockObject mockForProtocol:@protocol(ASImageCacheProtocol)];
  [[[mockCache stub] andDo:^(NSInvocation *inv) {
    ASImageCacherCompletion completion = [inv getArgumentAtIndexAsObject:4];
    completion(nil);
  }] cachedImageWithURL:[OCMArg any] callbackQueue:[OCMArg any] completion:[OCMArg any]];

  // Mock a 50%-progress URL download.
  id mockDownloader = [OCMockObject mockForProtocol:@protocol(ASImageDownloaderProtocol)];
  const CGFloat mockedProgress = 0.5;
  [[[mockDownloader stub] andDo:^(NSInvocation *inv) {
    // Simulate progress.
    ASImageDownloaderProgress progressBlock = [inv getArgumentAtIndexAsObject:4];
    progressBlock(mockedProgress);

    // Simulate completion.
    ASImageDownloaderCompletion completionBlock = [inv getArgumentAtIndexAsObject:5];
    completionBlock([self _testImage], nil, nil);
  }] downloadImageWithURL:[OCMArg any] callbackQueue:[OCMArg any] downloadProgress:[OCMArg any] completion:[OCMArg any]];

  ASMultiplexImageNode *imageNode = [[ASMultiplexImageNode alloc] initWithCache:mockCache downloader:mockDownloader];
  NSNumber *imageIdentifier = @1;

  // Mock the data source to return our test URL.
  id mockDataSource = [OCMockObject niceMockForProtocol:@protocol(ASMultiplexImageNodeDataSource)];
  [[[mockDataSource stub] andReturn:[self _testImageURL]] multiplexImageNode:imageNode URLForImageIdentifier:imageIdentifier];
  imageNode.dataSource = mockDataSource;

  // Mock the delegate to expect start, 50% progress, and completion invocations.
  id mockDelegate = [OCMockObject mockForProtocol:@protocol(ASMultiplexImageNodeDelegate)];
  [[mockDelegate expect] multiplexImageNode:imageNode didStartDownloadOfImageWithIdentifier:imageIdentifier];
  [[mockDelegate expect] multiplexImageNode:imageNode didUpdateDownloadProgress:mockedProgress forImageWithIdentifier:imageIdentifier];
  [[mockDelegate expect] multiplexImageNode:imageNode didFinishDownloadingImageWithIdentifier:imageIdentifier error:nil];
  [[mockDelegate expect] multiplexImageNode:imageNode didUpdateImage:[OCMArg any] withIdentifier:imageIdentifier fromImage:nil withIdentifier:nil];
  imageNode.delegate = mockDelegate;

  imageNode.imageIdentifiers = @[imageIdentifier];
  // Kick off loading.
  [imageNode reloadImageIdentifierSources];

  // Wait until the image is loaded.
  [self expectationForPredicate:[NSPredicate predicateWithFormat:@"loadedImageIdentifier = %@", imageIdentifier] evaluatedWithObject:imageNode handler:nil];
  [self waitForExpectationsWithTimeout:30 handler:nil];

  // Verify the delegation.
  [mockDelegate verify];
}

- (void)testThatSettingAnImageExternallyWillThrow
{
  ASMultiplexImageNode *multiplexImageNode = [[ASMultiplexImageNode alloc] init];
  XCTAssertThrows(multiplexImageNode.image = [UIImage imageNamed:@""]);
}

@end
