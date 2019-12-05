//
//  ASNetworkImageNodeTests.mm
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import <AsyncDisplayKit/ASDisplayNode+FrameworkPrivate.h>

@interface ASNetworkImageNodeTests : XCTestCase

@end

@interface ASTestImageDownloader : NSObject <ASImageDownloaderProtocol>
@end
@interface ASTestImageCache : NSObject <ASImageCacheProtocol>
@end

@implementation ASNetworkImageNodeTests {
  ASNetworkImageNode *node;
  id downloader;
  id cache;
}

- (void)setUp
{
  [super setUp];
  cache = [OCMockObject partialMockForObject:[[ASTestImageCache alloc] init]];
  downloader = [OCMockObject partialMockForObject:[[ASTestImageDownloader alloc] init]];
  node = [[ASNetworkImageNode alloc] initWithCache:cache downloader:downloader];
}

/// Test is flaky: https://github.com/facebook/AsyncDisplayKit/issues/2898
- (void)DISABLED_testThatProgressBlockIsSetAndClearedCorrectlyOnVisibility
{
  node.URL = [NSURL URLWithString:@"http://imageA"];

  // Enter preload range, wait for download start.
  [[[downloader expect] andForwardToRealObject] downloadImageWithURL:[OCMArg isNotNil] callbackQueue:OCMOCK_ANY downloadProgress:OCMOCK_ANY completion:OCMOCK_ANY];
  [node enterInterfaceState:ASInterfaceStatePreload];
  [downloader verifyWithDelay:5];

  // Make the node visible.
  [[downloader expect] setProgressImageBlock:[OCMArg isNotNil] callbackQueue:OCMOCK_ANY withDownloadIdentifier:@0];
  [node enterInterfaceState:ASInterfaceStateInHierarchy];
  [downloader verify];

  // Make the node invisible.
  [[downloader expect] setProgressImageBlock:[OCMArg isNil] callbackQueue:OCMOCK_ANY withDownloadIdentifier:@0];
  [node exitInterfaceState:ASInterfaceStateInHierarchy];
  [downloader verify];
}

- (void)testThatProgressBlockIsSetAndClearedCorrectlyOnChangeURL
{
  [node layer];
  [node enterInterfaceState:ASInterfaceStateInHierarchy];

  // Set URL while visible, should set progress block
  [[downloader expect] setProgressImageBlock:[OCMArg isNotNil] callbackQueue:OCMOCK_ANY withDownloadIdentifier:@0];
  node.URL = [NSURL URLWithString:@"http://imageA"];
  [downloader verifyWithDelay:5];

  // Change URL while visible, should clear prior block and set new one
  [[downloader expect] setProgressImageBlock:[OCMArg isNil] callbackQueue:OCMOCK_ANY withDownloadIdentifier:@0];
  [[downloader expect] cancelImageDownloadForIdentifier:@0];
  [[downloader expect] setProgressImageBlock:[OCMArg isNotNil] callbackQueue:OCMOCK_ANY withDownloadIdentifier:@1];
  node.URL = [NSURL URLWithString:@"http://imageB"];
  [downloader verifyWithDelay:5];
}

- (void)testThatSettingAnImageWillStayForEnteringAndExitingPreloadState
{
  UIImage *image = [[UIImage alloc] init];
  ASNetworkImageNode *networkImageNode = [[ASNetworkImageNode alloc] init];
  networkImageNode.image = image;
  [networkImageNode enterHierarchyState:ASHierarchyStateRangeManaged];  // Ensures didExitPreloadState is called
  XCTAssertEqualObjects(image, networkImageNode.image);
  [networkImageNode enterInterfaceState:ASInterfaceStatePreload];
  XCTAssertEqualObjects(image, networkImageNode.image);
  [networkImageNode exitInterfaceState:ASInterfaceStatePreload];
  XCTAssertEqualObjects(image, networkImageNode.image);
  [networkImageNode exitHierarchyState:ASHierarchyStateRangeManaged];
  XCTAssertEqualObjects(image, networkImageNode.image);
}

- (void)testThatSettingADefaultImageWillStayForEnteringAndExitingPreloadState
{
  UIImage *image = [[UIImage alloc] init];
  ASNetworkImageNode *networkImageNode = [[ASNetworkImageNode alloc] init];
  networkImageNode.defaultImage = image;
  [networkImageNode enterHierarchyState:ASHierarchyStateRangeManaged];  // Ensures didExitPreloadState is called
  XCTAssertEqualObjects(image, networkImageNode.defaultImage);
  [networkImageNode enterInterfaceState:ASInterfaceStatePreload];
  XCTAssertEqualObjects(image, networkImageNode.defaultImage);
  [networkImageNode exitInterfaceState:ASInterfaceStatePreload];
  XCTAssertEqualObjects(image, networkImageNode.defaultImage);
  [networkImageNode exitHierarchyState:ASHierarchyStateRangeManaged];
  XCTAssertEqualObjects(image, networkImageNode.defaultImage);
}

@end

@implementation ASTestImageCache

- (void)cachedImageWithURL:(NSURL *)URL callbackQueue:(dispatch_queue_t)callbackQueue completion:(ASImageCacherCompletion)completion
{
  completion(nil, ASImageCacheTypeAsynchronous);
}

@end

@implementation ASTestImageDownloader {
  NSInteger _currentDownloadID;
}

- (void)cancelImageDownloadForIdentifier:(id)downloadIdentifier
{
  // nop
}

- (id)downloadImageWithURL:(NSURL *)URL callbackQueue:(dispatch_queue_t)callbackQueue downloadProgress:(ASImageDownloaderProgress)downloadProgress completion:(ASImageDownloaderCompletion)completion
{
  return @(_currentDownloadID++);
}

- (void)setProgressImageBlock:(ASImageDownloaderProgressImage)progressBlock callbackQueue:(dispatch_queue_t)callbackQueue withDownloadIdentifier:(id)downloadIdentifier
{
  // nop
}
@end
