//
//  NSValue+ASBoxing.h
//  AsyncDisplayKit
//
//  Created by Adlai Holler on 5/6/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#ifdef __cplusplus

#import <Foundation/Foundation.h>
#import <AsyncDisplayKit/ASBaseDefines.h>

/**
 * Don't use this directly. Use the C++ functions `box` and `unbox` below.
 */
@interface NSValue (ASBoxing)

+ (NSValue *)_as_valueWithPointer:(const void *)pointer deallocBlock:(void(^)())deallocBlock;

@end

namespace AS {
  
  /**
   * Box an arbitrary type up into an NSValue. The value will be copied into the heap.
   * E.g. box((ASCrazyType){ .image = [UIImage blueColor ] })
   */
  template <typename T>
  AS_WARN_UNUSED_RESULT NSValue * box(T value) {
    // Copy the object into the heap
    // Schedule it to be deleted when this value is deallocated.
    T *heapObject = new T(value);
    return [NSValue _as_valueWithPointer:heapObject
                           deallocBlock:^{
      delete heapObject;
    }];
  }


  /**
   * Unbox an arbitrary type from the NSValue. Make sure it's the same type that was boxed.
   */
  template <typename T>
  AS_WARN_UNUSED_RESULT T unbox(NS_VALID_UNTIL_END_OF_SCOPE NSValue *object)
  {
    // Copy the object from the heap and return it.
    T *heapObject;
    [object getValue:&heapObject];
    return *heapObject;
  }
}

#endif // __cplusplus

// NOTE: Nullability annotations intentionally omitted from this file because
// they currently cause major problems for Objective-C++ functions if they're anywhere in the same file.
