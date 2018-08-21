//
//  NSMutableAttributedString+TextKitAdditions.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableAttributedString (TextKitAdditions)

- (void)attributeTextInRange:(NSRange)range withTextKitMinimumLineHeight:(CGFloat)minimumLineHeight;

- (void)attributeTextInRange:(NSRange)range withTextKitMinimumLineHeight:(CGFloat)minimumLineHeight maximumLineHeight:(CGFloat)maximumLineHeight;

- (void)attributeTextInRange:(NSRange)range withTextKitLineHeight:(CGFloat)lineHeight;

- (void)attributeTextInRange:(NSRange)range withTextKitParagraphStyle:(NSParagraphStyle *)paragraphStyle;

@end

NS_ASSUME_NONNULL_END
