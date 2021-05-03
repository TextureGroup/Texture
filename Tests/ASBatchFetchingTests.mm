//
//  ASBatchFetchingTests.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <XCTest/XCTest.h>

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import <AsyncDisplayKit/ASBatchFetching.h>

@interface ASBatchFetchingTests : XCTestCase

@end

@implementation ASBatchFetchingTests

#define PASSING_RECT CGRectMake(0,0,1,1)
#define PASSING_SIZE CGSizeMake(1,1)
#define PASSING_POINT CGPointMake(1,1)
#define VERTICAL_RECT(h) CGRectMake(0,0,1,h)
#define VERTICAL_SIZE(h) CGSizeMake(0,h)
#define VERTICAL_OFFSET(y) CGPointMake(0,y)
#define HORIZONTAL_RECT(w) CGRectMake(0,0,w,1)
#define HORIZONTAL_SIZE(w) CGSizeMake(w,0)
#define HORIZONTAL_OFFSET(x) CGPointMake(x,0)

- (void)testBatchNullState {
  ASBatchContext *context = [[ASBatchContext alloc] init];
  BOOL shouldFetch = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionDown, ASScrollDirectionVerticalDirections, CGRectZero, CGSizeZero, CGPointZero, 0.0, YES, NO, CGPointZero, NO, nil);
  XCTAssert(shouldFetch == NO, @"Should not fetch in the null state");

  // test RTL
  BOOL shouldFetchRTL = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionDown, ASScrollDirectionVerticalDirections, CGRectZero, CGSizeZero, CGPointZero, 0.0, YES, YES, CGPointZero, NO, nil);
  XCTAssert(shouldFetchRTL == NO, @"Should not fetch in the null state");

  // test RTL with a layout that automatically flips (should act the same as LTR)
  BOOL shouldFetchRTLFlip = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionDown, ASScrollDirectionVerticalDirections, CGRectZero, CGSizeZero, CGPointZero, 0.0, YES, YES, CGPointZero, YES, nil);
  XCTAssert(shouldFetchRTLFlip == NO, @"Should not fetch in the null state");
}

- (void)testBatchAlreadyFetching {
  ASBatchContext *context = [[ASBatchContext alloc] init];
  [context beginBatchFetching];
  BOOL shouldFetch = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionDown, ASScrollDirectionVerticalDirections, PASSING_RECT, PASSING_SIZE, PASSING_POINT, 1.0, YES, NO, CGPointZero, NO, nil);
  XCTAssert(shouldFetch == NO, @"Should not fetch when context is already fetching");

  // test RTL
  BOOL shouldFetchRTL = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionDown, ASScrollDirectionVerticalDirections, PASSING_RECT, PASSING_SIZE, PASSING_POINT, 1.0, YES, YES, CGPointZero, NO, nil);
  XCTAssert(shouldFetchRTL == NO, @"Should not fetch when context is already fetching");

  // test RTL with a layout that automatically flips (should act the same as LTR)
  BOOL shouldFetchRTLFlip = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionDown, ASScrollDirectionVerticalDirections, PASSING_RECT, PASSING_SIZE, PASSING_POINT, 1.0, YES, YES, CGPointZero, YES, nil);
  XCTAssert(shouldFetchRTLFlip == NO, @"Should not fetch in the null state");
}

