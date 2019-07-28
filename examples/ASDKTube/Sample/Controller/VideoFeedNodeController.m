//
//  VideoFeedNodeController.m
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "VideoFeedNodeController.h"
#import <AsyncDisplayKit/ASVideoPlayerNode.h>
#import "VideoModel.h"
#import "VideoContentCell.h"

@interface VideoFeedNodeController ()<ASTableDelegate, ASTableDataSource>

@end

@implementation VideoFeedNodeController
{
  ASTableNode *_tableNode;
  NSMutableArray<VideoModel*> *_videoFeedData;
}

- (instancetype)init
{
  _tableNode = [[ASTableNode alloc] init];
  _tableNode.delegate = self;
  _tableNode.dataSource = self;

  if (!(self = [super initWithNode:_tableNode])) {
    return nil;
  }
  
  [self generateFeedData];
  self.navigationItem.title = @"Home";

  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  [_tableNode reloadData];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
  return UIStatusBarStyleLightContent;
}

- (void)generateFeedData
{
  _videoFeedData = [[NSMutableArray alloc] init];

  for (int i = 0; i < 30; i++) {
    [_videoFeedData addObject:[[VideoModel alloc] init]];
  }
}

#pragma mark - ASCollectionDelegate - ASCollectionDataSource

- (NSInteger)numberOfSectionsInTableNode:(ASTableNode *)tableNode
{
  return 1;
}

- (NSInteger)tableNode:(ASTableNode *)tableNode numberOfRowsInSection:(NSInteger)section
{
  return _videoFeedData.count;
}

- (ASCellNodeBlock)tableNode:(ASTableNode *)tableNode nodeBlockForRowAtIndexPath:(NSIndexPath *)indexPath {
  VideoModel *videoObject = [_videoFeedData objectAtIndex:indexPath.row];
  return ^{
    VideoContentCell *cellNode = [[VideoContentCell alloc] initWithVideoObject:videoObject];
    return cellNode;
  };
}

@end
