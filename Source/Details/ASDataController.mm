//
//  ASDataController.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASDataController.h>

#import <AsyncDisplayKit/_ASHierarchyChangeSet.h>
#import <AsyncDisplayKit/_ASScopeTimer.h>
#import <AsyncDisplayKit/ASCellNode.h>
#import <AsyncDisplayKit/ASCollectionElement.h>
#import <AsyncDisplayKit/ASCollectionLayoutContext.h>
#import <AsyncDisplayKit/ASDispatch.h>
#import <AsyncDisplayKit/ASDisplayNodeExtras.h>
#import <AsyncDisplayKit/ASDisplayNodeInternal.h>
#import <AsyncDisplayKit/ASElementMap.h>
#import <AsyncDisplayKit/ASExperimentalFeatures.h>
#import <AsyncDisplayKit/ASLayout.h>
#import <AsyncDisplayKit/ASSignpost.h>
#import <AsyncDisplayKit/ASMainSerialQueue.h>
#import <AsyncDisplayKit/ASMutableElementMap.h>
#import <AsyncDisplayKit/ASRangeManagingNode.h>
#import <AsyncDisplayKit/ASThread.h>
#import <AsyncDisplayKit/ASSection.h>

#import <AsyncDisplayKit/ASInternalHelpers.h>
#import <AsyncDisplayKit/ASCellNode+Internal.h>
#import <AsyncDisplayKit/ASDisplayNode+Subclasses.h>
#import <AsyncDisplayKit/NSIndexSet+ASHelpers.h>

//#define LOG(...) NSLog(__VA_ARGS__)
#define LOG(...)

const static char * kASDataControllerEditingQueueKey = "kASDataControllerEditingQueueKey";
const static char * kASDataControllerEditingQueueContext = "kASDataControllerEditingQueueContext";
using namespace AS;

NSString * const ASDataControllerRowNodeKind = @"_ASDataControllerRowNodeKind";
NSString * const ASCollectionInvalidUpdateException = @"ASCollectionInvalidUpdateException";

typedef dispatch_block_t ASDataControllerCompletionBlock;

typedef void (^ASDataControllerSynchronizationBlock)();

BOOL gEnableAutoreleasePoolInQueues = NO;
BOOL ASGetEnableAutoreleasePoolInQueues(void) { return gEnableAutoreleasePoolInQueues; }
void ASSetEnableAutoreleasePoolInQueues(BOOL enable) { gEnableAutoreleasePoolInQueues = enable; }

BOOL gRemovePriorityInversion = NO;
BOOL ASGetRemovePriorityInversion(void) { return gRemovePriorityInversion; }
void ASSetRemovePriorityInversion(BOOL enable) { gRemovePriorityInversion = enable; }

static NSCache<id, ASCellNode *> *NodeCache()
{
  ASDisplayNodeCAssertMainThread();
  static constexpr NSTimeInterval kNodeCacheFlushDelay = 3.0;
  static constexpr NSTimeInterval kNodeCacheFlushLeeway = 1.0;

  static NSCache<id, ASCellNode *> *nodeCache;
  static dispatch_source_t flushTimer;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    nodeCache = [[NSCache alloc] init];
    nodeCache.name = @"org.TextureGroup.Texture.nodeCache";
    flushTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0,
                                        dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0));
    dispatch_source_set_event_handler(flushTimer, ^{
      [nodeCache removeAllObjects];
    });
  });

  // On each access, we delay the flush.
  dispatch_source_set_timer(flushTimer,
                            dispatch_time(DISPATCH_TIME_NOW, kNodeCacheFlushDelay * NSEC_PER_SEC),
                            DISPATCH_TIME_FOREVER, kNodeCacheFlushLeeway * NSEC_PER_SEC);
  dispatch_activate(flushTimer);
  return nodeCache;
}

@interface ASDataController () {
  id<ASDataControllerLayoutDelegate> _layoutDelegate;

  NSInteger _nextSectionID;
  
  BOOL _itemCountsFromDataSourceAreValid;     // Main thread only.
  std::vector<NSInteger> _itemCountsFromDataSource;         // Main thread only.
  
  ASMainSerialQueue *_mainSerialQueue;

  dispatch_queue_t _editingTransactionQueue;  // Serial background queue.  Dispatches concurrent layout and manages _editingNodes.
  dispatch_group_t _editingTransactionGroup;  // Group of all edit transaction blocks. Useful for waiting.
  std::atomic<int> _editingTransactionGroupCount;
  
  BOOL _initialReloadDataHasBeenCalled;

  BOOL _synchronized;
  NSMutableSet<ASDataControllerSynchronizationBlock> *_onDidFinishSynchronizingBlocks;

  struct {
    unsigned int supplementaryNodeKindsInSections:1;
    unsigned int supplementaryNodesOfKindInSection:1;
    unsigned int supplementaryNodeBlockOfKindAtIndexPath:1;
    unsigned int constrainedSizeForNodeAtIndexPath:1;
    unsigned int constrainedSizeForSupplementaryNodeOfKindAtIndexPath:1;
    unsigned int contextForSection:1;
  } _dataSourceFlags;
}

@property (copy) ASElementMap *pendingMap;
@property (copy) ASElementMap *visibleMap;
@end

@implementation ASDataController

#pragma mark - Lifecycle

- (instancetype)initWithDataSource:(id<ASDataControllerSource>)dataSource node:(nullable id<ASRangeManagingNode>)node
{
  if (!(self = [super init])) {
    return nil;
  }
  
  _node = node;
  _dataSource = dataSource;
  
  _dataSourceFlags.supplementaryNodeKindsInSections = [dataSource respondsToSelector:@selector(dataController:supplementaryNodeKindsInSections:)];
  _dataSourceFlags.supplementaryNodesOfKindInSection = [dataSource respondsToSelector:@selector(dataController:supplementaryNodesOfKind:inSection:)];
  _dataSourceFlags.supplementaryNodeBlockOfKindAtIndexPath = [dataSource respondsToSelector:@selector(dataController:supplementaryNodeBlockOfKind:atIndexPath:shouldAsyncLayout:)];
  _dataSourceFlags.constrainedSizeForNodeAtIndexPath = [dataSource respondsToSelector:@selector(dataController:constrainedSizeForNodeAtIndexPath:)];
  _dataSourceFlags.constrainedSizeForSupplementaryNodeOfKindAtIndexPath = [dataSource respondsToSelector:@selector(dataController:constrainedSizeForSupplementaryNodeOfKind:atIndexPath:)];
  _dataSourceFlags.contextForSection = [dataSource respondsToSelector:@selector(dataController:contextForSection:)];

  _visibleMap = _pendingMap = [[ASElementMap alloc] init];
  
  _nextSectionID = 0;
  
  _mainSerialQueue = [[ASMainSerialQueue alloc] init];

  _synchronized = YES;
  _onDidFinishSynchronizingBlocks = [[NSMutableSet alloc] init];

  dispatch_queue_attr_t queueAttributes = DISPATCH_QUEUE_SERIAL;
  if (AS_AVAILABLE_IOS_TVOS(10, 10)) {
    if (gEnableAutoreleasePoolInQueues) {
      queueAttributes = DISPATCH_QUEUE_SERIAL_WITH_AUTORELEASE_POOL;
    }
  }
  _editingTransactionQueue =
      dispatch_queue_create("org.TextureGroup.editingTransactionQueue", queueAttributes);
  _editingTransactionGroup = dispatch_group_create();
  
  return self;
}

