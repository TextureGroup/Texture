//
//  ViewController.m
//  Sample
//
//  Created by Max Wang on 9/8/17.
//  Copyright © 2017 Max Wang. All rights reserved.
//

#import "ViewController.h"
#import "TextCellNode.h"

@interface ViewController () <ASTableDelegate, ASTableDataSource> {
  ASTableNode* _tableNode;
  NSArray<NSString*>* _labels;
  NSArray<NSString*>* _examples;
  TextCellNode* _cellNode;
}

@end

@implementation ViewController

- (instancetype) init {
  _tableNode = [[ASTableNode alloc] initWithStyle:UITableViewStylePlain];
  self = [super initWithNode:_tableNode];
  if (self) {
    _tableNode.delegate = self;
    _tableNode.dataSource = self;
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  _tableNode.backgroundColor = [UIColor whiteColor];
  _labels = @[@"Fight of the Living Dead: Experiment 88Fight of the Living Dead: Exper", @"S1 • E1"];
}

-(void)viewDidLayoutSubviews {
  [super viewDidLayoutSubviews];

}


-(NSInteger)tableNode:(ASTableNode *)tableNode numberOfRowsInSection:(NSInteger)section {
  return 1;
}

- (ASCellNodeBlock)tableNode:(ASTableNode *)tableNode nodeBlockForRowAtIndexPath:(NSIndexPath *)indexPath {
  return ^{
    _cellNode = [[TextCellNode alloc] initWithText1:_labels[0] text2:_labels[1]];
    return _cellNode;
  };
}

-(void)tableNode:(ASTableNode *)tableNode didSelectRowAtIndexPath:(NSIndexPath *)indexPath {


}


@end
