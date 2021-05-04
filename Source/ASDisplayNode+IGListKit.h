#import <AsyncDisplayKit/ASAvailability.h>

#if AS_IG_LIST_KIT

#import <AsyncDisplayKit/ASDisplayNode.h>

#import <IGListKit/IGListDiff.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A trivial implementation of IGListDiffable for nodes. We currently use IGListDiff to update the
 * node tree to match the yoga tree.
 */
@interface ASDisplayNode (IGListDiffable) <IGListDiffable>
@end

NS_ASSUME_NONNULL_END

#endif
