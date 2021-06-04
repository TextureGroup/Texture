//
//  ASNodeContext+Private.h
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0

#if defined(__cplusplus)

#import <AsyncDisplayKit/ASNodeContext.h>
#import <AsyncDisplayKit/ASThread.h>

NS_ASSUME_NONNULL_BEGIN

@interface ASNodeContext () {
  // This ivar is declared public but obviously use with caution.
  // It is not in the main header because it requires C++.
@public
  AS::RecursiveMutex _mutex;
}

@end

NS_ASSUME_NONNULL_END

#endif  // defined(__cplusplus)
