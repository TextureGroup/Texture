//
//  ASNodeContext.mm
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0

#import <AsyncDisplayKit/ASNodeContext+Private.h>

#import <AsyncDisplayKit/ASAssert.h>

#import <stack>
#import <unordered_map>

#if AS_TLS_AVAILABLE

static thread_local std::stack<ASNodeContext *> gContexts;

void ASNodeContextPush(unowned ASNodeContext *context) {
  gContexts.push(context);
}

ASNodeContext *ASNodeContextGet() {
  return gContexts.empty() ? nil : gContexts.top();
}

void ASNodeContextPop() {
  if (DISPATCH_EXPECT(gContexts.empty(), false)) {
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

id ASNodeContextPerform(unowned ASNodeContext *ctx, id(^ NS_NOESCAPE body)(void))
{
  ASNodeContextPush(ctx);
  id result = body();
  ASNodeContextPop();
  return result;
}

@implementation ASNodeContext {
  std::unordered_map<uint32_t, id> _extensions;
}

- (id)createObject:(id(^ NS_NOESCAPE)())body
{
  ASNodeContextPush(self);
  id result = body();
  ASNodeContextPop();
  return result;
}

- (instancetype)init
{
  if (self = [super init]) {
    _mutex.SetDebugNameWithObject(self);
  }
  return self;
}

- (id)extensionWithIdentifier:(ASNodeContextExtensionIdentifier)extensionIdentifier
{
  AS::MutexLocker l(_mutex);
  auto it = _extensions.find(extensionIdentifier);
  return it != _extensions.end() ? it->second : nil;
}

- (void)setExtension:(id)extension forIdentifier:(ASNodeContextExtensionIdentifier)extensionIdentifier
{
  AS::MutexLocker l(_mutex);
  if (extension) {
    _extensions.emplace(extensionIdentifier, extension);
  } else {
    _extensions.erase(extensionIdentifier);
  }
}

#pragma mark ASLocking

ASSynthesizeLockingMethodsWithMutex(_mutex);

@end
