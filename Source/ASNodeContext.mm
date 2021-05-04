//
//  ASNodeContext.mm
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0

#import <AsyncDisplayKit/ASNodeContext+Private.h>

#import <AsyncDisplayKit/ASAssert.h>

#import <stack>

#if AS_TLS_AVAILABLE

AS_ASSUME_NORETAIN_BEGIN

static thread_local std::stack<ASNodeContext *> gContexts;

void ASNodeContextPush(ASNodeContext *context) {
  gContexts.push(context);
}

ASNodeContext *ASNodeContextGet() {
  return gContexts.empty() ? nil : gContexts.top();
}

void ASNodeContextPop() {
  if (AS_PREDICT_FALSE(gContexts.empty())) {
    ASDisplayNodeCFailAssert(@"Attempt to pop empty context stack.");
    return;
  }
  gContexts.pop();
}

#else   // !AS_TLS_AVAILABLE

// Only on 32-bit simulator. Performance expendable.

// Points to a NSMutableArray<ASNodeContext *>.
static constexpr NSString *ASNodeContextStackKey = @"org.TextureGroup.Texture.nodeContexts";

void ASNodeContextPush(unowned ASNodeContext *context) {
  unowned NSMutableDictionary *td = NSThread.currentThread.threadDictionary;
  unowned NSMutableArray<ASNodeContext *> *stack = td[ASNodeContextStackKey];
  if (!stack) {
    td[ASNodeContextStackKey] = [[NSMutableArray alloc] initWithObjects:context, nil];
  } else {
    [stack addObject:context];
  }
}

ASNodeContext *ASNodeContextGet() {
  return [NSThread.currentThread.threadDictionary[ASNodeContextStackKey] lastObject];
}

void ASNodeContextPop() {
  if (ASActivateExperimentalFeature(ASExperimentalNodeContext)) {
    [NSThread.currentThread.threadDictionary[ASNodeContextStackKey] removeLastObject];
  }
}

#endif  // !AS_TLS_AVAILABLE

@implementation ASNodeContext {
  ASNodeContextOptions _options;
}

- (instancetype)initWithOptions:(ASNodeContextOptions)options {
  if (self = [super init]) {
    _mutex.SetDebugNameWithObject(self);
    _options = options;
  }
  return self;
}

- (instancetype)init {
  return [self initWithOptions:ASNodeContextNone];
}

- (ASNodeContextOptions)options {
  return _options;
}

@end

AS::RecursiveMutex *ASNodeContextGetMutex(ASNodeContext *ctx) {
  if (AS_PREDICT_FALSE(!ctx)) {
    ASDisplayNodeCFailAssert(@"Passing nil context not allowed!");
    static auto dummy_mutex = new AS::RecursiveMutex;
    return dummy_mutex;
  }
  return &ctx->_mutex;
}

AS_ASSUME_NORETAIN_END
