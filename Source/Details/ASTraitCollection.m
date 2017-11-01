//
//  ASTraitCollection.m
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

#import <AsyncDisplayKit/ASAvailability.h>
#import <AsyncDisplayKit/ASTraitCollection.h>
#import <AsyncDisplayKit/ASObjectDescriptionHelpers.h>
#import <AsyncDisplayKit/ASLayoutElement.h>

#pragma mark - ASPrimitiveContentSizeCategory

// UIContentSizeCategoryUnspecified is available only in iOS 10.0 and later.
// This constant is used as a fallback for older iOS versions.
static UIContentSizeCategory const AS_UIContentSizeCategoryUnspecified = @"_UICTContentSizeCategoryUnspecified";

ASPrimitiveContentSizeCategory ASPrimitiveContentSizeCategoryMake(UIContentSizeCategory sizeCategory) {
  if ([sizeCategory isEqualToString:UIContentSizeCategoryExtraSmall]) {
    return UIContentSizeCategoryExtraSmall;
  }
  if ([sizeCategory isEqualToString:UIContentSizeCategorySmall]) {
    return UIContentSizeCategorySmall;
  }
  if ([sizeCategory isEqualToString:UIContentSizeCategoryMedium]) {
    return UIContentSizeCategoryMedium;
  }
  if ([sizeCategory isEqualToString:UIContentSizeCategoryLarge]) {
    return UIContentSizeCategoryLarge;
  }
  if ([sizeCategory isEqualToString:UIContentSizeCategoryExtraLarge]) {
    return UIContentSizeCategoryExtraLarge;
  }
  if ([sizeCategory isEqualToString:UIContentSizeCategoryExtraExtraLarge]) {
    return UIContentSizeCategoryExtraExtraLarge;
  }
  if ([sizeCategory isEqualToString:UIContentSizeCategoryExtraExtraExtraLarge]) {
    return UIContentSizeCategoryExtraExtraExtraLarge;
  }

  if ([sizeCategory isEqualToString:UIContentSizeCategoryAccessibilityMedium]) {
    return UIContentSizeCategoryAccessibilityMedium;
  }
  if ([sizeCategory isEqualToString:UIContentSizeCategoryAccessibilityLarge]) {
    return UIContentSizeCategoryAccessibilityLarge;
  }
  if ([sizeCategory isEqualToString:UIContentSizeCategoryAccessibilityExtraLarge]) {
    return UIContentSizeCategoryAccessibilityExtraLarge;
  }
  if ([sizeCategory isEqualToString:UIContentSizeCategoryAccessibilityExtraExtraLarge]) {
    return UIContentSizeCategoryAccessibilityExtraExtraLarge;
  }
  if ([sizeCategory isEqualToString:UIContentSizeCategoryAccessibilityExtraExtraExtraLarge]) {
    return UIContentSizeCategoryAccessibilityExtraExtraExtraLarge;
  }

  if (AS_AT_LEAST_IOS10) {
    return UIContentSizeCategoryUnspecified;
  }
  else {
    return AS_UIContentSizeCategoryUnspecified;
  }
}

#pragma mark - ASPrimitiveTraitCollection

extern void ASTraitCollectionPropagateDown(id<ASLayoutElement> element, ASPrimitiveTraitCollection traitCollection) {
  if (element) {
    element.primitiveTraitCollection = traitCollection;
  }
  
  for (id<ASLayoutElement> subelement in element.sublayoutElements) {
    ASTraitCollectionPropagateDown(subelement, traitCollection);
  }
}

ASPrimitiveTraitCollection ASPrimitiveTraitCollectionMakeDefault() {
  return (ASPrimitiveTraitCollection) {
    // Default values can be defined in here
    .displayGamut = UIDisplayGamutUnspecified,
    .userInterfaceIdiom = UIUserInterfaceIdiomUnspecified,
    .layoutDirection = UITraitEnvironmentLayoutDirectionUnspecified,
    .preferredContentSizeCategory = ASPrimitiveContentSizeCategoryMake(AS_AT_LEAST_IOS10 ? UIContentSizeCategoryUnspecified : AS_UIContentSizeCategoryUnspecified),
    .containerSize = CGSizeZero,
  };
}

