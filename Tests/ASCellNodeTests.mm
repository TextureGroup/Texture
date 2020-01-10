//
//  ASCellNodeTests.mm
//  AsyncDisplayKitTests
//
//  Created by Jordan Morgan on 1/10/20.
//  Copyright © 2020 Pinterest. All rights reserved.
//

#import "ASTestCase.h"
#import <AsyncDisplayKit/AsyncDisplayKit.h>

@interface ASCollectionNodeCellTestController : ASViewController <ASCollectionDataSource>

@property (nonatomic) ASCollectionNode *collectionNode;

@end

@implementation ASCollectionNodeCellTestController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  if (!(self = [super initWithNode:[[ASDisplayNode alloc] init]]))
    return nil;
  
  UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
  [layout setMinimumLineSpacing:0];
  [layout setMinimumInteritemSpacing:0];
  
  self.collectionNode = [[ASCollectionNode alloc] initWithCollectionViewLayout:layout];
  self.collectionNode.dataSource = self;
  
  [self.node setAutomaticallyManagesSubnodes:YES];
  
  __weak ASCollectionNodeCellTestController *weakSelf = self;
  self.node.layoutSpecBlock = ^ASLayoutSpec *(ASDisplayNode *_Nonnull node, ASSizeRange constrainedSize) {
    weakSelf.collectionNode.style.preferredSize = constrainedSize.min;
    return [ASAbsoluteLayoutSpec absoluteLayoutSpecWithChildren:@[weakSelf.collectionNode]];
  };
  
  return self;
}

- (NSInteger)collectionNode:(ASCollectionNode *)collectionNode numberOfItemsInSection:(NSInteger)section {
  return 1;
}

- (NSInteger)numberOfSectionsInCollectionNode:(ASCollectionNode *)collectionNode {
  return 1;
}

- (ASCellNodeBlock)collectionNode:(ASCollectionNode *)collectionNode nodeBlockForItemAtIndexPath:(NSIndexPath *)indexPath {
  UIViewController *testVC = [[UIViewController alloc] initWithNibName:nil bundle:nil];
  
  ASCellNode *(^ASCellNodeBlock)() = ^ASCellNode *() {
    return [[ASCellNode alloc] initWithViewControllerBlock:^UIViewController * _Nonnull{
      return testVC;
    } didLoadBlock:^(__kindof ASDisplayNode * _Nonnull node) {
      
    }];
  };
  
  return ASCellNodeBlock;
}

@end

@interface ASCellNodeTests : ASTestCase
@end

@implementation ASCellNodeTests

- (void)testCellNodeViewControllerIsDellocatedAfterBlockRuns
{
  ASCollectionNodeCellTestController *testController = [[ASCollectionNodeCellTestController alloc] initWithNibName:nil bundle:nil];
  UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  [window setRootViewController:testController];
  [window makeKeyAndVisible];
  
  [testController.collectionNode reloadData];
  [testController.collectionNode waitUntilAllUpdatesAreProcessed];
    
  ASCellNode *cellNode = [testController.collectionNode.view nodeForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
  UIViewController *cellNodeController = cellNode.viewController;
  
  XCTAssertNil(cellNodeController);
}

@end