- (id<ASDataControllerLayoutDelegate>)layoutDelegate
{
  ASDisplayNodeAssertMainThread();
  return _layoutDelegate;
}

- (void)setLayoutDelegate:(id<ASDataControllerLayoutDelegate>)layoutDelegate
{
  ASDisplayNodeAssertMainThread();
  if (layoutDelegate != _layoutDelegate) {
    _layoutDelegate = layoutDelegate;
  }
}

#pragma mark - Cell Layout

/**
 * Allocates and layouts nodes from the given collection elements, and blocks the current thread while doing so.
 *
 * @param elements The elements from which nodes can be allocated and laid out.
 * @param strictlyOnCurrentThread Whether or not all the work must be done strictly on the current thread.
 * YES means all nodes will be allocated and laid out serially on the current thread.
 * NO means the work can be offloaded to other thread(s), potentially reduce the blocking time on the calling thread.
 */
- (void)_allocateNodesFromElements:(NSArray<ASCollectionElement *> *)elements
           strictlyOnCurrentThread:(BOOL)strictlyOnCurrentThread
{
  ASAssertOnQueueIfIOS10(_editingTransactionQueue);
  
  NSUInteger nodeCount = elements.count;
  __weak id<ASDataControllerSource> weakDataSource = _dataSource;
  if (nodeCount == 0 || weakDataSource == nil) {
    return;
  }

  ASSignpostStart(DataControllerBatch, self, "%@", ASObjectDescriptionMakeTiny(weakDataSource));

  {
    as_activity_create_for_scope("Data controller batch");
    BOOL immediatelyApplyComputedLayouts = _immediatelyApplyComputedLayouts;
    void(^work)(size_t) = ^(size_t i) {
      __strong id<ASDataControllerSource> strongDataSource = weakDataSource;
      if (strongDataSource == nil) {
        return;
      }

      unowned ASCollectionElement *element = elements[i];

      NSMutableDictionary *dict = [[NSThread currentThread] threadDictionary];
      dict[ASThreadDictMaxConstraintSizeKey] =
          [NSValue valueWithCGSize:element.constrainedSize.max];
      unowned ASCellNode *node = element.node;
      [dict removeObjectForKey:ASThreadDictMaxConstraintSizeKey];

      // Layout the node if the size range is valid.
      ASSizeRange sizeRange = element.constrainedSize;
      if (ASSizeRangeHasSignificantArea(sizeRange)) {
        [self _layoutNode:node
            withConstrainedSize:sizeRange
               immediatelyApply:immediatelyApplyComputedLayouts];
      }
    };
    
    if (strictlyOnCurrentThread) {
      for (NSUInteger i = 0; i < nodeCount; i++) {
        work(i);
      }
    } else {
      dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0);
      NSUInteger threadCount = 0;
      if ([_dataSource dataControllerShouldSerializeNodeCreation:self]) {
        threadCount = 1;
      }
      ASDispatchApply(nodeCount, queue, threadCount, work);
    }
  }

  ASSignpostEnd(DataControllerBatch, self, "count: %lu", (unsigned long)nodeCount);
}

/**
 * Measure and layout the given node with the constrained size range.
 */
- (void)_layoutNode:(ASCellNode *)node
    withConstrainedSize:(ASSizeRange)constrainedSize
       immediatelyApply:(BOOL)immediatelyApply {
  // Note: Method may be called on main or background.
  if (![_dataSource dataController:self shouldEagerlyLayoutNode:node]) {
    return;
  }
  
  ASDisplayNodeAssert(ASSizeRangeHasSignificantArea(constrainedSize), @"Attempt to layout cell node with invalid size range %@", NSStringFromASSizeRange(constrainedSize));

  CGRect frame = CGRectZero;
  frame.size = [node measure:constrainedSize];
  node.frame = frame;

  /**
   * We need to hold the lock between checking if loaded and laying out. Unfortunately, __layout
   * expects to be called WITHOUT the lock held and in fact does not hold the lock during layout
   * i.e. it locks and then unlocks before calling deeper down to do its work. So there is an
   * unavoidable race condition here in theory, but in practice it's still worth experimenting with
   * because:
   * - If this is the first layout (after allocation) then the only way the view could get loaded
   * out from under us is if they, inside their node -init, dispatch_async to main and load the
   * view, which is bizarre.
   * - If this is a subsequent layout (say, rotation,) then we are being run synchronously
   * concurrently _from_ the main thread so the node can't be loaded out from under us.
   */
  if (immediatelyApply) {
    if (!node.nodeLoaded) {
      [node __layout];
    }
  }
}

#pragma mark - Data Source Access (Calling _dataSource)

