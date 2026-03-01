//
//  _ASDisplayViewAccessiblity.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <Foundation/Foundation.h>

// WARNING: When dealing with accessibility elements, please use the `accessibilityElements`
// property instead of the older methods e.g. `accessibilityElementCount()`. While the older methods
// should still work as long as accessibility is enabled, this framework provides no guarantees on
// their correctness. For details, see
// https://developer.apple.com/documentation/objectivec/nsobject/1615147-accessibilityelements

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
