//
//  ASTextLayout.h
//  Texture
//
//  Copyright (c) 2014-present, Facebook, Inc.  All rights reserved.
//  This source code is licensed under the BSD-style license found in the
//  LICENSE file in the /ASDK-Licenses directory of this source tree. An additional
//  grant of patent rights can be found in the PATENTS file in the same directory.
//
//  Modifications to this file made after 4/13/2017 are: Copyright (c) through the present,
//  Pinterest, Inc.  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

#import "ASTextDebugOption.h"
#import "ASTextLine.h"
#import "ASTextInput.h"

@protocol ASTextLinePositionModifier;

NS_ASSUME_NONNULL_BEGIN

/**
 The max text container size in layout.
 */
extern const CGSize ASTextContainerMaxSize;

/**
 The ASTextContainer class defines a region in which text is laid out.
 ASTextLayout class uses one or more ASTextContainer objects to generate layouts.
 
 A ASTextContainer defines rectangular regions (`size` and `insets`) or
 nonrectangular shapes (`path`), and you can define exclusion paths inside the
 text container's bounding rectangle so that text flows around the exclusion
 path as it is laid out.
 
 All methods in this class is thread-safe.
 
 Example:
 
 ┌─────────────────────────────┐  <------- container
 │                             │
 │    asdfasdfasdfasdfasdfa   <------------ container insets
 │    asdfasdfa   asdfasdfa    │
 │    asdfas         asdasd    │
 │    asdfa        <----------------------- container exclusion path
 │    asdfas         adfasd    │
 │    asdfasdfa   asdfasdfa    │
 │    asdfasdfasdfasdfasdfa    │
 │                             │
 └─────────────────────────────┘
 */
@interface ASTextContainer : NSObject <NSCoding, NSCopying>

/// Creates a container with the specified size. @param size The size.
+ (instancetype)containerWithSize:(CGSize)size NS_RETURNS_RETAINED;

/// Creates a container with the specified size and insets. @param size The size. @param insets The text insets.
+ (instancetype)containerWithSize:(CGSize)size insets:(UIEdgeInsets)insets NS_RETURNS_RETAINED;

/// Creates a container with the specified path. @param path The path.
+ (instancetype)containerWithPath:(nullable UIBezierPath *)path NS_RETURNS_RETAINED;

/// The constrained size. (if the size is larger than ASTextContainerMaxSize, it will be clipped)
@property CGSize size;

/// The insets for constrained size. The inset value should not be negative. Default is UIEdgeInsetsZero.
@property UIEdgeInsets insets;

/// Custom constrained path. Set this property to ignore `size` and `insets`. Default is nil.
@property (nullable, copy) UIBezierPath *path;

/// An array of `UIBezierPath` for path exclusion. Default is nil.
@property (nullable, copy) NSArray<UIBezierPath *> *exclusionPaths;

/// Path line width. Default is 0;
@property CGFloat pathLineWidth;

/// YES:(PathFillEvenOdd) Text is filled in the area that would be painted if the path were given to CGContextEOFillPath.
/// NO: (PathFillWindingNumber) Text is fill in the area that would be painted if the path were given to CGContextFillPath.
/// Default is YES;
@property (getter=isPathFillEvenOdd) BOOL pathFillEvenOdd;

/// Whether the text is vertical form (may used for CJK text layout). Default is NO.
@property (getter=isVerticalForm) BOOL verticalForm;

/// Maximum number of rows, 0 means no limit. Default is 0.
@property NSUInteger maximumNumberOfRows;

/// The line truncation type, default is none.
@property ASTextTruncationType truncationType;

/// The truncation token. If nil, the layout will use "…" instead. Default is nil.
@property (nullable, copy) NSAttributedString *truncationToken;

/// This modifier is applied to the lines before the layout is completed,
/// give you a chance to modify the line position. Default is nil.
@property (nullable, copy) id<ASTextLinePositionModifier> linePositionModifier;
@end