- (NSArray<NSIndexPath *> *)_allIndexPathsForItemsOfKind:(NSString *)kind inSections:(NSIndexSet *)sections
{
  ASDisplayNodeAssertMainThread();
  
  if (sections.count == 0 || _dataSource == nil) {
    return @[];
  }
  
  const auto indexPaths = [[NSMutableArray<NSIndexPath *> alloc] init];
  if ([kind isEqualToString:ASDataControllerRowNodeKind]) {
    std::vector<NSInteger> counts = [self itemCountsFromDataSource];
    [sections enumerateRangesUsingBlock:^(NSRange range, BOOL * _Nonnull stop) {
      for (NSUInteger sectionIndex = range.location; sectionIndex < NSMaxRange(range); sectionIndex++) {
        NSUInteger itemCount = counts[sectionIndex];
        for (NSUInteger i = 0; i < itemCount; i++) {
          [indexPaths addObject:[NSIndexPath indexPathForItem:i inSection:sectionIndex]];
        }
      }
    }];
  } else if (_dataSourceFlags.supplementaryNodesOfKindInSection) {
    id<ASDataControllerSource> dataSource = _dataSource;
    [sections enumerateRangesUsingBlock:^(NSRange range, BOOL * _Nonnull stop) {
      for (NSUInteger sectionIndex = range.location; sectionIndex < NSMaxRange(range); sectionIndex++) {
        NSUInteger itemCount = [dataSource dataController:self supplementaryNodesOfKind:kind inSection:sectionIndex];
        for (NSUInteger i = 0; i < itemCount; i++) {
          [indexPaths addObject:[NSIndexPath indexPathForItem:i inSection:sectionIndex]];
        }
      }
    }];
  }
  
  return indexPaths;
}

/**
 * Agressively repopulates supplementary nodes of all kinds for sections that contains some given index paths.
 *
 * @param map The element map into which to apply the change.
 * @param indexPaths The index paths belongs to sections whose supplementary nodes need to be repopulated.
 * @param changeSet The changeset that triggered this repopulation.
 * @param traitCollection The trait collection needed to initialize elements
 * @param indexPathsAreNew YES if index paths are "after the update," NO otherwise.
 * @param shouldFetchSizeRanges Whether constrained sizes should be fetched from data source
 */
- (void)_repopulateSupplementaryNodesIntoMap:(ASMutableElementMap *)map
             forSectionsContainingIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
                                   changeSet:(_ASHierarchyChangeSet *)changeSet
                             traitCollection:(ASPrimitiveTraitCollection)traitCollection
                            indexPathsAreNew:(BOOL)indexPathsAreNew
                       shouldFetchSizeRanges:(BOOL)shouldFetchSizeRanges
{
  ASDisplayNodeAssertMainThread();

  if (indexPaths.count ==  0) {
    return;
  }

  // Remove all old supplementaries from these sections
  NSIndexSet *oldSections = [NSIndexSet as_sectionsFromIndexPaths:indexPaths];

  // Add in new ones with the new kinds.
  NSIndexSet *newSections;
  if (indexPathsAreNew) {
    newSections = oldSections;
  } else {
    newSections = [oldSections as_indexesByMapping:^NSUInteger(NSUInteger oldSection) {
      return [changeSet newSectionForOldSection:oldSection];
    }];
  }

  for (NSString *kind in [self supplementaryKindsInSections:newSections]) {
    [self _insertElementsIntoMap:map kind:kind forSections:newSections traitCollection:traitCollection shouldFetchSizeRanges:shouldFetchSizeRanges changeSet:changeSet];
  }
}

/**
 * Update supplementary nodes of all kinds for sections.
 *
 * @param map The element map into which to apply the change.
 * @param traitCollection The trait collection needed to initialize elements
 * @param shouldFetchSizeRanges Whether constrained sizes should be fetched from data source
 */
- (void)_updateSupplementaryNodesIntoMap:(ASMutableElementMap *)map
                         traitCollection:(ASPrimitiveTraitCollection)traitCollection
                   shouldFetchSizeRanges:(BOOL)shouldFetchSizeRanges
{
  ASDisplayNodeAssertMainThread();
  if (self.layoutDelegate != nil) {
    // TODO: https://github.com/TextureGroup/Texture/issues/948
    return;
  }
  NSUInteger sectionCount = [self itemCountsFromDataSource].size();
  if (sectionCount > 0) {
    NSIndexSet *sectionIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, sectionCount)];
    ASSizeRange newSizeRange = ASSizeRangeZero;
    for (NSString *kind in [self supplementaryKindsInSections:sectionIndexes]) {
      NSArray<NSIndexPath *> *indexPaths = [self _allIndexPathsForItemsOfKind:kind inSections:sectionIndexes];
      NSMutableArray<NSIndexPath *> *indexPathsToDeleteForKind = [[NSMutableArray alloc] init];
      NSMutableArray<NSIndexPath *> *indexPathsToInsertForKind = [[NSMutableArray alloc] init];
      // If supplementary node does exist and size is now zero, remove it.
      // If supplementary node doesn't exist and size is now non-zero, insert one.
      for (NSIndexPath *indexPath in indexPaths) {
        ASCollectionElement *previousElement = [_pendingMap supplementaryElementOfKind:kind atIndexPath:indexPath];
        newSizeRange = [self constrainedSizeForNodeOfKind:kind atIndexPath:indexPath];
        BOOL sizeRangeIsZero = ASSizeRangeEqualToSizeRange(ASSizeRangeZero, newSizeRange);
        if (previousElement != nil && sizeRangeIsZero) {
          [indexPathsToDeleteForKind addObject:indexPath];
        } else if (previousElement == nil && !sizeRangeIsZero) {
          [indexPathsToInsertForKind addObject:indexPath];
        }
      }

      [map removeSupplementaryElementsAtIndexPaths:indexPathsToDeleteForKind kind:kind];
      [self _insertElementsIntoMap:map kind:kind atIndexPaths:indexPathsToInsertForKind traitCollection:traitCollection shouldFetchSizeRanges:shouldFetchSizeRanges changeSet:nil];
    }
  }
}

/**
 * Inserts new elements of a certain kind for some sections
 *
 * @param kind The kind of the elements, e.g ASDataControllerRowNodeKind
 * @param sections The sections that should be populated by new elements
 * @param traitCollection The trait collection needed to initialize elements
 * @param shouldFetchSizeRanges Whether constrained sizes should be fetched from data source
 */
- (void)_insertElementsIntoMap:(ASMutableElementMap *)map
                          kind:(NSString *)kind
                   forSections:(NSIndexSet *)sections
               traitCollection:(ASPrimitiveTraitCollection)traitCollection
         shouldFetchSizeRanges:(BOOL)shouldFetchSizeRanges
                     changeSet:(_ASHierarchyChangeSet *)changeSet
{
  ASDisplayNodeAssertMainThread();
  
  if (sections.count == 0 || _dataSource == nil) {
    return;
  }
  
  NSArray<NSIndexPath *> *indexPaths = [self _allIndexPathsForItemsOfKind:kind inSections:sections];
  [self _insertElementsIntoMap:map kind:kind atIndexPaths:indexPaths traitCollection:traitCollection shouldFetchSizeRanges:shouldFetchSizeRanges changeSet:changeSet];
}

