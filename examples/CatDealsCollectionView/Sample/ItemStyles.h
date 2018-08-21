//
//  ItemStyles.h
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

@interface ItemStyles : NSObject
+ (NSDictionary *)titleStyle;
+ (NSDictionary *)subtitleStyle;
+ (NSDictionary *)distanceStyle;
+ (NSDictionary *)secondInfoStyle;
+ (NSDictionary *)originalPriceStyle;
+ (NSDictionary *)finalPriceStyle;
+ (NSDictionary *)soldOutStyle;
+ (NSDictionary *)badgeStyle;
+ (UIColor *)badgeColor;
+ (UIImage *)placeholderImage;
@end
