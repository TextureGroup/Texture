//
//  UIViewController+TEActions.h
//  Sample
//
//  Created by Adlai Holler on 9/21/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

static SEL const TEActionShowMenu = sel_getUid("showActionsMenu:");
static SEL const TEActionPushNewInstance = sel_getUid("pushNewInstance:");

@interface UIResponder (TEActions)
- (void)showActionsMenu:(id)sender;
- (nullable NSArray<NSString *> *)actionsForMenu;
@end

@interface UIViewController (TEActions)

- (void)pushNewInstance:(id)sender;

@end

NS_ASSUME_NONNULL_END
