//
//  ASDisplayNode+InterfaceState.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//


#import <AsyncDisplayKit/ASDisplayNode+InterfaceState.h>

@interface ASDisplayNodeInterfaceDelegateManager ()
{
    NSHashTable *_interfaceDidChangeDelegates;
    NSHashTable *_interfaceDidEnterVisibleDelegates;
    NSHashTable *_interfaceDidExitVisibleDelegates;
    NSHashTable *_interfaceDidEnterDisplayDelegates;
    NSHashTable *_interfaceDidExitDisplayDelegates;
    NSHashTable *_interfaceDidEnterPreloadDelegates;
    NSHashTable *_interfaceDidExitPreloadDelegates;
    NSHashTable *_interfaceNodeDidLayoutDelegates;
    NSHashTable *_interfaceNodeDidLoadDelegates;
}
@end

@implementation ASDisplayNodeInterfaceDelegateManager

- (instancetype)init
{
    if (self = [super init]) {
        _interfaceDidChangeDelegates = [NSHashTable weakObjectsHashTable];
        _interfaceDidEnterVisibleDelegates = [NSHashTable weakObjectsHashTable];
        _interfaceDidExitVisibleDelegates = [NSHashTable weakObjectsHashTable];
        _interfaceDidEnterDisplayDelegates = [NSHashTable weakObjectsHashTable];
        _interfaceDidExitDisplayDelegates = [NSHashTable weakObjectsHashTable];
        _interfaceDidEnterPreloadDelegates = [NSHashTable weakObjectsHashTable];
        _interfaceDidExitPreloadDelegates = [NSHashTable weakObjectsHashTable];
        _interfaceNodeDidLayoutDelegates = [NSHashTable weakObjectsHashTable];
        _interfaceNodeDidLoadDelegates = [NSHashTable weakObjectsHashTable];
    }
}

- (void)addDelegate:(id<ASInterfaceStateDelegate>)delegate
{
  if ([delegate respondsToSelector:@selector(interfaceStateDidChange:fromState:)]) {
    [_interfaceDidChangeDelegates addObject:delegate];
  }
  if ([delegate respondsToSelector:@selector(didEnterVisibleState)]) {
    [_interfaceDidEnterVisibleDelegates addObject:delegate];
  }
  if ([delegate respondsToSelector:@selector(didExitVisibleState)]) {
    [_interfaceDidExitVisibleDelegates addObject:delegate];
  }
  if ([delegate respondsToSelector:@selector(didEnterDisplayState)]) {
    [_interfaceDidEnterDisplayDelegates addObject:delegate];
  }
  if ([delegate respondsToSelector:@selector(didExitDisplayState)]) {
    [_interfaceDidExitDisplayDelegates addObject:delegate];
  }
  if ([delegate respondsToSelector:@selector(didEnterPreloadState)]) {
    [_interfaceDidEnterPreloadDelegates addObject:delegate];
  }
  if ([delegate respondsToSelector:@selector(didExitPreloadState)]) {
    [_interfaceDidExitPreloadDelegates addObject:delegate];
  }
  if ([delegate respondsToSelector:@selector(nodeDidLayout)]) {
    [_interfaceNodeDidLayoutDelegates addObject:delegate];
  }
  if ([delegate respondsToSelector:@selector(nodeDidLoad)]) {
    [_interfaceNodeDidLoadDelegates addObject:delegate];
  }
}

- (void)removeDelegate:(id<ASInterfaceStateDelegate>)delegate
{
    [_interfaceDidChangeDelegates removeObject:delegate];
    [_interfaceDidEnterVisibleDelegates removeObject:delegate];
    [_interfaceDidExitVisibleDelegates removeObject:delegate];
    [_interfaceDidEnterDisplayDelegates removeObject:delegate];
    [_interfaceDidExitDisplayDelegates removeObject:delegate];
    [_interfaceDidEnterPreloadDelegates removeObject:delegate];
    [_interfaceDidExitPreloadDelegates removeObject:delegate];
    [_interfaceNodeDidLayoutDelegates removeObject:delegate];
    [_interfaceNodeDidLoadDelegates removeObject:delegate];
}

- (void)interfaceStateDidChange:(ASInterfaceState)newState fromState:(ASInterfaceState)oldState
{
  for (id <ASInterfaceStateDelegate>delegate in _interfaceDidChangeDelegates) {
    [delegate interfaceStateDidChange:newState fromState:oldState];
  }
}

- (void)didEnterVisibleState
{
  for (id <ASInterfaceStateDelegate>delegate in _interfaceDidEnterVisibleDelegates) {
    [delegate didEnterVisibleState];
  }
}

- (void)didExitVisibleState
{
  for (id <ASInterfaceStateDelegate>delegate in _interfaceDidExitVisibleDelegates) {
    [delegate didExitVisibleState];
  }
}

- (void)didEnterDisplayState
{
  for (id <ASInterfaceStateDelegate>delegate in _interfaceDidEnterDisplayDelegates) {
    [delegate didEnterDisplayState];
  }
}

- (void)didExitDisplayState
{
  for (id <ASInterfaceStateDelegate>delegate in _interfaceDidExitDisplayDelegates) {
    [delegate didExitDisplayState];
  }
}

- (void)didEnterPreloadState
{
  for (id <ASInterfaceStateDelegate>delegate in _interfaceDidEnterPreloadDelegates) {
    [delegate didEnterPreloadState];
  }
}

- (void)didExitPreloadState
{
  for (id <ASInterfaceStateDelegate>delegate in _interfaceDidExitPreloadDelegates) {
    [delegate didExitPreloadState];
  }
}

- (void)nodeDidLayout
{
  for (id <ASInterfaceStateDelegate>delegate in _interfaceNodeDidLayoutDelegates) {
    [delegate nodeDidLayout];
  }
}

- (void)nodeDidLoad
{
  for (id <ASInterfaceStateDelegate>delegate in _interfaceNodeDidLoadDelegates) {
    [delegate nodeDidLoad];
  }
}

@end
