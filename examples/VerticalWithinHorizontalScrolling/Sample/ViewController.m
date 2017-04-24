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

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import "ViewController.h"
#import "GradientTableNode.h"

@interface ViewController () <ASPagerDataSource, ASPagerDelegate>
{
  ASPagerNode *_pagerNode;
}

@end

@implementation ViewController

#pragma mark -
#pragma mark UIViewController.

- (instancetype)init
{
  if (!(self = [super init]))
    return nil;
  
  _pagerNode = [[ASPagerNode alloc] init];
  _pagerNode.dataSource = self;
  _pagerNode.delegate = self;
  ASDisplayNode.shouldShowRangeDebugOverlay = YES;
  
  // Could implement ASCollectionDelegate if we wanted extra callbacks, like from UIScrollView.
  //_pagerNode.delegate = self;
  
  self.title = @"Paging Table Nodes";
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRedo
                                                                                         target:self
                                                                                         action:@selector(reloadEverything)];

  return self;
}

- (void)reloadEverything
{
  [_pagerNode reloadData];
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  [self.view addSubnode:_pagerNode];
}

- (void)viewWillLayoutSubviews
{
  _pagerNode.frame = self.view.bounds;
}

#pragma mark -
#pragma mark ASPagerNode.

- (ASCellNode *)pagerNode:(ASPagerNode *)pagerNode nodeAtIndex:(NSInteger)index
{
  CGSize boundsSize = pagerNode.bounds.size;
  CGSize gradientRowSize = CGSizeMake(boundsSize.width, 100);
  GradientTableNode *node = [[GradientTableNode alloc] initWithElementSize:gradientRowSize];
  node.pageNumber = index;
  return node;
}

- (ASSizeRange)pagerNode:(ASPagerNode *)pagerNode constrainedSizeForNodeAtIndex:(NSInteger)index;
{
  return ASSizeRangeMake(pagerNode.bounds.size);
}

- (NSInteger)numberOfPagesInPagerNode:(ASPagerNode *)pagerNode
{
  return 10;
}

@end
