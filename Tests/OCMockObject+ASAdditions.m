//
//  OCMockObject+ASAdditions.m
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <OCMock/OCMockObject.h>
#import "ASInternalHelpers.h"
#import <objc/runtime.h>

@implementation OCMockObject (ASAdditions)

+ (void)load
{
  // Swap [OCProtocolMockObject respondsToSelector:] with [(self) swizzled_protocolMockRespondsToSelector:]
  Method orig = class_getInstanceMethod(OCMockObject.protocolMockObjectClass, @selector(respondsToSelector:));
  Method new = class_getInstanceMethod(self, @selector(swizzled_protocolMockRespondsToSelector:));
  method_exchangeImplementations(orig, new);
}

/// Since OCProtocolMockObject is private, use this method to get the class.
+ (Class)protocolMockObjectClass
{
  static Class c;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    c = NSClassFromString(@"OCProtocolMockObject");
    NSAssert(c != Nil, nil);
  });
  return c;
}

/// Whether the user has opted-in to specify which optional methods are implemented for this object.
- (BOOL)hasSpecifiedOptionalProtocolMethods
{
  return objc_getAssociatedObject(self, @selector(optionalImplementedMethods)) != nil;
}

/// The optional protocol selectors the user has added via -addImplementedOptionalProtocolMethods:
- (NSMutableSet<NSString *> *)optionalImplementedMethods
{
  NSMutableSet *result = objc_getAssociatedObject(self, _cmd);
  if (result == nil) {
    result = [NSMutableSet set];
    objc_setAssociatedObject(self, _cmd, result, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  return result;
}

- (void)addImplementedOptionalProtocolMethods:(SEL)aSelector, ...
{
  // Can't use isKindOfClass: since we're a proxy.
  NSAssert(object_getClass(self) == OCMockObject.protocolMockObjectClass, @"Cannot call this method on non-protocol mocks.");
  NSMutableSet *methods = self.optionalImplementedMethods;
  
  // First arg is not returned by va_arg, needs to be handled separately.
  if (aSelector != NULL) {
    [methods addObject:NSStringFromSelector(aSelector)];
  }
  
  va_list args;
  va_start(args, aSelector);
  SEL s;
  while((s = va_arg(args, SEL)))
  {
    [methods addObject:NSStringFromSelector(s)];
  }
  va_end(args);
}

- (BOOL)implementsOptionalProtocolMethod:(SEL)aSelector
{
  NSAssert(self.hasSpecifiedOptionalProtocolMethods, @"Shouldn't call this method if the user hasn't opted-in to specifying optional protocol methods.");
  
  // Check our collection first. It'll be in here if they explicitly marked the method as implemented.
  for (NSString *str in self.optionalImplementedMethods) {
    if (sel_isEqual(NSSelectorFromString(str), aSelector)) {
      return YES;
    }
  }
  
  // If they didn't explicitly mark it implemented, check if they stubbed/expected it. That counts too, but
  // we still want them to have the option to declare that the method exists without
  // stubbing it or making an expectation, so the rest of OCMock's mechanisms work as expected.
  return [self handleSelector:aSelector];
}

- (BOOL)swizzled_protocolMockRespondsToSelector:(SEL)aSelector
{
  // Can't use isKindOfClass: since we're a proxy.
  NSAssert(object_getClass(self) == OCMockObject.protocolMockObjectClass, @"Swizzled method should only ever be called for protocol mocks.");
  
  // If they haven't called our public method to opt-in, use the default behavior.
  if (!self.hasSpecifiedOptionalProtocolMethods) {
    return [self swizzled_protocolMockRespondsToSelector:aSelector];
  }
  
  Ivar i = class_getInstanceVariable([self class], "mockedProtocol");
  NSAssert(i != NULL, nil);
  Protocol *mockedProtocol = object_getIvar(self, i);
  NSAssert(mockedProtocol != NULL, nil);
  
  // Check if it's an optional protocol method. If not, just return the default implementation (which has now swapped).
  struct objc_method_description methodDescription;
  methodDescription = protocol_getMethodDescription(mockedProtocol, aSelector, NO, YES);
  if (methodDescription.name == NULL) {
    methodDescription = protocol_getMethodDescription(mockedProtocol, aSelector, NO, NO);
    if (methodDescription.name == NULL) {
      return [self swizzled_protocolMockRespondsToSelector:aSelector];
    }
  }
  
  // It's an optional instance or class method. Override the return value.
  return [self implementsOptionalProtocolMethod:aSelector];
}

@end
