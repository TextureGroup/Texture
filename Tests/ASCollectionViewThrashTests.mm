//
//  ASCollectionViewThrashTests.m
//  AsyncDisplayKitTests
//
//  Created by Michael Zuccarino on 11/15/18.
//  Copyright © 2018 Pinterest. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import <AsyncDisplayKit/ASCollectionView.h>
#import <stdatomic.h>

#import "ASThrashUtility.h"

@interface ASCollectionViewThrashTests : XCTestCase

@end

@implementation ASCollectionViewThrashTests  {
  // The current update, which will be logged in case of a failure.
  ASThrashUpdate *_update;
  BOOL _failed;
}

- (void)tearDown {
  if (_failed && _update != nil) {
    NSLog(@"Failed update %@: %@", _update, _update.logFriendlyBase64Representation);
  }
  _failed = NO;
  _update = nil;
}

// NOTE: Despite the documentation, this is not always called if an exception is caught.
- (void)recordFailureWithDescription:(NSString *)description inFile:(NSString *)filePath atLine:(NSUInteger)lineNumber expected:(BOOL)expected {
  _failed = YES;
  [super recordFailureWithDescription:description inFile:filePath atLine:lineNumber expected:expected];
}

- (void)verifyDataSource:(ASThrashDataSource *)ds {
  CollectionView *collectionView = ds.collectionView;
  NSArray <ASThrashTestSection *> *data = [ds data];
  for (NSInteger i = 0; i < collectionView.numberOfSections; i++) {
    XCTAssertEqual([collectionView numberOfItemsInSection:i], data[i].items.count);

    for (NSInteger j = 0; j < [collectionView numberOfItemsInSection:i]; j++) {
      NSIndexPath *indexPath = [NSIndexPath indexPathForItem:j inSection:i];
      ASThrashTestItem *item = data[i].items[j];
      ASThrashTestNode *node = (ASThrashTestNode *)[collectionView nodeForItemAtIndexPath:indexPath];
      XCTAssertEqualObjects(node.item, item, @"Wrong node at index path %@", indexPath);
    }
  }
}

#pragma mark Test Methods

// Disabled temporarily due to issue where cell nodes are not marked invisible before deallocation.
- (void)testInitialDataRead {
  ASThrashDataSource *ds = [[ASThrashDataSource alloc] initCollectionViewDataSourceWithData:[ASThrashTestSection sectionsWithCount:kInitialSectionCount]];
  [self verifyDataSource:ds];
}

@end
