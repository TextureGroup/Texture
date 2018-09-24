//
//  TEBaseViewController.m
//  Sample
//
//  Created by Adlai Holler on 9/21/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import "TEBaseViewController.h"

#import "flatbuffers/flatbuffers.h"
#import "flatbuffers/idl.h"
#import <AsyncDisplayKit/ASCollectionViewHelper.h>
#import <AsyncDisplayKit/ASDisplayNode.h>
#import "TECellView.h"
#import "UIViewController+TEActions.h"
#import <memory>

@interface TEBaseViewController ()

@end

@implementation TEBaseViewController {
  ASCollectionViewHelper *_texHelper;
  // NOTE: This is only safe because the NSData behind this pointer is retained
  // by a static variable.
  const UICollection *_data;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
    static NSData *pacManData;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      pacManData = [NSData dataWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"PacMan" ofType:@"bin"]];
    });
    
  
    _data = GetUICollection(pacManData.bytes);
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Act" style:UIBarButtonItemStyleDone target:self action:TEActionShowMenu];
  }
  return self;
}

- (NSArray<NSString *> *)actionsForMenu {
  return @[ NSStringFromSelector(TEActionPushNewInstance),
            NSStringFromSelector(@selector(reloadData)) ];
}

- (void)reloadData {
  NSAssert(NO, @"Abstract method.");
}

- (void)perform:(void (NS_NOESCAPE ^)())updates {
  NSAssert(NO, @"Abstract method.");
}

- (NSInteger)numberOfSections {
  return _data->sections()->size();
}

- (NSInteger)numberOfItemsIn:(NSInteger)section {
  return _data->sections()->Get((flatbuffers::uoffset_t)section)->items()->size();
}

- (CGSize)sizeAt:(const TEPath &)path {
  auto item = [self _itemAt:path];
  // No item is valid. Could be this section has no footer, for example.
  if (!item) {
    return CGSizeZero;
  }
  
  if (item->use_texture()) {
    ASDisplayNode *node; // TODO: Get the node from somewhere.
    return node.calculatedSize;
  } else {
    return [TECellView sizeForItem:*item inContainer:self.view];
  }
}

- (NSString *)reuseIdentifierAt:(const TEPath &)path {
  return ([self _itemAt:path]->use_texture() ? TEViewPlatformTexture : TEViewPlatformPlain);
}

- (void)hostItemAt:(const TEPath &)path in:(UIView *)contentView {
  auto item = [self _itemAt:path];
  if (item->use_texture()) {
    ASDisplayNode *node; // TODO: Get the node from somewhere.
    unowned UIView *nodeView = node.view;
    if ([contentView.subviews indexOfObjectIdenticalTo:nodeView] == NSNotFound) {
      for (UIView *subview in contentView.subviews) {
        [subview removeFromSuperview];
      }
      [contentView addSubview:nodeView];
    }
  } else {
    auto view = [TECellView hostInContentViewIfNeeded:contentView];
    [view setItem:*item];
  }
}

- (const Item *)_itemAt:(const TEPath &)path {
  if (path.supplementaryElementKind == UICollectionElementKindSectionHeader) {
    return _data->sections()->Get(path.section)->header();
  } else if (path.supplementaryElementKind == UICollectionElementKindSectionFooter) {
    return _data->sections()->Get(path.section)->footer();
  } else {
    return _data->sections()->Get(path.section)->items()->Get(path.item);
  }
}

@end
