//
//  ASTextKitRenderer+TextChecking.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASTextKitRenderer+TextChecking.h"

#if AS_ENABLE_TEXTNODE

#import "ASTextKitEntityAttribute.h"
#import "ASTextKitRenderer+Positioning.h"
#import "ASTextKitTailTruncater.h"

@implementation ASTextKitTextCheckingResult

{
  // Be explicit about the fact that we are overriding the super class' implementation of -range and -resultType
  // and substituting our own custom values. (We could use @synthesize to make these ivars, but our linter correctly
  // complains; it's weird to use @synthesize for properties that are redeclared on top of an original declaration in
  // the superclass. We only do it here because NSTextCheckingResult doesn't expose an initializer, which is silly.)
  NSRange _rangeOverride;
  NSTextCheckingType _resultTypeOverride;
}

- (instancetype)initWithType:(NSTextCheckingType)type
             entityAttribute:(ASTextKitEntityAttribute *)entityAttribute
                       range:(NSRange)range
{
  if ((self = [super init])) {
    _resultTypeOverride = type;
    _rangeOverride = range;
    _entityAttribute = entityAttribute;
  }
  return self;
}

- (NSTextCheckingType)resultType
{
  return _resultTypeOverride;
}

- (NSRange)range
{
  return _rangeOverride;
}

@end

@implementation ASTextKitRenderer (TextChecking)

- (NSTextCheckingResult *)textCheckingResultAtPoint:(CGPoint)point
{
  __block NSTextCheckingResult *result = nil;
  NSAttributedString *attributedString = self.attributes.attributedString;
  NSAttributedString *truncationAttributedString = self.attributes.truncationAttributedString;

  // get the index of the last character, so we can handle text in the truncation token
  __block NSRange truncationTokenRange = { NSNotFound, 0 };

  [truncationAttributedString enumerateAttribute:ASTextKitTruncationAttributeName inRange:NSMakeRange(0, truncationAttributedString.length)
                                         options:0
                                      usingBlock:^(id value, NSRange range, BOOL *stop) {
    if (value != nil && range.length > 0) {
      truncationTokenRange = range;
    }
  }];

  if (truncationTokenRange.location == NSNotFound) {
    // The truncation string didn't specify a substring which should be highlighted, so we just highlight it all
    truncationTokenRange = { 0, truncationAttributedString.length };
  }

  NSRange visibleRange = self.truncater.firstVisibleRange;
  truncationTokenRange.location += NSMaxRange(visibleRange);
  
  __block CGFloat minDistance = CGFLOAT_MAX;
  [self enumerateTextIndexesAtPosition:point usingBlock:^(NSUInteger index, CGRect glyphBoundingRect, BOOL *stop){
    if (index >= truncationTokenRange.location) {
      result = [[ASTextKitTextCheckingResult alloc] initWithType:ASTextKitTextCheckingTypeTruncation
                                                 entityAttribute:nil
                                                           range:truncationTokenRange];
    } else {
      NSRange range;
      NSDictionary *attributes = [attributedString attributesAtIndex:index effectiveRange:&range];
      ASTextKitEntityAttribute *entityAttribute = attributes[ASTextKitEntityAttributeName];
      CGFloat distance = hypot(CGRectGetMidX(glyphBoundingRect) - point.x, CGRectGetMidY(glyphBoundingRect) - point.y);
      if (entityAttribute && distance < minDistance) {
        result = [[ASTextKitTextCheckingResult alloc] initWithType:ASTextKitTextCheckingTypeEntity
                                                   entityAttribute:entityAttribute
                                                             range:range];
        minDistance = distance;
      }
    }
  }];
  return result;
}

@end

#endif
