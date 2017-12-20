//
//  ASCollectionViewFlowLayoutInspectorTests.m
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

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import <OCMock/OCMock.h>
#import "ASXCTExtensions.h"

#import <AsyncDisplayKit/ASCollectionNode.h>
#import <AsyncDisplayKit/ASCollectionViewFlowLayoutInspector.h>
#import <AsyncDisplayKit/ASCellNode.h>

/**
 * Test Data Source
 */
@interface InspectorTestDataSource : NSObject <ASCollectionDataSource>
@end

@implementation InspectorTestDataSource

- (ASCellNode *)collectionNode:(ASCollectionNode *)collectionNode nodeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return [[ASCellNode alloc] init];
}

- (ASCellNodeBlock)collectionNode:(ASCollectionNode *)collectionNode nodeBlockForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return ^{ return [[ASCellNode alloc] init]; };
}

- (NSInteger)collectionNode:(ASCollectionNode *)collectionNode numberOfItemsInSection:(NSInteger)section
{
  return 0;
}

- (NSInteger)numberOfSectionsInCollectionNode:(ASCollectionNode *)collectionNode
{
  return 2;
}

@end

/**
 * Test Delegate for Header Reference Size Implementation
 */
@interface HeaderReferenceSizeTestDelegate : NSObject <ASCollectionDelegateFlowLayout>

@end

@implementation HeaderReferenceSizeTestDelegate

- (ASSizeRange)collectionNode:(ASCollectionNode *)collectionNode sizeRangeForHeaderInSection:(NSInteger)section
{
  return ASSizeRangeMake(CGSizeMake(125.0, 125.0));
}

@end

/**
 * Test Delegate for Footer Reference Size Implementation
 */
@interface FooterReferenceSizeTestDelegate : NSObject <ASCollectionDelegateFlowLayout>

@end

@implementation FooterReferenceSizeTestDelegate

- (ASSizeRange)collectionNode:(ASCollectionNode *)collectionNode sizeRangeForFooterInSection:(NSInteger)section
{
  return ASSizeRangeMake(CGSizeMake(125.0, 125.0));
}

@end

@interface ASCollectionViewFlowLayoutInspectorTests : XCTestCase

@end

@implementation ASCollectionViewFlowLayoutInspectorTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - #collectionView:constrainedSizeForSupplementaryNodeOfKind:atIndexPath:

// Vertical

// Delegate implementation