/**
 * Inserts new elements of a certain kind at some index paths
 *
 * @param map The map to insert the elements into.
 * @param kind The kind of the elements, e.g ASDataControllerRowNodeKind
 * @param indexPaths The index paths at which new elements should be populated
 * @param traitCollection The trait collection needed to initialize elements
 * @param shouldFetchSizeRanges Whether constrained sizes should be fetched from data source
 */
- (void)_insertElementsIntoMap:(ASMutableElementMap *)map
                          kind:(NSString *)kind
                  atIndexPaths:(NSArray<NSIndexPath *> *)indexPaths
               traitCollection:(ASPrimitiveTraitCollection)traitCollection
         shouldFetchSizeRanges:(BOOL)shouldFetchSizeRanges
                     changeSet:(_ASHierarchyChangeSet *)changeSet
{
  ASDisplayNodeAssertMainThread();
  
  if (indexPaths.count == 0 || _dataSource == nil) {
    return;
  }
  
  BOOL isRowKind = [kind isEqualToString:ASDataControllerRowNodeKind];
  if (!isRowKind && !_dataSourceFlags.supplementaryNodeBlockOfKindAtIndexPath) {
    // Populating supplementary elements but data source doesn't support.
    return;
  }
  
  LOG(@"Populating elements of kind: %@, for index paths: %@", kind, indexPaths);
  id<ASDataControllerSource> dataSource = self.dataSource;
  id<ASRangeManagingNode> node = self.node;
  BOOL shouldAsyncLayout = YES;
  NSCache<id, ASCellNode *> *nodeCache = _useNodeCache ? NodeCache() : nil;
  for (NSIndexPath *indexPath in indexPaths) {
    ASCellNodeBlock nodeBlock;
    id nodeModel;
    if (isRowKind) {
      nodeModel = [dataSource dataController:self nodeModelForItemAtIndexPath:indexPath];
      // Attempt to use node cache.
      if (nodeModel && nodeCache) {
        if (ASCellNode *node = [nodeCache objectForKey:nodeModel]) {
          if ([node canUpdateToNodeModel:nodeModel]) {
            [nodeCache removeObjectForKey:nodeModel];
            nodeBlock = ^{
              return node;
            };
          }
        }
      }
      // Get the prior element and attempt to update the existing cell node.
      if (!nodeBlock && nodeModel != nil && !changeSet.includesReloadData) {
        NSIndexPath *oldIndexPath = [changeSet oldIndexPathForNewIndexPath:indexPath];
        if (oldIndexPath != nil) {
          ASCollectionElement *oldElement = [_pendingMap elementForItemAtIndexPath:oldIndexPath];
          ASCellNode *oldNode = oldElement.node;
          if ([oldNode canUpdateToNodeModel:nodeModel]) {
            // Just wrap the node in a block. The collection element will -setNodeModel:
            nodeBlock = ^{
              return oldNode;
            };
          }
        }
      }
      if (nodeBlock == nil) {
        nodeBlock = [dataSource dataController:self nodeBlockAtIndexPath:indexPath shouldAsyncLayout:&shouldAsyncLayout];
      }
    } else {
      nodeBlock = [dataSource dataController:self supplementaryNodeBlockOfKind:kind atIndexPath:indexPath shouldAsyncLayout:&shouldAsyncLayout];
    }

    ASSizeRange constrainedSize = ASSizeRangeUnconstrained;
    if (shouldFetchSizeRanges) {
      constrainedSize = [self constrainedSizeForNodeOfKind:kind atIndexPath:indexPath];
    }
    
    ASCollectionElement *element = [[ASCollectionElement alloc] initWithNodeModel:nodeModel
                                                                        nodeBlock:nodeBlock
                                                         supplementaryElementKind:isRowKind ? nil : kind
                                                                  constrainedSize:constrainedSize
                                                                       owningNode:node
                                                                  traitCollection:traitCollection];
    [map insertElement:element atIndexPath:indexPath];
    if (shouldAsyncLayout) {
      [changeSet incrementCountForAsyncLayout];
    }
  }
}

- (void)invalidateDataSourceItemCounts
{
  ASDisplayNodeAssertMainThread();
  _itemCountsFromDataSourceAreValid = NO;
}

- (std::vector<NSInteger>)itemCountsFromDataSource
{
  ASDisplayNodeAssertMainThread();
  if (NO == _itemCountsFromDataSourceAreValid) {
    id<ASDataControllerSource> source = self.dataSource;
    NSInteger sectionCount = [source numberOfSectionsInDataController:self];
    std::vector<NSInteger> newCounts;
    newCounts.reserve(sectionCount);
    for (NSInteger i = 0; i < sectionCount; i++) {
      newCounts.push_back([source dataController:self rowsInSection:i]);
    }
    _itemCountsFromDataSource = newCounts;
    _itemCountsFromDataSourceAreValid = YES;
  }
  return _itemCountsFromDataSource;
}

- (NSArray<NSString *> *)supplementaryKindsInSections:(NSIndexSet *)sections
{
  if (_dataSourceFlags.supplementaryNodeKindsInSections) {
    return [_dataSource dataController:self supplementaryNodeKindsInSections:sections];
  }
  
  return @[];
}

/**
 * Returns constrained size for the node of the given kind and at the given index path.
 * NOTE: index path must be in the data-source index space.
 */
- (ASSizeRange)constrainedSizeForNodeOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
  ASDisplayNodeAssertMainThread();
  
  id<ASDataControllerSource> dataSource = _dataSource;
  if (dataSource == nil || indexPath == nil) {
    return ASSizeRangeZero;
  }
  
  if ([kind isEqualToString:ASDataControllerRowNodeKind]) {
    ASDisplayNodeAssert(_dataSourceFlags.constrainedSizeForNodeAtIndexPath, @"-dataController:constrainedSizeForNodeAtIndexPath: must also be implemented");
    return [dataSource dataController:self constrainedSizeForNodeAtIndexPath:indexPath];
  }
  
  if (_dataSourceFlags.constrainedSizeForSupplementaryNodeOfKindAtIndexPath){
    return [dataSource dataController:self constrainedSizeForSupplementaryNodeOfKind:kind atIndexPath:indexPath];
  }
  
  ASDisplayNodeAssert(NO, @"Unknown constrained size for node of kind %@ by data source %@", kind, dataSource);
  return ASSizeRangeZero;
}

#pragma mark - Batching (External API)

