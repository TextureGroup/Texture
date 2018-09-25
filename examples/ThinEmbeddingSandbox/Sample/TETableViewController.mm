//
//  TETableViewController.m
//  Sample
//
//  Created by Adlai Holler on 9/21/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "TETableViewController.h"

@interface TETableViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation TETableViewController {
  UITableView *_tableView;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
    static NSInteger instanceID = 1;
    self.title = [NSString stringWithFormat:@"Table #%ld", (long)instanceID++];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  UIView *view = self.view;
  _tableView = [[UITableView alloc] initWithFrame:view.bounds style:UITableViewStylePlain];
  [_tableView registerClass:UITableViewCell.class forCellReuseIdentifier:TECellNativeReuseIdentifier];
  
  [_tableView registerClass:UITableViewHeaderFooterView.class forHeaderFooterViewReuseIdentifier:TECellNativeReuseIdentifier];
  [_tableView registerClass:UITableViewHeaderFooterView.class forHeaderFooterViewReuseIdentifier:TECellNativeReuseIdentifier];
  _tableView.delegate = self;
  _tableView.dataSource = self;
  [view addSubview:_tableView];
  _textureHelper = [[ASCollectionViewHelper alloc] initWithTableView:_tableView dataSource:self];
}

- (void)reloadData {
  [_tableView reloadData];
}

- (void)perform:(void (NS_NOESCAPE ^)())updates {
  [_tableView beginUpdates];
  updates();
  [_tableView endUpdates];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return [self numberOfSections];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [self numberOfItemsIn:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  CGFloat height;
  if ([_textureHelper tableView:tableView heightForRowAtIndexPath:indexPath height:&height]) {
    return height;
  }
  return [self sizeAt:TEPath::make(indexPath)].height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
  
  CGFloat height;
  if ([_textureHelper tableView:tableView heightForHeaderInSection:section height:&height]) {
    return height;
  }
  return [self sizeAt:TEPath::header(section)].height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
  CGFloat height;
  if ([_textureHelper tableView:tableView heightForFooterInSection:section height:&height]) {
    return height;
  }
  
  return [self sizeAt:TEPath::footer(section)].height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  if (auto cell = [_textureHelper tableView:tableView cellForRowAtIndexPath:indexPath]) {
    return cell;
  }
  
  auto path = TEPath::make(indexPath);
  auto cell = [tableView dequeueReusableCellWithIdentifier:TECellNativeReuseIdentifier forIndexPath:indexPath];
  [self hostItemAt:path in:cell.contentView];
  return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
  if (auto cell = [_textureHelper tableView:tableView viewForHeaderInSection:section]) {
    return cell;
  }
  
  auto path = TEPath::header(section);
  auto cell = [tableView dequeueReusableHeaderFooterViewWithIdentifier:TECellNativeReuseIdentifier];
  [self hostItemAt:path in:cell.contentView];
  return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
  if (auto cell = [_textureHelper tableView:tableView viewForFooterInSection:section]) {
    return cell;
  }
  auto path = TEPath::footer(section);
  auto cell = [tableView dequeueReusableHeaderFooterViewWithIdentifier:TECellNativeReuseIdentifier];
  [self hostItemAt:path in:cell.contentView];
  return cell;
}

@end
