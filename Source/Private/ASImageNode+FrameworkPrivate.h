#import <AsyncDisplayKit/ASImageNode.h>

@interface ASImageNodeDrawParameters : NSObject

// The original drawRect for the image in context for particular content mode.
@property(nonatomic, readonly) CGRect drawRect;

// The rect used for drawing image to context with borther width considered.
@property(nonatomic) CGRect adjustedDrawRect;

// The scaling ratio (backing size to bound size) for border image processor
// to properly apply image corner radius/border width
@property(nonatomic, readonly) CGFloat renderScale;

// Whether the image node will be rendered in RTL layout
@property(nonatomic, readonly) BOOL isRTL;

@end

#if YOGA
@interface ASImageNode(FrameworkPrivate)

-(void)_locked_setFlipsForRightToLeftLayoutDirection:(BOOL)flipsForRightToLeftLayoutDirection;

@end
#endif
