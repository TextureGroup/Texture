//
//  TECellNode.h
//  Sample
//
//  Created by Adlai Holler on 9/21/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>

#import "ui_collection_generated.h"

NS_ASSUME_NONNULL_BEGIN

@interface TECellNode : ASDisplayNode

- (void)setItem:(const Item &)item;

@end

NS_ASSUME_NONNULL_END
