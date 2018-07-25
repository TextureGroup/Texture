//
//  ASLayout+IGListKit.mm
//  Texture
//
//  Copyright (c) 2018-present, Pinterest, Inc.  All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
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