/**
 The ASTextLinePositionModifier protocol declares the required method to modify
 the line position in text layout progress. See `ASTextLinePositionSimpleModifier` for example.
 */
@protocol ASTextLinePositionModifier <NSObject, NSCopying>
@required
/**
 This method will called before layout is completed. The method should be thread-safe.
 @param lines     An array of ASTextLine.
 @param text      The full text.
 @param container The layout container.
 */
- (void)modifyLines:(NSArray<ASTextLine *> *)lines fromText:(NSAttributedString *)text inContainer:(ASTextContainer *)container;
@end


/**
 A simple implementation of `ASTextLinePositionModifier`. It can fix each line's position
 to a specified value, lets each line of height be the same.
 */
@interface ASTextLinePositionSimpleModifier : NSObject <ASTextLinePositionModifier>
@property CGFloat fixedLineHeight; ///< The fixed line height (distance between two baseline).
@end



/**
 ASTextLayout class is a readonly class stores text layout result.
 All the property in this class is readonly, and should not be changed.
 The methods in this class is thread-safe (except some of the draw methods).
 
 example: (layout with a circle exclusion path)
 
 ┌──────────────────────────┐  <------ container
 │ [--------Line0--------]  │  <- Row0
 │ [--------Line1--------]  │  <- Row1
 │ [-Line2-]     [-Line3-]  │  <- Row2
 │ [-Line4]       [Line5-]  │  <- Row3
 │ [-Line6-]     [-Line7-]  │  <- Row4
 │ [--------Line8--------]  │  <- Row5
 │ [--------Line9--------]  │  <- Row6
 └──────────────────────────┘
 */
@interface ASTextLayout : NSObject <NSCopying>


#pragma mark - Generate text layout
///=============================================================================
/// @name Generate text layout
///=============================================================================

/**
 Generate a layout with the given container size and text.
 
 @param size The text container's size
 @param text The text (if nil, returns nil).
 @return A new layout, or nil when an error occurs.
 */
+ (nullable ASTextLayout *)layoutWithContainerSize:(CGSize)size text:(NSAttributedString *)text;

/**
 Generate a layout with the given container and text.
 
 @param container The text container (if nil, returns nil).
 @param text      The text (if nil, returns nil).
 @return A new layout, or nil when an error occurs.
 */
+ (nullable ASTextLayout *)layoutWithContainer:(ASTextContainer *)container text:(NSAttributedString *)text;

/**
 Generate a layout with the given container and text.
 
 @param container The text container (if nil, returns nil).
 @param text      The text (if nil, returns nil).
 @param range     The text range (if out of range, returns nil). If the
 length of the range is 0, it means the length is no limit.
 @return A new layout, or nil when an error occurs.
 */
+ (nullable ASTextLayout *)layoutWithContainer:(ASTextContainer *)container text:(NSAttributedString *)text range:(NSRange)range;

/**
 Generate layouts with the given containers and text.
 
 @param containers An array of ASTextContainer object (if nil, returns nil).
 @param text       The text (if nil, returns nil).
 @return An array of ASTextLayout object (the count is same as containers),
 or nil when an error occurs.
 */
+ (nullable NSArray<ASTextLayout *> *)layoutWithContainers:(NSArray<ASTextContainer *> *)containers
                                                      text:(NSAttributedString *)text;

/**
 Generate layouts with the given containers and text.
 
 @param containers An array of ASTextContainer object (if nil, returns nil).
 @param text       The text (if nil, returns nil).
 @param range      The text range (if out of range, returns nil). If the
 length of the range is 0, it means the length is no limit.
 @return An array of ASTextLayout object (the count is same as containers),
 or nil when an error occurs.
 */
+ (nullable NSArray<ASTextLayout *> *)layoutWithContainers:(NSArray<ASTextContainer *> *)containers
                                                      text:(NSAttributedString *)text
                                                     range:(NSRange)range;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;


