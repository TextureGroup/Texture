//
//  ASLayoutElementPrivate.h
//  Texture
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

#import <AsyncDisplayKit/ASLayoutElementContext.h>

#pragma mark - ASLayoutElementContext

@implementation ASLayoutElementContext

- (instancetype)init
{
  if (self = [super init]) {
    _transitionID = ASLayoutElementContextDefaultTransitionID;
    _pendingLayoutMap = std::make_shared<std::unordered_map<void *, std::shared_ptr<ASDisplayNodeLayout>>>();
  }
  return self;
}

@end

CGFloat const ASLayoutElementParentDimensionUndefined = NAN;
CGSize const ASLayoutElementParentSizeUndefined = {ASLayoutElementParentDimensionUndefined, ASLayoutElementParentDimensionUndefined};

int32_t const ASLayoutElementContextInvalidTransitionID = 0;
int32_t const ASLayoutElementContextDefaultTransitionID = ASLayoutElementContextInvalidTransitionID + 1;

pthread_key_t ASLayoutElementContextKey;

static void ASLayoutElementDestructor(void *p) {
  if (p != NULL) {
    ASDisplayNodeCFailAssert(@"Thread exited without clearing layout element context!");
    CFBridgingRelease(p);
  }
};

// pthread_key_create must be called before the key can be used. This function does that.
void ASLayoutElementContextEnsureKey()
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    pthread_key_create(&ASLayoutElementContextKey, ASLayoutElementDestructor);
  });
}

void ASLayoutElementPushContext(ASLayoutElementContext *context)
{
  ASLayoutElementContextEnsureKey();
  // NOTE: It would be easy to support nested contexts – just use an NSMutableArray here.
  ASDisplayNodeCAssertNil(ASLayoutElementGetCurrentContext(), @"Nested ASLayoutElementContexts aren't supported.");
  pthread_setspecific(ASLayoutElementContextKey, CFBridgingRetain(context));
}

ASLayoutElementContext *ASLayoutElementGetCurrentContext()
{
  ASLayoutElementContextEnsureKey();
  // Don't retain here. Caller will retain if it wants to!
  return (__bridge __unsafe_unretained ASLayoutElementContext *)pthread_getspecific(ASLayoutElementContextKey);
}

void ASLayoutElementPopContext()
{
  ASLayoutElementContextEnsureKey();
  ASDisplayNodeCAssertNotNil(ASLayoutElementGetCurrentContext(), @"Attempt to pop context when there wasn't a context!");
  CFBridgingRelease(pthread_getspecific(ASLayoutElementContextKey));
  pthread_setspecific(ASLayoutElementContextKey, NULL);
}

std::shared_ptr<ASDisplayNodeLayout> ASLayoutElementContextGetPendingLayout(ASDisplayNode *node)
{
  if (node == nil) {
    return nullptr;
  }
  
  void *nodePointer = (__bridge void *)node;
  std::shared_ptr<std::unordered_map<void *,
                  std::shared_ptr<ASDisplayNodeLayout>>> pendingLayoutMap =
                                                            ASLayoutElementGetCurrentContext().pendingLayoutMap;
  if (pendingLayoutMap == nullptr) {
    // WARNING: This condition should probably not be reached. It implies that the
    // caller is asking for _pendingLayout outside of any layout operation.
    return nullptr;
  }

  return (*(ASLayoutElementGetCurrentContext().pendingLayoutMap))[nodePointer];
}

void ASLayoutElementContextSetPendingLayout(ASDisplayNode *node, std::shared_ptr<ASDisplayNodeLayout> layout)
{
  if (node == nil) {
    return;
  }

  void *nodePointer = (__bridge void *)node;
  std::shared_ptr<std::unordered_map<void *,
                  std::shared_ptr<ASDisplayNodeLayout>>> pendingLayoutMap =
                                                            ASLayoutElementGetCurrentContext().pendingLayoutMap;

  if (pendingLayoutMap == nullptr) {
    return;
  }

  if (layout != nullptr) {
    (*(pendingLayoutMap))[nodePointer] = layout;
  } else if ((*(pendingLayoutMap))[nodePointer] != nullptr) {
    (*(pendingLayoutMap)).erase(nodePointer);
  }
}



