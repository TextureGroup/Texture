//
//  ASDisplayNode+Yoga2.mm
//  AsyncDisplayKit
//
//  Created by Adlai Holler on 3/8/19.
//  Copyright © 2019 Pinterest. All rights reserved.
//

#import <AsyncDisplayKit/ASDisplayNode+Yoga2.h>
#import <AsyncDisplayKit/ASAvailability.h>
#import <AsyncDisplayKit/ASBaseDefines.h>

#if YOGA

#import <AsyncDisplayKit/ASAssert.h>
#import <AsyncDisplayKit/ASDisplayNode+FrameworkPrivate.h>
#import <AsyncDisplayKit/ASDisplayNodeInternal.h>
#import <AsyncDisplayKit/ASInternalHelpers.h>
#import <AsyncDisplayKit/ASLayoutElementStylePrivate.h>

#import YOGA_HEADER_PATH

namespace AS {
namespace Yoga2 {

bool GetEnabled(ASDisplayNode *node) {
  if (node) {
    MutexLocker l(node->__instanceLock__);
    return node->_flags.yoga;
  } else {
    return false;
  }
}

#else  // !YOGA

namespace AS {
namespace Yoga2 {

bool GetEnabled(ASDisplayNode *node) { return false; }

#endif  // YOGA

}  // namespace Yoga2
}  // namespace AS