- (void)waitUntilAllUpdatesAreProcessed
{
  // Schedule block in main serial queue to wait until all operations are finished that are
  // where scheduled while waiting for the _editingTransactionQueue to finish
  [self _scheduleBlockOnMainSerialQueue:^{ }];
}

- (BOOL)isProcessingUpdates
{
  ASDisplayNodeAssertMainThread();
  BOOL doneEditing = !dispatch_group_wait(_editingTransactionGroup, DISPATCH_TIME_NOW);
  return !doneEditing || _mainSerialQueue.numberOfScheduledBlocks > 0;
}

- (void)onDidFinishProcessingUpdates:(void (^)())completion
{
  ASDisplayNodeAssertMainThread();
  if (!completion) {
    return;
  }
  if ([self isProcessingUpdates] == NO) {
    ASPerformBlockOnMainThread(completion);
  } else {
    dispatch_async(_editingTransactionQueue, ^{
      // Retry the block. If we're done processing updates, it'll run immediately, otherwise
      // wait again for updates to quiesce completely.
      // Don't use _mainSerialQueue so that we don't affect -isProcessingUpdates.
      dispatch_async(dispatch_get_main_queue(), ^{
        [self onDidFinishProcessingUpdates:completion];
      });
    });
  }
}

- (BOOL)isSynchronized {
  return _synchronized;
}

- (void)onDidFinishSynchronizing:(void (^)())completion {
  ASDisplayNodeAssertMainThread();
  if (!completion) {
    return;
  }
  if ([self isSynchronized]) {
    ASPerformBlockOnMainThread(completion);
  } else {
    // Hang on to the completion block so that it gets called the next time view is synchronized to data.
    [_onDidFinishSynchronizingBlocks addObject:[completion copy]];
  }
}

- (void)updateWithChangeSet:(_ASHierarchyChangeSet *)changeSet
{
  ASDisplayNodeAssertMainThread();

  _synchronized = NO;
  ASSignpostStart(DataControllerUpdate, self, "%@ %@ %@",
                  ASObjectDescriptionMakeTiny(self.dataSource),
                  NSStringFromCGRect([self.dataSource dataControllerFrameForDebugging:self]),
                  changeSet);
  [changeSet addCompletionHandler:^(BOOL finished) {
    self->_synchronized = YES;
    ASSignpostEnd(DataControllerUpdate, self, "");
    [self onDidFinishProcessingUpdates:^{
      if (self->_synchronized) {
        for (ASDataControllerSynchronizationBlock block in self->_onDidFinishSynchronizingBlocks) {
          block();
        }
        [self->_onDidFinishSynchronizingBlocks removeAllObjects];
      }
    }];
  }];

  if (changeSet.includesReloadData) {
    if (_initialReloadDataHasBeenCalled) {
      os_log_debug(ASCollectionLog(), "reloadData %@", ASViewToDisplayNode(ASDynamicCast(self.dataSource, UIView)));
    } else {
      os_log_debug(ASCollectionLog(), "Initial reloadData %@", ASViewToDisplayNode(ASDynamicCast(self.dataSource, UIView)));
      _initialReloadDataHasBeenCalled = YES;
    }
  } else {
    os_log_debug(ASCollectionLog(), "performBatchUpdates %@ %@", ASViewToDisplayNode(ASDynamicCast(self.dataSource, UIView)), changeSet);
  }

  if (!ASActivateExperimentalFeature(ASExperimentalOptimizeDataControllerPipeline)) {
    NSTimeInterval transactionQueueFlushDuration = 0.0f;
    {
      AS::ScopeTimer t(transactionQueueFlushDuration);
      [self _drainEditingQueue];
    }
  }

  // If the initial reloadData has not been called, just bail because we don't have our old data source counts.
  // See ASUICollectionViewTests.testThatIssuingAnUpdateBeforeInitialReloadIsUnacceptable
  // for the issue that UICollectionView has that we're choosing to workaround.
  if (!_initialReloadDataHasBeenCalled) {
    os_log_debug(ASCollectionLog(), "%@ Skipped update because load hasn't happened.", ASObjectDescriptionMakeTiny(_dataSource));
    [changeSet executeCompletionHandlerWithFinished:YES];
    return;
  }
  
  [self invalidateDataSourceItemCounts];
  
  // Attempt to mark the update completed. This is when update validation will occur inside the changeset.
  // If an invalid update exception is thrown, we catch it and inject our "validationErrorSource" object,
  // which is the table/collection node's data source, into the exception reason to help debugging.
  @try {
    [changeSet markCompletedWithNewItemCounts:[self itemCountsFromDataSource]];
  } @catch (NSException *e) {
    id responsibleDataSource = self.validationErrorSource;
    if (e.name == ASCollectionInvalidUpdateException && responsibleDataSource != nil) {
      [NSException raise:ASCollectionInvalidUpdateException format:@"%@: %@", [responsibleDataSource class], e.reason];
    } else {
      @throw e;
    }
  }

  /// Take all deleted nodes and put them in the cache for potential reuse.
  if (_useNodeCache) {
    NSCache<id, ASCellNode *> *cache = NodeCache();
    for (const auto &indexPath : changeSet.indexPathsForRemovedItems) {
      ASCollectionElement *element = [_pendingMap elementForItemAtIndexPath:indexPath];
      if (id model = element.nodeModel) {
        if (ASCellNode *node = element.nodeIfAllocated) {
          [cache setObject:node forKey:model];
        }
      }
    }
  }

  BOOL canDelegate = (self.layoutDelegate != nil);
  ASElementMap *newMap;
  ASCollectionLayoutContext *layoutContext;
  {
    as_activity_scope(as_activity_create("Latch new data for collection update", changeSet.rootActivity, OS_ACTIVITY_FLAG_DEFAULT));

    // Step 1: Populate a new map that reflects the data source's state and use it as pendingMap
    if (changeSet.isEmpty) {
      // If the change set is empty, nothing has changed so we can just reuse the previous map
      newMap = _pendingMap;
    } else {
      // Mutable copy of current data.
      ASMutableElementMap *mutableMap = [_pendingMap mutableCopy];

      // Step 1.1: Update the mutable copies to match the data source's state
      [self _updateSectionsInMap:mutableMap changeSet:changeSet];
      ASPrimitiveTraitCollection existingTraitCollection = [self.node primitiveTraitCollection];
      [self _updateElementsInMap:mutableMap changeSet:changeSet traitCollection:existingTraitCollection shouldFetchSizeRanges:(! canDelegate)];

      // Step 1.2: Clone the new data
      newMap = [mutableMap copy];
    }
    self.pendingMap = newMap;

    // Step 2: Ask layout delegate for contexts
    if (canDelegate) {
      layoutContext = [self.layoutDelegate layoutContextWithElements:newMap];
    }

    changeSet.dataLatched = YES;
  }

  BOOL synchronous = [_dataSource dataController:self shouldSynchronouslyProcessChangeSet:changeSet];
  NSUInteger batchSize = _updateBatchSize;
  if (synchronous || changeSet.countForAsyncLayout < batchSize) {
    batchSize = 0;
  }
  if (batchSize > 0) {
    const std::vector<_ASHierarchyChangeSet *> segments = [changeSet divideIntoSegmentsOfMaximumSize:batchSize];
    // We need to form intermediary maps that will be committed at the end of each segment.
    // The last one is obvious – the end state of the entire update.
    // For the others, take the next one and remove all the content that is to be added in the next segment.
    std::vector<ASElementMap *> intermediaryMaps;
    intermediaryMaps.resize(segments.size(), nil);
    intermediaryMaps[segments.size() - 1] = newMap; // End of last segment = end of whole batch.
    ASMutableElementMap *mutableIntermediaryMap = [newMap mutableCopy];

    // Form the intermediary maps by walking backward from the end state, removing content added in
    // the subsequent segment. Ignore the last (it is the end state, and we set it above.)
    for (int i = (int)segments.size() - 2; i >= 0; i--) {
      [mutableIntermediaryMap removeContentAddedInChangeSet:segments[i + 1]];
      intermediaryMaps[i] = [mutableIntermediaryMap copy];
    }

    // Now fire off each segment, targeting each intermediary map we formed above.
    for (size_t i = 0; i < segments.size(); i++) {
      [self _scheduleUpdateWithChangeSet:segments[i] newMap:intermediaryMaps[i] context:layoutContext];
    }
  } else {
    [self _scheduleUpdateWithChangeSet:changeSet newMap:newMap context:layoutContext];
  }

  // We've now dispatched node allocation and layout to a concurrent background queue.
  // In some cases, it's advantageous to prevent the main thread from returning, to ensure the next
  // frame displayed to the user has the view updates in place. Doing this does slightly reduce
  // total latency, by donating the main thread's priority to the background threads. As such, the
  // two cases where it makes sense to block:
  // 1. There is very little work to be performed in the background (UIKit passthrough)
  // 2. There is a higher priority on display latency than smoothness, e.g. app startup.
  if (synchronous) {
    [self waitUntilAllUpdatesAreProcessed];
  }
}

