//
//  ViewController.m
//  Sample
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the /ASDK-Licenses directory of this source tree. An additional
//  grant of patent rights can be found in the PATENTS file in the same directory.
//
//  Modifications to this file made after 4/13/2017 are: Copyright (c) 2017-present,
//  Pinterest, Inc.  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//  
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//  FACEBOOK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
//  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import <AsyncDisplayKit/ASAssert.h>

#import "ViewController.h"
#import "HorizontalScrollCellNode.h"

@interface ViewController () <ASTableDataSource, ASTableDelegate>
{
  ASTableNode *_tableNode;
}

@end

@implementation ViewController

#pragma mark -
#pragma mark UIViewController.

- (instancetype)init
{
  _tableNode = [[ASTableNode alloc] initWithStyle:UITableViewStylePlain];
  _tableNode.dataSource = self;
  _tableNode.delegate = self;

  if (!(self = [super initWithNode:_tableNode]))
    return nil;

  self.title = @"Horizontal Scrolling Gradients";
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRedo
                                                                                         target:self
                                                                                         action:@selector(reloadEverything)];

  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  _tableNode.view.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)reloadEverything
{
  [_tableNode reloadData];
}

#pragma mark - ASTableNode

- (ASCellNode *)tableNode:(ASTableNode *)tableNode nodeForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return [[HorizontalScrollCellNode alloc] initWithElementSize:CGSizeMake(100, 100)];
}

- (NSInteger)tableNode:(ASTableNode *)tableNode numberOfRowsInSection:(NSInteger)section
{
  return 100;
}

@end
