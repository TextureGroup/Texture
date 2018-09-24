//
//  TECellView.m
//  Sample
//
//  Created by Adlai Holler on 9/21/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "TECellView.h"

@implementation TECellView {
  UIStackView *_stackView;
  UILabel *_label;
}

- (instancetype)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    _stackView = [[UIStackView alloc] initWithFrame:self.bounds];
    _stackView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_stackView];
    
    _label = [[UILabel alloc] init];
    [_stackView addArrangedSubview:_label];
  }
  return self;
}

- (void)setItem:(const Item &)item {
  auto textPtr = item.text();
  _label.text = [[NSString alloc] initWithBytes:textPtr->c_str() length:textPtr->size() encoding:NSUTF8StringEncoding];
}

+ (TECellView *)hostInContentViewIfNeeded:(UIView *)contentView {
  TECellView *view = contentView.subviews.firstObject;
  if (view) {
    return view;
  }
  view = [[TECellView alloc] initWithFrame:contentView.bounds];
  [contentView addSubview:view];
  view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  return view;
}

+ (CGSize)sizeForItem:(const Item &)item inContainer:(UIView *)view {
  NSAssert(NSThread.isMainThread, nil);
  static TECellView *mannequinView;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    mannequinView = [[TECellView alloc] init];
  });
  [mannequinView setItem:item];
  return [mannequinView sizeThatFits:view.bounds.size];
}

@end
