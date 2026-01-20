//
//  ASCellVisibilityScrollEventTests.m
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

#import <AsyncDisplayKit/AsyncDisplayKit.h>

@interface ASCellVisibilityTestNode: ASTextCellNode
@property (nonatomic) NSUInteger cellNodeVisibilityEventVisibleCount;
@property (nonatomic) NSUInteger cellNodeVisibilityEventVisibleRectChangedCount;
@property (nonatomic) NSUInteger cellNodeVisibilityEventInvisibleCount;
@property (nonatomic) NSUInteger cellNodeVisibilityEventWillBeginDraggingCount;
@property (nonatomic) NSUInteger cellNodeVisibilityEventDidEndDraggingCount;
@property (nonatomic) NSUInteger cellNodeVisibilityEventDidStopScrollingCount;
@end

@implementation ASCellVisibilityTestNode

- (void)cellNodeVisibilityEvent:(ASCellNodeVisibilityEvent)event inScrollView:(UIScrollView *)scrollView withCellFrame:(CGRect)cellFrame
{
  switch (event) {
    case ASCellNodeVisibilityEventVisible:
      self.cellNodeVisibilityEventVisibleCount++;
      break;
    case ASCellNodeVisibilityEventVisibleRectChanged:
      self.cellNodeVisibilityEventVisibleRectChangedCount++;
      break;
    case ASCellNodeVisibilityEventInvisible:
      self.cellNodeVisibilityEventInvisibleCount++;
      break;
    case ASCellNodeVisibilityEventWillBeginDragging:
      self.cellNodeVisibilityEventWillBeginDraggingCount++;
      break;
    case ASCellNodeVisibilityEventDidEndDragging:
      self.cellNodeVisibilityEventDidEndDraggingCount++;
      break;
    case ASCellNodeVisibilityEventDidStopScrolling:
      self.cellNodeVisibilityEventDidStopScrollingCount++;
      break;
  }
}

@end

@interface ASTableView (Private_Testing)
- (void)scrollViewDidScroll:(UIScrollView *)scrollView;
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView;
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView;
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate;
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
@end

@interface ASCellVisibilityTableViewTestController: UIViewController<ASTableDataSource>

@property (nonatomic) ASTableNode *tableNode;
@property (nonatomic) ASTableView *tableView;

@end

@implementation ASCellVisibilityTableViewTestController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.tableNode = [[ASTableNode alloc] init];
    self.tableView = self.tableNode.view;
    self.tableNode.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableNode.dataSource = self;
    
    [self.view addSubview:self.tableView];
  }
  return self;
}

- (NSInteger)tableNode:(ASTableNode *)tableNode numberOfRowsInSection:(NSInteger)section
{
  return 1;
}

- (ASCellNodeBlock)tableNode:(ASTableNode *)tableNode nodeBlockForRowAtIndexPath:(NSIndexPath *)indexPath;
{
  return ^{
    ASCellVisibilityTestNode *cell = [[ASCellVisibilityTestNode alloc] init];
    return cell;
  };
}

@end

@interface ASCollectionView (Private_Testing)
- (void)scrollViewDidScroll:(UIScrollView *)scrollView;
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView;
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView;
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate;
- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)rawCell forItemAtIndexPath:(NSIndexPath *)indexPath;
@end

@interface ASCellVisibilityCollectionViewTestController: UIViewController<ASCollectionDataSource>

@property (nonatomic) ASCollectionNode *collectionNode;
@property (nonatomic) ASCollectionView *collectionView;

@end

@implementation ASCellVisibilityCollectionViewTestController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    id realLayout = [UICollectionViewFlowLayout new];
    self.collectionNode = [[ASCollectionNode alloc] initWithFrame:self.view.bounds collectionViewLayout:realLayout];
    self.collectionView = self.collectionNode.view;
    self.collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.collectionNode.dataSource = self;
    
    [self.view addSubview:self.collectionView];
  }
  return self;
}