ASPrimitiveTraitCollection ASPrimitiveTraitCollectionFromUITraitCollection(UITraitCollection *traitCollection) {
  ASPrimitiveTraitCollection environmentTraitCollection = ASPrimitiveTraitCollectionMakeDefault();
  environmentTraitCollection.horizontalSizeClass = traitCollection.horizontalSizeClass;
  environmentTraitCollection.verticalSizeClass = traitCollection.verticalSizeClass;
  environmentTraitCollection.displayScale = traitCollection.displayScale;
  environmentTraitCollection.userInterfaceIdiom = traitCollection.userInterfaceIdiom;
  if (AS_AT_LEAST_IOS9) {
    environmentTraitCollection.forceTouchCapability = traitCollection.forceTouchCapability;
  }
  if (AS_AT_LEAST_IOS10) {
    environmentTraitCollection.displayGamut = traitCollection.displayGamut;
    environmentTraitCollection.layoutDirection = traitCollection.layoutDirection;

    // preferredContentSizeCategory is also available on older iOS versions, but only via UIApplication class.
    // It should be noted that [UIApplication sharedApplication] is unavailable because Texture is built with only extension-safe API.
    environmentTraitCollection.preferredContentSizeCategory = ASPrimitiveContentSizeCategoryMake(traitCollection.preferredContentSizeCategory);

    #if TARGET_OS_TV
      environmentTraitCollection.userInterfaceStyle = traitCollection.userInterfaceStyle;
    #endif
  }
  return environmentTraitCollection;
}

BOOL ASPrimitiveTraitCollectionIsEqualToASPrimitiveTraitCollection(ASPrimitiveTraitCollection lhs, ASPrimitiveTraitCollection rhs) {
  return
    lhs.verticalSizeClass == rhs.verticalSizeClass &&
    lhs.horizontalSizeClass == rhs.horizontalSizeClass &&
    lhs.displayScale == rhs.displayScale &&
    lhs.displayGamut == rhs.displayGamut &&
    lhs.userInterfaceIdiom == rhs.userInterfaceIdiom &&
    lhs.forceTouchCapability == rhs.forceTouchCapability &&
    lhs.layoutDirection == rhs.layoutDirection &&
    #if TARGET_OS_TV
      lhs.userInterfaceStyle == rhs.userInterfaceStyle &&
    #endif

    // preferredContentSizeCategory always points to one of UIContentSizeCategory constants.
    // Assuming their values do not duplicate, we can simply compare pointers, avoiding string comparison.
    lhs.preferredContentSizeCategory == rhs.preferredContentSizeCategory &&

    CGSizeEqualToSize(lhs.containerSize, rhs.containerSize);
}

// Named so as not to conflict with a hidden Apple function, in case compiler decides not to inline
ASDISPLAYNODE_INLINE NSString *AS_NSStringFromUIUserInterfaceIdiom(UIUserInterfaceIdiom idiom) {
  switch (idiom) {
    case UIUserInterfaceIdiomTV:
      return @"TV";
    case UIUserInterfaceIdiomPad:
      return @"Pad";
    case UIUserInterfaceIdiomPhone:
      return @"Phone";
    case UIUserInterfaceIdiomCarPlay:
      return @"CarPlay";
    default:
      return @"Unspecified";
  }
}

// Named so as not to conflict with a hidden Apple function, in case compiler decides not to inline
ASDISPLAYNODE_INLINE NSString *AS_NSStringFromUIForceTouchCapability(UIForceTouchCapability capability) {
  switch (capability) {
    case UIForceTouchCapabilityAvailable:
      return @"Available";
    case UIForceTouchCapabilityUnavailable:
      return @"Unavailable";
    default:
      return @"Unknown";
  }
}

