//
//  ASTipNode.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASControlNode.h>
#import <AsyncDisplayKit/ASBaseDefines.h>

#if AS_ENABLE_TIPS

@class ASTip;

NS_ASSUME_NONNULL_BEGIN

/**
 * ASTipNode will send these up the responder chain.
 */
@protocol ASTipNodeActions <NSObject>
- (void)didTapTipNode:(id)sender;
@end

AS_SUBCLASSING_RESTRICTED
@interface ASTipNode : ASControlNode

- (instancetype)initWithTip:(ASTip *)tip NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, readonly) ASTip *tip;

@end

NS_ASSUME_NONNULL_END

#endif // AS_ENABLE_TIPS
