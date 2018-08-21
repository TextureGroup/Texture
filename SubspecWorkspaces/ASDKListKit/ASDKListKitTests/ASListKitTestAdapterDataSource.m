//
//  ASListKitTestAdapterDataSource.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASListKitTestAdapterDataSource.h"
#import "ASListTestSection.h"

@implementation ASListKitTestAdapterDataSource

- (NSArray *)objectsForListAdapter:(IGListAdapter *)listAdapter
{
  return self.objects;
}

- (IGListSectionController *)listAdapter:(IGListAdapter *)listAdapter sectionControllerForObject:(id)object
{
  ASListTestSection *section = [[ASListTestSection alloc] init];
  return section;
}

- (nullable UIView *)emptyViewForListAdapter:(IGListAdapter *)listAdapter
{
  return nil;
}

@end