- (void)testUnsupportedScrollDirections {
  ASBatchContext *context = [[ASBatchContext alloc] init];
  BOOL fetchRight = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionRight, ASScrollDirectionHorizontalDirections, PASSING_RECT, PASSING_SIZE, PASSING_POINT, 1.0, YES, NO, CGPointZero, NO, nil);
  XCTAssert(fetchRight == YES, @"Should fetch for scrolling right");
  BOOL fetchDown = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionDown, ASScrollDirectionVerticalDirections, PASSING_RECT, PASSING_SIZE, PASSING_POINT, 1.0, YES, NO, CGPointZero, NO, nil);
  XCTAssert(fetchDown == YES, @"Should fetch for scrolling down");
  BOOL fetchUp = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionUp, ASScrollDirectionVerticalDirections, PASSING_RECT, PASSING_SIZE, PASSING_POINT, 1.0, YES, NO, CGPointZero, NO, nil);
  XCTAssert(fetchUp == NO, @"Should not fetch for scrolling up");
  BOOL fetchLeft = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionLeft, ASScrollDirectionHorizontalDirections, PASSING_RECT, PASSING_SIZE, PASSING_POINT, 1.0, YES, NO, CGPointZero, NO, nil);
  XCTAssert(fetchLeft == NO, @"Should not fetch for scrolling left");
  
  // test RTL
  BOOL fetchRightRTL = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionRight, ASScrollDirectionHorizontalDirections, PASSING_RECT, PASSING_SIZE, PASSING_POINT, 1.0, YES, YES, CGPointZero, NO, nil);
  XCTAssert(fetchRightRTL == NO, @"Should not fetch for scrolling right");
  BOOL fetchDownRTL = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionDown, ASScrollDirectionVerticalDirections, PASSING_RECT, PASSING_SIZE, PASSING_POINT, 1.0, YES, YES, CGPointZero, NO, nil);
  XCTAssert(fetchDownRTL == YES, @"Should fetch for scrolling down");
  BOOL fetchUpRTL = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionUp, ASScrollDirectionVerticalDirections, PASSING_RECT, PASSING_SIZE, PASSING_POINT, 1.0, YES, YES, CGPointZero, NO, nil);
  XCTAssert(fetchUpRTL == NO, @"Should not fetch for scrolling up");
  BOOL fetchLeftRTL = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionLeft, ASScrollDirectionHorizontalDirections, PASSING_RECT, PASSING_SIZE, PASSING_POINT, 1.0, YES, YES, CGPointZero, NO, nil);
  XCTAssert(fetchLeftRTL == YES, @"Should fetch for scrolling left");

  // test RTL with a layout that automatically flips (should act the same as LTR)
  BOOL fetchRightRTLFlip = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionRight, ASScrollDirectionHorizontalDirections, PASSING_RECT, PASSING_SIZE, PASSING_POINT, 1.0, YES, YES, CGPointZero, YES, nil);
  XCTAssert(fetchRightRTLFlip == NO, @"Should fetch for scrolling right");
  BOOL fetchDownRTLFlip = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionDown, ASScrollDirectionVerticalDirections, PASSING_RECT, PASSING_SIZE, PASSING_POINT, 1.0, YES, YES, CGPointZero, YES, nil);
  XCTAssert(fetchDownRTLFlip == YES, @"Should fetch for scrolling down");
  BOOL fetchUpRTLFlip = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionUp, ASScrollDirectionVerticalDirections, PASSING_RECT, PASSING_SIZE, PASSING_POINT, 1.0, YES, YES, CGPointZero, YES, nil);
  XCTAssert(fetchUpRTLFlip == NO, @"Should not fetch for scrolling up");
  BOOL fetchLeftRTLFlip = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionLeft, ASScrollDirectionHorizontalDirections, PASSING_RECT, PASSING_SIZE, PASSING_POINT, 1.0, YES, YES, CGPointZero, YES, nil);
  XCTAssert(fetchLeftRTLFlip == YES, @"Should not fetch for scrolling left");
}

- (void)testVerticalScrollToExactLeading {
  CGFloat screen = 1.0;
  ASBatchContext *context = [[ASBatchContext alloc] init];
  // scroll to 1-screen top offset, height is 1 screen, so bottom is 1 screen away from end of content
  BOOL shouldFetch = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionDown, ASScrollDirectionVerticalDirections, VERTICAL_RECT(screen), VERTICAL_SIZE(screen * 3.0), VERTICAL_OFFSET(screen * 1.0), 1.0, YES, NO, CGPointZero, NO, nil);
  XCTAssert(shouldFetch == YES, @"Fetch should begin when vertically scrolling to exactly 1 leading screen away");

  // test RTL
  BOOL shouldFetchRTL = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionDown, ASScrollDirectionVerticalDirections, VERTICAL_RECT(screen), VERTICAL_SIZE(screen * 3.0), VERTICAL_OFFSET(screen * 1.0), 1.0, YES, YES, CGPointZero, NO, nil);
  XCTAssert(shouldFetchRTL == YES, @"Fetch should begin when vertically scrolling to exactly 1 leading screen away");

  // test RTL with a layout that automatically flips (should act the same as LTR)
  BOOL shouldFetchRTLFlip = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionDown, ASScrollDirectionVerticalDirections, VERTICAL_RECT(screen), VERTICAL_SIZE(screen * 3.0), VERTICAL_OFFSET(screen * 1.0), 1.0, YES, YES, CGPointZero, YES, nil);
  XCTAssert(shouldFetchRTLFlip == YES, @"Fetch should begin when vertically scrolling to exactly 1 leading screen away");
}

