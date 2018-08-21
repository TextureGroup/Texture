//
//  ASTip.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/ASBaseDefines.h>

#if AS_ENABLE_TIPS

NS_ASSUME_NONNULL_BEGIN

@class ASDisplayNode;

typedef NS_ENUM (NSInteger, ASTipKind) {
  ASTipKindEnableLayerBacking
};

AS_SUBCLASSING_RESTRICTED
@interface ASTip : NSObject

- (instancetype)initWithNode:(ASDisplayNode *)node
                        kind:(ASTipKind)kind
                      format:(NSString *)format, ... NS_FORMAT_FUNCTION(3, 4);

/**
 * The kind of tip this is.
 */
@property (nonatomic, readonly) ASTipKind kind;

/**
 * The node that this tip applies to.
 */
@property (nonatomic, readonly) ASDisplayNode *node;

/**
 * The text to show the user.
 */
@property (nonatomic, readonly) NSString *text;

@end

NS_ASSUME_NONNULL_END

#endif // AS_ENABLE_TIPS