#pragma mark - Text layout attributes
///=============================================================================
/// @name Text layout attributes
///=============================================================================

///< The text container
@property (nonatomic, readonly) ASTextContainer *container;
///< The full text
@property (nonatomic, readonly) NSAttributedString *text;
///< The text range in full text
@property (nonatomic, readonly) NSRange range;
///< CTFrameSetter
@property (nonatomic, readonly) CTFramesetterRef frameSetter;
///< CTFrame
@property (nonatomic, readonly) CTFrameRef frame;
///< Array of `ASTextLine`, no truncated
@property (nonatomic, readonly) NSArray<ASTextLine *> *lines;
///< ASTextLine with truncated token, or nil
@property (nullable, nonatomic, readonly) ASTextLine *truncatedLine;
///< Array of `ASTextAttachment`
@property (nullable, nonatomic, readonly) NSArray<ASTextAttachment *> *attachments;
///< Array of NSRange(wrapped by NSValue) in text
@property (nullable, nonatomic, readonly) NSArray<NSValue *> *attachmentRanges;
///< Array of CGRect(wrapped by NSValue) in container
@property (nullable, nonatomic, readonly) NSArray<NSValue *> *attachmentRects;
///< Set of Attachment (UIImage/UIView/CALayer)
@property (nullable, nonatomic, readonly) NSSet *attachmentContentsSet;
///< Number of rows
@property (nonatomic, readonly) NSUInteger rowCount;
///< Visible text range
@property (nonatomic, readonly) NSRange visibleRange;
///< Bounding rect (glyphs)
@property (nonatomic, readonly) CGRect textBoundingRect;
///< Bounding size (glyphs and insets, ceil to pixel)
@property (nonatomic, readonly) CGSize textBoundingSize;
///< Has highlight attribute
@property (nonatomic, readonly) BOOL containsHighlight;
///< Has block border attribute
@property (nonatomic, readonly) BOOL needDrawBlockBorder;
///< Has background border attribute
@property (nonatomic, readonly) BOOL needDrawBackgroundBorder;
///< Has shadow attribute
@property (nonatomic, readonly) BOOL needDrawShadow;
///< Has underline attribute
@property (nonatomic, readonly) BOOL needDrawUnderline;
///< Has visible text
@property (nonatomic, readonly) BOOL needDrawText;
///< Has attachment attribute
@property (nonatomic, readonly) BOOL needDrawAttachment;
///< Has inner shadow attribute
@property (nonatomic, readonly) BOOL needDrawInnerShadow;
///< Has strickthrough attribute
@property (nonatomic, readonly) BOOL needDrawStrikethrough;
///< Has border attribute
@property (nonatomic, readonly) BOOL needDrawBorder;


#pragma mark - Query information from text layout
///=============================================================================
/// @name Query information from text layout
///=============================================================================

/**
 The first line index for row.
 
 @param row  A row index.
 @return The line index, or NSNotFound if not found.
 */
- (NSUInteger)lineIndexForRow:(NSUInteger)row;

/**
 The number of lines for row.
 
 @param row  A row index.
 @return The number of lines, or NSNotFound when an error occurs.
 */
- (NSUInteger)lineCountForRow:(NSUInteger)row;

/**
 The row index for line.
 
 @param line A row index.
 
 @return The row index, or NSNotFound if not found.
 */
- (NSUInteger)rowIndexForLine:(NSUInteger)line;

/**
 The line index for a specified point.
 
 @discussion It returns NSNotFound if there's no text at the point.
 
 @param point  A point in the container.
 @return The line index, or NSNotFound if not found.
 */
- (NSUInteger)lineIndexForPoint:(CGPoint)point;

/**
 The line index closest to a specified point.
 
 @param point  A point in the container.
 @return The line index, or NSNotFound if no line exist in layout.
 */
- (NSUInteger)closestLineIndexForPoint:(CGPoint)point;

