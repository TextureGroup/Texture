//
//  ViewController.m
//  Sample
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the root directory of this source tree. An additional grant
//  of patent rights can be found in the PATENTS file in the same directory.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//  FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
//  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "ViewController.h"
#import "ICCellNode.h"
#import "ICCollectionNode.h"
#import "ICDisplayNode.h"

@interface ViewController () <ASCollectionDataSource, ASCollectionDelegate, ICCellNodeDelegate>
@end

@implementation ViewController {
  NSArray *_colors;
  NSArray *_colorNames;

  ICCollectionNode *_collectionNode;
  UICollectionViewFlowLayout *_flowLayout;
}

- (instancetype)init
{
  _flowLayout = [[UICollectionViewFlowLayout alloc] init];
  _collectionNode = [[ICCollectionNode alloc] initWithCollectionViewLayout:_flowLayout];

  if (!(self = [super initWithNode:_collectionNode]))
    return nil;
  _flowLayout.minimumLineSpacing = 0;
  self.navigationController.navigationBarHidden = NO;
  _colors = @[[UIColor redColor], [UIColor greenColor], [UIColor blueColor]];
  _colorNames = @[@"Red", @"Green", @"Blue"];
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  _collectionNode.delegate = self;
  _collectionNode.dataSource = self;
}

- (NSInteger)numberOfSectionsInCollectionNode:(ASCollectionNode *)collectionNode {
  return 1;
}

- (NSInteger)collectionNode:(ASCollectionNode *)collectionNode numberOfItemsInSection:(NSInteger)section {
  return _colors.count;
}

- (ASSizeRange)collectionNode:(ASCollectionNode *)collectionNode constrainedSizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  return ASSizeRangeMake([UIScreen mainScreen].bounds.size);
}

- (ASCellNodeBlock)collectionNode:(ASCollectionNode *)collectionNode nodeBlockForItemAtIndexPath:(NSIndexPath *)indexPath {
  return ^ASCellNode *{
    ICCellNode *cellNode = [[ICCellNode alloc] initWithColor: _colors[indexPath.row] colorName: _colorNames[indexPath.row]];
    cellNode.delegate = self;
    return cellNode;
  };
}

- (void)collectionNode:(ASCollectionNode *)collectionNode willDisplayItemWithNode:(ASCellNode *)node {
  NSLog(@"^^^^ willDisplayItemWithNode %@", node);
}

- (void)collectionNode:(ASCollectionNode *)collectionNode didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
  ICDisplayNode *node = [[ICDisplayNode alloc] init];
  ViewController *vc = [[ViewController alloc] initWithNode:node];
  [self.navigationController pushViewController:vc animated:YES];
}

- (void)cellDidEnterVisibleState:(ICCellNode *)cellNode {
  //_collectionNode.contentOffset = CGPointMake(0, 100);
}

- (void)viewWillDisappear:(BOOL)animated {
  [super viewWillDisappear:animated];
  NSLog(@"^^^^ viewWillDisappear %@", self);
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
  NSLog(@"^^^^ viewDidDisappear %@", self);
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  NSLog(@"^^^^ viewWillAppear %@", self);
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  NSLog(@"^^^^ viewDidAppear %@", self);
}


@end
