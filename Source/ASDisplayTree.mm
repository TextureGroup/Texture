//
//  ASDisplayTree.m
//  AsyncDisplayKit
//
//  Created by Adlai on 5/28/18.
//  Copyright © 2018 Pinterest. All rights reserved.
//

#import "ASDisplayTree.h"

#import <AsyncDisplayKit/ASDisplayNodeInternal.h>
#import <AsyncDisplayKit/ASThread.h>

using namespace ASDN;

/*
 * Assert we're locked. ASThread.h has some of the same logic, but it's not on
 * by default during debugging for performance reasons. Since this component is much
 * higher level, and also since it requires the client to lock it for enumerating,
 * this assertion is at the default level.
 */
#define ASDisplayTreeAssertLocked() //ASDisplayNodeAssert(_lockedThread == pthread_self(), nil)
#define ASDisplayTreeAssertNotLocked() //ASDisplayNodeAssert(_lockedThread != pthread_self(), nil)

@interface ASDisplayTree () <NSFastEnumeration>
@end

@implementation ASDisplayTree {
  ASDN::RecursiveMutex _lock;
#if ASDISPLAYNODE_ASSERTIONS_ENABLED
  pthread_key_t _lockSpecific;
#endif
  
  ASPrimitiveTraitCollection _traitCollection;
}

#pragma mark - Querying

- (NSUInteger)l_indexOf:(ASDisplayNode *)node
{
  NSParameterAssert(node);
  ASDisplayTreeAssertLocked();
  auto parent = [self supernodeOf:node];
  auto index = [[self l_mutableSubnodesOf:parent] indexOfObjectIdenticalTo:node];
  NSParameterAssert(index != NSNotFound); // Still a parameter assert b/c precondition fail.
  return index;
}

- (NSArray<ASDisplayNode *> *)copySubnodesOf:(ASDisplayNode *)node
{
  NSParameterAssert(node);
  ASLockScopeSelf();
  auto mNodes = [self l_mutableSubnodesOf:node];
  NSParameterAssert(mNodes != nil);
  return [mNodes copy];
}

- (ASDisplayNode *)supernodeOf:(ASDisplayNode *)node
{
  NSParameterAssert(node);
  ASLockScopeSelf();
  return node->_supernode;
}

#pragma mark - Mutating

- (void)insert:(ASDisplayNode *)node at:(ASTreeInsertionLocation)location relativeTo:(ASDisplayNode *)otherNode with:(NSInteger)indexArg
{
  NSParameterAssert(node);
  NSParameterAssert(otherNode);
  NSParameterAssert(node != otherNode);
  
  ASLockMany(3, self, node, otherNode);
  
  if (node->_supernode != nil || otherNode->_tree != self) {
    // Let them get away with this. Possibly a race condition.
    ASUnlockMany(3, self, node, otherNode);
    return;
  }
  
  // Save the node's old tree (so we can unlock it)
  // and push self down the subtree.
  auto previousTree = node->_tree;
  node->_tree = self;
  if (previousTree) {
    for (ASDisplayNode *subnode in [previousTree l_enumeratingDownwardFrom:node with:ASEnumerateSkipSelf]) {
      // Cannot lock subnode here or we risk deadlock.
      // Since we locked the subnode's current tree, the
      // node can't be removed from it in the middle of this method.
      // We MAY have to use an atomic accessor – need to think through that more.
      subnode->_tree = self;
    }
  }
  
  // Update subnodes array for the parent node (it's locked).
  ASDisplayNode *parent;
  auto index = [self l_resolveInsertionPointFor:location relativeTo:otherNode with:indexArg gettingParent:&parent];
  auto array = [self l_mutableSubnodesOf:parent];
  if (location == ASTreeInsertReplace) {
    array[index] = node;
    [self l_createTreeFor:otherNode];
  } else {
    [array insertObject:node atIndex:index];
  }
  
  ASUnlockMany(3, self, node, otherNode);
}

- (void)remove:(ASDisplayNode *)node
{
  ASLockMany(2, self, node);
  
  // If the node is a root node, or if it's part of some other
  // tree, then we have a race. Let it slide and ignore the call.
  if (node->_supernode == nil || node->_tree != self) {
    [self unlock];
    [node unlock];
    return;
  }
  
  auto index = [self l_indexOf:node];
  auto parent = [self supernodeOf:node];
  [[self l_mutableSubnodesOf:parent] removeObjectAtIndex:index];
  [self l_createTreeFor:node];
  [self unlock];
  [node unlock];
}

#pragma mark - Enumerating

- (id<NSFastEnumeration>)l_enumeratingSubnodesOf:(ASDisplayNode *)node
{
  ASDisplayTreeAssertLocked();
  return self;
}

- (id<NSFastEnumeration>)l_enumeratingUpwardFrom:(ASDisplayNode *)startNode
{
  ASDisplayTreeAssertLocked();
  return self;
}

- (id<NSFastEnumeration>)l_enumeratingDownwardFrom:(ASDisplayNode *)startNode with:(ASTreeEnumerationOptions)options
{
  ASDisplayTreeAssertLocked();
  return self;
}

- (id<NSFastEnumeration>)l_enumeratingUpwardFromParentOf:(ASDisplayNode *)startNode
{
  ASDisplayTreeAssertLocked();
  return self;
}

#pragma mark - Treewide data

- (ASPrimitiveTraitCollection)traitCollection
{
  return ASLockedSelf(_traitCollection);
}

- (void)setTraitCollection:(ASPrimitiveTraitCollection)traitCollection
{
  ASLockedSelf(_traitCollection = traitCollection);
}

#pragma mark - Internal

- (NSMutableArray *)l_mutableSubnodesOf:(ASDisplayNode *)node
{
  ASDisplayTreeAssertLocked();
  return node->_subnodes;
}

/*
 * Convert a relative insertion point to an absolute point and a parent node.
 */
- (NSInteger)l_resolveInsertionPointFor:(ASTreeInsertionLocation)location relativeTo:(ASDisplayNode *)otherNode with:(NSInteger)index gettingParent:(ASDisplayNode **)parentPtr
{
  ASDisplayTreeAssertLocked();
  NSParameterAssert(parentPtr);
  switch (location) {
    case ASTreeInsertAtIndex:
      *parentPtr = otherNode;
      return index;
    case ASTreeInsertAtEnd:
      *parentPtr = otherNode;
      return [self l_mutableSubnodesOf:otherNode].count;
    case ASTreeInsertAbove:
      *parentPtr = [self supernodeOf:otherNode];
      return [self l_indexOf:otherNode] + 1;
    case ASTreeInsertBelow:
    case ASTreeInsertReplace:
      *parentPtr = [self supernodeOf:otherNode];
      return [self l_indexOf:otherNode];
  }
}

- (void)l_createTreeFor:(ASDisplayNode *)detachedNode
{
  ASDisplayTreeAssertLocked();
}

#pragma mark - NSFastEnumeration

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id  _Nullable __unsafe_unretained [])buffer count:(NSUInteger)len
{
  ASDisplayTreeAssertLocked();
  return 0;
}

ASSynthesizeLockingMethodsWithMutex(_lock)

@end
