//
//  ASTextUtilities.mm
//  Texture
//
//  Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "ASTextUtilities.h"

NSCharacterSet *ASTextVerticalFormRotateCharacterSet() {
  static NSMutableCharacterSet *set;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    set = [NSMutableCharacterSet new];
    [set addCharactersInRange:NSMakeRange(0x1100, 256)]; // Hangul Jamo
    [set addCharactersInRange:NSMakeRange(0x2460, 160)]; // Enclosed Alphanumerics
    [set addCharactersInRange:NSMakeRange(0x2600, 256)]; // Miscellaneous Symbols
    [set addCharactersInRange:NSMakeRange(0x2700, 192)]; // Dingbats
    [set addCharactersInRange:NSMakeRange(0x2E80, 128)]; // CJK Radicals Supplement
    [set addCharactersInRange:NSMakeRange(0x2F00, 224)]; // Kangxi Radicals
    [set addCharactersInRange:NSMakeRange(0x2FF0, 16)]; // Ideographic Description Characters
    [set addCharactersInRange:NSMakeRange(0x3000, 64)]; // CJK Symbols and Punctuation
    [set removeCharactersInRange:NSMakeRange(0x3008, 10)];
    [set removeCharactersInRange:NSMakeRange(0x3014, 12)];
    [set addCharactersInRange:NSMakeRange(0x3040, 96)]; // Hiragana
    [set addCharactersInRange:NSMakeRange(0x30A0, 96)]; // Katakana
    [set addCharactersInRange:NSMakeRange(0x3100, 48)]; // Bopomofo
    [set addCharactersInRange:NSMakeRange(0x3130, 96)]; // Hangul Compatibility Jamo
    [set addCharactersInRange:NSMakeRange(0x3190, 16)]; // Kanbun
    [set addCharactersInRange:NSMakeRange(0x31A0, 32)]; // Bopomofo Extended
    [set addCharactersInRange:NSMakeRange(0x31C0, 48)]; // CJK Strokes
    [set addCharactersInRange:NSMakeRange(0x31F0, 16)]; // Katakana Phonetic Extensions
    [set addCharactersInRange:NSMakeRange(0x3200, 256)]; // Enclosed CJK Letters and Months
    [set addCharactersInRange:NSMakeRange(0x3300, 256)]; // CJK Compatibility
    [set addCharactersInRange:NSMakeRange(0x3400, 2582)]; // CJK Unified Ideographs Extension A
    [set addCharactersInRange:NSMakeRange(0x4E00, 20941)]; // CJK Unified Ideographs
    [set addCharactersInRange:NSMakeRange(0xAC00, 11172)]; // Hangul Syllables
    [set addCharactersInRange:NSMakeRange(0xD7B0, 80)]; // Hangul Jamo Extended-B
    [set addCharactersInString:@""]; // U+F8FF (Private Use Area)
    [set addCharactersInRange:NSMakeRange(0xF900, 512)]; // CJK Compatibility Ideographs
    [set addCharactersInRange:NSMakeRange(0xFE10, 16)]; // Vertical Forms
    [set addCharactersInRange:NSMakeRange(0xFF00, 240)]; // Halfwidth and Fullwidth Forms
    [set addCharactersInRange:NSMakeRange(0x1F200, 256)]; // Enclosed Ideographic Supplement
    [set addCharactersInRange:NSMakeRange(0x1F300, 768)]; // Enclosed Ideographic Supplement
    [set addCharactersInRange:NSMakeRange(0x1F600, 80)]; // Emoticons (Emoji)
    [set addCharactersInRange:NSMakeRange(0x1F680, 128)]; // Transport and Map Symbols
    
    // See http://unicode-table.com/ for more information.
  });
  return set;
}

NSCharacterSet *ASTextVerticalFormRotateAndMoveCharacterSet() {
  static NSMutableCharacterSet *set;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    set = [NSMutableCharacterSet new];
    [set addCharactersInString:@"，。、．"];
  });
  return set;
}

CGRect ASTextCGRectFitWithContentMode(CGRect rect, CGSize size, UIViewContentMode mode) {
  rect = CGRectStandardize(rect);
  size.width = size.width < 0 ? -size.width : size.width;
  size.height = size.height < 0 ? -size.height : size.height;
  CGPoint center = CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
  switch (mode) {
    case UIViewContentModeScaleAspectFit:
    case UIViewContentModeScaleAspectFill: {
      if (rect.size.width < 0.01 || rect.size.height < 0.01 ||
          size.width < 0.01 || size.height < 0.01) {
        rect.origin = center;
        rect.size = CGSizeZero;
      } else {
        CGFloat scale;
        if (mode == UIViewContentModeScaleAspectFit) {
          if (size.width / size.height < rect.size.width / rect.size.height) {
            scale = rect.size.height / size.height;
          } else {
            scale = rect.size.width / size.width;
          }
        } else {
          if (size.width / size.height < rect.size.width / rect.size.height) {
            scale = rect.size.width / size.width;
          } else {
            scale = rect.size.height / size.height;
          }
        }
        size.width *= scale;
        size.height *= scale;
        rect.size = size;
        rect.origin = CGPointMake(center.x - size.width * 0.5, center.y - size.height * 0.5);
      }
    } break;
    case UIViewContentModeCenter: {
      rect.size = size;
      rect.origin = CGPointMake(center.x - size.width * 0.5, center.y - size.height * 0.5);
    } break;
    case UIViewContentModeTop: {
      rect.origin.x = center.x - size.width * 0.5;
      rect.size = size;
    } break;
    case UIViewContentModeBottom: {
      rect.origin.x = center.x - size.width * 0.5;
      rect.origin.y += rect.size.height - size.height;
      rect.size = size;
    } break;
    case UIViewContentModeLeft: {
      rect.origin.y = center.y - size.height * 0.5;
      rect.size = size;
    } break;
    case UIViewContentModeRight: {
      rect.origin.y = center.y - size.height * 0.5;
      rect.origin.x += rect.size.width - size.width;
      rect.size = size;
    } break;
    case UIViewContentModeTopLeft: {
      rect.size = size;
    } break;
    case UIViewContentModeTopRight: {
      rect.origin.x += rect.size.width - size.width;
      rect.size = size;
    } break;
    case UIViewContentModeBottomLeft: {
      rect.origin.y += rect.size.height - size.height;
      rect.size = size;
    } break;
    case UIViewContentModeBottomRight: {
      rect.origin.x += rect.size.width - size.width;
      rect.origin.y += rect.size.height - size.height;
      rect.size = size;
    } break;
    case UIViewContentModeScaleToFill:
    case UIViewContentModeRedraw:
    default: {
      rect = rect;
    }
  }
  return rect;
}