- (void)_scheduleUpdateWithChangeSet:(_ASHierarchyChangeSet *)changeSet
                             newMap:(ASElementMap *)newMap
                            context:(ASCollectionLayoutContext *)layoutContext {
  ASDisplayNodeAssertMainThread();
  os_log_debug(ASCollectionLog(), "New content: %@", newMap.smallDescription);
  BOOL canDelegate = (self.layoutDelegate != nil);

  Class<ASDataControllerLayoutDelegate> layoutDelegateClass = [self.layoutDelegate class];

  // Step 3: Call the layout delegate if possible. Otherwise, allocate and layout all elements
  void (^step3)(BOOL) = ^(BOOL strictlyOnCurrentThread){
    __block __unused os_activity_scope_state_s preparationScope = {}; // unused if deployment target < iOS10
    as_activity_scope_enter(as_activity_create("Prepare nodes for collection update", AS_ACTIVITY_CURRENT, OS_ACTIVITY_FLAG_DEFAULT), &preparationScope);
    if (canDelegate) {
      // Don't pass strictlyOnCurrentThread to the layout delegate. Instead give it
      // total control over its threading behavior, as long as it blocks the
      // calling thread while preparing the layout (which is part of the API contract).
      [layoutDelegateClass calculateLayoutWithContext:layoutContext];
    } else {
      const auto elementsToProcess = [[NSMutableArray<ASCollectionElement *> alloc] init];
      for (ASCollectionElement *element in newMap) {
        ASCellNode *nodeIfAllocated = element.nodeIfAllocated;
        if (nodeIfAllocated.shouldUseUIKitCell) {
          // If the node exists and we know it is a passthrough cell, we know it will never have a .calculatedLayout.
          continue;
        } else if (CGSizeEqualToSize(nodeIfAllocated.calculatedSize, CGSizeZero)) {
          // If the node hasn't been allocated, or it doesn't have a valid layout, let's process it.
          [elementsToProcess addObject:element];
        }
      }
      [self _allocateNodesFromElements:elementsToProcess
               strictlyOnCurrentThread:strictlyOnCurrentThread];
    }
  };

  // Step 3 can be done on the main thread or on _editingTransactionQueue
  // depending on an experiment.
  BOOL mainThreadOnly = ASActivateExperimentalFeature(ASExperimentalMainThreadOnlyDataController);
  if (mainThreadOnly) {
    // In main-thread-only mode allocate and layout all nodes serially on the main thread.
    //
    // After this step, we'll still dispatch to _editingTransactionQueue only to schedule a block
    // to _mainSerialQueue to execute next steps. This is not optimized because
    // in theory we can skip _editingTransactionQueue entirely, but it's much safer
    // because change sets will still flow through the pipeline in pretty the same way
    // (main thread -> _editingTransactionQueue -> _mainSerialQueue) and so
    // any methods that block on _editingTransactionQueue will still work.
    step3(YES);
  }

  ++_editingTransactionGroupCount;
  dispatch_group_async(_editingTransactionGroup, _editingTransactionQueue, ^{
    __block __unused os_activity_scope_state_s preparationScope = {}; // unused if deployment target < iOS10
    as_activity_scope_enter(as_activity_create("Prepare nodes for collection update", AS_ACTIVITY_CURRENT, OS_ACTIVITY_FLAG_DEFAULT), &preparationScope);

    if (!mainThreadOnly) {
      step3(NO);
    }

    // Step 4: Inform the delegate on main thread
    [self->_mainSerialQueue performBlockOnMainThread:^{
      as_activity_scope_leave(&preparationScope);
      [self->_delegate dataController:self updateWithChangeSet:changeSet updates:^{
        // Step 5: Deploy the new data as "completed"
        //
        // Note that since the backing collection view might be busy responding to user events (e.g scrolling),
        // it will not consume the batch update blocks immediately.
        // As a result, in a short intermidate time, the view will still be relying on the old data source state.
        // Thus, we can't just swap the new map immediately before step 4, but until this update block is executed.
        // (https://github.com/TextureGroup/Texture/issues/378)
        self.visibleMap = newMap;
      }];
    }];
    --self->_editingTransactionGroupCount;
  });
}

