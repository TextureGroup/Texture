//
//  ASCollectionLayoutCache.mm
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASCollectionLayoutCache.h>

#import <AsyncDisplayKit/ASCollectionLayoutContext.h>
#import <AsyncDisplayKit/ASCollectionLayoutState.h>
#import <AsyncDisplayKit/ASElementMap.h>
#import <AsyncDisplayKit/ASThread.h>

@implementation ASCollectionLayoutCache {
  ASDN::Mutex __instanceLock__;

  /**
   * The underlying data structure of this cache.
   *
   * The outer map table is a weak to strong table. That is because ASCollectionLayoutContext doesn't (and shouldn't) 
   * hold a strong reference on its element map. As a result, this cache should handle the case in which 
   * an element map no longer exists and all contexts and layouts associated with it should be cleared.
   *
   * The inner map table is a standard strong to strong map.
   * Since different ASCollectionLayoutContext objects with the same content are considered equal, 
   * "object pointer personality" can't be used as a key option.
   */
  NSMapTable<ASElementMap *, NSMapTable<ASCollectionLayoutContext *, ASCollectionLayoutState *> *> *_map;
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    _map = [NSMapTable mapTableWithKeyOptions:(NSMapTableWeakMemory | NSMapTableObjectPointerPersonality) valueOptions:NSMapTableStrongMemory];
  }
  return self;
}

- (ASCollectionLayoutState *)layoutForContext:(ASCollectionLayoutContext *)context
{
  ASElementMap *elements = context.elements;
  if (elements == nil) {
    return nil;
  }

  ASDN::MutexLocker l(__instanceLock__);
  return [[_map objectForKey:elements] objectForKey:context];
}

- (void)setLayout:(ASCollectionLayoutState *)layout forContext:(ASCollectionLayoutContext *)context
{
  ASElementMap *elements = context.elements;
  if (layout == nil || elements == nil) {
    return;
  }

  ASDN::MutexLocker l(__instanceLock__);
  auto innerMap = [_map objectForKey:elements];
  if (innerMap == nil) {
    innerMap = [NSMapTable strongToStrongObjectsMapTable];
    [_map setObject:innerMap forKey:elements];
  }
  [innerMap setObject:layout forKey:context];
}

- (void)removeLayoutForContext:(ASCollectionLayoutContext *)context
{
  ASElementMap *elements = context.elements;
  if (elements == nil) {
    return;
  }

  ASDN::MutexLocker l(__instanceLock__);
  [[_map objectForKey:elements] removeObjectForKey:context];
}

- (void)removeAllLayouts
{
  ASDN::MutexLocker l(__instanceLock__);
  [_map removeAllObjects];
}

@end
