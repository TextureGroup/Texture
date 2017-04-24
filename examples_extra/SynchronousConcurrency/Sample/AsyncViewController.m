//
//  AsyncViewController.m
//  Sample
//
//  Created by Scott Goodson on 9/26/15.
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

#import "AsyncViewController.h"
#import "RandomCoreGraphicsNode.h"

@implementation AsyncViewController

- (instancetype)init
{
  if (!(self = [super initWithNode:[[RandomCoreGraphicsNode alloc] init]])) {
    return nil;
  }

  self.neverShowPlaceholders = YES;
  self.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemFavorites tag:0];
  return self;
}

- (void)viewWillAppear:(BOOL)animated
{
  // FIXME: This is only being called on the first time the UITabBarController shows us.
  [super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
  [self.node recursivelyClearContents];
  [super viewDidDisappear:animated];
}

@end