// Named so as not to conflict with a hidden Apple function, in case compiler decides not to inline
ASDISPLAYNODE_INLINE NSString *AS_NSStringFromUIUserInterfaceSizeClass(UIUserInterfaceSizeClass sizeClass) {
  switch (sizeClass) {
    case UIUserInterfaceSizeClassCompact:
      return @"Compact";
    case UIUserInterfaceSizeClassRegular:
      return @"Regular";
    default:
      return @"Unspecified";
  }
}

// Named so as not to conflict with a hidden Apple function, in case compiler decides not to inline
ASDISPLAYNODE_INLINE NSString *AS_NSStringFromUIDisplayGamut(UIDisplayGamut displayGamut) {
  switch (displayGamut) {
    case UIDisplayGamutSRGB:
      return @"sRGB";
    case UIDisplayGamutP3:
      return @"P3";
    default:
      return @"Unspecified";
  }
}

// Named so as not to conflict with a hidden Apple function, in case compiler decides not to inline
ASDISPLAYNODE_INLINE NSString *AS_NSStringFromUITraitEnvironmentLayoutDirection(UITraitEnvironmentLayoutDirection layoutDirection) {
  switch (layoutDirection) {
    case UITraitEnvironmentLayoutDirectionLeftToRight:
      return @"LeftToRight";
    case UITraitEnvironmentLayoutDirectionRightToLeft:
      return @"RightToLeft";
    default:
      return @"Unspecified";
  }
}

#if TARGET_OS_TV
// Named so as not to conflict with a hidden Apple function, in case compiler decides not to inline
ASDISPLAYNODE_INLINE NSString *AS_NSStringFromUIUserInterfaceStyle(UIUserInterfaceStyle userInterfaceStyle) {
  switch (userInterfaceStyle) {
    case UIUserInterfaceStyleLight:
      return @"Light";
    case UIUserInterfaceStyleDark:
      return @"Dark";
    default:
      return @"Unspecified";
  }
}
#endif

NSString *NSStringFromASPrimitiveTraitCollection(ASPrimitiveTraitCollection traits) {
  NSMutableArray<NSDictionary *> *props = [NSMutableArray array];
  [props addObject:@{ @"verticalSizeClass": AS_NSStringFromUIUserInterfaceSizeClass(traits.verticalSizeClass) }];
  [props addObject:@{ @"horizontalSizeClass": AS_NSStringFromUIUserInterfaceSizeClass(traits.horizontalSizeClass) }];
  [props addObject:@{ @"displayScale": [NSString stringWithFormat: @"%.0lf", (double)traits.displayScale] }];
  [props addObject:@{ @"displayGamut": AS_NSStringFromUIDisplayGamut(traits.displayGamut) }];
  [props addObject:@{ @"userInterfaceIdiom": AS_NSStringFromUIUserInterfaceIdiom(traits.userInterfaceIdiom) }];
  [props addObject:@{ @"forceTouchCapability": AS_NSStringFromUIForceTouchCapability(traits.forceTouchCapability) }];
  [props addObject:@{ @"layoutDirection": AS_NSStringFromUITraitEnvironmentLayoutDirection(traits.layoutDirection) }];
  #if TARGET_OS_TV
    [props addObject:@{ @"userInterfaceStyle": AS_NSStringFromUIUserInterfaceStyle(traits.userInterfaceStyle) }];
  #endif
  [props addObject:@{ @"preferredContentSizeCategory": (UIContentSizeCategory)traits.preferredContentSizeCategory }];
  [props addObject:@{ @"containerSize": NSStringFromCGSize(traits.containerSize) }];
  return ASObjectDescriptionMakeWithoutObject(props);
}

#pragma mark - ASTraitCollection

@implementation ASTraitCollection

