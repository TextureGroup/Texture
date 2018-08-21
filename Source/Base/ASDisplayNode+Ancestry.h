//
//  ASDisplayNode+Ancestry.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/ASDisplayNode.h>

NS_ASSUME_NONNULL_BEGIN

@interface ASDisplayNode (Ancestry)

/**
 * Returns an object to enumerate the supernode ancestry of this node, starting with its supernode.
 *
 * For instance, you could write:
 *   for (ASDisplayNode *node in self.supernodes) {
 *     if ([node.backgroundColor isEqual:[UIColor blueColor]]) {
 *       node.hidden = YES;
 *     }
 *   }
 *
 * Note: If this property is read on the main thread, the enumeration will attempt to go up
 *  the layer hierarchy if it finds a break in the display node hierarchy.
 */
@property (readonly) id<NSFastEnumeration> supernodes;

/**
 * Same as `supernodes` but begins the enumeration with self.
 */
@property (readonly) id<NSFastEnumeration> supernodesIncludingSelf;

/**
 * Searches the supernodes of this node for one matching the given class.
 *
 * @param supernodeClass The class of node you're looking for.
 * @param includeSelf Whether to include self in the search.
 * @return A node of the given class that is an ancestor of this node, or nil.
 *
 * @note See the documentation on `supernodes` for details about the upward traversal.
 */
- (nullable __kindof ASDisplayNode *)supernodeOfClass:(Class)supernodeClass includingSelf:(BOOL)includeSelf;

/**
 * e.g. "(<MYTextNode: 0xFFFF>, <MYTextContainingNode: 0xFFFF>, <MYCellNode: 0xFFFF>)"
 */
@property (copy, readonly) NSString *ancestryDescription;

@end

NS_ASSUME_NONNULL_END