- (NSInteger)collectionNode:(ASCollectionNode *)collectionNode numberOfItemsInSection:(NSInteger)section
{
  return 1;
}

- (ASCellNodeBlock)collectionNode:(ASCollectionNode *)collectionNode nodeBlockForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return ^{
    ASCellVisibilityTestNode *cell = [[ASCellVisibilityTestNode alloc] init];
    return cell;
  };
}

@end


@interface ASCellVisibilityScrollEventTests : XCTestCase
@end

@implementation ASCellVisibilityScrollEventTests

- (void)testTableNodeEvents
{
  ASCellVisibilityTableViewTestController *testController = [[ASCellVisibilityTableViewTestController alloc] initWithNibName:nil bundle:nil];
  
  UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  [window setRootViewController:testController];
  [window makeKeyAndVisible];

  [testController.tableNode reloadData];
  [testController.tableNode waitUntilAllUpdatesAreProcessed];
  [testController.tableNode layoutIfNeeded];
  
  ASTableView *tableView = testController.tableView;
  
  NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
  ASCellVisibilityTestNode *cell = (ASCellVisibilityTestNode *)[testController.tableNode nodeForRowAtIndexPath:indexPath];
  UITableViewCell *uicell = [testController.tableNode cellForRowAtIndexPath:indexPath];
  
  // Pretend the cell is appearing so it is added to _cellsForVisibilityUpdates
  [tableView tableView:tableView willDisplayCell:uicell forRowAtIndexPath:indexPath];
  
  // simulator scrollViewDidScroll so we can see if the cell got the event
  [tableView scrollViewDidScroll:tableView];
  XCTAssertTrue(cell.cellNodeVisibilityEventVisibleRectChangedCount == 1);
  
  [tableView scrollViewDidEndDecelerating:tableView];
  XCTAssertTrue(cell.cellNodeVisibilityEventDidStopScrollingCount == 1);

  [tableView scrollViewWillBeginDragging:tableView];
  XCTAssertTrue(cell.cellNodeVisibilityEventWillBeginDraggingCount == 1);

  [tableView scrollViewDidEndDragging:tableView willDecelerate:YES];
  XCTAssertTrue(cell.cellNodeVisibilityEventDidEndDraggingCount == 1);

}

- (void)testCollectionNodeEvents
{
  ASCellVisibilityCollectionViewTestController *testController = [[ASCellVisibilityCollectionViewTestController alloc] initWithNibName:nil bundle:nil];
  
  UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  [window setRootViewController:testController];
  [window makeKeyAndVisible];

  [testController.collectionNode reloadData];
  [testController.collectionNode waitUntilAllUpdatesAreProcessed];
  [testController.collectionNode layoutIfNeeded];
  
  ASCollectionView *collectionView = testController.collectionView;
  
  NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
  ASCellVisibilityTestNode *cell = (ASCellVisibilityTestNode *)[testController.collectionNode nodeForItemAtIndexPath:indexPath];
  UICollectionViewCell *uicell = [testController.collectionNode cellForItemAtIndexPath:indexPath];
  
  // Pretend the cell is appearing so it is added to _cellsForVisibilityUpdates
  [collectionView collectionView:collectionView willDisplayCell:uicell forItemAtIndexPath:indexPath];

  // simulator scrollViewDidScroll so we can see if the cell got the event
  [collectionView scrollViewDidScroll:collectionView];
  XCTAssertTrue(cell.cellNodeVisibilityEventVisibleRectChangedCount == 1);
  
  [collectionView scrollViewDidEndDecelerating:collectionView];
  XCTAssertTrue(cell.cellNodeVisibilityEventDidStopScrollingCount == 1);

  [collectionView scrollViewWillBeginDragging:collectionView];
  XCTAssertTrue(cell.cellNodeVisibilityEventWillBeginDraggingCount == 1);

  [collectionView scrollViewDidEndDragging:collectionView willDecelerate:YES];
  XCTAssertTrue(cell.cellNodeVisibilityEventDidEndDraggingCount == 1);
}


@end

