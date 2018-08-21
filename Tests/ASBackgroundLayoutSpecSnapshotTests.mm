//
//  ASBackgroundLayoutSpecSnapshotTests.mm
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASLayoutSpecSnapshotTestsHelper.h"

#import <AsyncDisplayKit/ASBackgroundLayoutSpec.h>
#import <AsyncDisplayKit/ASCenterLayoutSpec.h>

static const ASSizeRange kSize = {{320, 320}, {320, 320}};

@interface ASBackgroundLayoutSpecSnapshotTests : ASLayoutSpecSnapshotTestCase

@end

@implementation ASBackgroundLayoutSpecSnapshotTests

- (void)testBackground
{
  ASDisplayNode *backgroundNode = ASDisplayNodeWithBackgroundColor([UIColor blueColor]);
  ASDisplayNode *foregroundNode = ASDisplayNodeWithBackgroundColor([UIColor blackColor], {20, 20});
  
  ASLayoutSpec *layoutSpec =
  [ASBackgroundLayoutSpec
   backgroundLayoutSpecWithChild:
   [ASCenterLayoutSpec
    centerLayoutSpecWithCenteringOptions:ASCenterLayoutSpecCenteringXY
    sizingOptions:{}
    child:foregroundNode]
   background:backgroundNode];
  
  [self testLayoutSpec:layoutSpec sizeRange:kSize subnodes:@[backgroundNode, foregroundNode] identifier: nil];
}

@end
