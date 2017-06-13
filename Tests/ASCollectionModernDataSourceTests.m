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

@interface ASTestCellNode : ASCellNode
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
  [collectionNode waitUntilAllUpdatesAreCommitted];
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

  [self performUpdateReloadingItems:@{ reloadedPath: [NSObject new] }
                     reloadMappings:@{ reloadedPath: reloadedPath }
                     insertingItems:nil
                      deletingItems:nil
            skippedReloadIndexPaths:nil];
}

- (void)testInsertingAnItem
{
  [self loadInitialData];

  // Insert at (1, 0)
  NSIndexPath *insertedPath = [NSIndexPath indexPathForItem:0 inSection:1];

  [self performUpdateReloadingItems:nil
                     reloadMappings:nil
                     insertingItems:@{ insertedPath: [NSObject new] }
                      deletingItems:nil
            skippedReloadIndexPaths:nil];
}

- (void)testReloadingAnItemWithACompatibleViewModel
{
  [self loadInitialData];

  // Reload and delete together, for good measure.
  NSIndexPath *reloadedPath = [NSIndexPath indexPathForItem:1 inSection:0];
  NSIndexPath *deletedPath = [NSIndexPath indexPathForItem:0 inSection:0];

  id viewModel = [NSObject new];

  // Cell node should get -canUpdateToViewModel:
  id mockCellNode = [collectionNode nodeForItemAtIndexPath:reloadedPath];
  [mockCellNode setExpectationOrderMatters:YES];
  OCMExpect([mockCellNode canUpdateToViewModel:viewModel])
  .andReturn(YES);
  OCMExpect([mockCellNode setViewModel:viewModel])
  .andForwardToRealObject();

  [self performUpdateReloadingItems:@{ reloadedPath: viewModel }
                     reloadMappings:@{ reloadedPath: [NSIndexPath indexPathForItem:0 inSection:0] }
                     insertingItems:nil
                      deletingItems:@[ deletedPath ]
            skippedReloadIndexPaths:@[ reloadedPath ]];
  
  OCMVerifyAll(mockCellNode);
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
        [self expectViewModelMethodForItemAtIndexPath:indexPath viewModel:items[i]];
        [self expectNodeBlockMethodForItemAtIndexPath:indexPath];
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

- (void)expectViewModelMethodForItemAtIndexPath:(NSIndexPath *)indexPath viewModel:(id)viewModel
{
  OCMExpect([mockDataSource collectionNode:collectionNode viewModelForItemAtIndexPath:indexPath])
  .andReturn(viewModel);
}

- (void)expectNodeBlockMethodForItemAtIndexPath:(NSIndexPath *)indexPath
{
  ASCellNodeBlock nodeBlock = ^{
    ASCellNode *node = [ASTestCellNode new];
    // Generating multiple partial mocks of the same class is not thread-safe.
    @synchronized (NSNull.null) {
      return OCMPartialMock(node);
    }
  };
  OCMExpect([mockDataSource collectionNode:collectionNode nodeBlockForItemAtIndexPath:indexPath])
  .andReturn(nodeBlock);
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
 * indexPathsForPreservedNodes are the old index paths for nodes that should use -canUpdateToViewModel: instead of being refetched.
 */
- (void)performUpdateReloadingItems:(NSDictionary<NSIndexPath *, id> *)reloadedItems
                     reloadMappings:(NSDictionary<NSIndexPath *, NSIndexPath *> *)reloadMappings
                     insertingItems:(NSDictionary<NSIndexPath *, id> *)insertedItems
                      deletingItems:(NSArray<NSIndexPath *> *)deletedItems
            skippedReloadIndexPaths:(NSArray<NSIndexPath *> *)skippedReloadIndexPaths
{
  [collectionNode performBatchUpdates:^{
    // First update our data source.
    [reloadedItems enumerateKeysAndObjectsUsingBlock:^(NSIndexPath * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
      sections[key.section][key.item] = obj;
    }];
    for (NSIndexPath *indexPath in [deletedItems sortedArrayUsingSelector:@selector(compare:)].reverseObjectEnumerator) {
      [sections[indexPath.section] removeObjectAtIndex:indexPath.item];
    }
    [insertedItems enumerateKeysAndObjectsUsingBlock:^(NSIndexPath * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
      [sections[key.section] insertObject:obj atIndex:key.item];
    }];
    
    // Then update the collection node.
    [collectionNode reloadItemsAtIndexPaths:reloadedItems.allKeys];
    [collectionNode deleteItemsAtIndexPaths:deletedItems];
    [collectionNode insertItemsAtIndexPaths:insertedItems.allKeys];
    
    // Before the commit, lay out our expectations.
    
    // It loads the new counts
    [self expectDataSourceCountMethods];
    
    // It loads view models and node blocks as needed for reloaded & inserted items.
    [reloadedItems enumerateKeysAndObjectsUsingBlock:^(NSIndexPath * _Nonnull oldIndexPath, id  _Nonnull obj, BOOL * _Nonnull stop) {
      NSIndexPath *newIndexPath = reloadMappings[oldIndexPath];
      [self expectViewModelMethodForItemAtIndexPath:newIndexPath viewModel:obj];
      if (![skippedReloadIndexPaths containsObject:oldIndexPath]) {
        [self expectNodeBlockMethodForItemAtIndexPath:newIndexPath];
      }
    }];
    
    [insertedItems enumerateKeysAndObjectsUsingBlock:^(NSIndexPath * _Nonnull newIndexPath, id  _Nonnull obj, BOOL * _Nonnull stop) {
      [self expectViewModelMethodForItemAtIndexPath:newIndexPath viewModel:obj];
      [self expectNodeBlockMethodForItemAtIndexPath:newIndexPath];
    }];
  } completion:nil];

  [self assertCollectionNodeContent];
}

@end

@implementation ASTestCellNode

- (BOOL)canUpdateToViewModel:(id)viewModel
{
  // Our tests default to NO for migrating view models. We use OCMExpect to return YES when we specifically want to.
  return NO;
}

@end
