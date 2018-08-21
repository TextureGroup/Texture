//
//  ASWrapperSpecSnapshotTests.mm
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

@interface ASWrapperSpecSnapshotTests : ASLayoutSpecSnapshotTestCase
@end

@implementation ASWrapperSpecSnapshotTests

- (void)testWrapperSpecWithOneElementShouldSizeToElement
{
  ASDisplayNode *child = ASDisplayNodeWithBackgroundColor([UIColor redColor], {50, 50});
  
  ASSizeRange sizeRange = ASSizeRangeMake(CGSizeZero, CGSizeMake(INFINITY, INFINITY));
  [self testWithChildren:@[child] sizeRange:sizeRange identifier:nil];
}

- (void)testWrapperSpecWithMultipleElementsShouldSizeToLargestElement
{
  ASDisplayNode *firstChild = ASDisplayNodeWithBackgroundColor([UIColor redColor], {50, 50});
  ASDisplayNode *secondChild = ASDisplayNodeWithBackgroundColor([UIColor greenColor], {100, 100});
  
  ASSizeRange sizeRange = ASSizeRangeMake(CGSizeZero, CGSizeMake(INFINITY, INFINITY));
  [self testWithChildren:@[secondChild, firstChild] sizeRange:sizeRange identifier:nil];
}

- (void)testWithChildren:(NSArray *)children sizeRange:(ASSizeRange)sizeRange identifier:(NSString *)identifier
{
  ASDisplayNode *backgroundNode = ASDisplayNodeWithBackgroundColor([UIColor whiteColor]);

  NSMutableArray *subnodes = [NSMutableArray arrayWithArray:children];
  [subnodes insertObject:backgroundNode atIndex:0];

  ASLayoutSpec *layoutSpec =
  [ASBackgroundLayoutSpec backgroundLayoutSpecWithChild:
   [ASWrapperLayoutSpec
    wrapperWithLayoutElements:children]
   background:backgroundNode];
  
  [self testLayoutSpec:layoutSpec sizeRange:sizeRange subnodes:subnodes identifier:identifier];
}

@end
