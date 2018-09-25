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
#import "TECellNode.h"
#import "TECellView.h"
#import "TEItem.h"
#import "UIViewController+TEActions.h"
#import <memory>

@interface TEBaseViewController ()

@end

@implementation TEBaseViewController {
  // NOTE: This is only safe because the NSData behind this pointer is retained
  // by a static variable.
  const UICollection *_data;
  
  NSMutableArray<NSMutableArray<ASNodeController *> *> *_nodeControllers;
  NSMutableArray<ASNodeController *> *_headers;
  NSMutableArray<ASNodeController *> *_footers;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
    static NSData *pacManData;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      pacManData = [NSData dataWithContentsOfFile:[NSBundle.mainBundle pathForResource:@"PacMan" ofType:@"bin"]];
    });
    _headers = [[NSMutableArray alloc] init];
    _footers = [[NSMutableArray alloc] init];
    _nodeControllers = [[NSMutableArray alloc] init];
    
    _data = GetUICollection(pacManData.bytes);
    for (let &section : *_data->sections()) {
      if (section->header() && section->header()->use_texture()) {
        [_headers addObject:[[ASNodeController alloc] init]];
      } else {
        [_headers addObject:(id)kCFNull];
      }
      if (section->footer() && section->footer()->use_texture()) {
        [_footers addObject:[[ASNodeController alloc] init]];
      } else {
        [_footers addObject:(id)kCFNull];
      }
      let itemArray = [[NSMutableArray alloc] init];
      for (let &item : *section->items()) {
        if (item->use_texture()) {
          [itemArray addObject:[[ASNodeController alloc] init]];
        } else {
          [itemArray addObject:(id)kCFNull];
        }
      }
      [_nodeControllers addObject:itemArray];
    }
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

- (ASCollectionViewHelper *)loadTextureHelper {
  NSAssert(NO, @"Abstract method.");
  return nil;
}

- (NSInteger)numberOfSections {
  return _nodeControllers.count;
}

- (NSInteger)numberOfItemsIn:(NSInteger)section {
  return _nodeControllers[section].count;
}

- (CGSize)sizeAt:(const TEPath &)path {

  auto item = [self _itemAt:path];
  // No item is valid. Could be this section has no footer, for example.
  if (!item) {
    return CGSizeZero;
  }
  
  NSAssert(!item->use_texture(), @"Texture-backed cell should not enter the native code path.");
  return [TECellView sizeForItem:*item inContainer:self.view];
}

- (void)hostItemAt:(const TEPath &)path in:(UIView *)contentView {
  auto item = [self _itemAt:path];
  NSAssert(!item->use_texture(), @"Texture-backed cell should not enter the native code path.");
  auto view = [TECellView hostInContentViewIfNeeded:contentView];
  [view setItem:*item];
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

- (id(^)())collectionViewHelper:(ASCollectionViewHelper *)helper nodeBlockForObject:(id)object indexPath:(NSIndexPath *)indexPath supplementaryElementKind:(NSString *)supplementaryElementKind {
  
  return ^{
    return [[TECellNode alloc] init];
  };
}

- (id)collectionViewHelper:(ASCollectionViewHelper *)helper objectForFooterInSection:(NSInteger)section {
  auto item = [self _itemAt:TEPath::footer(section)];
  if (!item || !item->use_texture()) {
    return nil;
  }
  return _footers[section];
}

- (id)collectionViewHelper:(ASCollectionViewHelper *)helper objectForHeaderInSection:(NSInteger)section {
  auto item = [self _itemAt:TEPath::header(section)];
  if (!item || !item->use_texture()) {
    return nil;
  }
  return _headers[section];
}

- (id)collectionViewHelper:(ASCollectionViewHelper *)helper objectForItemAtIndexPath:(NSIndexPath *)path {
  auto item = [self _itemAt:TEPath::make(path)];
  NSAssert(item, nil);
  if (!item || !item->use_texture()) {
    return nil;
  }
  return _nodeControllers[path.section][path.item];
}

@end