/**
 * Update sections based on the given change set.
 */
- (void)_updateSectionsInMap:(ASMutableElementMap *)map changeSet:(_ASHierarchyChangeSet *)changeSet
{
  ASDisplayNodeAssertMainThread();
  
  if (changeSet.includesReloadData) {
    [map removeAllSections];
    
    NSUInteger sectionCount = [self itemCountsFromDataSource].size();
    NSIndexSet *sectionIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, sectionCount)];
    [self _insertSectionsIntoMap:map indexes:sectionIndexes];
    // Return immediately because reloadData can't be used in conjuntion with other updates.
    return;
  }
  
  for (_ASHierarchySectionChange *change in [changeSet sectionChangesOfType:_ASHierarchyChangeTypeDelete]) {
    [map removeSectionsAtIndexes:change.indexSet];
  }
  
  for (_ASHierarchySectionChange *change in [changeSet sectionChangesOfType:_ASHierarchyChangeTypeInsert]) {
    [self _insertSectionsIntoMap:map indexes:change.indexSet];
  }
}

- (void)_insertSectionsIntoMap:(ASMutableElementMap *)map indexes:(NSIndexSet *)sectionIndexes
{
  ASDisplayNodeAssertMainThread();

  [sectionIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
    id<ASSectionContext> context;
    if (_dataSourceFlags.contextForSection) {
      context = [_dataSource dataController:self contextForSection:idx];
    }
    ASSection *section = [[ASSection alloc] initWithSectionID:_nextSectionID context:context];
    [map insertSection:section atIndex:idx];
    _nextSectionID++;
  }];
}

/**
 * Update elements based on the given change set.
 */
- (void)_updateElementsInMap:(ASMutableElementMap *)map
                   changeSet:(_ASHierarchyChangeSet *)changeSet
             traitCollection:(ASPrimitiveTraitCollection)traitCollection
       shouldFetchSizeRanges:(BOOL)shouldFetchSizeRanges
{
  ASDisplayNodeAssertMainThread();

  if (changeSet.includesReloadData) {
    [map removeAllElements];
    
    NSUInteger sectionCount = [self itemCountsFromDataSource].size();
    if (sectionCount > 0) {
      NSIndexSet *sectionIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, sectionCount)];
      [self _insertElementsIntoMap:map sections:sectionIndexes traitCollection:traitCollection shouldFetchSizeRanges:shouldFetchSizeRanges changeSet:changeSet];
    }
    // Return immediately because reloadData can't be used in conjuntion with other updates.
    return;
  }
  
  // Migrate old supplementary nodes to their new index paths.
  [map migrateSupplementaryElementsWithSectionMapping:changeSet.sectionMapping];

  for (_ASHierarchyItemChange *change in [changeSet itemChangesOfType:_ASHierarchyChangeTypeDelete]) {
    [map removeItemsAtIndexPaths:change.indexPaths];
    // Aggressively repopulate supplementary nodes (#1773 & #1629)
    [self _repopulateSupplementaryNodesIntoMap:map forSectionsContainingIndexPaths:change.indexPaths
                                     changeSet:changeSet
                               traitCollection:traitCollection
                              indexPathsAreNew:NO
                         shouldFetchSizeRanges:shouldFetchSizeRanges];
  }

  for (_ASHierarchySectionChange *change in [changeSet sectionChangesOfType:_ASHierarchyChangeTypeDelete]) {
    NSIndexSet *sectionIndexes = change.indexSet;
    [map removeSectionsOfItems:sectionIndexes];
  }
  
  for (_ASHierarchySectionChange *change in [changeSet sectionChangesOfType:_ASHierarchyChangeTypeInsert]) {
    [self _insertElementsIntoMap:map sections:change.indexSet traitCollection:traitCollection shouldFetchSizeRanges:shouldFetchSizeRanges changeSet:changeSet];
  }
  
  for (_ASHierarchyItemChange *change in [changeSet itemChangesOfType:_ASHierarchyChangeTypeInsert]) {
    [self _insertElementsIntoMap:map kind:ASDataControllerRowNodeKind atIndexPaths:change.indexPaths traitCollection:traitCollection shouldFetchSizeRanges:shouldFetchSizeRanges changeSet:changeSet];
    // Aggressively reload supplementary nodes (#1773 & #1629)
    [self _repopulateSupplementaryNodesIntoMap:map forSectionsContainingIndexPaths:change.indexPaths
                                     changeSet:changeSet
                               traitCollection:traitCollection
                              indexPathsAreNew:YES
                         shouldFetchSizeRanges:shouldFetchSizeRanges];
  }
}

- (void)_insertElementsIntoMap:(ASMutableElementMap *)map
                      sections:(NSIndexSet *)sectionIndexes
               traitCollection:(ASPrimitiveTraitCollection)traitCollection
         shouldFetchSizeRanges:(BOOL)shouldFetchSizeRanges
                     changeSet:(_ASHierarchyChangeSet *)changeSet
{
  ASDisplayNodeAssertMainThread();
  
  if (sectionIndexes.count == 0 || _dataSource == nil) {
    return;
  }

  // Items
  [map insertEmptySectionsOfItemsAtIndexes:sectionIndexes];
  [self _insertElementsIntoMap:map kind:ASDataControllerRowNodeKind forSections:sectionIndexes traitCollection:traitCollection shouldFetchSizeRanges:shouldFetchSizeRanges changeSet:changeSet];

  // Supplementaries
  for (NSString *kind in [self supplementaryKindsInSections:sectionIndexes]) {
    // Step 2: Populate new elements for all sections
    [self _insertElementsIntoMap:map kind:kind forSections:sectionIndexes traitCollection:traitCollection shouldFetchSizeRanges:shouldFetchSizeRanges changeSet:changeSet];
  }
}

#pragma mark - Relayout

