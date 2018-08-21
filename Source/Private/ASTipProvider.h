//
//  ASTipProvider.h
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

@class ASDisplayNode, ASTip;

NS_ASSUME_NONNULL_BEGIN

/**
 * An abstract superclass for all tip providers.
 */
@interface ASTipProvider : NSObject

/**
 * The provider looks at the node's current situation and
 * generates a tip, if any, to add to the node.
 *
 * Subclasses must override this.
 */
- (nullable ASTip *)tipForNode:(ASDisplayNode *)node;

@end

@interface ASTipProvider (Lookup)

@property (class, nonatomic, copy, readonly) NSArray<__kindof ASTipProvider *> *all;

@end

NS_ASSUME_NONNULL_END

#endif // AS_ENABLE_TIPS
