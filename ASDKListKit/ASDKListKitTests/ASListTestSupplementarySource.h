//
//  ASListTestSupplementarySource.h
//  Texture
//
//  Created by Adlai Holler on 12/25/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import <IGListKit/IGListKit.h>
#import <AsyncDisplayKit/AsyncDisplayKit.h>

@interface ASListTestSupplementarySource : NSObject <IGListSupplementaryViewSource, ASSupplementaryNodeSource>

@property (nonatomic, strong, readwrite) NSArray<NSString *> *supportedElementKinds;

@property (nonatomic, weak) id<IGListCollectionContext> collectionContext;

@property (nonatomic, weak) IGListSectionController<IGListSectionType> *sectionController;

@end
