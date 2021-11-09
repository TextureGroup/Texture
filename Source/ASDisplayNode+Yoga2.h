//
//  ASDisplayNode+Yoga2.h
//  AsyncDisplayKit
//
//  Created by Adlai Holler on 3/8/19.
//  Copyright © 2019 Pinterest. All rights reserved.
//

#if defined(__cplusplus)

#import <AsyncDisplayKit/AsyncDisplayKit.h>
#import <AsyncDisplayKit/ASAvailability.h>
#import <UIKit/UIKit.h>

#if YOGA
#import YOGA_HEADER_PATH
#endif

NS_ASSUME_NONNULL_BEGIN

namespace AS {
namespace Yoga2 {

/**
 * Returns whether Yoga2 is enabled for this node.
 */
bool GetEnabled(ASDisplayNode *node);

inline void AssertEnabled() {
  ASDisplayNodeCAssert(false, @"Expected Yoga2 to be enabled.");
}

inline void AssertEnabled(ASDisplayNode *node) {
  ASDisplayNodeCAssert(GetEnabled(node), @"Expected Yoga2 to be enabled.");
}

inline void AssertDisabled(ASDisplayNode *node) {
  ASDisplayNodeCAssert(!GetEnabled(node), @"Expected Yoga2 to be disabled.");
}


}  // namespace Yoga2
}  // namespace AS

NS_ASSUME_NONNULL_END

#endif  // defined(__cplusplus)
