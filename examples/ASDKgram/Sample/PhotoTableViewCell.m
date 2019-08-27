//
//  PhotoTableViewCell.m
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import "PhotoTableViewCell.h"
#import "Utilities.h"
#import "PINImageView+PINRemoteImage.h"
#import "PINButton+PINRemoteImage.h"

#define DEBUG_PHOTOCELL_LAYOUT  0
#define USE_UIKIT_AUTOLAYOUT    0
#define USE_UIKIT_MANUAL_LAYOUT !USE_UIKIT_AUTOLAYOUT

#define HEADER_HEIGHT           50
#define USER_IMAGE_HEIGHT       30
#define HORIZONTAL_BUFFER       10
#define VERTICAL_BUFFER         5
#define FONT_SIZE               14

@implementation PhotoTableViewCell
{
  PhotoModel *_photoModel;
  
  UIImageView *_userAvatarImageView;
  UIImageView *_photoImageView;
  UILabel *_userNameLabel;
  UILabel *_photoLocationLabel;
  UILabel *_photoTimeIntervalSincePostLabel;
  UILabel *_photoLikesLabel;
  UILabel *_photoDescriptionLabel;
  
  NSLayoutConstraint *_userNameYPositionWithPhotoLocation;
  NSLayoutConstraint *_userNameYPositionWithoutPhotoLocation;
  NSLayoutConstraint *_photoLocationYPosition;
}

#pragma mark - Class Methods

+ (CGFloat)heightForPhotoModel:(PhotoModel *)photo withWidth:(CGFloat)width;
{
  CGFloat photoHeight = width;
  
  UIFont *font = [UIFont systemFontOfSize:FONT_SIZE];
  CGFloat likesHeight = roundf([font lineHeight]);

  static UILabel *sizingLabel = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sizingLabel = [[UILabel alloc] init];
    sizingLabel.numberOfLines = 3;
  });

  sizingLabel.attributedText = [photo descriptionAttributedStringWithFontSize:FONT_SIZE];;
  CGFloat descriptionHeight = [sizingLabel sizeThatFits:CGSizeMake(width - HORIZONTAL_BUFFER * 2, CGFLOAT_MAX)].height;
  
  return HEADER_HEIGHT + photoHeight + likesHeight + descriptionHeight + (4 * VERTICAL_BUFFER);
}

#pragma mark - Lifecycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  
  if (self) {
    _userAvatarImageView = [[UIImageView alloc] init];
    _userAvatarImageView.backgroundColor = [UIColor backgroundColor];
    _photoImageView = [[UIImageView alloc] init];
    _photoImageView.contentMode = UIViewContentModeScaleAspectFill;
    _photoImageView.clipsToBounds = YES;
    _photoImageView.backgroundColor = [UIColor backgroundColor];
    _userNameLabel = [[UILabel alloc] init];
    _userNameLabel.backgroundColor = [UIColor whiteColor];
    _photoLocationLabel = [[UILabel alloc] init];
    _photoLocationLabel.backgroundColor = [UIColor backgroundColor];
    _photoTimeIntervalSincePostLabel = [[UILabel alloc] init];
    _photoTimeIntervalSincePostLabel.backgroundColor = [UIColor whiteColor];
    _photoLikesLabel = [[UILabel alloc] init];
    _photoLikesLabel.backgroundColor = [UIColor whiteColor];
    _photoDescriptionLabel = [[UILabel alloc] init];
    _photoDescriptionLabel.numberOfLines = 3;
    _photoDescriptionLabel.backgroundColor = [UIColor whiteColor];

    [self.contentView addSubview:_userAvatarImageView];
    [self.contentView addSubview:_photoImageView];
    [self.contentView addSubview:_userNameLabel];
    [self.contentView addSubview:_photoLocationLabel];
    [self.contentView addSubview:_photoTimeIntervalSincePostLabel];
    [self.contentView addSubview:_photoLikesLabel];
    [self.contentView addSubview:_photoDescriptionLabel];

#if USE_UIKIT_AUTOLAYOUT
    [_userAvatarImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_photoImageView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_userNameLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_photoLocationLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_photoTimeIntervalSincePostLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_photoLikesLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [_photoDescriptionLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self setupConstraints];
    [self updateConstraints];
#endif
    
#if DEBUG_PHOTOCELL_LAYOUT
    _userAvatarImageView.backgroundColor              = [UIColor greenColor];
    _userNameLabel.backgroundColor                    = [UIColor greenColor];
    _photoLocationLabel.backgroundColor               = [UIColor greenColor];
    _photoTimeIntervalSincePostLabel.backgroundColor  = [UIColor greenColor];
    _photoDescriptionLabel.backgroundColor            = [UIColor greenColor];
    _photoLikesLabel.backgroundColor                  = [UIColor greenColor];
#endif
  }
  
  return self;
}

