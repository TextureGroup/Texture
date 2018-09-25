//
//  TEItem.m
//  Sample
//
//  Created by Adlai Holler on 9/24/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "TEItem.h"

@implementation TEItem

- (instancetype)initWithItemPointer:(Item *)item {
  if (self = [super init]) {
    _item = item;
  }
  return self;
}

@end