- (instancetype)initWithHorizontalSizeClass:(UIUserInterfaceSizeClass)horizontalSizeClass
                          verticalSizeClass:(UIUserInterfaceSizeClass)verticalSizeClass
                               displayScale:(CGFloat)displayScale
                               displayGamut:(UIDisplayGamut)displayGamut
                         userInterfaceIdiom:(UIUserInterfaceIdiom)userInterfaceIdiom
                       forceTouchCapability:(UIForceTouchCapability)forceTouchCapability
                            layoutDirection:(UITraitEnvironmentLayoutDirection)layoutDirection
#if TARGET_OS_TV
                         userInterfaceStyle:(UIUserInterfaceStyle)userInterfaceStyle
#endif
               preferredContentSizeCategory:(UIContentSizeCategory)preferredContentSizeCategory
                              containerSize:(CGSize)windowSize
{
    self = [super init];
    if (self) {
      _horizontalSizeClass = horizontalSizeClass;
      _verticalSizeClass = verticalSizeClass;
      _displayScale = displayScale;
      _displayGamut = displayGamut;
      _userInterfaceIdiom = userInterfaceIdiom;
      _forceTouchCapability = forceTouchCapability;
      _layoutDirection = layoutDirection;
      #if TARGET_OS_TV
        _userInterfaceStyle = userInterfaceStyle;
      #endif
      _preferredContentSizeCategory = preferredContentSizeCategory;
      _containerSize = windowSize;
    }
    return self;
}

+ (instancetype)traitCollectionWithHorizontalSizeClass:(UIUserInterfaceSizeClass)horizontalSizeClass
                                     verticalSizeClass:(UIUserInterfaceSizeClass)verticalSizeClass
                                          displayScale:(CGFloat)displayScale
                                          displayGamut:(UIDisplayGamut)displayGamut
                                    userInterfaceIdiom:(UIUserInterfaceIdiom)userInterfaceIdiom
                                  forceTouchCapability:(UIForceTouchCapability)forceTouchCapability
                                       layoutDirection:(UITraitEnvironmentLayoutDirection)layoutDirection
#if TARGET_OS_TV
                                    userInterfaceStyle:(UIUserInterfaceStyle)userInterfaceStyle
#endif
                          preferredContentSizeCategory:(UIContentSizeCategory)preferredContentSizeCategory
                                         containerSize:(CGSize)windowSize
{
  return [[self alloc] initWithHorizontalSizeClass:horizontalSizeClass
                                 verticalSizeClass:verticalSizeClass
                                      displayScale:displayScale
                                      displayGamut:displayGamut
                                userInterfaceIdiom:userInterfaceIdiom
                              forceTouchCapability:forceTouchCapability
                                   layoutDirection:layoutDirection
#if TARGET_OS_TV
                                userInterfaceStyle:userIntefaceStyle
#endif
                      preferredContentSizeCategory:preferredContentSizeCategory
                                     containerSize:windowSize];
}

+ (instancetype)traitCollectionWithASPrimitiveTraitCollection:(ASPrimitiveTraitCollection)traits
{
  return [self traitCollectionWithHorizontalSizeClass:traits.horizontalSizeClass
                                    verticalSizeClass:traits.verticalSizeClass
                                         displayScale:traits.displayScale
                                         displayGamut:traits.displayGamut
                                   userInterfaceIdiom:traits.userInterfaceIdiom
                                 forceTouchCapability:traits.forceTouchCapability
                                      layoutDirection:traits.layoutDirection
#if TARGET_OS_TV
                                   userInterfaceStyle:traits.userInterfaceStyle
#endif
                         preferredContentSizeCategory:(UIContentSizeCategory)traits.preferredContentSizeCategory
                                        containerSize:traits.containerSize];
}

+ (instancetype)traitCollectionWithUITraitCollection:(UITraitCollection *)traitCollection
                                       containerSize:(CGSize)windowSize
{
  return [self traitCollectionWithUITraitCollection:traitCollection
                                      containerSize:windowSize
                        fallbackContentSizeCategory:AS_AT_LEAST_IOS10 ? UIContentSizeCategoryUnspecified : AS_UIContentSizeCategoryUnspecified];
}


