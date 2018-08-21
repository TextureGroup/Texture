//
//  ASLayout+IGListKit.h
//  Texture
//
//  Copyright (c) 2017-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License").
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//

#if AS_IG_LIST_KIT
#import <AsyncDisplayKit/ASLayout.h>
#import <IGListKit/IGListKit.h>
@interface ASLayout(IGListKit) <IGListDiffable>
@end

#endif // AS_IG_LIST_KIT