- (void)testVerticalScrollToLessThanLeading {
  CGFloat screen = 1.0;
  ASBatchContext *context = [[ASBatchContext alloc] init];
  // 3 screens of content, scroll only 1/2 of one screen
  BOOL shouldFetch = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionDown, ASScrollDirectionVerticalDirections, VERTICAL_RECT(screen), VERTICAL_SIZE(screen * 3.0), VERTICAL_OFFSET(screen * 0.5), 1.0, YES, NO, CGPointZero, NO, nil);
  XCTAssert(shouldFetch == NO, @"Fetch should not begin when vertically scrolling less than the leading distance away");

  // test RTL
  BOOL shouldFetchRTL = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionDown, ASScrollDirectionVerticalDirections, VERTICAL_RECT(screen), VERTICAL_SIZE(screen * 3.0), VERTICAL_OFFSET(screen * 0.5), 1.0, YES, YES, CGPointZero, NO, nil);
  XCTAssert(shouldFetchRTL == NO, @"Fetch should not begin when vertically scrolling less than the leading distance away");

  // test RTL with a layout that automatically flips (should act the same as LTR)
  BOOL shouldFetchRTLFlip = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionDown, ASScrollDirectionVerticalDirections, VERTICAL_RECT(screen), VERTICAL_SIZE(screen * 3.0), VERTICAL_OFFSET(screen * 0.5), 1.0, YES, YES, CGPointZero, YES, nil);
  XCTAssert(shouldFetchRTLFlip == NO, @"Fetch should not begin when vertically scrolling less than the leading distance away");
}

- (void)testVerticalScrollingPastContentSize {
  CGFloat screen = 1.0;
  ASBatchContext *context = [[ASBatchContext alloc] init];
  // 3 screens of content, top offset to 3-screens, height 1 screen, so its 1 screen past the leading
  BOOL shouldFetch = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionDown, ASScrollDirectionVerticalDirections, VERTICAL_RECT(screen), VERTICAL_SIZE(screen * 3.0), VERTICAL_OFFSET(screen * 3.0), 1.0, YES, NO, CGPointZero, NO, nil);
  XCTAssert(shouldFetch == YES, @"Fetch should begin when vertically scrolling past the content size");

  // test RTL
  BOOL shouldFetchRTL = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionDown, ASScrollDirectionVerticalDirections, VERTICAL_RECT(screen), VERTICAL_SIZE(screen * 3.0), VERTICAL_OFFSET(screen * 3.0), 1.0, YES, YES, CGPointZero, NO, nil);
  XCTAssert(shouldFetchRTL == YES, @"Fetch should begin when vertically scrolling past the content size");

  // test RTL with a layout that automatically flips (should act the same as LTR)
  BOOL shouldFetchRTLFlip = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionDown, ASScrollDirectionVerticalDirections, VERTICAL_RECT(screen), VERTICAL_SIZE(screen * 3.0), VERTICAL_OFFSET(screen * 3.0), 1.0, YES, YES, CGPointZero, YES, nil);
  XCTAssert(shouldFetchRTLFlip == YES, @"Fetch should begin when vertically scrolling past the content size");
}

