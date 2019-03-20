//
//  _ASPendingState.h
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <UIKit/UIKit.h>

#import <AsyncDisplayKit/UIView+ASConvenience.h>

@protocol _ASPendingState <ASDisplayNodeViewProperties, ASDisplayProperties>

// Supports all of the properties included in the ASDisplayNodeViewProperties protocol

- (void)applyToView:(UIView *)view withSpecialPropertiesHandling:(BOOL)setFrameDirectly;
- (void)applyToLayer:(CALayer *)layer;

+ (id<_ASPendingState>)pendingViewStateFromLayer:(CALayer *)layer;
+ (id<_ASPendingState>)pendingViewStateFromView:(UIView *)view;

@property (nonatomic, readonly) BOOL hasSetNeedsLayout;
@property (nonatomic, readonly) BOOL hasSetNeedsDisplay;

- (void)clearChanges;

@property (nonatomic, readonly) BOOL hasChanges;

@end

/**

 Private header for ASDisplayNode.mm

 _ASPendingState is a proxy for a UIView that has yet to be created.
 In response to its setters, it sets an internal property and a flag that indicates that that property has been set.

 When you want to configure a view from this pending state information, just call -applyToView:
 */

@interface _ASPendingStateInflated : NSObject <_ASPendingState>

- (NSUInteger)cost;

@end
