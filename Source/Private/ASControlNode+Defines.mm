//
//  ASControlNode+Defines.m
//  AsyncDisplayKit
//
//  Created by Ashley Nelson on 4/6/21.
//  Copyright © 2021 Pinterest. All rights reserved.
//

#import <AsyncDisplayKit/ASControlNode+Defines.h>

static BOOL __enableUserInteractionSettingAXElement = YES;

@implementation ASControlNode (Defines)

+ (void)setShouldUserInteractionEnabledSetIsAXElement:(BOOL)enable {
  __enableUserInteractionSettingAXElement = enable;
}

+ (BOOL)shouldUserInteractionEnabledSetIsAXElement {
  return __enableUserInteractionSettingAXElement;
}

@end