#if USE_UIKIT_AUTOLAYOUT

- (void)setupConstraints
{
  // _userAvatarImageView
  [self addConstraint:[NSLayoutConstraint constraintWithItem:_userAvatarImageView
                                                   attribute:NSLayoutAttributeLeft
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:_userAvatarImageView.superview
                                                   attribute:NSLayoutAttributeLeft
                                                  multiplier:1.0
                                                    constant:HORIZONTAL_BUFFER]];
  
  [self addConstraint:[NSLayoutConstraint constraintWithItem:_userAvatarImageView
                                                   attribute:NSLayoutAttributeTop
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:_userAvatarImageView.superview
                                                   attribute:NSLayoutAttributeTop
                                                  multiplier:1.0
                                                    constant:HORIZONTAL_BUFFER]];
  
  [self addConstraint:[NSLayoutConstraint constraintWithItem:_userAvatarImageView
                                                   attribute:NSLayoutAttributeWidth
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:nil
                                                   attribute:NSLayoutAttributeNotAnAttribute
                                                  multiplier:0.0
                                                    constant:USER_IMAGE_HEIGHT]];
  
  [self addConstraint:[NSLayoutConstraint constraintWithItem:_userAvatarImageView
                                                   attribute:NSLayoutAttributeHeight
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:_userAvatarImageView
                                                   attribute:NSLayoutAttributeWidth
                                                  multiplier:1.0
                                                    constant:0.0]];
  
  // _userNameLabel
  [self addConstraint:[NSLayoutConstraint constraintWithItem:_userNameLabel
                                                   attribute:NSLayoutAttributeLeft
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:_userAvatarImageView
                                                   attribute:NSLayoutAttributeRight
                                                  multiplier:1.0
                                                    constant:HORIZONTAL_BUFFER]];
  
  [self addConstraint:[NSLayoutConstraint constraintWithItem:_userNameLabel
                                                   attribute:NSLayoutAttributeRight
                                                   relatedBy:NSLayoutRelationLessThanOrEqual
                                                      toItem:_photoTimeIntervalSincePostLabel
                                                   attribute:NSLayoutAttributeLeft
                                                  multiplier:1.0
                                                    constant:-HORIZONTAL_BUFFER]];
  
  _userNameYPositionWithoutPhotoLocation = [NSLayoutConstraint constraintWithItem:_userNameLabel
                                                                        attribute:NSLayoutAttributeCenterY
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:_userAvatarImageView
                                                                        attribute:NSLayoutAttributeCenterY
                                                                       multiplier:1.0
                                                                         constant:0.0];
  [self addConstraint:_userNameYPositionWithoutPhotoLocation];
  
  _userNameYPositionWithPhotoLocation = [NSLayoutConstraint constraintWithItem:_userNameLabel
                                                                     attribute:NSLayoutAttributeTop
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:_userAvatarImageView
                                                                     attribute:NSLayoutAttributeTop
                                                                    multiplier:1.0
                                                                      constant:-2];
  _userNameYPositionWithPhotoLocation.active = NO;
  [self addConstraint:_userNameYPositionWithPhotoLocation];
  
  // _photoLocationLabel
  [self addConstraint:[NSLayoutConstraint constraintWithItem:_photoLocationLabel
                                                   attribute:NSLayoutAttributeLeft
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:_userAvatarImageView
                                                   attribute:NSLayoutAttributeRight
                                                  multiplier:1.0
                                                    constant:HORIZONTAL_BUFFER]];
  
  [self addConstraint:[NSLayoutConstraint constraintWithItem:_photoLocationLabel
                                                   attribute:NSLayoutAttributeRight
                                                   relatedBy:NSLayoutRelationLessThanOrEqual
                                                      toItem:_photoTimeIntervalSincePostLabel
                                                   attribute:NSLayoutAttributeLeft
                                                  multiplier:1.0
                                                    constant:-HORIZONTAL_BUFFER]];
  
  _photoLocationYPosition = [NSLayoutConstraint constraintWithItem:_photoLocationLabel
                                                         attribute:NSLayoutAttributeBottom
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:_userAvatarImageView
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1.0
                                                          constant:2];
  _photoLocationYPosition.active = NO;
  [self addConstraint:_photoLocationYPosition];
  
  // _photoTimeIntervalSincePostLabel
  [self addConstraint:[NSLayoutConstraint constraintWithItem:_photoTimeIntervalSincePostLabel
                                                   attribute:NSLayoutAttributeRight
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:_photoTimeIntervalSincePostLabel.superview
                                                   attribute:NSLayoutAttributeRight
                                                  multiplier:1.0
                                                    constant:-HORIZONTAL_BUFFER]];
  
  [self addConstraint:[NSLayoutConstraint constraintWithItem:_photoTimeIntervalSincePostLabel
                                                   attribute:NSLayoutAttributeCenterY
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:_userAvatarImageView
                                                   attribute:NSLayoutAttributeCenterY
                                                  multiplier:1.0
                                                    constant:0.0]];
  
  // _photoImageView
  [self addConstraint:[NSLayoutConstraint constraintWithItem:_photoImageView
                                                   attribute:NSLayoutAttributeTop
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:_photoImageView.superview
                                                   attribute:NSLayoutAttributeTop
                                                  multiplier:1.0
                                                    constant:HEADER_HEIGHT]];
  
  [self addConstraint:[NSLayoutConstraint constraintWithItem:_photoImageView
                                                   attribute:NSLayoutAttributeWidth
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:self
                                                   attribute:NSLayoutAttributeWidth
                                                  multiplier:1.0
                                                    constant:0.0]];
  
  [self addConstraint:[NSLayoutConstraint constraintWithItem:_photoImageView
                                                   attribute:NSLayoutAttributeHeight
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:_photoImageView
                                                   attribute:NSLayoutAttributeWidth
                                                  multiplier:1.0
                                                    constant:0.0]];
  
  // _photoLikesLabel
  [self addConstraint:[NSLayoutConstraint constraintWithItem:_photoLikesLabel
                                                   attribute:NSLayoutAttributeTop
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:_photoImageView
                                                   attribute:NSLayoutAttributeBottom
                                                  multiplier:1.0
                                                    constant:VERTICAL_BUFFER]];
  
  [self addConstraint:[NSLayoutConstraint constraintWithItem:_photoLikesLabel
                                                   attribute:NSLayoutAttributeLeft
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:_photoLikesLabel.superview
                                                   attribute:NSLayoutAttributeLeft
                                                  multiplier:1.0
                                                    constant:HORIZONTAL_BUFFER]];
  
  // _photoDescriptionLabel
  [self addConstraint:[NSLayoutConstraint constraintWithItem:_photoDescriptionLabel
                                                   attribute:NSLayoutAttributeTop
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:_photoLikesLabel
                                                   attribute:NSLayoutAttributeBottom
                                                  multiplier:1.0
                                                    constant:VERTICAL_BUFFER]];
  
  [self addConstraint:[NSLayoutConstraint constraintWithItem:_photoDescriptionLabel
                                                   attribute:NSLayoutAttributeLeft
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:_photoDescriptionLabel.superview
                                                   attribute:NSLayoutAttributeLeft
                                                  multiplier:1.0
                                                    constant:HORIZONTAL_BUFFER]];
  
  [self addConstraint:[NSLayoutConstraint constraintWithItem:_photoDescriptionLabel
                                                   attribute:NSLayoutAttributeWidth
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:_photoDescriptionLabel.superview
                                                   attribute:NSLayoutAttributeWidth
                                                  multiplier:1.0
                                                    constant:-HORIZONTAL_BUFFER]];

}

