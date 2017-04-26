//
//  ASRangeManagedNode.h
//  AsyncDisplayKit
//
//  Created by Adlai Holler on 4/26/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/ASTraitCollection.h>

@class ASCellNode;

NS_ASSUME_NONNULL_BEGIN

/**
 * Basically ASTableNode or ASCollectionNode.
 */
@protocol ASRangeManagedNode <NSObject, ASTraitEnvironment>

/**
 * Retrieve the index path for the given node, if it's a member of this container.
 *
 * @param node The node.
 * @return The index path, or nil if the node is not part of this container.
 */
- (nullable NSIndexPath *)indexPathForNode:(ASCellNode *)node;

@end

NS_ASSUME_NONNULL_END
