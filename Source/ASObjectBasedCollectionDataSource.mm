//
//  ASObjectBasedCollectionDataSource.m
//  AsyncDisplayKit
//
//  Created by Adlai Holler on 5/16/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "ASObjectBasedCollectionDataSource.h"
#import <atomic>
#import <set>
#import <vector>
#import <AsyncDisplayKit/ASCellNode.h>
#import <AsyncDisplayKit/ASLayoutSpec.h>
#import <AsyncDisplayKit/ASMainSerialQueue.h>
#import <AsyncDisplayKit/ASThread.h>

@implementation ASObjectRenderer {
  NSMapTable<Class, NSMutableArray<ASObjectRenderBlock> *> *_classToRenderBlocksMap;
  std::atomic<BOOL> _mapIsReadOnly;
}

+ (ASObjectRenderer *)sharedRenderer
{
  static ASObjectRenderer *sharedRenderer;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedRenderer = [[ASObjectRenderer alloc] init];
  });
  return sharedRenderer;
}

- (instancetype)init
{
  if (self = [super init]) {
    _classToRenderBlocksMap = [NSMapTable mapTableWithKeyOptions:NSMapTableObjectPointerPersonality valueOptions:NSMapTableStrongMemory];
  }
  return self;
}

- (void)addRenderMethodForObjectClass:(Class)c block:(ASDisplayNode * _Nonnull (^)(id _Nonnull))block
{
  ASDisplayNodeAssertMainThread();
  if (_mapIsReadOnly.load()) {
    ASDisplayNodeFailAssert(@"Cannot add renderers after first render.");
    return;
  }
  
  c = c ?: [NSObject class];
  auto blocks = [_classToRenderBlocksMap objectForKey:c];
  if (blocks == nil) {
    blocks = [NSMutableArray array];
    [_classToRenderBlocksMap setObject:blocks forKey:c];
  }
  [blocks insertObject:block atIndex:0];
}

- (ASDisplayNode *)renderObject:(id)object
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _mapIsReadOnly = YES;
  });
  
  NSParameterAssert(object != nil);
  Class c = object_getClass(object);
  while (c != nil) {
    for (ASObjectRenderBlock block in [_classToRenderBlocksMap objectForKey:c]) {
      auto node = block(object);
      if (node != nil) {
        return node;
      }
    }
    c = class_getSuperclass(c);
  }
  
  ASDisplayNodeFailAssert(@"Failed to render node for object: %@", object);
  return [[ASDisplayNode alloc] init];
}

@end

@interface ASObjectBasedInvalidationContextImpl : NSObject <ASObjectBasedInvalidationContext>
@end

@interface ASCollectionDataInvalidation : NSObject
@property (nonatomic, copy, nullable) void (^animationCompletion)(BOOL finished);

@end

@interface ASCollectionDataRequest ()
@property (nonatomic, copy) asdisplaynode_iscancelled_block_t cancelledBlock;
@property (nonatomic, strong) ASCollectionData *capturedData;

@property (nonatomic, strong) id diffResult;
@end

@implementation ASCollectionDataRequest

- (BOOL)isCancelled
{
  return self.cancelledBlock ? self.cancelledBlock() : NO;
}

@end

@interface ASObjectBasedCollectionDataSource () {
  std::atomic<NSUInteger> _sourceDataVersion;
}
@property (atomic, copy) ASCollectionData *dataCommittedToNode;

@property (nonatomic, readonly) dispatch_queue_t privateQueue;

@property (nonatomic, strong, readonly) ASMainSerialQueue *mainSerialQueue;
@end



@implementation ASCollectionDataInvalidation

@end

/**
 *
 */
@implementation ASObjectBasedCollectionDataSource {
  std::atomic<BOOL> _updateScheduled;
  char _sourceQueueKey;
  char _privateQueueKey;
  
  ASAtomicArrayType(ASCollectionDataInvalidation) *_invalidations;
  
  // Only written to on sourceQueue, read from multiple queues.
  std::atomic<BOOL> _sourceDataIsFullyValid;
}

