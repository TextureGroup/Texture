//
//  ICDisplayNode.m
//  Sample
//
//  Created by Max Wang on 4/6/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "ICDisplayNode.h"

@implementation ICDisplayNode

- (instancetype)init
{
  self = [super init];
  if (self) {
    self.backgroundColor = [UIColor whiteColor];
  }
  return self;
}
- (void)didEnterVisibleState {
  [super didEnterVisibleState];
  NSLog(@"^^^^ didEnterVisibleState %@", self);
}

- (void)didExitVisibleState {
  [super didExitVisibleState];
  NSLog(@"^^^^ didExitVisibleState %@", self);
}

- (void)didEnterDisplayState {
  [super didEnterDisplayState];
  NSLog(@"^^^^ didEnterDisplayState %@", self);
}

- (void)didExitDisplayState {
  [super didExitDisplayState];
  NSLog(@"^^^^ didExitDisplayState %@", self);
}

- (void)didEnterPreloadState {
  [super didEnterPreloadState];
  NSLog(@"^^^^ didEnterPreloadState %@", self);
}

- (void)didExitPreloadState {
  [super didExitPreloadState];
  NSLog(@"^^^^ didExitPreloadState %@", self);
}

@end
