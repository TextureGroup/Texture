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
@class ASAccessibilityElement;

/**
 * The methods adopted by the object to provide frame information for a given
 * ASAccessibilityElement
 */
@protocol ASAccessibilityElementFrameProviding

/**
 * Returns the accessibilityFrame for the given ASAccessibilityElement
 */
- (CGRect)accessibilityFrameForAccessibilityElement:(ASAccessibilityElement *)accessibilityElement;

@end

/**
 * Encapsulates Texture related information about an item that should be
 * accessible to users with disabilities, but that isn’t accessible by default.
 */
@interface ASAccessibilityElement : UIAccessibilityElement

@property (nonatomic) ASDisplayNode *node;
@property (nonatomic) NSRange accessibilityRange;

/**
 * If a frameProvider is set on the ASAccessibilityElement it will be asked to
 * return the frame for the corresponding UIAccessibilityElement within
 * accessibilityElement.
 *
 * @note: If a frameProvider is set any accessibilityFrame set on the
 * UIAccessibilityElement explicitly will be ignored
 */
@property (nonatomic) id<ASAccessibilityElementFrameProviding> frameProvider;

@end

@interface ASAccessibilityCustomAction : UIAccessibilityCustomAction

@property (nonatomic, readonly) ASDisplayNode *node;
@property (nonatomic, nullable, readonly) id value;
@property (nonatomic, readonly) NSRange textRange;

@end

// After recusively collecting all of the accessibility elements of a node, they get sorted. This sort determines
// the order that a screen reader will traverse the elements. By default, we sort these elements based on their
// origin: lower y origin comes first, then lower x origin. If 2 nodes have an equal origin, the node with the smaller
// height is placed before the node with the smaller width. If two nodes have the exact same rect, we throw up our hands
// and return NSOrderedSame.
//
// In general this seems to work fairly well. However, if you want to provide a custom sort you can do so via
// setUserDefinedAccessibilitySortComparator(). The two elements you are comparing are NSObjects, which conforms to the
// informal UIAccessibility protocol, so you can safely compare properties like accessibilityFrame.
typedef NSComparisonResult (^ASSortAccessibilityElementsComparator)(NSObject *, NSObject *);

// Use this method to supply your own custom sort comparator used to determine the order of the accessibility elements
void setUserDefinedAccessibilitySortComparator(ASSortAccessibilityElementsComparator userDefinedComparator);

NS_ASSUME_NONNULL_END
