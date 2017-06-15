//
//  TDDebugger.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASAvailability.h>

#if AS_TEXTURE_DEBUGGER

#import <PonyDebugger/PDDebugger.h>

@interface TDDebugger : PDDebugger

+ (TDDebugger *)defaultInstance;

- (void)enableLayoutElementDebuggingWithApplication:(UIApplication *)application;

@end

#endif // AS_TEXTURE_DEBUGGER
