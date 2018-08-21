//
//  ASTableLayoutController.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/ASAbstractLayoutController.h>

NS_ASSUME_NONNULL_BEGIN

@class UITableView;

/**
 *  A layout controller designed for use with UITableView.
 */
AS_SUBCLASSING_RESTRICTED
@interface ASTableLayoutController : ASAbstractLayoutController

@property (nonatomic, weak, readonly) UITableView *tableView;

- (instancetype)initWithTableView:(UITableView *)tableView;

@end

NS_ASSUME_NONNULL_END
