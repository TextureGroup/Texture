//
//  UIView+ASConvenience.h
//  Texture
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the /ASDK-Licenses directory of this source tree. An additional
//  grant of patent rights can be found in the PATENTS file in the same directory.
//
//  Modifications to this file made after 4/13/2017 are: Copyright (c) 2017-present,
//  Pinterest, Inc.  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


/**
 These are the properties we support from CALayer (implemented in the pending state)
 */

@protocol ASDisplayProperties <NSObject>

@property (nonatomic, assign) CGPoint position;
@property (nonatomic, assign) CGFloat zPosition;
@property (nonatomic, assign) CGPoint anchorPoint;
@property (nonatomic, assign) CGFloat cornerRadius;
@property (nullable, nonatomic, strong) id contents;
@property (nonatomic, copy)   NSString *contentsGravity;
@property (nonatomic, assign) CGRect contentsRect;
@property (nonatomic, assign) CGRect contentsCenter;
@property (nonatomic, assign) CGFloat contentsScale;
@property (nonatomic, assign) CGFloat rasterizationScale;
@property (nonatomic, assign) CATransform3D transform;
@property (nonatomic, assign) CATransform3D sublayerTransform;
@property (nonatomic, assign) BOOL needsDisplayOnBoundsChange;
@property (nonatomic, strong) __attribute__((NSObject)) CGColorRef shadowColor;
@property (nonatomic, assign) CGFloat shadowOpacity;
@property (nonatomic, assign) CGSize shadowOffset;
@property (nonatomic, assign) CGFloat shadowRadius;
@property (nonatomic, assign) CGFloat borderWidth;
@property (nonatomic, assign, getter = isOpaque) BOOL opaque;
@property (nonatomic, strong) __attribute__((NSObject)) CGColorRef borderColor;
@property (nonatomic, strong) __attribute__((NSObject)) CGColorRef backgroundColor;
@property (nonatomic, assign) BOOL allowsGroupOpacity;
@property (nonatomic, assign) BOOL allowsEdgeAntialiasing;
@property (nonatomic, assign) unsigned int edgeAntialiasingMask;

- (void)setNeedsDisplay;
- (void)setNeedsLayout;
- (void)layoutIfNeeded;

@end

/**
 These are all of the "good" properties of the UIView API that we support in pendingViewState or view of an ASDisplayNode.
 */
@protocol ASDisplayNodeViewProperties

@property (nonatomic, assign)          BOOL clipsToBounds;
@property (nonatomic, getter=isHidden) BOOL hidden;
@property (nonatomic, assign)          BOOL autoresizesSubviews;
@property (nonatomic, assign)          UIViewAutoresizing autoresizingMask;
@property (nonatomic, strong, null_resettable) UIColor *tintColor;
@property (nonatomic, assign)          CGFloat alpha;
@property (nonatomic, assign)          CGRect bounds;
@property (nonatomic, assign)          CGRect frame;   // Only for use with nodes wrapping synchronous views
@property (nonatomic, assign)          UIViewContentMode contentMode;
@property (nonatomic, assign)          UISemanticContentAttribute semanticContentAttribute API_AVAILABLE(ios(9.0), tvos(9.0));
@property (nonatomic, assign, getter=isUserInteractionEnabled) BOOL userInteractionEnabled;
@property (nonatomic, assign, getter=isExclusiveTouch) BOOL exclusiveTouch;
@property (nonatomic, assign, getter=asyncdisplaykit_isAsyncTransactionContainer, setter = asyncdisplaykit_setAsyncTransactionContainer:) BOOL asyncdisplaykit_asyncTransactionContainer;
@property (nonatomic, assign)           UIEdgeInsets layoutMargins;
@property (nonatomic, assign)           BOOL preservesSuperviewLayoutMargins;
@property (nonatomic, assign)           BOOL insetsLayoutMarginsFromSafeArea;

/**
 Following properties of the UIAccessibility informal protocol are supported as well.
 We don't declare them here, so _ASPendingState does not complain about them being not implemented,
 as they are already on NSObject

 @property (nonatomic, assign)           BOOL isAccessibilityElement;
 @property (nonatomic, copy, nullable)   NSString *accessibilityLabel;
 @property (nonatomic, copy, nullable)   NSAttributedString *accessibilityAttributedLabel API_AVAILABLE(ios(11.0),tvos(11.0));
 @property (nonatomic, copy, nullable)   NSString *accessibilityHint;
 @property (nonatomic, copy, nullable)   NSAttributedString *accessibilityAttributedHint API_AVAILABLE(ios(11.0),tvos(11.0));
 @property (nonatomic, copy, nullable)   NSString *accessibilityValue;
 @property (nonatomic, copy, nullable)   NSAttributedString *accessibilityAttributedValue API_AVAILABLE(ios(11.0),tvos(11.0));
 @property (nonatomic, assign)           UIAccessibilityTraits accessibilityTraits;
 @property (nonatomic, assign)           CGRect accessibilityFrame;
 @property (nonatomic, strong, nullable) NSString *accessibilityLanguage;
 @property (nonatomic, assign)           BOOL accessibilityElementsHidden;
 @property (nonatomic, assign)           BOOL accessibilityViewIsModal;
 @property (nonatomic, assign)           BOOL shouldGroupAccessibilityChildren;
 */

// Accessibility identification support
@property (nullable, nonatomic, copy)          NSString *accessibilityIdentifier;

@end

NS_ASSUME_NONNULL_END
