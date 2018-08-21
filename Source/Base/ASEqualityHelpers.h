//
//  ASEqualityHelpers.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASBaseDefines.h>

/**
 @abstract Correctly equates two objects, including cases where both objects are nil. The latter is a case where `isEqual:` fails.
 @param obj The first object in the comparison. Can be nil.
 @param otherObj The second object in the comparison. Can be nil.
 @result YES if the objects are equal, including cases where both object are nil.
 */
ASDISPLAYNODE_INLINE BOOL ASObjectIsEqual(id<NSObject> obj, id<NSObject> otherObj)
{
  return obj == otherObj || [obj isEqual:otherObj];
}