- (void)updateConstraints
{
  [super updateConstraints];
  
  if (_photoLocationLabel.attributedText.length) {
    _userNameYPositionWithoutPhotoLocation.active = NO;
    _userNameYPositionWithPhotoLocation.active = YES;
    _photoLocationYPosition.active = YES;
  } else {
    _userNameYPositionWithoutPhotoLocation.active = YES;
    _userNameYPositionWithPhotoLocation.active = NO;
    _photoLocationYPosition.active = NO;
  }
}

#endif

- (void)layoutSubviews
{
  [super layoutSubviews];
  
#if USE_UIKIT_MANUAL_LAYOUT
  CGSize boundsSize = self.contentView.bounds.size;
  
  CGRect rect = CGRectMake(HORIZONTAL_BUFFER, (HEADER_HEIGHT - USER_IMAGE_HEIGHT) / 2.0,
                           USER_IMAGE_HEIGHT, USER_IMAGE_HEIGHT);
  _userAvatarImageView.frame = rect;

  [_photoTimeIntervalSincePostLabel sizeToFit];
  rect.size = _photoTimeIntervalSincePostLabel.bounds.size;
  rect.origin.x = boundsSize.width - HORIZONTAL_BUFFER - rect.size.width;
  rect.origin.y = (HEADER_HEIGHT - rect.size.height) / 2.0;
  _photoTimeIntervalSincePostLabel.frame = rect;

  CGFloat availableWidth = CGRectGetMinX(_photoTimeIntervalSincePostLabel.frame) - HORIZONTAL_BUFFER;
  [_userNameLabel sizeToFit];
  rect.size = _userNameLabel.bounds.size;
  rect.size.width = MIN(availableWidth, rect.size.width);

  rect.origin.x = HORIZONTAL_BUFFER + USER_IMAGE_HEIGHT + HORIZONTAL_BUFFER;

  [_photoLocationLabel sizeToFit];
  if (_photoLocationLabel.attributedText.length) {
    CGSize locationSize = _photoLocationLabel.bounds.size;
    locationSize.width = MIN(availableWidth, locationSize.width);
    
    rect.origin.y = (HEADER_HEIGHT - rect.size.height - locationSize.height) / 2.0;
    _userNameLabel.frame = rect;
    
    // FIXME: Name rects at least for this sub-condition
    rect.origin.y += rect.size.height;
    rect.size = locationSize;
    _photoLocationLabel.frame = rect;
  } else {
    rect.origin.y = (HEADER_HEIGHT - rect.size.height) / 2.0;
    _userNameLabel.frame = rect;
  }

  _photoImageView.frame = CGRectMake(0, HEADER_HEIGHT, boundsSize.width, boundsSize.width);
  

  [_photoLikesLabel sizeToFit];
  rect.size = _photoLikesLabel.bounds.size;
  rect.origin = CGPointMake(HORIZONTAL_BUFFER, CGRectGetMaxY(_photoImageView.frame) + VERTICAL_BUFFER);
  _photoLikesLabel.frame = rect;

  rect.size = [_photoDescriptionLabel sizeThatFits:CGSizeMake(boundsSize.width - HORIZONTAL_BUFFER * 2, CGFLOAT_MAX)];
  rect.origin.y = CGRectGetMaxY(_photoLikesLabel.frame) + VERTICAL_BUFFER;
  _photoDescriptionLabel.frame = rect;
#endif
}

