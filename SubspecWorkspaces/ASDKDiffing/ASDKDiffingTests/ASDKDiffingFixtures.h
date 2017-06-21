//
//  ASDKDiffingFixtures.h
//  ASDKDiffing
//
//  Created by Adlai Holler on 6/20/17.
//
//

#import <Foundation/Foundation.h>
#import <IGListKit/IGListDiffKit.h>
#import <AsyncDisplayKit/AsyncDisplayKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ASTViewModel : NSObject <IGListDiffable>
@property (nonatomic, readonly)	NSInteger identifier;			// Globally unique.
@property (nonatomic, readonly)	NSInteger contents;				// Globally unique. Auto-increments.
@property (nonatomic, nullable, copy) NSString *debugName;		// Helpful. Copied when updating.
// Returns a new view model with the next `contents` value.
- (instancetype)viewModelByUpdating;

+ (void)reset;

@end

@interface ASTItem : ASTViewModel
@end

@interface ASTSection : ASTViewModel

@end

@interface ASTSectionCtrl : ASDiffingSectionController

@end

@interface ASTItemNode : ASCellNode

@end

NS_ASSUME_NONNULL_END