+ (instancetype)traitCollectionWithUITraitCollection:(UITraitCollection *)traitCollection
                                       containerSize:(CGSize)windowSize
                         fallbackContentSizeCategory:(UIContentSizeCategory)fallbackContentSizeCategory
{
  UIForceTouchCapability forceTouch = AS_AT_LEAST_IOS9 ? traitCollection.forceTouchCapability : UIForceTouchCapabilityUnknown;
  UIDisplayGamut displayGamut;
  UITraitEnvironmentLayoutDirection layoutDirection;
  UIContentSizeCategory sizeCategory;
  #if TARGET_OS_TV
    UIUserInterfaceStyle userInterfaceStyle;
  #endif
  if (AS_AT_LEAST_IOS10) {
    displayGamut = traitCollection.displayGamut;
    layoutDirection = traitCollection.layoutDirection;
    sizeCategory = traitCollection.preferredContentSizeCategory;
    #if TARGET_OS_TV
      userInterfaceStyle = traitCollection.userInterfaceStyle;
    #endif
  } else {
    displayGamut = UIDisplayGamutUnspecified;
    layoutDirection = UITraitEnvironmentLayoutDirectionUnspecified;
    sizeCategory = fallbackContentSizeCategory;
    #if TARGET_OS_TV
      userInterfaceStyle = UIUserInterfaceStyleUnspecified;
    #endif
  }

  return [self traitCollectionWithHorizontalSizeClass:traitCollection.horizontalSizeClass
                                    verticalSizeClass:traitCollection.verticalSizeClass
                                         displayScale:traitCollection.displayScale
                                         displayGamut:displayGamut
                                   userInterfaceIdiom:traitCollection.userInterfaceIdiom
                                 forceTouchCapability:forceTouch
                                      layoutDirection:layoutDirection
#if TARGET_OS_TV
                                   userInterfaceStyle:userInterfaceStyle
#endif
                         preferredContentSizeCategory:sizeCategory
                                        containerSize:windowSize];
}

- (ASPrimitiveTraitCollection)primitiveTraitCollection
{
  return (ASPrimitiveTraitCollection) {
    .horizontalSizeClass = self.horizontalSizeClass,
    .verticalSizeClass = self.verticalSizeClass,
    .displayScale = self.displayScale,
    .displayGamut = self.displayGamut,
    .userInterfaceIdiom = self.userInterfaceIdiom,
    .forceTouchCapability = self.forceTouchCapability,
    .layoutDirection = self.layoutDirection,
    #if TARGET_OS_TV
      .userInterfaceStyle = self.userInterfaceStyle,
    #endif
    .preferredContentSizeCategory = ASPrimitiveContentSizeCategoryMake(self.preferredContentSizeCategory),
    .containerSize = self.containerSize,
  };
}

- (BOOL)isEqualToTraitCollection:(ASTraitCollection *)traitCollection
{
  if (self == traitCollection) {
    return YES;
  }

  return
    self.horizontalSizeClass == traitCollection.horizontalSizeClass &&
    self.verticalSizeClass == traitCollection.verticalSizeClass &&
    self.displayScale == traitCollection.displayScale &&
    self.displayGamut == traitCollection.displayGamut &&
    self.userInterfaceIdiom == traitCollection.userInterfaceIdiom &&
    self.forceTouchCapability == traitCollection.forceTouchCapability &&
    self.layoutDirection == traitCollection.layoutDirection &&
    #if TARGET_OS_TV
      self.userInterfaceStyle == traitCollection.userInterfaceStyle &&
    #endif
    [self.preferredContentSizeCategory isEqualToString:traitCollection.preferredContentSizeCategory] &&
    CGSizeEqualToSize(self.containerSize, traitCollection.containerSize);
}

@end
