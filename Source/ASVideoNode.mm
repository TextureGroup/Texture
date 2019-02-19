//
//  ASVideoNode.mm
//  Texture
//
//  Copyright (c) Facebook, Inc. and its affiliates.  All rights reserved.
//  Changes after 4/13/2017 are: Copyright (c) Pinterest, Inc.  All rights reserved.
//  Licensed under Apache 2.0: http://www.apache.org/licenses/LICENSE-2.0
//

#import <AsyncDisplayKit/ASVideoNode.h>

#if AS_USE_VIDEO

#import <AVFoundation/AVFoundation.h>
#import <AsyncDisplayKit/ASDisplayNode+FrameworkPrivate.h>
#import <AsyncDisplayKit/ASDisplayNode+Subclasses.h>
#import <AsyncDisplayKit/ASDisplayNodeInternal.h>
#import <AsyncDisplayKit/ASEqualityHelpers.h>
#import <AsyncDisplayKit/ASInternalHelpers.h>
#import <AsyncDisplayKit/ASDisplayNodeExtras.h>
#import <AsyncDisplayKit/ASThread.h>

static BOOL ASAssetIsEqual(AVAsset *asset1, AVAsset *asset2) {
  return ASObjectIsEqual(asset1, asset2)
  || ([asset1 isKindOfClass:[AVURLAsset class]]
      && [asset2 isKindOfClass:[AVURLAsset class]]
      && ASObjectIsEqual(((AVURLAsset *)asset1).URL, ((AVURLAsset *)asset2).URL));
}

