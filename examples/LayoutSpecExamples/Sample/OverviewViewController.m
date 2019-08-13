//
//  OverviewViewController.m
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "OverviewViewController.h"
#import "LayoutExampleNodes.h"
#import "LayoutExampleViewController.h"
#import "OverviewCellNode.h"

@interface OverviewViewController () <ASTableDelegate, ASTableDataSource>
@property (nonatomic, strong) NSArray *layoutExamples;
@property (nonatomic, strong) ASTableNode *tableNode;
@end

@implementation OverviewViewController

#pragma mark - Lifecycle Methods

- (instancetype)init
{
  _tableNode = [ASTableNode new];
  self = [super initWithNode:_tableNode];
  
  if (self) {
    self.title = @"Layout Examples";
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    
    _tableNode.delegate = self;
    _tableNode.dataSource = self;
    
    _layoutExamples = @[[HeaderWithRightAndLeftItems class],
                        [PhotoWithInsetTextOverlay class],
                        [PhotoWithOutsetIconOverlay class],
                        [FlexibleSeparatorSurroundingContent class],
                        [CornerLayoutExample class],
                        [UserProfileSample class]
                        ];
  }
  
  return self;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  
  NSIndexPath *indexPath = _tableNode.indexPathForSelectedRow;
  if (indexPath != nil) {
    [_tableNode deselectRowAtIndexPath:indexPath animated:YES];
  }
}

#pragma mark - ASTableDelegate, ASTableDataSource

- (NSInteger)tableNode:(ASTableNode *)tableNode numberOfRowsInSection:(NSInteger)section
{
  return [_layoutExamples count];
}

- (ASCellNodeBlock)tableNode:(ASTableNode *)tableNode nodeBlockForRowAtIndexPath:(NSIndexPath *)indexPath {
    Class layoutExample = _layoutExamples[indexPath.row];
    return ^{
        return [[OverviewCellNode alloc] initWithLayoutExampleClass:layoutExample];
    };
}

- (void)tableNode:(ASTableNode *)tableNode didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  Class layoutExampleClass = [[tableNode nodeForRowAtIndexPath:indexPath] layoutExampleClass];
  LayoutExampleViewController *detail = [[LayoutExampleViewController alloc] initWithLayoutExampleClass:layoutExampleClass];
  [self.navigationController pushViewController:detail animated:YES];
}

@end
