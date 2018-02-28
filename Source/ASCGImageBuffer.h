//
//  ASCGImageBuffer.h
//  AsyncDisplayKit
//
//  Created by Adlai on 2/28/18.
//  Copyright © 2018 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ASCGImageBuffer : NSObject

- (instancetype)initWithLength:(NSUInteger)length;

@property (readonly) NSUInteger length;

@property (readonly) void *mutableBytes NS_RETURNS_INNER_POINTER;

- (CGDataProviderRef)createDataProviderAndInvalidate;

@end

NS_ASSUME_NONNULL_END
