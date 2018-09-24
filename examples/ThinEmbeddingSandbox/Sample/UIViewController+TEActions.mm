//
//  UIViewController+TEActions.m
//  Sample
//
//  Created by Adlai Holler on 9/21/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "UIViewController+TEActions.h"

@implementation UIResponder (TEActions)

- (void)showActionsMenu:(id)sender {
  auto actionLists = [[NSMutableArray<NSArray<NSString *> *> alloc] init];
  auto responders = [[NSMutableArray<UIResponder *> alloc] init];
  UINavigationController *navCtrl;
  
  __unsafe_unretained UIResponder *responder = self;
  while (responder) {
    auto actions = [responder actionsForMenu];
    if (actions.count > 0) {
      [actionLists addObject:actions];
      [responders addObject:responder];
    }
    if (!navCtrl && [responder isKindOfClass:[UINavigationController class]]) {
      navCtrl = (UINavigationController *)responder;
    }
    responder = [responder nextResponder];
  }
  // Found no actions anywhere in responder chain.
  if (!actionLists.count) {
    return;
  }
  
  UIAlertController *ac = [UIAlertController alertControllerWithTitle:@"Actions" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
  for (int i = 0; i < actionLists.count; i++) {
    NSString *headerTitle = [NSString stringWithFormat:@"-- %@ --", responders[i].class];
    auto headerAction = [UIAlertAction actionWithTitle:headerTitle style:UIAlertActionStyleDefault handler:nil];
    headerAction.enabled = NO;
    [ac addAction:headerAction];
    
    for (int j = 0; j < actionLists[i].count; j++) {
      NSString *title = actionLists[i][j];
      auto action = [UIAlertAction actionWithTitle:title style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [UIApplication.sharedApplication sendAction:NSSelectorFromString(title) to:responders[i] from:sender forEvent:nil];
      }];
      [ac addAction:action];
    }
  }
  auto cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
  [ac addAction:cancel];
  [navCtrl presentViewController:ac animated:YES completion:nil];
}

- (NSArray<NSString *> *)actionsForMenu {
  return nil;
}

@end
@implementation UIViewController (TEActions)

- (void)pushNewInstance:(id)sender
{
  UIViewController *inst = [[self.class alloc] init];
  [self showViewController:inst sender:sender];
}

@end
