#import <AsyncDisplayKit/ASDisplayNode+IGListKit.h>

#if AS_IG_LIST_KIT

@implementation ASDisplayNode (IGListDiffable)

#pragma mark IGListDiffable

- (id<NSObject>)diffIdentifier {
  return self;
}

- (BOOL)isEqualToDiffableObject:(id<IGListDiffable>)object {
  return self == object;
}

@end

#endif
