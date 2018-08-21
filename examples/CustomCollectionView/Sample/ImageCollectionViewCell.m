//
//  ImageCollectionViewCell.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "ImageCollectionViewCell.h"

@implementation ImageCollectionViewCell
{
  UILabel *_title;
  UILabel *_description;
}

- (id)initWithFrame:(CGRect)aRect
{
  self = [super initWithFrame:aRect];
  if (self) {
    _title = [[UILabel alloc] init];
    _title.text = @"UICollectionViewCell";
    [self.contentView addSubview:_title];
    
    _description = [[UILabel alloc] init];
    _description.text = @"description for cell";
    [self.contentView addSubview:_description];
    
    self.contentView.backgroundColor = [UIColor orangeColor];
  }
  return self;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  
  [_title sizeToFit];
  [_description sizeToFit];
  
  CGRect frame = _title.frame;
  frame.origin.y = _title.frame.size.height;
  _description.frame = frame;
}

@end
