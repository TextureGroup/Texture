//
//  TEItem.h
//  Sample
//
//  Created by Adlai Holler on 9/24/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ui_collection_generated.h"

NS_ASSUME_NONNULL_BEGIN

/// An object-wrapper for the Item flatbuf.
@interface TEItem : NSObject {
@package
  Item *_item;
}

- (instancetype)initWithItemPointer:(Item *)item;

@end

NS_ASSUME_NONNULL_END