- (void)testHorizontalScrollToExactLeading {
  CGFloat screen = 1.0;
  ASBatchContext *context = [[ASBatchContext alloc] init];
  // scroll to 1-screen left offset, width is 1 screen, so right is 1 screen away from end of content
  BOOL shouldFetch = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionRight, ASScrollDirectionVerticalDirections, HORIZONTAL_RECT(screen), HORIZONTAL_SIZE(screen * 3.0), HORIZONTAL_OFFSET(screen * 1.0), 1.0, YES, NO, CGPointZero, NO, nil);
  XCTAssert(shouldFetch == YES, @"Fetch should begin when horizontally scrolling to exactly 1 leading screen away");

  // test RTL
  BOOL shouldFetchRTL = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionRight, ASScrollDirectionVerticalDirections, HORIZONTAL_RECT(screen), HORIZONTAL_SIZE(screen * 3.0), HORIZONTAL_OFFSET(screen * 1.0), 1.0, YES, YES, CGPointZero, NO, nil);
  XCTAssert(shouldFetchRTL == YES, @"Fetch should begin when horizontally scrolling to exactly 1 leading screen away");

  // test RTL with a layout that automatically flips (should act the same as LTR)
  BOOL shouldFetchRTLFlip = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionRight, ASScrollDirectionVerticalDirections, HORIZONTAL_RECT(screen), HORIZONTAL_SIZE(screen * 3.0), HORIZONTAL_OFFSET(screen * 1.0), 1.0, YES, YES, CGPointZero, YES, nil);
  XCTAssert(shouldFetchRTLFlip == YES, @"Fetch should begin when horizontally scrolling to exactly 1 leading screen away");
}

- (void)testHorizontalScrollToLessThanLeading {
  CGFloat screen = 1.0;
  ASBatchContext *context = [[ASBatchContext alloc] init];
  // 3 screens of content, scroll only 1/2 of one screen
  BOOL shouldFetch = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionLeft, ASScrollDirectionHorizontalDirections, HORIZONTAL_RECT(screen), HORIZONTAL_SIZE(screen * 3.0), HORIZONTAL_OFFSET(screen * 0.5), 1.0, YES, NO, CGPointZero, NO, nil);
  XCTAssert(shouldFetch == NO, @"Fetch should not begin when horizontally scrolling less than the leading distance away");
  
  // In RTL since scrolling is reversed, our remaining distance is actually our offset (0.5) which is less than our leading screen (1). So we do want to fetch
  BOOL shouldFetchRTL = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionLeft, ASScrollDirectionHorizontalDirections, HORIZONTAL_RECT(screen), HORIZONTAL_SIZE(screen * 3.0), HORIZONTAL_OFFSET(screen * 0.5), 1.0, YES, YES, CGPointZero, NO, nil);
  XCTAssert(shouldFetchRTL == YES, @"Fetch should begin when horizontally scrolling less than the leading distance away");

  // test RTL with a layout that automatically flips (should act the same as LTR)
  BOOL shouldFetchRTLFlip = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionLeft, ASScrollDirectionHorizontalDirections, HORIZONTAL_RECT(screen), HORIZONTAL_SIZE(screen * 3.0), HORIZONTAL_OFFSET(screen * 0.5), 1.0, YES, YES, CGPointZero, YES, nil);
  XCTAssert(shouldFetchRTLFlip == NO, @"Fetch should not begin when horizontally scrolling less than the leading distance away");
}

- (void)testHorizontalScrollingPastContentSize {
  CGFloat screen = 1.0;
  ASBatchContext *context = [[ASBatchContext alloc] init];
  // 3 screens of content, left offset to 3-screens, width 1 screen, so its 1 screen past the leading
  BOOL shouldFetch = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionDown, ASScrollDirectionHorizontalDirections, HORIZONTAL_RECT(screen), HORIZONTAL_SIZE(screen * 3.0), HORIZONTAL_OFFSET(screen * 3.0), 1.0, YES, NO, CGPointZero, NO, nil);
  XCTAssert(shouldFetch == YES, @"Fetch should begin when horizontally scrolling past the content size");

  // In RTL scrolling is reversed, our remaining distance is actually our offset (3) which is more than our leading screen (1). So we do no fetch
  BOOL shouldFetchRTL = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionDown, ASScrollDirectionHorizontalDirections, HORIZONTAL_RECT(screen), HORIZONTAL_SIZE(screen * 3.0), HORIZONTAL_OFFSET(screen * 3.0), 1.0, YES, YES, CGPointZero, NO, nil);
  XCTAssert(shouldFetchRTL == NO, @"Fetch not should begin when horizontally scrolling past the content size");

  // test RTL with a layout that automatically flips (should act the same as LTR)
  // 3 screens of content, left offset to 3-screens, width 1 screen, so its 1 screen past the leading
  BOOL shouldFetchFlipRTL = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionDown, ASScrollDirectionHorizontalDirections, HORIZONTAL_RECT(screen), HORIZONTAL_SIZE(screen * 3.0), HORIZONTAL_OFFSET(screen * 3.0), 1.0, YES, YES, CGPointZero, YES, nil);
  XCTAssert(shouldFetchFlipRTL == YES, @"Fetch should begin when horizontally scrolling past the content size");
}

