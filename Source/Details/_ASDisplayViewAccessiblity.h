//
//  _ASDisplayViewAccessiblity.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// WARNING: When dealing with accessibility elements, please use the `accessibilityElements`
// property instead of the older methods e.g. `accessibilityElementCount()`. While the older methods
// should still work as long as accessibility is enabled, this framework provides no guarantees on
// their correctness. For details, see
// https://developer.apple.com/documentation/objectivec/nsobject/1615147-accessibilityelements

@class ASDisplayNode;

@interface ASAccessibilityCustomAction : UIAccessibilityCustomAction

@property (nonatomic, readonly) ASDisplayNode *node;
@property (nonatomic, nullable, readonly) id value;
@property (nonatomic, readonly) NSRange textRange;

@end

NS_ASSUME_NONNULL_END
