//
//  ASCornerLayoutSpec.mm
//  Texture
//
//  Created by huangkun on 2017/10/22.
//  Copyright © 2017年 AsyncDisplayKit. All rights reserved.
//

#import <AsyncDisplayKit/ASCornerLayoutSpec.h>
#import <AsyncDisplayKit/ASLayout.h>
#import <AsyncDisplayKit/ASLayoutSpec+Subclasses.h>
#import <AsyncDisplayKit/ASDisplayNode.h>

CGPoint as_calculatedCornerOriginIn(CGRect baseRect, CGSize cornerSize, ASCornerLayoutLocation cornerLocation, CGPoint offset) {
    
    CGPoint cornerOrigin = CGPointZero;
    CGPoint baseOrigin = baseRect.origin;
    CGSize baseSize = baseRect.size;
    
    switch (cornerLocation) {
        case ASCornerLayoutLocationTopLeft:
            cornerOrigin.x = baseOrigin.x - cornerSize.width / 2;
            cornerOrigin.y = baseOrigin.y - cornerSize.height / 2;
            break;
        case ASCornerLayoutLocationTopRight:
            cornerOrigin.x = baseOrigin.x + baseSize.width - cornerSize.width / 2;
            cornerOrigin.y = baseOrigin.y - cornerSize.height / 2;
            break;
        case ASCornerLayoutLocationBottomLeft:
            cornerOrigin.x = baseOrigin.x - cornerSize.width / 2;
            cornerOrigin.y = baseOrigin.y + baseSize.height - cornerSize.height / 2;
            break;
        case ASCornerLayoutLocationBottomRight:
            cornerOrigin.x = baseOrigin.x + baseSize.width - cornerSize.width / 2;
            cornerOrigin.y = baseOrigin.y + baseSize.height - cornerSize.height / 2;
            break;
    }
    
    cornerOrigin.x += offset.x;
    cornerOrigin.y += offset.y;
    
    return cornerOrigin;
}

static NSUInteger const kBaseChildIndex = 0;
static NSUInteger const kCornerChildIndex = 1;

@interface ASCornerLayoutSpec()
@end

@implementation ASCornerLayoutSpec

- (instancetype)initWithChild:(id <ASLayoutElement>)child corner:(id <ASLayoutElement>)corner location:(ASCornerLayoutLocation)location {
    self = [super init];
    if (self) {
        self.child = child;
        self.corner = corner;
        self.cornerLocation = location;
    }
    return self;
}

+ (instancetype)cornerLayoutSpecWithChild:(id <ASLayoutElement>)child corner:(id <ASLayoutElement>)corner location:(ASCornerLayoutLocation)location {
    return [[self alloc] initWithChild:child corner:corner location:location];
}

#pragma mark - Children

- (void)setChild:(id<ASLayoutElement>)child {
    ASDisplayNodeAssertNotNil(child, @"Child shouldn't be nil.");
    [super setChild:child atIndex:kBaseChildIndex];
}

- (id<ASLayoutElement>)child {
    return [super childAtIndex:kBaseChildIndex];
}

- (void)setCorner:(id<ASLayoutElement>)corner {
    ASDisplayNodeAssertNotNil(corner, @"Corner element cannot be nil.");
    [super setChild:corner atIndex:kCornerChildIndex];
}

- (id<ASLayoutElement>)corner {
    return [super childAtIndex:kCornerChildIndex];
}

#pragma mark - Calculation

- (ASLayout *)calculateLayoutThatFits:(ASSizeRange)constrainedSize {
    id <ASLayoutElement> child = self.child;
    id <ASLayoutElement> corner = self.corner;
    
    // If element is invalid, throw exceptions.
    [self validateElement:child];
    [self validateElement:corner];
    
    // Prepare Layout
    NSMutableArray <ASLayout *> *sublayouts = [NSMutableArray arrayWithCapacity:2];
    
    // Layout child
    ASLayout *childLayout = [child layoutThatFits:constrainedSize parentSize:constrainedSize.max];
    childLayout.position = child.style.layoutPosition;
    [sublayouts addObject:childLayout];
    
    // Layout corner
    ASLayout *cornerLayout = [corner layoutThatFits:constrainedSize parentSize:constrainedSize.max];
    cornerLayout.position = corner.style.layoutPosition;
    [sublayouts addObject:cornerLayout];
    
    // Calculate corner's position
    CGRect childRect = (CGRect){ (CGPoint)childLayout.position, (CGSize)childLayout.size };
    CGRect cornerRect = (CGRect){ (CGPoint)cornerLayout.position, (CGSize)cornerLayout.size };
    CGPoint cornerOrigin = as_calculatedCornerOriginIn(childRect, cornerRect.size, _cornerLocation, _offset);
    
    // Update corner's position
    cornerRect.origin = cornerOrigin;
    cornerLayout.position = cornerOrigin;
    corner.style.layoutPosition = cornerOrigin;

    // Calculate Size
    CGSize size = childLayout.size;
    if (_includeCornerForSizeCalculation) {
        CGRect unionRect = CGRectUnion(childRect, cornerRect);
        size = ASSizeRangeClamp(constrainedSize, unionRect.size);
    }
    
    return [ASLayout layoutWithLayoutElement:self size:size sublayouts:sublayouts];
}

- (BOOL)validateElement:(id <ASLayoutElement>)element {
    
    // Validate non-nil element
    if (element == nil) {
        NSString *failedReason = [NSString stringWithFormat:@"[%@]: Must have a non-nil child/corner for layout calculation.", self.class];
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:failedReason userInfo:nil];
        return NO;
    }
    
    // Validate preferredSize if needed
    CGSize size = element.style.preferredSize;
    if (!CGSizeEqualToSize(size, CGSizeZero) && !ASIsCGSizeValidForSize(size) && (size.width < 0 || (size.height < 0))) {
        NSString *failedReason = [NSString stringWithFormat:@"[%@]: Should give a valid preferredSize value for %@ before corner's position calculation.", self.class, element];
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:failedReason userInfo:nil];
        return NO;
    }
    
    return YES;
}

@end