- (void)prepareForReuse
{
  [super prepareForReuse];
  
  _userAvatarImageView.image = nil;
  _photoImageView.image = nil;
  _userNameLabel.attributedText = nil;
  _photoLocationLabel.attributedText = nil;
  _photoTimeIntervalSincePostLabel.attributedText = nil;
  _photoLikesLabel.attributedText = nil;
  _photoDescriptionLabel.attributedText = nil;
}

#pragma mark - Instance Methods

- (void)updateCellWithPhotoObject:(PhotoModel *)photo
{
  _photoModel = photo;
  _userNameLabel.attributedText = [photo.ownerUserProfile usernameAttributedStringWithFontSize:FONT_SIZE];
  _photoTimeIntervalSincePostLabel.attributedText = [photo uploadDateAttributedStringWithFontSize:FONT_SIZE];
  _photoLikesLabel.attributedText = [photo likesAttributedStringWithFontSize:FONT_SIZE];
  _photoDescriptionLabel.attributedText = [photo descriptionAttributedStringWithFontSize:FONT_SIZE];
  _photoLocationLabel.attributedText = [photo locationAttributedStringWithFontSize:FONT_SIZE];

  NSURL *photoURLLoading = photo.URL;
  [UIImage downloadImageForURL:photoURLLoading completion:^(UIImage *image) {
    if (![photoURLLoading isEqual:_photoModel.URL]) {
      return;
    }
    _photoImageView.image = image;
  }];

  [self downloadAndProcessUserAvatar];

  // Update active state of photo location label adjustment
  [self setNeedsUpdateConstraints];
  [self setNeedsLayout];
}

#pragma mark - Helper Methods

static NSURL *UserProfileURLForPhotoModel(PhotoModel *photoModel) {
  return photoModel.ownerUserProfile != nil
    ? photoModel.ownerUserProfile.userPicURL
    : photoModel.URL;
}

- (void)downloadAndProcessUserAvatar
{
  NSURL *userProfileURL = UserProfileURLForPhotoModel(_photoModel);

  [UIImage downloadImageForURL:userProfileURL completion:^(UIImage *image) {
    if (![userProfileURL isEqual:UserProfileURLForPhotoModel(_photoModel)]) {
      return;
    }

    CGSize profileImageSize = CGSizeMake(USER_IMAGE_HEIGHT, USER_IMAGE_HEIGHT);
    _userAvatarImageView.image = [image makeCircularImageWithSize:profileImageSize backgroundColor:[UIColor backgroundColor]];
  }];
}

@end
