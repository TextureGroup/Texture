//
//  ASYogaLayoutSpec.h
//  AsyncDisplayKit
//
//  Created by Scott Goodson on 5/6/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import <AsyncDisplayKit/ASAvailability.h>

#if !YOGA_TREE_CONTIGUOUS /* !YOGA_TREE_CONTIGUOUS */

#import <AsyncDisplayKit/ASDisplayNode.h>
#import <AsyncDisplayKit/ASLayoutSpec.h>

@interface ASYogaLayoutSpec : ASLayoutSpec
@property (nonatomic, strong, nonnull) ASDisplayNode *rootNode;
@property (nonatomic, strong, nullable) NSArray<ASDisplayNode *> *yogaChildren;
@end

#endif /* !YOGA_TREE_CONTIGUOUS */