- (void)testVerticalScrollingSmallContentSize {
  CGFloat screen = 1.0;
  ASBatchContext *context = [[ASBatchContext alloc] init];
  // when the content size is < screen size, the target offset will always be 0
  BOOL shouldFetch = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionDown, ASScrollDirectionVerticalDirections, VERTICAL_RECT(screen), VERTICAL_SIZE(screen * 0.5), VERTICAL_OFFSET(0.0), 1.0, YES, NO, CGPointZero, NO, nil);
  XCTAssert(shouldFetch == YES, @"Fetch should begin when the target is 0 and the content size is smaller than the scree");
  
  // test RTL
  BOOL shouldFetchRTL = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionDown, ASScrollDirectionVerticalDirections, VERTICAL_RECT(screen), VERTICAL_SIZE(screen * 0.5), VERTICAL_OFFSET(0.0), 1.0, YES, YES, CGPointZero, NO, nil);
  XCTAssert(shouldFetchRTL == YES, @"Fetch should begin when the target is 0 and the content size is smaller than the scree");

  // test RTL with a layout that automatically flips (should act the same as LTR)
  BOOL shouldFetchRTLFlip = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionDown, ASScrollDirectionVerticalDirections, VERTICAL_RECT(screen), VERTICAL_SIZE(screen * 0.5), VERTICAL_OFFSET(0.0), 1.0, YES, YES, CGPointZero, YES, nil);
  XCTAssert(shouldFetchRTLFlip == YES, @"Fetch should begin when the target is 0 and the content size is smaller than the scree");
}

- (void)testHorizontalScrollingSmallContentSize {
  CGFloat screen = 1.0;
  ASBatchContext *context = [[ASBatchContext alloc] init];
  // when the content size is < screen size, the target offset will always be 0
  BOOL shouldFetch = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionRight, ASScrollDirectionHorizontalDirections, HORIZONTAL_RECT(screen), HORIZONTAL_SIZE(screen * 0.5), HORIZONTAL_OFFSET(0.0), 1.0, YES, NO, CGPointZero, NO, nil);
  XCTAssert(shouldFetch == YES, @"Fetch should begin when the target is 0 and the content size is smaller than the scree");

  // test RTL
  BOOL shouldFetchRTL = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionRight, ASScrollDirectionHorizontalDirections, HORIZONTAL_RECT(screen), HORIZONTAL_SIZE(screen * 0.5), HORIZONTAL_OFFSET(0.0), 1.0, YES, YES, CGPointZero, NO, nil);
  XCTAssert(shouldFetchRTL == YES, @"Fetch should begin when the target is 0 and the content size is smaller than the scree");

  // test RTL with a layout that automatically flips (should act the same as LTR)
  BOOL shouldFetchRTLFlip = ASDisplayShouldFetchBatchForContext(context, ASScrollDirectionRight, ASScrollDirectionHorizontalDirections, HORIZONTAL_RECT(screen), HORIZONTAL_SIZE(screen * 0.5), HORIZONTAL_OFFSET(0.0), 1.0, YES, YES, CGPointZero, YES, nil);
  XCTAssert(shouldFetchRTLFlip == YES, @"Fetch should begin when the target is 0 and the content size is smaller than the scree");
}

@end