- (void)relayoutNodes:(id<NSFastEnumeration>)nodes nodesSizeChanged:(NSMutableArray<ASCellNode *> *)nodesSizesChanged
{
  NSParameterAssert(nodes);
  NSParameterAssert(nodesSizesChanged);
  
  ASDisplayNodeAssertMainThread();
  if (!_initialReloadDataHasBeenCalled) {
    return;
  }
  
  id<ASDataControllerSource> dataSource = _dataSource;
  for (ASCellNode *node in nodes) {
    const auto element = node.collectionElement;
    NSIndexPath *indexPathInPendingMap = [_pendingMap indexPathForElement:element];
    // Ensure the element is present in both maps or skip it. If it's not in the visible map,
    // then we can't check the presented size. If it's not in the pending map, we can't get the constrained size.
    // This will only happen if the element has been deleted, so the specifics of this behavior aren't important.
    if (indexPathInPendingMap == nil || [_visibleMap indexPathForElement:element] == nil) {
      continue;
    }

    NSString *kind = element.supplementaryElementKind ?: ASDataControllerRowNodeKind;
    ASSizeRange constrainedSize = [self constrainedSizeForNodeOfKind:kind atIndexPath:indexPathInPendingMap];
    [self _layoutNode:node
        withConstrainedSize:constrainedSize
           immediatelyApply:self.immediatelyApplyComputedLayouts];

    BOOL matchesSize = [dataSource dataController:self presentedSizeForElement:element matchesSize:node.frame.size];
    if (! matchesSize) {
      [nodesSizesChanged addObject:node];
    }
  }
}

- (void)relayoutAllNodesWithInvalidationBlock:(nullable void (^)())invalidationBlock
{
  ASDisplayNodeAssertMainThread();
  if (!_initialReloadDataHasBeenCalled) {
    return;
  }
  
  // Can't relayout right away because _visibleMap may not be up-to-date,
  // i.e there might be some nodes that were measured using the old constrained size but haven't been added to _visibleMap
  LOG(@"Edit Command - relayoutRows");
  [self _scheduleBlockOnMainSerialQueue:^{
    // Because -invalidateLayout doesn't trigger any operations by itself, and we answer queries from UICollectionView using layoutThatFits:,
    // we invalidate the layout before we have updated all of the cells. Any cells that the collection needs the size of immediately will get
    // -layoutThatFits: with a new constraint, on the main thread, and synchronously calculate them. Meanwhile, relayoutAllNodes will update
    // the layout of any remaining nodes on background threads (and fast-return for any nodes that the UICV got to first).
    if (invalidationBlock) {
      invalidationBlock();
    }
    [self _relayoutAllNodes];
  }];
}

- (void)_relayoutAllNodes
{
  ASDisplayNodeAssertMainThread();
  // Aggressively repopulate all supplemtary elements
  // Assuming this method is run on the main serial queue, _pending and _visible maps are synced and can be manipulated directly.
  // TODO: If there is a layout delegate, it should be able to handle relayouts. Verify that and bail early.
  ASDisplayNodeAssert(_visibleMap == _pendingMap, @"Expected visible and pending maps to be synchronized: %@", self);
  ASSignpostStart(RemeasureCollection, self, "%@ %@ count: %d",
                  ASObjectDescriptionMakeTiny(self.dataSource),
                  NSStringFromCGRect([self.dataSource dataControllerFrameForDebugging:self]),
                  (int)_visibleMap.count);

  ASMutableElementMap *newMap = [_pendingMap mutableCopy];
  [self _updateSupplementaryNodesIntoMap:newMap
                         traitCollection:[self.node primitiveTraitCollection]
                   shouldFetchSizeRanges:YES];
  self.pendingMap = self.visibleMap = [newMap copy];

  // First update size constraints on the main thread.
  NSDictionary<ASCollectionElement *, NSIndexPath *> *elementToIndexPath =
      _visibleMap.elementToIndexPath;
  [elementToIndexPath
      enumerateKeysAndObjectsUsingBlock:^(ASCollectionElement *element, NSIndexPath *indexPath,
                                          __unused BOOL *stop) {
        element.constrainedSize =
            [self constrainedSizeForNodeOfKind:(element.supplementaryElementKind
                                                    ?: ASDataControllerRowNodeKind)
                                   atIndexPath:indexPath];
      }];

  // Then concurrently synchronously ensure every node is measured against new constraints.
  BOOL immediatelyApply = self.immediatelyApplyComputedLayouts;
  [elementToIndexPath
      enumerateKeysAndObjectsWithOptions:NSEnumerationConcurrent
                              usingBlock:^(ASCollectionElement *element, NSIndexPath *indexPath,
                                           __unused BOOL *stop) {
                                const ASSizeRange sizeRange = element.constrainedSize;
                                if (ASSizeRangeHasSignificantArea(sizeRange)) {
                                  if (ASCellNode *node = element.nodeIfAllocated) {
                                    [self _layoutNode:node
                                        withConstrainedSize:sizeRange
                                           immediatelyApply:immediatelyApply];
                                  }
                                }
                              }];
  ASSignpostEnd(RemeasureCollection, self, "");
}

# pragma mark - ASPrimitiveTraitCollection

- (void)environmentDidChange
{
  ASPerformBlockOnMainThread(^{
    if (!self->_initialReloadDataHasBeenCalled) {
      return;
    }

    // Can't update the trait collection right away because _visibleMap may not be up-to-date,
    // i.e there might be some elements that were allocated using the old trait collection but haven't been added to _visibleMap
    [self _scheduleBlockOnMainSerialQueue:^{
      ASPrimitiveTraitCollection newTraitCollection = [self.node primitiveTraitCollection];
      for (ASCollectionElement *element in self->_visibleMap) {
        element.traitCollection = newTraitCollection;
      }
    }];
  });
}

- (void)clearData
{
  ASDisplayNodeAssertMainThread();
  if (_initialReloadDataHasBeenCalled) {
    [self waitUntilAllUpdatesAreProcessed];
    // Always use the setters for these atomics, so that other threads get them safely.
    self.visibleMap = self.pendingMap = [[ASElementMap alloc] init];
  }
}

# pragma mark - Helper methods

- (void)_drainEditingQueue
{
  ASDisplayNodeAssertMainThread();
  if (gRemovePriorityInversion) {
    // dispatch_sync an empty block to the serial queue for the scheduler to resolve priority
    // inversion automatically. b/168618264
    dispatch_sync(_editingTransactionQueue, ^{});
  } else {
    dispatch_group_wait(_editingTransactionGroup, DISPATCH_TIME_FOREVER);
  }
}

- (void)_scheduleBlockOnMainSerialQueue:(dispatch_block_t)block
{
  ASDisplayNodeAssertMainThread();
  [self _drainEditingQueue];

  [_mainSerialQueue performBlockOnMainThread:block];
}

@end