/**
 The offset in container for a text position in a specified line.
 
 @discussion The offset is the text position's baseline point.x.
 If the container is vertical form, the offset is the baseline point.y;
 
 @param position   The text position in string.
 @param lineIndex  The line index.
 @return The offset in container, or CGFLOAT_MAX if not found.
 */
- (CGFloat)offsetForTextPosition:(NSUInteger)position lineIndex:(NSUInteger)lineIndex;

/**
 The text position for a point in a specified line.
 
 @discussion This method just call CTLineGetStringIndexForPosition() and does
 NOT consider the emoji, line break character, binding text...
 
 @param point      A point in the container.
 @param lineIndex  The line index.
 @return The text position, or NSNotFound if not found.
 */
- (NSUInteger)textPositionForPoint:(CGPoint)point lineIndex:(NSUInteger)lineIndex;

/**
 The closest text position to a specified point.
 
 @discussion This method takes into account the restrict of emoji, line break
 character, binding text and text affinity.
 
 @param point  A point in the container.
 @return A text position, or nil if not found.
 */
- (nullable ASTextPosition *)closestPositionToPoint:(CGPoint)point;

/**
 Returns the new position when moving selection grabber in text view.
 
 @discussion There are two grabber in the text selection period, user can only
 move one grabber at the same time.
 
 @param point          A point in the container.
 @param oldPosition    The old text position for the moving grabber.
 @param otherPosition  The other position in text selection view.
 
 @return A text position, or nil if not found.
 */
- (nullable ASTextPosition *)positionForPoint:(CGPoint)point
                                  oldPosition:(ASTextPosition *)oldPosition
                                otherPosition:(ASTextPosition *)otherPosition;

/**
 Returns the character or range of characters that is at a given point in the container.
 If there is no text at the point, returns nil.
 
 @discussion This method takes into account the restrict of emoji, line break
 character, binding text and text affinity.
 
 @param point  A point in the container.
 @return An object representing a range that encloses a character (or characters)
 at point. Or nil if not found.
 */
- (nullable ASTextRange *)textRangeAtPoint:(CGPoint)point;

/**
 Returns the closest character or range of characters that is at a given point in
 the container.
 
 @discussion This method takes into account the restrict of emoji, line break
 character, binding text and text affinity.
 
 @param point  A point in the container.
 @return An object representing a range that encloses a character (or characters)
 at point. Or nil if not found.
 */
- (nullable ASTextRange *)closestTextRangeAtPoint:(CGPoint)point;

/**
 If the position is inside an emoji, composed character sequences, line break '\\r\\n'
 or custom binding range, then returns the range by extend the position. Otherwise,
 returns a zero length range from the position.
 
 @param position A text-position object that identifies a location in layout.
 
 @return A text-range object that extend the position. Or nil if an error occurs
 */
- (nullable ASTextRange *)textRangeByExtendingPosition:(ASTextPosition *)position;

/**
 Returns a text range at a given offset in a specified direction from another
 text position to its farthest extent in a certain direction of layout.
 
 @param position  A text-position object that identifies a location in layout.
 @param direction A constant that indicates a direction of layout (right, left, up, down).
 @param offset    A character offset from position.
 
 @return A text-range object that represents the distance from position to the
 farthest extent in direction. Or nil if an error occurs.
 */
- (nullable ASTextRange *)textRangeByExtendingPosition:(ASTextPosition *)position
                                           inDirection:(UITextLayoutDirection)direction
                                                offset:(NSInteger)offset;

/**
 Returns the line index for a given text position.
 
 @discussion This method takes into account the text affinity.
 
 @param position A text-position object that identifies a location in layout.
 @return The line index, or NSNotFound if not found.
 */
- (NSUInteger)lineIndexForPosition:(ASTextPosition *)position;

/**
 Returns the baseline position for a given text position.
 
 @param position An object that identifies a location in the layout.
 @return The baseline position for text, or CGPointZero if not found.
 */
- (CGPoint)linePositionForPosition:(ASTextPosition *)position;

