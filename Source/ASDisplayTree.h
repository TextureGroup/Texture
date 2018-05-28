//
//  ASDisplayTree.h
//  AsyncDisplayKit
//
//  Created by Adlai on 5/28/18.
//  Copyright © 2018 Pinterest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/ASBaseDefines.h>
#import <AsyncDisplayKit/ASLocking.h>
#import <AsyncDisplayKit/ASTraitCollection.h>

@class ASDisplayNode;

typedef NS_OPTIONS(NSUInteger, ASTreeEnumerationOptions) {
  ASEnumerateBreadthFirst  = 1 << 0,  // Default is depth-first.
  ASEnumerateSkipSelf   = 1 << 1,     // Default is to include self.
};

typedef NS_ENUM(NSInteger, ASTreeInsertionLocation) {
  ASTreeInsertBelow,      // Other node is sibling above. Index ignored.
  ASTreeInsertReplace,    // Other node is replaced. Index ignored.
  ASTreeInsertAbove,      // Other node is sibling below. Index ignored.
  ASTreeInsertAtEnd,      // Other node is parent. Index ignored.
  ASTreeInsertAtIndex     // Other node is parent.
};

NS_ASSUME_NONNULL_BEGIN

/*
 * An entire tree of display nodes. Subtrees are not
 * represented by these objects.
 *
 * When a node is added to a tree, the tree object
 * is pushed down to it from its new parent.
 *
 * Trees use a recursive lock to ensure safe access
 * from multiple threads simultaneously.
 *
 * Trees do not own their nodes. The root node is responsible
 * for owning the tree.
 */
AS_SUBCLASSING_RESTRICTED
@interface ASDisplayTree : NSObject <ASLocking>

#pragma mark - Querying

/*
 * Copy the direct subnodes of the given node.
 * Consider using @p enumerateSubnodesOf: @c instead.
 */
- (NSArray<ASDisplayNode *> *)copySubnodesOf:(ASDisplayNode *)node;

/*
 * Get the supernode for the given node. nil if we're at root.
 */
- (nullable ASDisplayNode *)supernodeOf:(ASDisplayNode *)node;

#pragma mark - Mutating

/*
 * Insert the given node's tree into the receiver, at the given index.
 *
 * @param node The new node to add. It must be a root node.
 * @param location The location option for the insert.
 * @param otherNode The other node to position this node. See ASTreeInsertionLocation.
 * @param index The absolute index, if ASTreeInsertAtIndex is specified. Ignored otherwise, pass NSNotFound.
 */
- (void)insert:(ASDisplayNode *)node
            at:(ASTreeInsertionLocation)location
    relativeTo:(ASDisplayNode *)otherNode
          with:(NSInteger)index;

/*
 * Remove the given node.
 */
- (void)remove:(ASDisplayNode *)node;

/*
 * Note about enumerating: you must hold the lock for the tree throughout enumeration.
 *
 * These methods actually configure the receiver and then return `self`.
 */
#pragma mark - Enumerating

/*
 * Hold the lock.
 */
- (id<NSFastEnumeration>)l_enumeratingSubnodesOf:(ASDisplayNode *)node;

/*
 * Hold the lock.
 */
- (id<NSFastEnumeration>)l_enumeratingUpwardFrom:(ASDisplayNode *)startNode;

/*
 * Hold the lock.
 */
- (id<NSFastEnumeration>)l_enumeratingUpwardFromParentOf:(ASDisplayNode *)startNode;

/*
 * Hold the lock.
 */
- (id<NSFastEnumeration>)l_enumeratingDownwardFrom:(ASDisplayNode *)startNode with:(ASTreeEnumerationOptions)options;

#pragma mark - Tree-wide data

@property ASPrimitiveTraitCollection traitCollection;

@end

NS_ASSUME_NONNULL_END
