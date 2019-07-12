//
//  Utilities.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (Additions)

+ (UIColor *)backgroundColor;
+ (UIColor *)darkBlueColor;
+ (UIColor *)lightBlueColor;

@end

@interface UIImage (Additions)

+ (void)downloadImageForURL:(NSURL *)url completion:(void (^)(UIImage *))block;
- (UIImage *)makeCircularImageWithSize:(CGSize)size backgroundColor:(nullable UIColor *)backgroundColor;

@end

@interface NSString (Additions)

// returns a user friendly elapsed time such as '50s', '6m' or '3w'
+ (NSString *)elapsedTimeStringSinceDate:(NSString *)uploadDateString;

@end

@interface NSAttributedString (Additions)

+ (NSAttributedString *)attributedStringWithString:(NSString *)string
                                          fontSize:(CGFloat)size
                                             color:(nullable UIColor *)color
                                    firstWordColor:(nullable UIColor *)firstWordColor;

@end

NS_ASSUME_NONNULL_END
