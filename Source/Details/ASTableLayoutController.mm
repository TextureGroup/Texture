//
//  ASTableLayoutController.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASTableLayoutController.h>

#import <UIKit/UIKit.h>

#import <AsyncDisplayKit/ASAssert.h>
#import <AsyncDisplayKit/ASElementMap.h>

@interface ASTableLayoutController()
@end

@implementation ASTableLayoutController

- (instancetype)initWithTableView:(UITableView *)tableView
{
  if (!(self = [super init])) {
    return nil;
  }
  _tableView = tableView;
  return self;
}

#pragma mark - ASLayoutController

- (CGRect)bounds
{
  ASDisplayNodeAssertMainThread();
  return _tableView.bounds;
}

- (void)getLayoutItemsInRect:(CGRect)rect buffer:(std::vector<ASCollectionLayoutItem> *)buffer
{
  ASDisplayNodeAssertMainThread();
  NSParameterAssert(buffer->empty());
  __autoreleasing NSArray<NSIndexPath *> *paths = [_tableView indexPathsForRowsInRect:rect];
  buffer->reserve(paths.count);
  for (NSIndexPath *indexPath in paths) {
    buffer->push_back({[_tableView rectForRowAtIndexPath:indexPath], indexPath, nil});
  }
}

@end
