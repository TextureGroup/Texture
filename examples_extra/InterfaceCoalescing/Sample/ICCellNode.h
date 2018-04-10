//
//  ICCellNode.h
//  Sample
//
//  Created by Max Wang on 4/5/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <AsyncDisplayKit/AsyncDisplayKit.h>

@class ICCellNode;

@protocol ICCellNodeDelegate
- (void)cellDidEnterVisibleState:(ICCellNode *)cellNode;
@end

@interface ICCellNode : ASCellNode

- (instancetype)initWithColor:(UIColor *)color colorName:(NSString *)colorName;

@property (nonatomic, copy) NSString *colorName;
@property (nonatomic, assign) NSUInteger didEnterVisibleCount;
@property (nonatomic, assign) NSUInteger didExitVisibleCount;

@property (nonatomic, weak) id<ICCellNodeDelegate> delegate;

@end