/**
 Returns a rectangle used to draw the caret at a given insertion point.
 
 @param position An object that identifies a location in the layout.
 @return A rectangle that defines the area for drawing the caret. The width is
 always zero in normal container, the height is always zero in vertical form container.
 If not found, it returns CGRectNull.
 */
- (CGRect)caretRectForPosition:(ASTextPosition *)position;

/**
 Returns the first rectangle that encloses a range of text in the layout.
 
 @param range An object that represents a range of text in layout.
 
 @return The first rectangle in a range of text. You might use this rectangle to
 draw a correction rectangle. The "first" in the name refers the rectangle
 enclosing the first line when the range encompasses multiple lines of text.
 If not found, it returns CGRectNull.
 */
- (CGRect)firstRectForRange:(ASTextRange *)range;

/**
 Returns the rectangle union that encloses a range of text in the layout.
 
 @param range An object that represents a range of text in layout.
 
 @return A rectangle that defines the area than encloses the range.
 If not found, it returns CGRectNull.
 */
- (CGRect)rectForRange:(ASTextRange *)range;

/**
 Returns an array of selection rects corresponding to the range of text.
 The start and end rect can be used to show grabber.
 
 @param range An object representing a range in text.
 @return An array of `ASTextSelectionRect` objects that encompass the selection.
 If not found, the array is empty.
 */
- (NSArray<ASTextSelectionRect *> *)selectionRectsForRange:(ASTextRange *)range;

/**
 Returns an array of selection rects corresponding to the range of text.
 
 @param range An object representing a range in text.
 @return An array of `ASTextSelectionRect` objects that encompass the selection.
 If not found, the array is empty.
 */
- (NSArray<ASTextSelectionRect *> *)selectionRectsWithoutStartAndEndForRange:(ASTextRange *)range;

/**
 Returns the start and end selection rects corresponding to the range of text.
 The start and end rect can be used to show grabber.
 
 @param range An object representing a range in text.
 @return An array of `ASTextSelectionRect` objects contains the start and end to
 the selection. If not found, the array is empty.
 */
- (NSArray<ASTextSelectionRect *> *)selectionRectsWithOnlyStartAndEndForRange:(ASTextRange *)range;


#pragma mark - Draw text layout
///=============================================================================
/// @name Draw text layout
///=============================================================================

/**
 Draw the layout and show the attachments.
 
 @discussion If the `view` parameter is not nil, then the attachment views will
 add to this `view`, and if the `layer` parameter is not nil, then the attachment
 layers will add to this `layer`.
 
 @warning This method should be called on main thread if `view` or `layer` parameter
 is not nil and there's UIView or CALayer attachments in layout.
 Otherwise, it can be called on any thread.
 
 @param context The draw context. Pass nil to avoid text and image drawing.
 @param size    The context size.
 @param point   The point at which to draw the layout.
 @param view    The attachment views will add to this view.
 @param layer   The attachment layers will add to this layer.
 @param debug   The debug option. Pass nil to avoid debug drawing.
 @param cancel  The cancel checker block. It will be called in drawing progress.
 If it returns YES, the further draw progress will be canceled.
 Pass nil to ignore this feature.
 */
- (void)drawInContext:(nullable CGContextRef)context
                 size:(CGSize)size
                point:(CGPoint)point
                 view:(nullable UIView *)view
                layer:(nullable CALayer *)layer
                debug:(nullable ASTextDebugOption *)debug
               cancel:(nullable BOOL (^)(void))cancel;

/**
 Draw the layout text and image (without view or layer attachments).
 
 @discussion This method is thread safe and can be called on any thread.
 
 @param context The draw context. Pass nil to avoid text and image drawing.
 @param size    The context size.
 @param debug   The debug option. Pass nil to avoid debug drawing.
 */
- (void)drawInContext:(nullable CGContextRef)context
                 size:(CGSize)size
                debug:(nullable ASTextDebugOption *)debug;

@end

NS_ASSUME_NONNULL_END
