//
//  NSValue+ASBoxing.mm
//  AsyncDisplayKit
//
//  Created by Adlai Holler on 5/6/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "NSValue+ASBoxing.h"
#import <AsyncDisplayKit/ASAssert.h>
#import <AsyncDisplayKit/ASHashing.h>
#import <functional>

AS_SUBCLASSING_RESTRICTED
@interface ASCXXValue : NSValue {
  @package
  void (^_deallocBlock)();
  const void *_ptr;
}

@end

@implementation NSValue (ASBoxing)

+ (NSValue *)_as_valueWithPointer:(const void *)pointer deallocBlock:(void(^)())deallocBlock
{
  ASCXXValue *value = [[ASCXXValue alloc] init];
  value->_ptr = pointer;
  value->_deallocBlock = deallocBlock;
  return value;
}

@end


@implementation ASCXXValue

- (void)encodeWithCoder:(NSCoder *)aCoder
{
  ASDisplayNodeFailAssert(@"Can't encode C++ values.");
}

- (void)getValue:(void *)value
{
  *(const void **)value = _ptr;
}

- (const char *)objCType
{
  return @encode(void*);
}

- (id)copyWithZone:(NSZone *)zone
{
  // We are immutable, and we can't have our bytes getting copied.
  return self;
}

- (void)setDeallocationBlock:(void (^)(void))deallocBlock
{
  _deallocBlock = deallocBlock;
}

- (void)dealloc
{
  _deallocBlock();
}

@end

