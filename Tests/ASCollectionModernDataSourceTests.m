//
//  ASCollectionModernDataSourceTests.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import <AsyncDisplayKit/NSIndexSet+ASHelpers.h>
#import "OCMockObject+ASAdditions.h"
#import "ASTestCase.h"

@interface ASCollectionModernDataSourceTests : ASTestCase

@end

@implementation ASCollectionModernDataSourceTests {
@private
  id mockDataSource;
  UIWindow *window;
  UIViewController *viewController;
  ASCollectionNode *collectionNode;
}

- (void)setUp {
  [super setUp];
  window = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
  viewController = [[UIViewController alloc] init];

  window.rootViewController = viewController;
  [window makeKeyAndVisible];
  collectionNode = [[ASCollectionNode alloc] initWithCollectionViewLayout:[UICollectionViewFlowLayout new]];
  collectionNode.frame = viewController.view.bounds;
  collectionNode.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  [viewController.view addSubnode:collectionNode];

  mockDataSource = OCMStrictProtocolMock(@protocol(ASCollectionDataSource));
  [mockDataSource addImplementedOptionalProtocolMethods:
   @selector(numberOfSectionsInCollectionNode:),
   @selector(collectionNode:numberOfItemsInSection:),
   @selector(collectionNode:nodeBlockForItemAtIndexPath:),
   nil];
  [mockDataSource setExpectationOrderMatters:YES];
  
  // NOTE: Adding optionally-implemented methods after this point won't work due to ASCollectionNode selector caching.
  collectionNode.dataSource = mockDataSource;
}

- (void)tearDown
{
  OCMVerifyAll(mockDataSource);
  [super tearDown];
}

- (void)testInitialDataLoadingCallPattern
{
  /// BUG: these methods are called twice in a row i.e. this for-loop shouldn't be here. https://github.com/TextureGroup/Texture/issues/351
  for (int i = 0; i < 2; i++) {
    NSArray *counts = @[ @2 ];
    [self expectDataSourceMethodsWithCounts:counts];
  }
  
  [window layoutIfNeeded];
}

#pragma mark - Helpers

/**
 * Adds expectations for the sequence:
 *
 * numberOfSectionsInCollectionNode:
 * for section in countsArray
 *  numberOfItemsInSection:
 *  for item < itemCount
 *    nodeBlockForItemAtIndexPath:
 */
- (void)expectDataSourceMethodsWithCounts:(NSArray<NSNumber *> *)counts
{
  // -numberOfSectionsInCollectionNode
  OCMExpect([mockDataSource numberOfSectionsInCollectionNode:collectionNode])
  .andReturn(counts.count);
  
  // For each section:
  // Note: Skip fast enumeration for readability.
  for (NSInteger section = 0; section < counts.count; section++) {
    NSInteger itemCount = counts[section].integerValue;
    OCMExpect([mockDataSource collectionNode:collectionNode numberOfItemsInSection:section])
    .andReturn(itemCount);
    
    // For each item:
    for (NSInteger i = 0; i < itemCount; i++) {
      NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:section];
      OCMExpect([mockDataSource collectionNode:collectionNode nodeBlockForItemAtIndexPath:indexPath])
      .andReturn((ASCellNodeBlock)^{ return [[ASCellNode alloc] init]; });
    }
  }
}

@end
