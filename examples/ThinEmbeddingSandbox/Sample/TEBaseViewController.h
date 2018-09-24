//
//  TEBaseViewController.h
//  Sample
//
//  Created by Adlai Holler on 9/21/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ui_collection_generated.h"

NS_ASSUME_NONNULL_BEGIN
static NSString *const TEViewPlatformPlain = @"plain";
static NSString *const TEViewPlatformTexture = @"texture";

struct TEPath {
  int section;  // NSNotFound means "global."
  int item;     // NSNotFound means "section-level."
  __unsafe_unretained NSString * _Nullable supplementaryElementKind; // Nil means item.
  static TEPath make(NSIndexPath *indexPath, NSString *supplementaryElementKindArg = nil) {
    return { (int)indexPath.section, (int)indexPath.item, supplementaryElementKindArg };
  }
  static TEPath header(NSInteger sectionArg) {
    return { (int)sectionArg, 0, UICollectionElementKindSectionHeader };
  }
  static TEPath footer(NSInteger sectionArg) {
    return { (int)sectionArg, 0, UICollectionElementKindSectionFooter };
  }
};

@class TECellView, TEModel, TESectionController;

@interface TEBaseViewController : UIViewController

/// Tell the view to reload data. Doesn't affect data source data.
- (void)reloadData;

/// Don't call on base class.
- (void)perform:(void(NS_NOESCAPE ^)(void))updates;

@end

@interface TEBaseViewController (UISubclassingHooks)

// Things subclasses call:
- (NSInteger)numberOfSections;
- (NSInteger)numberOfItemsIn:(NSInteger)section;
- (CGSize)sizeAt:(const TEPath &)path;
- (NSString *)reuseIdentifierAt:(const TEPath &)path;
- (void)hostItemAt:(const TEPath &)path in:(UIView *)contentView;

@end

NS_ASSUME_NONNULL_END
