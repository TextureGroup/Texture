//
//  ASCGImageBuffer.h
//  AsyncDisplayKit
//
//  Created by Adlai on 2/28/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/ASBaseDefines.h>
#import <CoreGraphics/CGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

AS_SUBCLASSING_RESTRICTED
@interface ASCGImageBuffer : NSObject

- (instancetype)initWithLength:(NSUInteger)length;

@property (readonly) void *mutableBytes NS_RETURNS_INNER_POINTER;

/// Don't do any drawing or call any methods after calling this.
- (CGDataProviderRef)createDataProviderAndInvalidate;

@end

NS_ASSUME_NONNULL_END