static UIViewContentMode ASContentModeFromVideoGravity(NSString *videoGravity) {
  if ([videoGravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
    return UIViewContentModeScaleAspectFill;
  } else if ([videoGravity isEqualToString:AVLayerVideoGravityResize]) {
    return UIViewContentModeScaleToFill;
  } else {
    return UIViewContentModeScaleAspectFit;
  }
}

static void *ASVideoNodeContext = &ASVideoNodeContext;
static NSString * const kPlaybackLikelyToKeepUpKey = @"playbackLikelyToKeepUp";
static NSString * const kplaybackBufferEmpty = @"playbackBufferEmpty";
static NSString * const kStatus = @"status";
static NSString * const kRate = @"rate";

@interface ASVideoNode ()
{
  struct {
    unsigned int delegateVideNodeShouldChangePlayerStateTo:1;
    unsigned int delegateVideoDidPlayToEnd:1;
    unsigned int delegateDidTapVideoNode:1;
    unsigned int delegateVideoNodeWillChangePlayerStateToState:1;
    unsigned int delegateVideoNodeDidPlayToTimeInterval:1;
    unsigned int delegateVideoNodeDidStartInitialLoading:1;
    unsigned int delegateVideoNodeDidFinishInitialLoading:1;
    unsigned int delegateVideoNodeDidSetCurrentItem:1;
    unsigned int delegateVideoNodeDidStallAtTimeInterval:1;
    unsigned int delegateVideoNodeDidRecoverFromStall:1;
    unsigned int delegateVideoNodeDidFailToLoadValueForKey:1;
  } _delegateFlags;
  
  BOOL _shouldBePlaying;
  
  BOOL _shouldAutorepeat;
  BOOL _shouldAutoplay;
  BOOL _shouldAggressivelyRecoverFromStall;
  BOOL _muted;
  
  ASVideoNodePlayerState _playerState;
  
  AVAsset *_asset;
  NSURL *_assetURL;
  AVVideoComposition *_videoComposition;
  AVAudioMix *_audioMix;
  
  AVPlayerItem *_currentPlayerItem;
  AVPlayer *_player;
  
  id _timeObserver;
  int32_t _periodicTimeObserverTimescale;
  CMTime _timeObserverInterval;
  
  CMTime _lastPlaybackTime;
	
  ASDisplayNode *_playerNode;
  NSString *_gravity;
}

@end

@implementation ASVideoNode

@dynamic delegate;

// TODO: Support preview images with HTTP Live Streaming videos.

#pragma mark - Construction and Layout

- (instancetype)initWithCache:(id<ASImageCacheProtocol>)cache downloader:(id<ASImageDownloaderProtocol>)downloader
{
  if (!(self = [super initWithCache:cache downloader:downloader])) {
    return nil;
  }

  self.gravity = AVLayerVideoGravityResizeAspect;
  _periodicTimeObserverTimescale = 10000;
  [self addTarget:self action:@selector(tapped) forControlEvents:ASControlNodeEventTouchUpInside];
  _lastPlaybackTime = kCMTimeZero;
  
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  [notificationCenter addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
  
  return self;
}

- (ASDisplayNode *)constructPlayerNode
{
  ASVideoNode * __weak weakSelf = self;

  return [[ASDisplayNode alloc] initWithLayerBlock:^CALayer *{
    AVPlayerLayer *playerLayer = [[AVPlayerLayer alloc] init];
    playerLayer.player = weakSelf.player;
    playerLayer.videoGravity = weakSelf.gravity;
    return playerLayer;
  }];
}

- (AVPlayerItem *)constructPlayerItem
{
  ASDisplayNodeAssertMainThread();
  ASLockScopeSelf();

  AVPlayerItem *playerItem = nil;
  if (_assetURL != nil) {
    playerItem = [[AVPlayerItem alloc] initWithURL:_assetURL];
    _asset = [playerItem asset];
  } else {
    playerItem = [[AVPlayerItem alloc] initWithAsset:_asset];
  }

  playerItem.videoComposition = _videoComposition;
  playerItem.audioMix = _audioMix;
  return playerItem;
}

- (void)prepareToPlayAsset:(AVAsset *)asset withKeys:(NSArray<NSString *> *)requestedKeys
{
  ASDisplayNodeAssertMainThread();
  
  for (NSString *key in requestedKeys) {
    NSError *error = nil;
    AVKeyValueStatus keyStatus = [asset statusOfValueForKey:key error:&error];
    if (keyStatus == AVKeyValueStatusFailed) {
      NSLog(@"Asset loading failed with error: %@", error);
      if (_delegateFlags.delegateVideoNodeDidFailToLoadValueForKey) {
        [self.delegate videoNode:self didFailToLoadValueForKey:key asset:asset error:error];
      }
    }
  }
  
  if ([asset isPlayable] == NO) {
    NSLog(@"Asset is not playable.");
    return;
  }

  AVPlayerItem *playerItem = [self constructPlayerItem];
  [self setCurrentItem:playerItem];
  
  if (_player != nil) {
    [_player replaceCurrentItemWithPlayerItem:playerItem];
  } else {
    self.player = [AVPlayer playerWithPlayerItem:playerItem];
  }

  if (_delegateFlags.delegateVideoNodeDidSetCurrentItem) {
    [self.delegate videoNode:self didSetCurrentItem:playerItem];
  }

  if (self.image == nil && self.URL == nil) {
    [self generatePlaceholderImage];
  }
}

- (void)addPlayerItemObservers:(AVPlayerItem *)playerItem
{
  if (playerItem == nil) {
    return;
  }
  
  [playerItem addObserver:self forKeyPath:kStatus options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:ASVideoNodeContext];
  [playerItem addObserver:self forKeyPath:kPlaybackLikelyToKeepUpKey options:NSKeyValueObservingOptionNew context:ASVideoNodeContext];
  [playerItem addObserver:self forKeyPath:kplaybackBufferEmpty options:NSKeyValueObservingOptionNew context:ASVideoNodeContext];
  
  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  [notificationCenter addObserver:self selector:@selector(didPlayToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
  [notificationCenter addObserver:self selector:@selector(videoNodeDidStall:) name:AVPlayerItemPlaybackStalledNotification object:playerItem];
  [notificationCenter addObserver:self selector:@selector(errorWhilePlaying:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:playerItem];
  [notificationCenter addObserver:self selector:@selector(errorWhilePlaying:) name:AVPlayerItemNewErrorLogEntryNotification object:playerItem];
}

- (void)removePlayerItemObservers:(AVPlayerItem *)playerItem
{
  @try {
    [playerItem removeObserver:self forKeyPath:kStatus context:ASVideoNodeContext];
    [playerItem removeObserver:self forKeyPath:kPlaybackLikelyToKeepUpKey context:ASVideoNodeContext];
    [playerItem removeObserver:self forKeyPath:kplaybackBufferEmpty context:ASVideoNodeContext];
  }
  @catch (NSException * __unused exception) {
    NSLog(@"Unnecessary KVO removal");
  }

  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  [notificationCenter removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
  [notificationCenter removeObserver:self name: AVPlayerItemPlaybackStalledNotification object:playerItem];
  [notificationCenter removeObserver:self name:AVPlayerItemFailedToPlayToEndTimeNotification object:playerItem];
  [notificationCenter removeObserver:self name:AVPlayerItemNewErrorLogEntryNotification object:playerItem];
}

- (void)addPlayerObservers:(AVPlayer *)player
{
  if (player == nil) {
    return;
  }

  [player addObserver:self forKeyPath:kRate options:NSKeyValueObservingOptionNew context:ASVideoNodeContext];

  __weak __typeof(self) weakSelf = self;
  _timeObserverInterval = CMTimeMake(1, _periodicTimeObserverTimescale);
  _timeObserver = [player addPeriodicTimeObserverForInterval:_timeObserverInterval queue:NULL usingBlock:^(CMTime time){
    [weakSelf periodicTimeObserver:time];
  }];
}

- (void) removePlayerObservers:(AVPlayer *)player
{
  if (_timeObserver != nil) {
    [player removeTimeObserver:_timeObserver];
    _timeObserver = nil;
  }

  @try {
    [player removeObserver:self forKeyPath:kRate context:ASVideoNodeContext];
  }
  @catch (NSException * __unused exception) {
    NSLog(@"Unnecessary KVO removal");
  }
}

- (void)layout
{
  [super layout];
  // The _playerNode wraps AVPlayerLayer, and therefore should extend across the entire bounds.
  _playerNode.frame = self.bounds;
}

- (CGSize)calculateSizeThatFits:(CGSize)constrainedSize
{
  ASDisplayNode *playerNode = ASLockedSelf(_playerNode);

  CGSize calculatedSize = constrainedSize;
  
  // Prevent crashes through if infinite width or height
  if (isinf(calculatedSize.width) || isinf(calculatedSize.height)) {
    ASDisplayNodeAssert(NO, @"Infinite width or height in ASVideoNode");
    calculatedSize = CGSizeZero;
  }
  
  if (playerNode != nil) {
    playerNode.style.preferredSize = calculatedSize;
    [playerNode layoutThatFits:ASSizeRangeMake(CGSizeZero, calculatedSize)];
  }
  
  return calculatedSize;
}

- (void)generatePlaceholderImage
{
  ASVideoNode * __weak weakSelf = self;
  AVAsset *asset = self.asset;

  [self imageAtTime:kCMTimeZero completionHandler:^(UIImage *image) {
    ASPerformBlockOnMainThread(^{
      // Ensure the asset hasn't changed since the image request was made
      if (ASAssetIsEqual(weakSelf.asset, asset)) {
        [weakSelf setVideoPlaceholderImage:image];
      }
    });
  }];
}

- (void)imageAtTime:(CMTime)imageTime completionHandler:(void(^)(UIImage *image))completionHandler
{
  ASPerformBlockOnBackgroundThread(^{
    AVAsset *asset = self.asset;

    // Skip the asset image generation if we don't have any tracks available that are capable of supporting it
    NSArray<AVAssetTrack *>* visualAssetArray = [asset tracksWithMediaCharacteristic:AVMediaCharacteristicVisual];
    if (visualAssetArray.count == 0) {
      completionHandler(nil);
      return;
    }

    AVAssetImageGenerator *previewImageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    previewImageGenerator.appliesPreferredTrackTransform = YES;
    previewImageGenerator.videoComposition = _videoComposition;

    [previewImageGenerator generateCGImagesAsynchronouslyForTimes:@[[NSValue valueWithCMTime:imageTime]]
                                                completionHandler:^(CMTime requestedTime, CGImageRef image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error) {
                                                  if (error != nil && result != AVAssetImageGeneratorCancelled) {
                                                    NSLog(@"Asset preview image generation failed with error: %@", error);
                                                  }
                                                  completionHandler(image ? [UIImage imageWithCGImage:image] : nil);
                                                }];
  });
}

- (void)setVideoPlaceholderImage:(UIImage *)image
{
  NSString *gravity = self.gravity;
  
  if (image != nil) {
    self.contentMode = ASContentModeFromVideoGravity(gravity);
  }
  self.image = image;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  ASDN::UniqueLock l(__instanceLock__);

  if (object == _currentPlayerItem) {
    if ([keyPath isEqualToString:kStatus]) {
      if ([change[NSKeyValueChangeNewKey] integerValue] == AVPlayerItemStatusReadyToPlay) {
        if (self.playerState != ASVideoNodePlayerStatePlaying) {
          self.playerState = ASVideoNodePlayerStateReadyToPlay;
          if (_shouldBePlaying && ASInterfaceStateIncludesVisible(self.interfaceState)) {
            l.unlock();
            [self play];
            l.lock();
          }
        }
        // If we don't yet have a placeholder image update it now that we should have data available for it
        if (self.image == nil && self.URL == nil) {
          [self generatePlaceholderImage];
        }
      }
    } else if ([keyPath isEqualToString:kPlaybackLikelyToKeepUpKey]) {
      BOOL likelyToKeepUp = [change[NSKeyValueChangeNewKey] boolValue];
      if (likelyToKeepUp && self.playerState == ASVideoNodePlayerStatePlaying) {
        return;
      }
      if (!likelyToKeepUp) {
        self.playerState = ASVideoNodePlayerStateLoading;
      } else if (self.playerState != ASVideoNodePlayerStateFinished) {
        self.playerState = ASVideoNodePlayerStatePlaybackLikelyToKeepUpButNotPlaying;
      }
      if (_shouldBePlaying && (_shouldAggressivelyRecoverFromStall || likelyToKeepUp) && ASInterfaceStateIncludesVisible(self.interfaceState)) {
        if (self.playerState == ASVideoNodePlayerStateLoading && _delegateFlags.delegateVideoNodeDidRecoverFromStall) {
          [self.delegate videoNodeDidRecoverFromStall:self];
        }
        
        l.unlock();
        [self play]; // autoresume after buffer catches up
        // NOTE: Early return without re-locking.
        return;
      }
    } else if ([keyPath isEqualToString:kplaybackBufferEmpty]) {
      if (_shouldBePlaying && [change[NSKeyValueChangeNewKey] boolValue] == YES && ASInterfaceStateIncludesVisible(self.interfaceState)) {
        self.playerState = ASVideoNodePlayerStateLoading;
      }
    }
  } else if (object == _player) {
    if ([keyPath isEqualToString:kRate]) {
      if ([change[NSKeyValueChangeNewKey] floatValue] == 0.0) {
        if (self.playerState == ASVideoNodePlayerStatePlaying) {
          self.playerState = ASVideoNodePlayerStatePaused;
        }
      } else {
        self.playerState = ASVideoNodePlayerStatePlaying;
      }
    }
  }
  
  // NOTE: Early return above.
}

- (void)tapped
{
  if (_delegateFlags.delegateDidTapVideoNode) {
    [self.delegate didTapVideoNode:self];
    
  } else {
    if (_shouldBePlaying) {
      [self pause];
    } else {
      [self play];
    }
  }
}

- (void)didEnterPreloadState
{
  [super didEnterPreloadState];
  
  ASLockScopeSelf();
  AVAsset *asset = self.asset;
  // Return immediately if the asset is nil;
  if (asset == nil || self.playerState != ASVideoNodePlayerStateUnknown) {
      return;
  }

  self.playerState = ASVideoNodePlayerStateLoading;
  if (_delegateFlags.delegateVideoNodeDidStartInitialLoading) {
      [self.delegate videoNodeDidStartInitialLoading:self];
  }
  
  NSArray<NSString *> *requestedKeys = @[@"playable"];
  [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:^{
    ASPerformBlockOnMainThread(^{
      if (_delegateFlags.delegateVideoNodeDidFinishInitialLoading) {
        [self.delegate videoNodeDidFinishInitialLoading:self];
      }
      [self prepareToPlayAsset:asset withKeys:requestedKeys];
    });
  }];
}

- (void)periodicTimeObserver:(CMTime)time
{
  NSTimeInterval timeInSeconds = CMTimeGetSeconds(time);
  if (timeInSeconds <= 0) {
    return;
  }
  
  if (_delegateFlags.delegateVideoNodeDidPlayToTimeInterval) {
    [self.delegate videoNode:self didPlayToTimeInterval:timeInSeconds];
    
  }
}

- (void)didExitPreloadState
{
  [super didExitPreloadState];
  
  {
    ASLockScopeSelf();

    self.player = nil;
    self.currentItem = nil;
    self.playerState = ASVideoNodePlayerStateUnknown;
  }
}

- (void)didEnterVisibleState
{
  [super didEnterVisibleState];
  
  BOOL shouldPlay = NO;
  {
    ASLockScopeSelf();
    if (_shouldBePlaying || _shouldAutoplay) {
      if (_player != nil && CMTIME_IS_VALID(_lastPlaybackTime)) {
        [_player seekToTime:_lastPlaybackTime];
      }
      shouldPlay = YES;
    }
  }
  
  if (shouldPlay) {
    [self play];
  }
}

- (void)didExitVisibleState
{
  [super didExitVisibleState];
  
  ASLockScopeSelf();
  
  if (_shouldBePlaying) {
    [self pause];
    if (_player != nil && CMTIME_IS_VALID(_player.currentTime)) {
      _lastPlaybackTime = _player.currentTime;
    }
    _shouldBePlaying = YES;
  }
}

#pragma mark - Video Properties

- (void)setPlayerState:(ASVideoNodePlayerState)playerState
{
  ASLockScopeSelf();
  
  ASVideoNodePlayerState oldState = _playerState;
  
  if (oldState == playerState) {
    return;
  }
  
  if (_delegateFlags.delegateVideoNodeWillChangePlayerStateToState) {
    [self.delegate videoNode:self willChangePlayerState:oldState toState:playerState];
  }
  
  _playerState = playerState;
}

- (void)setAssetURL:(NSURL *)assetURL
{
  ASDisplayNodeAssertMainThread();
  
  if (ASObjectIsEqual(assetURL, self.assetURL) == NO) {
    [self setAndFetchAsset:[AVURLAsset assetWithURL:assetURL] url:assetURL];
  }
}

- (NSURL *)assetURL
{
  ASLockScopeSelf();

  if (_assetURL != nil) {
    return _assetURL;
  } else if ([_asset isKindOfClass:AVURLAsset.class]) {
    return ((AVURLAsset *)_asset).URL;
  }

  return nil;
}

- (void)setAsset:(AVAsset *)asset
{
  ASDisplayNodeAssertMainThread();
  
  if (ASAssetIsEqual(asset, self.asset) == NO) {
    [self setAndFetchAsset:asset url:nil];
  }
}

- (AVAsset *)asset
{
  ASLockScopeSelf();
  return _asset;
}

- (void)setAndFetchAsset:(AVAsset *)asset url:(NSURL *)assetURL
{
  ASDisplayNodeAssertMainThread();
  
  [self didExitPreloadState];
  
  {
    ASLockScopeSelf();
    self.videoPlaceholderImage = nil;
    _asset = asset;
    _assetURL = assetURL;
  }
  
  [self setNeedsPreload];
}

- (void)setVideoComposition:(AVVideoComposition *)videoComposition
{
  ASLockScopeSelf();

  _videoComposition = videoComposition;
  _currentPlayerItem.videoComposition = videoComposition;
}

- (AVVideoComposition *)videoComposition
{
  ASLockScopeSelf();
  return _videoComposition;
}

- (void)setAudioMix:(AVAudioMix *)audioMix
{
  ASLockScopeSelf();

  _audioMix = audioMix;
  _currentPlayerItem.audioMix = audioMix;
}

- (AVAudioMix *)audioMix
{
  ASLockScopeSelf();
  return _audioMix;
}

- (AVPlayer *)player
{
  ASLockScopeSelf();
  return _player;
}

- (AVPlayerLayer *)playerLayer
{
  ASLockScopeSelf();
  return (AVPlayerLayer *)_playerNode.layer;
}

- (void)setDelegate:(id<ASVideoNodeDelegate>)delegate
{
  [super setDelegate:delegate];
  
  if (delegate == nil) {
    memset(&_delegateFlags, 0, sizeof(_delegateFlags));
  } else {
    _delegateFlags.delegateVideNodeShouldChangePlayerStateTo = [delegate respondsToSelector:@selector(videoNode:shouldChangePlayerStateTo:)];
    _delegateFlags.delegateVideoDidPlayToEnd = [delegate respondsToSelector:@selector(videoDidPlayToEnd:)];
    _delegateFlags.delegateDidTapVideoNode = [delegate respondsToSelector:@selector(didTapVideoNode:)];
    _delegateFlags.delegateVideoNodeWillChangePlayerStateToState = [delegate respondsToSelector:@selector(videoNode:willChangePlayerState:toState:)];
    _delegateFlags.delegateVideoNodeDidPlayToTimeInterval = [delegate respondsToSelector:@selector(videoNode:didPlayToTimeInterval:)];
    _delegateFlags.delegateVideoNodeDidStartInitialLoading = [delegate respondsToSelector:@selector(videoNodeDidStartInitialLoading:)];
    _delegateFlags.delegateVideoNodeDidFinishInitialLoading = [delegate respondsToSelector:@selector(videoNodeDidFinishInitialLoading:)];
    _delegateFlags.delegateVideoNodeDidSetCurrentItem = [delegate respondsToSelector:@selector(videoNode:didSetCurrentItem:)];
    _delegateFlags.delegateVideoNodeDidStallAtTimeInterval = [delegate respondsToSelector:@selector(videoNode:didStallAtTimeInterval:)];
    _delegateFlags.delegateVideoNodeDidRecoverFromStall = [delegate respondsToSelector:@selector(videoNodeDidRecoverFromStall:)];
    _delegateFlags.delegateVideoNodeDidFailToLoadValueForKey = [delegate respondsToSelector:@selector(videoNode:didFailToLoadValueForKey:asset:error:)];
  }
}

- (void)setGravity:(NSString *)gravity
{
  ASLockScopeSelf();
  if (!gravity) {
    gravity = AVLayerVideoGravityResizeAspect;
  }
  
  if (!ASCompareAssignObjects(_gravity, gravity)) {
    return;
  }
  
  if (_playerNode.isNodeLoaded) {
    ((AVPlayerLayer *)_playerNode.layer).videoGravity = gravity;
  }
  self.contentMode = ASContentModeFromVideoGravity(gravity);
  _gravity = gravity;
}

- (NSString *)gravity
{
  ASLockScopeSelf();
  return _gravity;
}

- (BOOL)muted
{
  ASLockScopeSelf();
  return _muted;
}

- (void)setMuted:(BOOL)muted
{
  ASLockScopeSelf();
  
  _player.muted = muted;
  _muted = muted;
}

#pragma mark - Video Playback

- (void)play
{
  ASLockScopeSelf();

  if (![self isStateChangeValid:ASVideoNodePlayerStatePlaying]) {
    return;
  }

  if (_player == nil) {
    ASUnlockScope(self);
    [self setNeedsPreload];
  }

  if (_playerNode == nil) {
    _playerNode = [self constructPlayerNode];

    {
      ASUnlockScope(self);
      [self addSubnode:_playerNode];
    }

    [self setNeedsLayout];
  }
  
  
  [_player play];
  _shouldBePlaying = YES;
}

- (BOOL)ready
{
  return _currentPlayerItem.status == AVPlayerItemStatusReadyToPlay;
}

- (void)pause
{
  ASLockScopeSelf();
  if (![self isStateChangeValid:ASVideoNodePlayerStatePaused]) {
    return;
  }
  [_player pause];
  _shouldBePlaying = NO;
}

- (BOOL)isPlaying
{
  ASLockScopeSelf();
  
  return (_player.rate > 0 && !_player.error);
}

- (BOOL)isStateChangeValid:(ASVideoNodePlayerState)state
{
  if (_delegateFlags.delegateVideNodeShouldChangePlayerStateTo) {
    if (![self.delegate videoNode:self shouldChangePlayerStateTo:state]) {
      return NO;
    }
  }
  return YES;
}

- (void)resetToPlaceholder
{
  ASLockScopeSelf();
  
  if (_playerNode != nil) {
    [_playerNode removeFromSupernode];
    _playerNode = nil;
  }
  
  [_player seekToTime:kCMTimeZero];
  [self pause];
}


#pragma mark - Playback observers

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
  if (self.shouldBePlaying && self.isVisible) {
    [self play];
  }
}

- (void)didPlayToEnd:(NSNotification *)notification
{
  self.playerState = ASVideoNodePlayerStateFinished;
  if (_delegateFlags.delegateVideoDidPlayToEnd) {
    [self.delegate videoDidPlayToEnd:self];
  }

  if (_shouldAutorepeat) {
    [_player seekToTime:kCMTimeZero];
    [self play];
  } else {
    [self pause];
  }
}

- (void)videoNodeDidStall:(NSNotification *)notification
{
  self.playerState = ASVideoNodePlayerStateLoading;
  if (_delegateFlags.delegateVideoNodeDidStallAtTimeInterval) {
    [self.delegate videoNode:self didStallAtTimeInterval:CMTimeGetSeconds(_player.currentItem.currentTime)];
  }
}

- (void)errorWhilePlaying:(NSNotification *)notification
{
  if ([notification.name isEqualToString:AVPlayerItemFailedToPlayToEndTimeNotification]) {
    NSLog(@"Failed to play video");
  } else if ([notification.name isEqualToString:AVPlayerItemNewErrorLogEntryNotification]) {
    AVPlayerItem *item = (AVPlayerItem *)notification.object;
    AVPlayerItemErrorLogEvent *logEvent = item.errorLog.events.lastObject;
    NSLog(@"AVPlayerItem error log entry added for video with error %@ status %@", item.error,
          (item.status == AVPlayerItemStatusFailed ? @"FAILED" : [NSString stringWithFormat:@"%ld", (long)item.status]));
    NSLog(@"Item is %@", item);
    
    if (logEvent) {
      NSLog(@"Log code %ld domain %@ comment %@", (long)logEvent.errorStatusCode, logEvent.errorDomain, logEvent.errorComment);
    }
  }
}

#pragma mark - Internal Properties

- (AVPlayerItem *)currentItem
{
  ASLockScopeSelf();
  return _currentPlayerItem;
}

- (void)setCurrentItem:(AVPlayerItem *)currentItem
{
  ASLockScopeSelf();

  [self removePlayerItemObservers:_currentPlayerItem];

  _currentPlayerItem = currentItem;

  if (currentItem != nil) {
    [self addPlayerItemObservers:currentItem];
  }
}

- (ASDisplayNode *)playerNode
{
  ASLockScopeSelf();
  return _playerNode;
}

- (void)setPlayerNode:(ASDisplayNode *)playerNode
{
  {
    ASLockScopeSelf();
    _playerNode = playerNode;
  }

  [self setNeedsLayout];
}

- (void)setPlayer:(AVPlayer *)player
{
  ASLockScopeSelf();

  [self removePlayerObservers:_player];

  _player = player;
  player.muted = _muted;
  ((AVPlayerLayer *)_playerNode.layer).player = player;

  if (player != nil) {
    [self addPlayerObservers:player];
  }
}

- (BOOL)shouldBePlaying
{
  ASLockScopeSelf();
  return _shouldBePlaying;
}

- (void)setShouldBePlaying:(BOOL)shouldBePlaying
{
  ASLockScopeSelf();
  _shouldBePlaying = shouldBePlaying;
}

#pragma mark - Lifecycle

- (void)dealloc
{
  [self removePlayerItemObservers:_currentPlayerItem];
  [self removePlayerObservers:_player];

  NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
  [notificationCenter removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

@end

#endif
