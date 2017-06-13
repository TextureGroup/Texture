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
  NSMutableArray<NSMutableArray *> *sections;
}

- (void)setUp {
  [super setUp];
  // Default is 2 sections: 2 items in first, 1 item in second.
  sections = [NSMutableArray array];
  [sections addObject:[NSMutableArray arrayWithObjects:[NSObject new], [NSObject new], nil]];
  [sections addObject:[NSMutableArray arrayWithObjects:[NSObject new], nil]];
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
   @selector(collectionNode:viewModelForItemAtIndexPath:),
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

#pragma mark - Test Methods

- (void)testInitialDataLoading
{
  [self loadInitialData];
}

- (void)testReloadingAnItem
{
  [self loadInitialData];

  // Reload at (0, 0)
  NSIndexPath *reloadedPath = [NSIndexPath indexPathForItem:0 inSection:0];

  sections[reloadedPath.section][reloadedPath.item] = [NSObject new];
  [self performUpdateInvalidatingItems:@[ reloadedPath ] block:^{
    [collectionNode reloadItemsAtIndexPaths:@[ reloadedPath ]];
  }];
}

- (void)testInsertingAnItem
{
  [self loadInitialData];

  // Insert at (1, 0)
  NSIndexPath *insertedPath = [NSIndexPath indexPathForItem:0 inSection:1];

  [sections[insertedPath.section] insertObject:[NSObject new] atIndex:insertedPath.item];
  [self performUpdateInvalidatingItems:@[ insertedPath ] block:^{
    [collectionNode insertItemsAtIndexPaths:@[ insertedPath ]];
  }];
}

#pragma mark - Helpers

- (void)loadInitialData
{
  /// BUG: these methods are called twice in a row i.e. this for-loop shouldn't be here. https://github.com/TextureGroup/Texture/issues/351
  for (int i = 0; i < 2; i++) {
    // It reads all the counts
    [self expectDataSourceCountMethods];

    // It reads the contents for each item.
    for (NSInteger section = 0; section < sections.count; section++) {
      NSArray *items = sections[section];

      // For each item:
      for (NSInteger i = 0; i < items.count; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:section];
        [self expectContentMethodsForItemAtIndexPath:indexPath];
      }
    }
  }

  [window layoutIfNeeded];

  // Assert item counts & content:
  [self assertCollectionNodeContent];
}

/**
 * Adds expectations for the sequence:
 *
 * numberOfSectionsInCollectionNode:
 * for section in countsArray
 *  numberOfItemsInSection:
 */
- (void)expectDataSourceCountMethods
{
  // -numberOfSectionsInCollectionNode
  OCMExpect([mockDataSource numberOfSectionsInCollectionNode:collectionNode])
  .andReturn(sections.count);
  
  // For each section:
  // Note: Skip fast enumeration for readability.
  for (NSInteger section = 0; section < sections.count; section++) {
    NSInteger itemCount = sections[section].count;
    OCMExpect([mockDataSource collectionNode:collectionNode numberOfItemsInSection:section])
    .andReturn(itemCount);
  }
}

// Expects viewModelForItemAtIndexPath: and nodeBlockForItemAtIndexPath:
- (void)expectContentMethodsForItemAtIndexPath:(NSIndexPath *)indexPath
{
  id viewModel = sections[indexPath.section][indexPath.item];
  OCMExpect([mockDataSource collectionNode:collectionNode viewModelForItemAtIndexPath:indexPath])
  .andReturn(viewModel);
  OCMExpect([mockDataSource collectionNode:collectionNode nodeBlockForItemAtIndexPath:indexPath])
  .andReturn((ASCellNodeBlock)^{ return [ASCellNode new]; });
}

- (void)assertCollectionNodeContent
{
  // Assert section count
  XCTAssertEqual(collectionNode.numberOfSections, sections.count);

  for (NSInteger section = 0; section < sections.count; section++) {
    NSArray *items = sections[section];
    // Assert item count
    XCTAssertEqual([collectionNode numberOfItemsInSection:section], items.count);
    for (NSInteger item = 0; item < items.count; item++) {
      // Assert view model
      // Could use pointer equality but the error message is less readable.
      NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
      id viewModel = sections[indexPath.section][indexPath.item];
      XCTAssertEqualObjects(viewModel, [collectionNode viewModelForItemAtIndexPath:indexPath]);
      ASCellNode *node = [collectionNode nodeForItemAtIndexPath:indexPath];
      XCTAssertEqualObjects(node.viewModel, viewModel);
    }
  }
}

/**
 * Updates the collection node, with expectations and assertions about the call-order and the correctness of the
 * new data. You should update the data source _before_ calling this method.
 *
 * invalidatedIndexPaths are the items we expect to get refetched (reloaded/inserted).
 */
- (void)performUpdateInvalidatingItems:(NSArray<NSIndexPath *> *)invalidatedIndexPaths block:(void(^)())update
{
  // When we do an edit, it'll read the new counts
  [self expectDataSourceCountMethods];

  // Then it'll load the contents for inserted/reloaded items.
  for (NSIndexPath *indexPath in invalidatedIndexPaths) {
    [self expectContentMethodsForItemAtIndexPath:indexPath];
  }

  [collectionNode performBatchUpdates:update completion:nil];

  [self assertCollectionNodeContent];
}

@end
