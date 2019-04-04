//
//  PhotoFeedNodeController.m
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "PhotoFeedNodeController.h"
#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "Utilities.h"
#import "PhotoModel.h"
#import "PhotoCellNode.h"
#import "PhotoFeedModel.h"

#define AUTO_TAIL_LOADING_NUM_SCREENFULS  2.5

@interface PhotoFeedNodeController () <ASTableDelegate, ASTableDataSource>
@property (nonatomic, strong) ASTableNode *tableNode;
@end

@implementation PhotoFeedNodeController

#pragma mark - Lifecycle

// -init is often called off the main thread in ASDK. Therefore it is imperative that no UIKit objects are accessed.
// Examples of common errors include accessing the node’s view or creating a gesture recognizer.
- (instancetype)init
{
  _tableNode = [[ASTableNode alloc] init];
  self = [super initWithNode:_tableNode];

  if (self) {
    self.navigationItem.title = @"ASDK";
    [self.navigationController setNavigationBarHidden:YES];

    _tableNode.dataSource = self;
    _tableNode.delegate = self;
  }

  return self;
}

// -loadView is guaranteed to be called on the main thread and is the appropriate place to
// set up an UIKit objects you may be using.
- (void)loadView
{
  [super loadView];

  self.tableNode.leadingScreensForBatching = AUTO_TAIL_LOADING_NUM_SCREENFULS;  // overriding default of 2.0
}

- (void)prependNewRows:(NSArray *)newPhotos
{
  __auto_type prevContentHeight = self.tableNode.view.contentSize.height;
  NSInteger section = 0;
  NSMutableArray *indexPaths = [NSMutableArray array];
  for (NSInteger row = 0; row < newPhotos.count; row++) {
    NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:section];
    [indexPaths addObject:path];
  }

  [self.tableNode performBatchUpdates:^{
    [self.tableNode insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
  } completion:^(BOOL finished) {
    if (finished) {
      __auto_type presentHeight = self.tableNode.view.contentSize.height;
      __auto_type diff = presentHeight - prevContentHeight;
      __auto_type offset = self.tableNode.contentOffset;
      offset.y += diff;
      [self.tableNode setContentOffset:offset animated:NO];
    }
  }];
}

- (void)loadPagePrepandWithContext:(ASBatchContext *)context {
  [self.photoFeed requestPrependPageWithCompletionBlock:^(NSArray *newPhotos) {
    [self prependNewRows:newPhotos];
    if (context) {
      [context completeBatchFetching:YES];
    }
  } numResultsToReturn:20];
}

-(void)loadPageWithContext:(ASBatchContext *)context
{
  [self.photoFeed requestPageWithCompletionBlock:^(NSArray *newPhotos){

    [self insertNewRows:newPhotos];
    if (context) {
      [context completeBatchFetching:YES];
    }
  } numResultsToReturn:20];
}

#pragma mark - Subclassing

- (UITableView *)tableView
{
  return _tableNode.view;
}

- (void)loadPage
{
  [self loadPageWithContext:nil];
}

#pragma mark - ASTableDataSource methods

- (NSInteger)tableNode:(ASTableNode *)tableNode numberOfRowsInSection:(NSInteger)section
{
  return [self.photoFeed numberOfItemsInFeed];
}

- (ASCellNodeBlock)tableNode:(ASTableNode *)tableNode nodeBlockForRowAtIndexPath:(NSIndexPath *)indexPath
{
  PhotoModel *photoModel = [self.photoFeed objectAtIndex:indexPath.row];
  // this will be executed on a background thread - important to make sure it's thread safe
  ASCellNode *(^ASCellNodeBlock)() = ^ASCellNode *() {
    PhotoCellNode *cellNode = [[PhotoCellNode alloc] initWithPhotoObject:photoModel];
    return cellNode;
  };

  return ASCellNodeBlock;
}

#pragma mark - ASTableDelegate methods

- (BOOL)shouldBatchFetchPrependForTableNode:(ASTableNode *)tableNode {
  return YES;
}

- (void)tableNode:(ASTableNode *)tableNode willBeginBatchFetchPrependWithContext:(nonnull ASBatchContext *)context {
  [context beginBatchFetching];
  [self loadPagePrepandWithContext:context];
}

// Receive a message that the tableView is near the end of its data set and more data should be fetched if necessary.
- (void)tableNode:(ASTableNode *)tableNode willBeginBatchFetchWithContext:(ASBatchContext *)context
{
  [context beginBatchFetching];
  [self loadPageWithContext:context];
}

@end
