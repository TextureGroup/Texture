//
//  ASTextLine.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASTextLine.h>
#import <AsyncDisplayKit/ASTextUtilities.h>

@implementation ASTextLine {
  CGFloat _firstGlyphPos; // first glyph position for baseline, typically 0.
}

+ (instancetype)lineWithCTLine:(CTLineRef)CTLine position:(CGPoint)position vertical:(BOOL)isVertical NS_RETURNS_RETAINED {
  if (!CTLine) return nil;
  ASTextLine *line = [self new];
  line->_position = position;
  line->_vertical = isVertical;
  [line setCTLine:CTLine];
  return line;
}

- (void)dealloc {
  if (_CTLine) CFRelease(_CTLine);
}

- (void)setCTLine:(_Nonnull CTLineRef)CTLine {
  if (_CTLine != CTLine) {
    if (CTLine) CFRetain(CTLine);
    if (_CTLine) CFRelease(_CTLine);
    _CTLine = CTLine;
    if (_CTLine) {
      _lineWidth = CTLineGetTypographicBounds(_CTLine, &_ascent, &_descent, &_leading);
      CFRange range = CTLineGetStringRange(_CTLine);
      _range = NSMakeRange(range.location, range.length);
      if (CTLineGetGlyphCount(_CTLine) > 0) {
        CFArrayRef runs = CTLineGetGlyphRuns(_CTLine);
        CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(runs, 0);
        CGPoint pos;
        CTRunGetPositions(run, CFRangeMake(0, 1), &pos);
        _firstGlyphPos = pos.x;
      } else {
        _firstGlyphPos = 0;
      }
      _trailingWhitespaceWidth = CTLineGetTrailingWhitespaceWidth(_CTLine);
    } else {
      _lineWidth = _ascent = _descent = _leading = _firstGlyphPos = _trailingWhitespaceWidth = 0;
      _range = NSMakeRange(0, 0);
    }
    [self reloadBounds];
  }
}

- (void)setPosition:(CGPoint)position {
  _position = position;
  [self reloadBounds];
}

- (void)reloadBounds {
  if (_vertical) {
    _bounds = CGRectMake(_position.x - _descent, _position.y, _ascent + _descent, _lineWidth);
    _bounds.origin.y += _firstGlyphPos;
  } else {
    _bounds = CGRectMake(_position.x, _position.y - _ascent, _lineWidth, _ascent + _descent);
    _bounds.origin.x += _firstGlyphPos;
  }
  
  _attachments = nil;
  _attachmentRanges = nil;
  _attachmentRects = nil;
  if (!_CTLine) return;
  CFArrayRef runs = CTLineGetGlyphRuns(_CTLine);
  NSUInteger runCount = CFArrayGetCount(runs);
  if (runCount == 0) return;
  
  NSMutableArray<ASTextAttachment *> *attachments = nil;
  NSMutableArray<NSValue *> *attachmentRanges = nil;
  NSMutableArray<NSValue *> *attachmentRects = nil;
  for (NSUInteger r = 0; r < runCount; r++) {
    CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(runs, r);
    CFIndex glyphCount = CTRunGetGlyphCount(run);
    if (glyphCount == 0) continue;
    NSDictionary *attrs = (id)CTRunGetAttributes(run);
    ASTextAttachment *attachment = attrs[ASTextAttachmentAttributeName];
    if (attachment) {
      CGPoint runPosition = CGPointZero;
      CTRunGetPositions(run, CFRangeMake(0, 1), &runPosition);
      
      CGFloat ascent, descent, leading, runWidth;
      CGRect runTypoBounds;
      runWidth = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, &leading);
      
      if (_vertical) {
        ASTEXT_SWAP(runPosition.x, runPosition.y);
        runPosition.y = _position.y + runPosition.y;
        runTypoBounds = CGRectMake(_position.x + runPosition.x - descent, runPosition.y , ascent + descent, runWidth);
      } else {
        runPosition.x += _position.x;
        runPosition.y = _position.y - runPosition.y;
        runTypoBounds = CGRectMake(runPosition.x, runPosition.y - ascent, runWidth, ascent + descent);
      }
      
      NSRange runRange = ASTextNSRangeFromCFRange(CTRunGetStringRange(run));
      if (!attachments) {
        attachments = [[NSMutableArray alloc] init];
        attachmentRanges = [[NSMutableArray alloc] init];
        attachmentRects = [[NSMutableArray alloc] init];
      }
      [attachments addObject:attachment];
      [attachmentRanges addObject:[NSValue valueWithRange:runRange]];
      [attachmentRects addObject:[NSValue valueWithCGRect:runTypoBounds]];
    }
  }
  _attachments = attachments;
  _attachmentRanges = attachmentRanges;
  _attachmentRects = attachmentRects;
}

- (CGSize)size {
  return _bounds.size;
}

- (CGFloat)width {
  return CGRectGetWidth(_bounds);
}

- (CGFloat)height {
  return CGRectGetHeight(_bounds);
}

- (CGFloat)top {
  return CGRectGetMinY(_bounds);
}

- (CGFloat)bottom {
  return CGRectGetMaxY(_bounds);
}

- (CGFloat)left {
  return CGRectGetMinX(_bounds);
}

- (CGFloat)right {
  return CGRectGetMaxX(_bounds);
}

- (NSString *)description {
  NSMutableString *desc = @"".mutableCopy;
  NSRange range = self.range;
  [desc appendFormat:@"<ASTextLine: %p> row:%ld range:%tu,%tu", self, (long)self.row, range.location, range.length];
  [desc appendFormat:@" position:%@",NSStringFromCGPoint(self.position)];
  [desc appendFormat:@" bounds:%@",NSStringFromCGRect(self.bounds)];
  return desc;
}

@end


@implementation ASTextRunGlyphRange
+ (instancetype)rangeWithRange:(NSRange)range drawMode:(ASTextRunGlyphDrawMode)mode NS_RETURNS_RETAINED {
  ASTextRunGlyphRange *one = [self new];
  one.glyphRangeInRun = range;
  one.drawMode = mode;
  return one;
}
@end