- (void)testThatItReturnsAVerticalConstrainedSizeFromTheHeaderDelegateImplementation
{
  InspectorTestDataSource *dataSource = [[InspectorTestDataSource alloc] init];
  HeaderReferenceSizeTestDelegate *delegate = [[HeaderReferenceSizeTestDelegate alloc] init];
  
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.scrollDirection = UICollectionViewScrollDirectionVertical;

  CGRect rect = CGRectMake(0, 0, 100.0, 100.0);
  ASCollectionNode *collectionNode = [[ASCollectionNode alloc] initWithFrame:rect collectionViewLayout:layout];
  ASCollectionView *collectionView = collectionNode.view;
  collectionNode.dataSource = dataSource;
  collectionNode.delegate = delegate;
  
  ASCollectionViewFlowLayoutInspector *inspector = ASDynamicCast(collectionNode.layoutInspector, ASCollectionViewFlowLayoutInspector);
  ASSizeRange size = [inspector collectionView:collectionView constrainedSizeForSupplementaryNodeOfKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  ASSizeRange sizeCompare = ASSizeRangeMake(CGSizeMake(collectionNode.bounds.size.width, 125.0));

  ASXCTAssertEqualSizeRanges(size, sizeCompare, @"should have a size constrained by the values returned in the delegate implementation");
  
  collectionNode.dataSource = nil;
  collectionNode.delegate = nil;
}

- (void)testThatItReturnsAVerticalConstrainedSizeFromTheFooterDelegateImplementation
{
  InspectorTestDataSource *dataSource = [[InspectorTestDataSource alloc] init];
  FooterReferenceSizeTestDelegate *delegate = [[FooterReferenceSizeTestDelegate alloc] init];
  
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.scrollDirection = UICollectionViewScrollDirectionVertical;
  
  CGRect rect = CGRectMake(0, 0, 100.0, 100.0);
  ASCollectionNode *collectionNode = [[ASCollectionNode alloc] initWithFrame:rect collectionViewLayout:layout];
  ASCollectionView *collectionView = collectionNode.view;
  collectionNode.dataSource = dataSource;
  collectionNode.delegate = delegate;
  
  ASCollectionViewFlowLayoutInspector *inspector = ASDynamicCast(collectionNode.layoutInspector, ASCollectionViewFlowLayoutInspector);
  ASSizeRange size = [inspector collectionView:collectionView constrainedSizeForSupplementaryNodeOfKind:UICollectionElementKindSectionFooter atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  ASSizeRange sizeCompare = ASSizeRangeMake(CGSizeMake(collectionNode.bounds.size.width, 125.0));
  ASXCTAssertEqualSizeRanges(size, sizeCompare, @"should have a size constrained by the values returned in the delegate implementation");
  
  collectionNode.dataSource = nil;
  collectionNode.delegate = nil;
}

// Size implementation

- (void)testThatItReturnsAVerticalConstrainedSizeFromTheHeaderProperty
{
  InspectorTestDataSource *dataSource = [[InspectorTestDataSource alloc] init];
  
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.scrollDirection = UICollectionViewScrollDirectionVertical;
  layout.headerReferenceSize = CGSizeMake(125.0, 125.0);
  
  CGRect rect = CGRectMake(0, 0, 100.0, 100.0);
  ASCollectionNode *collectionNode = [[ASCollectionNode alloc] initWithFrame:rect collectionViewLayout:layout];
  ASCollectionView *collectionView = collectionNode.view;
  collectionNode.dataSource = dataSource;
  
  ASCollectionViewFlowLayoutInspector *inspector = ASDynamicCast(collectionNode.layoutInspector, ASCollectionViewFlowLayoutInspector);
  ASSizeRange size = [inspector collectionView:collectionView constrainedSizeForSupplementaryNodeOfKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  ASSizeRange sizeCompare = ASSizeRangeMake(CGSizeMake(collectionNode.bounds.size.width, 125.0));
  ASXCTAssertEqualSizeRanges(size, sizeCompare, @"should have a size constrained by the size set on the layout");
  
  collectionNode.dataSource = nil;
  collectionNode.delegate = nil;
}

- (void)testThatItReturnsAVerticalConstrainedSizeFromTheFooterProperty
{
  InspectorTestDataSource *dataSource = [[InspectorTestDataSource alloc] init];
  
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.scrollDirection = UICollectionViewScrollDirectionVertical;
  layout.footerReferenceSize = CGSizeMake(125.0, 125.0);
  
  CGRect rect = CGRectMake(0, 0, 100.0, 100.0);
  ASCollectionNode *collectionNode = [[ASCollectionNode alloc] initWithFrame:rect collectionViewLayout:layout];
  ASCollectionView *collectionView = collectionNode.view;
  collectionNode.dataSource = dataSource;
  
  ASCollectionViewFlowLayoutInspector *inspector = ASDynamicCast(collectionNode.layoutInspector, ASCollectionViewFlowLayoutInspector);
  ASSizeRange size = [inspector collectionView:collectionView constrainedSizeForSupplementaryNodeOfKind:UICollectionElementKindSectionFooter atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  ASSizeRange sizeCompare = ASSizeRangeMake(CGSizeMake(collectionNode.bounds.size.width, 125.0));
  ASXCTAssertEqualSizeRanges(size, sizeCompare, @"should have a size constrained by the size set on the layout");
  
  collectionNode.dataSource = nil;
  collectionNode.delegate = nil;
}

// Horizontal

- (void)testThatItReturnsAHorizontalConstrainedSizeFromTheHeaderDelegateImplementation
{
  InspectorTestDataSource *dataSource = [[InspectorTestDataSource alloc] init];
  HeaderReferenceSizeTestDelegate *delegate = [[HeaderReferenceSizeTestDelegate alloc] init];
  
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
  
  CGRect rect = CGRectMake(0, 0, 100.0, 100.0);
  ASCollectionNode *collectionNode = [[ASCollectionNode alloc] initWithFrame:rect collectionViewLayout:layout];
  ASCollectionView *collectionView = collectionNode.view;
  collectionNode.dataSource = dataSource;
  collectionNode.delegate = delegate;
  
  ASCollectionViewFlowLayoutInspector *inspector = ASDynamicCast(collectionNode.layoutInspector, ASCollectionViewFlowLayoutInspector);
  ASSizeRange size = [inspector collectionView:collectionView constrainedSizeForSupplementaryNodeOfKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  ASSizeRange sizeCompare = ASSizeRangeMake(CGSizeMake(125.0, collectionNode.bounds.size.height));
  ASXCTAssertEqualSizeRanges(size, sizeCompare, @"should have a size constrained by the values returned in the delegate implementation");
  
  collectionNode.dataSource = nil;
  collectionNode.delegate = nil;
}

- (void)testThatItReturnsAHorizontalConstrainedSizeFromTheFooterDelegateImplementation
{
  InspectorTestDataSource *dataSource = [[InspectorTestDataSource alloc] init];
  FooterReferenceSizeTestDelegate *delegate = [[FooterReferenceSizeTestDelegate alloc] init];
  
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
  
  CGRect rect = CGRectMake(0, 0, 100.0, 100.0);
  ASCollectionNode *collectionNode = [[ASCollectionNode alloc] initWithFrame:rect collectionViewLayout:layout];
  ASCollectionView *collectionView = collectionNode.view;
  collectionNode.dataSource = dataSource;
  collectionNode.delegate = delegate;
  
  ASCollectionViewFlowLayoutInspector *inspector = ASDynamicCast(collectionNode.layoutInspector, ASCollectionViewFlowLayoutInspector);
  ASSizeRange size = [inspector collectionView:collectionView constrainedSizeForSupplementaryNodeOfKind:UICollectionElementKindSectionFooter atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  ASSizeRange sizeCompare = ASSizeRangeMake(CGSizeMake(125.0, collectionNode.bounds.size.height));
  ASXCTAssertEqualSizeRanges(size, sizeCompare, @"should have a size constrained by the values returned in the delegate implementation");
  
  collectionNode.dataSource = nil;
  collectionNode.delegate = nil;
}

// Size implementation

- (void)testThatItReturnsAHorizontalConstrainedSizeFromTheHeaderProperty
{
  InspectorTestDataSource *dataSource = [[InspectorTestDataSource alloc] init];
  
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
  layout.headerReferenceSize = CGSizeMake(125.0, 125.0);
  
  CGRect rect = CGRectMake(0, 0, 100.0, 100.0);
  ASCollectionNode *collectionNode = [[ASCollectionNode alloc] initWithFrame:rect collectionViewLayout:layout];
  ASCollectionView *collectionView = collectionNode.view;
  collectionNode.dataSource = dataSource;
  
  ASCollectionViewFlowLayoutInspector *inspector = ASDynamicCast(collectionNode.layoutInspector, ASCollectionViewFlowLayoutInspector);
  ASSizeRange size = [inspector collectionView:collectionView constrainedSizeForSupplementaryNodeOfKind:UICollectionElementKindSectionHeader atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  ASSizeRange sizeCompare = ASSizeRangeMake(CGSizeMake(125.0, collectionNode.bounds.size.width));
  ASXCTAssertEqualSizeRanges(size, sizeCompare, @"should have a size constrained by the size set on the layout");
  
  collectionNode.dataSource = nil;
  collectionNode.delegate = nil;
}

- (void)testThatItReturnsAHorizontalConstrainedSizeFromTheFooterProperty
{
  InspectorTestDataSource *dataSource = [[InspectorTestDataSource alloc] init];
  
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
  layout.footerReferenceSize = CGSizeMake(125.0, 125.0);
  
  CGRect rect = CGRectMake(0, 0, 100.0, 100.0);
  ASCollectionNode *collectionNode = [[ASCollectionNode alloc] initWithFrame:rect collectionViewLayout:layout];
  ASCollectionView *collectionView = collectionNode.view;
  collectionNode.dataSource = dataSource;
  
  ASCollectionViewFlowLayoutInspector *inspector = ASDynamicCast(collectionNode.layoutInspector, ASCollectionViewFlowLayoutInspector);
  ASSizeRange size = [inspector collectionView:collectionView constrainedSizeForSupplementaryNodeOfKind:UICollectionElementKindSectionFooter atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  ASSizeRange sizeCompare = ASSizeRangeMake(CGSizeMake(125.0, collectionNode.bounds.size.height));
  ASXCTAssertEqualSizeRanges(size, sizeCompare, @"should have a size constrained by the size set on the layout");
  
  collectionNode.dataSource = nil;
  collectionNode.delegate = nil;
}

- (void)testThatItReturnsZeroSizeWhenNoReferenceSizeIsImplemented
{
  InspectorTestDataSource *dataSource = [[InspectorTestDataSource alloc] init];
  HeaderReferenceSizeTestDelegate *delegate = [[HeaderReferenceSizeTestDelegate alloc] init];
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  ASCollectionNode *collectionNode = [[ASCollectionNode alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
  collectionNode.dataSource = dataSource;
  collectionNode.delegate = delegate;
  ASCollectionViewFlowLayoutInspector *inspector = ASDynamicCast(collectionNode.layoutInspector, ASCollectionViewFlowLayoutInspector);
  ASSizeRange size = [inspector collectionView:collectionNode.view constrainedSizeForSupplementaryNodeOfKind:UICollectionElementKindSectionFooter atIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  ASSizeRange sizeCompare = ASSizeRangeMake(CGSizeZero, CGSizeZero);
  XCTAssert(CGSizeEqualToSize(size.min, sizeCompare.min) && CGSizeEqualToSize(size.max, sizeCompare.max), @"should have a zero size");
  
  collectionNode.dataSource = nil;
  collectionNode.delegate = nil;
}

#pragma mark - #collectionView:supplementaryNodesOfKind:inSection:

- (void)testThatItReturnsOneWhenAValidSizeIsImplementedOnTheDelegate
{
  InspectorTestDataSource *dataSource = [[InspectorTestDataSource alloc] init];
  HeaderReferenceSizeTestDelegate *delegate = [[HeaderReferenceSizeTestDelegate alloc] init];
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  ASCollectionNode *collectionNode = [[ASCollectionNode alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
  ASCollectionView *collectionView = collectionNode.view;
  collectionNode.dataSource = dataSource;
  collectionNode.delegate = delegate;
  ASCollectionViewFlowLayoutInspector *inspector = ASDynamicCast(collectionNode.layoutInspector, ASCollectionViewFlowLayoutInspector);
  NSUInteger count = [inspector collectionView:collectionView supplementaryNodesOfKind:UICollectionElementKindSectionHeader inSection:0];
  XCTAssert(count == 1, @"should have a header supplementary view");
  
  collectionNode.dataSource = nil;
  collectionNode.delegate = nil;
}

- (void)testThatItReturnsOneWhenAValidSizeIsImplementedOnTheLayout
{
  InspectorTestDataSource *dataSource = [[InspectorTestDataSource alloc] init];
  HeaderReferenceSizeTestDelegate *delegate = [[HeaderReferenceSizeTestDelegate alloc] init];
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  layout.footerReferenceSize = CGSizeMake(125.0, 125.0);
  ASCollectionNode *collectionNode = [[ASCollectionNode alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
  ASCollectionView *collectionView = collectionNode.view;
  collectionNode.dataSource = dataSource;
  collectionNode.delegate = delegate;
  ASCollectionViewFlowLayoutInspector *inspector = ASDynamicCast(collectionNode.layoutInspector, ASCollectionViewFlowLayoutInspector);
  NSUInteger count = [inspector collectionView:collectionView supplementaryNodesOfKind:UICollectionElementKindSectionFooter inSection:0];
  XCTAssert(count == 1, @"should have a footer supplementary view");
  
  collectionNode.dataSource = nil;
  collectionNode.delegate = nil;
}

- (void)testThatItReturnsNoneWhenNoReferenceSizeIsImplemented
{
  InspectorTestDataSource *dataSource = [[InspectorTestDataSource alloc] init];
  HeaderReferenceSizeTestDelegate *delegate = [[HeaderReferenceSizeTestDelegate alloc] init];
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  ASCollectionNode *collectionNode = [[ASCollectionNode alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
  collectionNode.dataSource = dataSource;
  collectionNode.delegate = delegate;
  ASCollectionViewFlowLayoutInspector *inspector = ASDynamicCast(collectionNode.layoutInspector, ASCollectionViewFlowLayoutInspector);
  NSUInteger count = [inspector collectionView:collectionNode.view supplementaryNodesOfKind:UICollectionElementKindSectionFooter inSection:0];
  XCTAssert(count == 0, @"should not have a footer supplementary view");
  
  collectionNode.dataSource = nil;
  collectionNode.delegate = nil;
}

@end
