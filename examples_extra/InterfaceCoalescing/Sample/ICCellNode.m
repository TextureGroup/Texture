//
//  ICCellNode.m
//  Sample
//
//  Created by Max Wang on 4/5/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "ICCellNode.h"

@implementation ICCellNode {
  UIColor *_color;
  NSString *_colorName;
}

- (instancetype)initWithColor:(UIColor *)color colorName:(NSString *)colorName {
  if (self = [super init]) {
//    self.automaticallyManagesSubnodes = NO;
    _color = color;
    _colorName = colorName;

    _didEnterVisibleCount = 0;
    _didExitVisibleCount = 0;

    self.backgroundColor = _color;
  }
  return self;
}

- (void)layout {
  [super layout];
  NSLog(@"^^^^ Layout");
}

- (void)didLoad {
  [super didLoad];
}

- (void)didEnterVisibleState {
  [super didEnterVisibleState];
  self.didEnterVisibleCount += 1;
  NSLog(@"^^^^ %@ didEnterVisibleState %@", _colorName, self);

  [self.delegate cellDidEnterVisibleState:self];
}

- (void)didExitVisibleState {
  [super didExitVisibleState];
  self.didExitVisibleCount += 1;
  NSLog(@"^^^^ %@ didExitVisibleState %@", _colorName, self);
}

- (void)didEnterDisplayState {
  [super didEnterDisplayState];
  NSLog(@"^^^^ %@ didEnterDisplayState %@", _colorName, self);
}

- (void)didExitDisplayState {
  [super didExitDisplayState];
  NSLog(@"^^^^ %@ didExitDisplayState %@", _colorName, self);
}

- (void)didEnterPreloadState {
  [super didEnterPreloadState];
  NSLog(@"^^^^ %@ didEnterPreloadState %@", _colorName, self);
}

- (void)didExitPreloadState {
  [super didExitPreloadState];
  NSLog(@"^^^^ %@ didExitPreloadState %@", _colorName, self);
}

@end
