//
//  ASRequiringMainThreadDeallocating.h
//  AsyncDisplayKit
//
//  Created by Michael Schneider on 10/1/17.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ASRequiringMainThreadDeallocating <NSObject>
+ (BOOL)requiresMainThreadDeallocation;
@end
