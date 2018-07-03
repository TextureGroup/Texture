//
//  ASLayout+IGListKit.h
//  AsyncDisplayKit
//
//  Created by Kevin Smith on 7/1/18.
//  Copyright © 2018 Pinterest. All rights reserved.
//

#if AS_IG_LIST_KIT
#import <AsyncDisplayKit/ASLayout.h>
#import <IGListKit/IGListKit.h>
@interface ASLayout(IGListKit) <IGListDiffable>
@end

#endif // AS_IG_LIST_KIT
