//
//  ASLayerBackingTipProvider.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASTipProvider.h"
#import <AsyncDisplayKit/ASBaseDefines.h>

#if AS_ENABLE_TIPS

NS_ASSUME_NONNULL_BEGIN

AS_SUBCLASSING_RESTRICTED
@interface ASLayerBackingTipProvider : ASTipProvider

@end

NS_ASSUME_NONNULL_END

#endif // AS_ENABLE_TIPS
