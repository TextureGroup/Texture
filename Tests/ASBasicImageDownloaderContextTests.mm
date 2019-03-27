//
//  ASBasicImageDownloaderContextTests.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASBasicImageDownloader.h>
#import <AsyncDisplayKit/ASBasicImageDownloaderInternal.h>

#import <OCMock/OCMock.h>

#import <XCTest/XCTest.h>


@interface ASBasicImageDownloaderContextTests : XCTestCase

@end

@implementation ASBasicImageDownloaderContextTests

- (NSURL *)randomURL
{
  // random URL for each test, doesn't matter that this is not really a URL
  return [NSURL URLWithString:[NSUUID UUID].UUIDString];
}

- (void)testContextCreation
{
  NSURL *url = [self randomURL];
  ASBasicImageDownloaderContext *c1 = [ASBasicImageDownloaderContext contextForURL:url];
  ASBasicImageDownloaderContext *c2 = [ASBasicImageDownloaderContext contextForURL:url];
  XCTAssert(c1 == c2, @"Context objects are not the same");
}

- (void)testContextInvalidation
{
  NSURL *url = [self randomURL];
  ASBasicImageDownloaderContext *context = [ASBasicImageDownloaderContext contextForURL:url];
  [context cancel];
  XCTAssert([context isCancelled], @"Context should be cancelled");
}

/* This test is currently unreliable.  See https://github.com/facebook/AsyncDisplayKit/issues/459
- (void)testAsyncContextInvalidation
{
  NSURL *url = [self randomURL];
  ASBasicImageDownloaderContext *context = [ASBasicImageDownloaderContext contextForURL:url];
  XCTestExpectation *expectation = [self expectationWithDescription:@"Context invalidation"];

  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    [expectation fulfill];
    XCTAssert([context isCancelled], @"Context should be cancelled");
  });

  [context cancel];
  [self waitForExpectationsWithTimeout:30.0 handler:nil];
}
*/

- (void)testContextSessionCanceled
{
  NSURL *url = [self randomURL];
  id task = [OCMockObject mockForClass:[NSURLSessionTask class]];
  ASBasicImageDownloaderContext *context = [ASBasicImageDownloaderContext contextForURL:url];
  context.sessionTask = task;

  [[task expect] cancel];

  [context cancel];
}

@end