- (instancetype)initWithCollectionNode:(ASCollectionNode *)collectionNode sourceQueue:(nullable dispatch_queue_t)sourceQueue
{
  if (self = [super init]) {
    _privateQueue = dispatch_queue_create("com.texture.objectBasedCollectionDataSource.privateQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_set_specific(_privateQueue, &_privateQueueKey, (void *)kCFNull, NULL);
    _mainSerialQueue = [[ASMainSerialQueue alloc] init];
    if (sourceQueue) {
      _sourceQueue = sourceQueue;
      dispatch_queue_set_specific(_sourceQueue, &_sourceQueueKey, (void *)kCFNull, NULL);
    }
  }
  return self;
}

- (BOOL)isOnPrivateQueue
{
  return dispatch_get_specific(&_privateQueueKey) != NULL;
}

- (BOOL)isOnSourceQueue
{
  if (_sourceQueue) {
    return dispatch_get_specific(&_sourceQueueKey) != NULL;
  } else {
    return ASDisplayNodeThreadIsMain();
  }
}

- (void)dealloc
{
  if (_sourceQueue) {
    dispatch_queue_set_specific(_sourceQueue, &_sourceQueueKey, NULL, NULL);
  }
}

- (void)performOnSourceQueue:(void(^)())block
{
  if ([self isOnSourceQueue]) {
    block();
  } else {
    if (_sourceQueue) {
      dispatch_async(_sourceQueue, block);
    } else {
      [_mainSerialQueue performBlockOnMainThread:block];
    }
  }
}

- (void)invalidateWithAnimationCompletion:(void (^)(BOOL))animationCompletion
{
  ASCollectionDataInvalidation *invalidation = [[ASCollectionDataInvalidation alloc] init];
  invalidation.animationCompletion = animationCompletion;
  [_invalidations accessWithBlock:^(NSMutableArray<ASCollectionDataInvalidation *> * _Nonnull mutableValue) {
    [mutableValue addObject:invalidation];
  }];
  
  if (!_updateScheduled.exchange(YES)) {
    dispatch_async(_privateQueue, ^{
      _updateScheduled = NO;
      [self privateQueue_runUpdateFromTopLevel];
    });
  }
}

- (void)privateQueue_runUpdateFromTopLevel
{
  NSParameterAssert([self isOnPrivateQueue]);
  auto group = dispatch_group_create();
  auto request = [[ASCollectionDataRequest alloc] init];
  
  // On source queue, latch in a new copy of data.
  dispatch_group_enter(group);
  [self performOnSourceQueue:^{
    [self sourceQueue_captureDataWithRequest:request];
    dispatch_group_leave(group);
  }];
  dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
  
  // On private queue (here), compute the diff.
  [self privateQueue_processDataFromRequest:request];
  
  // On main thread, apply the update to the collection node.
  dispatch_group_enter(group);
  [_mainSerialQueue performBlockOnMainThread:^{
    [self mainThread_applyDiffWithRequest:request];
    dispatch_group_leave(group);
  }];
  dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
}

- (void)sourceQueue_captureDataWithRequest:(ASCollectionDataRequest *)request
{
  NSParameterAssert([self isOnSourceQueue]);
  
  request.capturedInvalidationCount = ASAtomicAccessOneProperty(_invalidations, count);
  request.capturedData = self.dataBlock(request);
  request.cancelledBlock = ^BOOL{
    return !_sourceDataIsFullyValid;
  };
}

- (void)privateQueue_processDataFromRequest:(ASCollectionDataRequest *)request
{
  NSParameterAssert([self isOnPrivateQueue]);
  if (request.cancelled) {
    return;
  }
  request.diffResult = nil;
  
  auto capturedData = request.capturedData;
  // Gather new array of sections and perform full hierarchical diff.
  NSArray *oldSections = self.dataCommittedToNode.sections;
  NSArray *newSections = capturedData.sections;
  for (id section in newSections) {
    
  }
}

- (void)mainThread_applyDiffWithRequest:(ASCollectionDataRequest *)request
{
  ASDisplayNodeAssertMainThread();
  if (request.cancelled) {
    return;
  }
  
  // Now that we're committed, grab the first chunk of animation completion blocks.
  __block NSArray *blocksToRun;
  NSRange range = NSMakeRange(0, request.animationCompletionBlockCount);
  [_animationCompletionBlocks accessWithBlock:^(NSMutableArray<void (^)(BOOL)> * _Nonnull mutableValue) {
    blocksToRun = [mutableValue subarrayWithRange:range];
    [mutableValue removeObjectsInRange:range];
  }];
  
  [self.collectionNode performBatchUpdates:^{
    self.dataCommittedToNode = request.capturedData;
    // Apply diff.
    
  } completion:^(BOOL finished) {
    for (void(^block)(BOOL) in blocksToRun) {
      block(finished);
    }
  }];
}

#pragma mark - ASCollectionDataSource

- (ASCellNodeBlock)collectionNode:(ASCollectionNode *)collectionNode nodeBlockForItemAtIndexPath:(NSIndexPath *)indexPath
{
  id object = [self.dataCommittedToNode itemAtIndexPath:indexPath];
  return ^{
    auto node = [ASObjectRenderer.sharedRenderer renderObject:object];
    if ([node isKindOfClass:[ASCellNode class]]) {
      return (ASCellNode *)node;
    } else {
      ASCellNode *cellNode = [[ASCellNode alloc] init];
      [cellNode addSubnode:node];
      cellNode.layoutSpecBlock = ^ASLayoutSpec * _Nonnull(__kindof ASDisplayNode * _Nonnull node, ASSizeRange constrainedSize) {
        return [[ASWrapperLayoutSpec alloc] initWithLayoutElement:node];
      };
      return cellNode;
    }
  };
}

- (NSInteger)numberOfSectionsInCollectionNode:(ASCollectionNode *)collectionNode
{
  return self.dataCommittedToNode.sections.count;
}

- (NSInteger)collectionNode:(ASCollectionNode *)collectionNode numberOfItemsInSection:(NSInteger)section
{
  return [self.dataCommittedToNode itemsInSectionAtIndex:section].count;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  // TODO: Handle cases where the delegate doesn't implement this.
  return [self.scrollViewDelegate scrollViewDidScroll:scrollView];
}

// TODO: Other UIScrollViewDelegate methods.

@end
