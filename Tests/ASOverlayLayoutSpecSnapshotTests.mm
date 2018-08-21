//
//  ASOverlayLayoutSpecSnapshotTests.mm
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASLayoutSpecSnapshotTestsHelper.h"

#import <AsyncDisplayKit/ASOverlayLayoutSpec.h>
#import <AsyncDisplayKit/ASCenterLayoutSpec.h>

static const ASSizeRange kSize = {{320, 320}, {320, 320}};

@interface ASOverlayLayoutSpecSnapshotTests : ASLayoutSpecSnapshotTestCase
@end

@implementation ASOverlayLayoutSpecSnapshotTests

- (void)testOverlay
{
  ASDisplayNode *backgroundNode = ASDisplayNodeWithBackgroundColor([UIColor blueColor]);
  ASDisplayNode *foregroundNode = ASDisplayNodeWithBackgroundColor([UIColor blackColor], {20, 20});
  
  ASLayoutSpec *layoutSpec =
  [ASOverlayLayoutSpec
   overlayLayoutSpecWithChild:backgroundNode
   overlay:
   [ASCenterLayoutSpec
    centerLayoutSpecWithCenteringOptions:ASCenterLayoutSpecCenteringXY
    sizingOptions:{}
    child:foregroundNode]];
  
  [self testLayoutSpec:layoutSpec sizeRange:kSize subnodes:@[backgroundNode, foregroundNode] identifier: nil];
}

@end
