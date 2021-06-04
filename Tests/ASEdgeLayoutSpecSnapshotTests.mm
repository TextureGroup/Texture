//
//  ASEdgeLayoutSpecSnapshotTests.mm
//  AsyncDisplayKitTests
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASLayoutSpecSnapshotTestsHelper.h"
#import <AsyncDisplayKit/ASEdgeLayoutSpec.h>
#import <AsyncDisplayKit/ASBackgroundLayoutSpec.h>
#import <AsyncDisplayKit/ASCenterLayoutSpec.h>

@interface ASEdgeLayoutSpecSnapshotTests : ASLayoutSpecSnapshotTestCase

@property (nonatomic, copy) UIColor *boxColor;
@property (nonatomic, copy) UIColor *baseColor;
@property (nonatomic, copy) UIColor *edgeColor;
@property (nonatomic, copy) UIColor *contextColor;

@property (nonatomic) CGSize baseSize;
@property (nonatomic) CGSize edgeSize;
@property (nonatomic) CGSize contextSize;

@property (nonatomic) ASSizeRange contextSizeRange;

@end

@implementation ASEdgeLayoutSpecSnapshotTests

- (void)setUp
{
  [super setUp];

  self.recordMode = NO;

  _boxColor = [UIColor greenColor];
  _baseColor = [UIColor blueColor];
  _edgeColor = [UIColor orangeColor];
  _contextColor = [UIColor lightGrayColor];

  _baseSize = CGSizeMake(60, 60);
  _edgeSize = CGSizeMake(20, 20);
  _contextSize = CGSizeMake(200, 200);

  _contextSizeRange = ASSizeRangeMake(CGSizeZero, _contextSize);
}

- (void)testEdgeSpecForAllLocations
{
  CGFloat offset = 0.0;
  [self testEdgeSpecWithLocation:ASEdgeLayoutLocationTop offset:offset];
  [self testEdgeSpecWithLocation:ASEdgeLayoutLocationLeft offset:offset];
  [self testEdgeSpecWithLocation:ASEdgeLayoutLocationBottom offset:offset];
  [self testEdgeSpecWithLocation:ASEdgeLayoutLocationRight offset:offset];
}

- (void)testEdgeSpecForAllLocationsWithInnerOffset
{
  [self testEdgeSpecWithLocation:ASEdgeLayoutLocationTop offset:-_edgeSize.height];
  [self testEdgeSpecWithLocation:ASEdgeLayoutLocationLeft offset:-_edgeSize.width];
  [self testEdgeSpecWithLocation:ASEdgeLayoutLocationBottom offset:-_edgeSize.height];
  [self testEdgeSpecWithLocation:ASEdgeLayoutLocationRight offset:-_edgeSize.width];
}

- (void)testEdgeSpecForAllLocationsWithOuterOffset
{
  [self testEdgeSpecWithLocation:ASEdgeLayoutLocationTop offset:_edgeSize.height];
  [self testEdgeSpecWithLocation:ASEdgeLayoutLocationLeft offset:_edgeSize.width];
  [self testEdgeSpecWithLocation:ASEdgeLayoutLocationBottom offset:_edgeSize.height];
  [self testEdgeSpecWithLocation:ASEdgeLayoutLocationRight offset:_edgeSize.width];
}


- (void)testEdgeSpecWithLocation:(ASEdgeLayoutLocation)location
                          offset:(CGFloat)offset
{
  ASDisplayNode *baseNode = ASDisplayNodeWithBackgroundColor(_baseColor, _baseSize);
  ASDisplayNode *edgeNode = ASDisplayNodeWithBackgroundColor(_edgeColor, _edgeSize);
  ASDisplayNode *debugBoxNode = ASDisplayNodeWithBackgroundColor(_boxColor);

  ASEdgeLayoutSpec *edgeSpec = [ASEdgeLayoutSpec edgeLayoutSpecWithChild:baseNode
                                                                    edge:edgeNode
                                                                location:location];
  edgeSpec.offset = offset;

  ASCenterLayoutSpec *centerSpec = [ASCenterLayoutSpec centerLayoutSpecWithCenteringOptions:ASCenterLayoutSpecCenteringXY sizingOptions:ASCenterLayoutSpecSizingOptionDefault child:edgeSpec];

  ASBackgroundLayoutSpec *backgroundSpec = [ASBackgroundLayoutSpec backgroundLayoutSpecWithChild:centerSpec
                                                                                      background:debugBoxNode];

  [self testLayoutSpec:backgroundSpec
             sizeRange:_contextSizeRange
              subnodes:@[debugBoxNode, baseNode, edgeNode]
            identifier:[self suffixWithLocation:location offset:offset]];
}

- (NSString *)suffixWithLocation:(ASEdgeLayoutLocation)location
                          offset:(CGFloat)offset
{
  NSMutableString *desc = [NSMutableString string];

  switch (location) {
    case ASEdgeLayoutLocationTop:
      [desc appendString:@"top"];
      break;
    case ASEdgeLayoutLocationLeft:
      [desc appendString:@"left"];
      break;
    case ASEdgeLayoutLocationBottom:
      [desc appendString:@"bottom"];
      break;
    case ASEdgeLayoutLocationRight:
      [desc appendString:@"right"];
      break;
  }

  [desc appendString:@"_"];

  switch (location) {
    case ASEdgeLayoutLocationTop:
      if (offset >= 0.0) {
        [desc appendString:@"outer"];
      } else {
        [desc appendString:@"inner"];
      }
      break;
    case ASEdgeLayoutLocationLeft:
      if (offset >= 0.0) {
        [desc appendString:@"inner"];
      } else {
        [desc appendString:@"outer"];
      }
      break;
    case ASEdgeLayoutLocationBottom:
      if (offset >= 0.0) {
        [desc appendString:@"inner"];
      } else {
        [desc appendString:@"outer"];
      }
      break;
    case ASEdgeLayoutLocationRight:
      if (offset >= 0.0) {
        [desc appendString:@"outer"];
      } else {
        [desc appendString:@"inner"];
      }
      break;
  }

  return desc.copy;
}

@end
