//
//  ASControlNode+Defines.h
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASControlNode.h>

@interface ASControlNode (Defines)

/**
 * Class method that when set to YES ensures the BOOL parameter passed to -[ASControlNode
 * setUserInteractionEnabled:] is also passed to -[ASControlNode setIsAccessibilityElement:]. Thus
 * the two properties `userInteractionEnabled` and `isAccessibilityElement` stay in sync. When set
 * to NO, these two properties are unrelated.
 */
@property(class, nonatomic) BOOL shouldUserInteractionEnabledSetIsAXElement;

@end
