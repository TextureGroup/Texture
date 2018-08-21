//
//  ItemViewModel.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface ItemViewModel : NSObject

+ (ItemViewModel *)randomItem;

@property (nonatomic, readonly) NSInteger identifier;
@property (nonatomic, copy) NSString *titleText;
@property (nonatomic, copy) NSString *firstInfoText;
@property (nonatomic, copy) NSString *secondInfoText;
@property (nonatomic, copy) NSString *originalPriceText;
@property (nonatomic, copy) NSString *finalPriceText;
@property (nonatomic, copy) NSString *soldOutText;
@property (nonatomic, copy) NSString *distanceLabelText;
@property (nonatomic, copy) NSString *badgeText;

- (NSURL *)imageURLWithSize:(CGSize)size;

@end
