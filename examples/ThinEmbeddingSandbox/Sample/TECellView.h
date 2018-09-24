//
//  TECellView.h
//  Sample
//
//  Created by Adlai Holler on 9/21/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ui_collection_generated.h"
#include <memory>

NS_ASSUME_NONNULL_BEGIN

@class TEModel;

@interface TECellView : UIView

- (void)setItem:(const Item &)item;

+ (TECellView *)hostInContentViewIfNeeded:(UIView *)contentView;

+ (CGSize)sizeForItem:(const Item &)item inContainer:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
