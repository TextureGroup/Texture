//
//  ASTextCacheKey.h
//  AsyncDisplayKit
//
//  Created by Adlai on 5/19/18.
//  Copyright © 2018 Pinterest. All rights reserved.
//

#import <AsyncDisplayKit/ASBaseDefines.h>
#import <Foundation/Foundation.h>

@class ASTextLayout, ASTextContainer;

NS_ASSUME_NONNULL_BEGIN

AS_SUBCLASSING_RESTRICTED
@interface ASTextCacheKey : NSObject

/// The container you pass in will not be copied. The attributedString however will be.
- (instancetype)initWithContainer:(ASTextContainer *)container
                 attributedString:(NSAttributedString *)attributedString;

// nil if we don't have a layout yet.
// non-null for entries stored in the cache.
@property (atomic, readonly, nullable) ASTextLayout *layout;

// Cache miss method. Compute the layout and store it on self.
- (ASTextLayout *)createLayout;

@end

NS_ASSUME_NONNULL_END
