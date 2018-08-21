//
//  ASImageContainerProtocolCategories.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <UIKit/UIKit.h>
#import <AsyncDisplayKit/ASImageProtocols.h>

@interface UIImage (ASImageContainerProtocol) <ASImageContainerProtocol>

@end

@interface NSData (ASImageContainerProtocol) <ASImageContainerProtocol>

@end
