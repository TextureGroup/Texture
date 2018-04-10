//
//  ICCollectionNode.m
//  Sample
//
//  Created by Max Wang on 4/5/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "ICCollectionNode.h"

@implementation ICCollectionNode

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
