//
//  ASTextRunDelegate.m
//  ASText <https://github.com/ibireme/ASText>
//
//  Created by ibireme on 14/10/14.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <AsyncDisplayKit/ASTextRunDelegate.h>

static void DeallocCallback(void *ref) {
  ASTextRunDelegate *self = (__bridge_transfer ASTextRunDelegate *)(ref);
  self = nil; // release
}

static CGFloat GetAscentCallback(void *ref) {
  ASTextRunDelegate *self = (__bridge ASTextRunDelegate *)(ref);
  return self.ascent;
}

static CGFloat GetDecentCallback(void *ref) {
  ASTextRunDelegate *self = (__bridge ASTextRunDelegate *)(ref);
  return self.descent;
}

static CGFloat GetWidthCallback(void *ref) {
  ASTextRunDelegate *self = (__bridge ASTextRunDelegate *)(ref);
  return self.width;
}

@implementation ASTextRunDelegate

- (CTRunDelegateRef)CTRunDelegate CF_RETURNS_RETAINED {
  CTRunDelegateCallbacks callbacks;
  callbacks.version = kCTRunDelegateCurrentVersion;
  callbacks.dealloc = DeallocCallback;
  callbacks.getAscent = GetAscentCallback;
  callbacks.getDescent = GetDecentCallback;
  callbacks.getWidth = GetWidthCallback;
  return CTRunDelegateCreate(&callbacks, (__bridge_retained void *)(self.copy));
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  [aCoder encodeObject:@(_ascent) forKey:@"ascent"];
  [aCoder encodeObject:@(_descent) forKey:@"descent"];
  [aCoder encodeObject:@(_width) forKey:@"width"];
  [aCoder encodeObject:_userInfo forKey:@"userInfo"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super init];
  _ascent = ((NSNumber *)[aDecoder decodeObjectForKey:@"ascent"]).floatValue;
  _descent = ((NSNumber *)[aDecoder decodeObjectForKey:@"descent"]).floatValue;
  _width = ((NSNumber *)[aDecoder decodeObjectForKey:@"width"]).floatValue;
  _userInfo = [aDecoder decodeObjectForKey:@"userInfo"];
  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  __typeof__(self) one = [self.class new];
  one.ascent = self.ascent;
  one.descent = self.descent;
  one.width = self.width;
  one.userInfo = self.userInfo;
  return one;
}

@end
