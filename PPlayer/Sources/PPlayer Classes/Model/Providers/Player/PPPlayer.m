//
//  Copyright © 2015 Alexander Orlov
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "PPPlayer.h"
#import "PPLibraryPlaylistItemModel.h"
#import "PPLibraryProvider.h"
#import "PPPlayerVisualizer.h"

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

static NSString *titlePlaceholder() {
    return NSLocalizedString(@"Not plaing now", nil);
}

static NSString *subTitlePlaceholder() {
    return NSLocalizedString(@"Unknown artist - Unkwnown album", nil);
}

static UIImage *artworkPlaceholder() {
    return [UIImage imageNamed:@"ArtworkPlaceHolderBig.png"];
}

@interface PPPlayer () <AVAudioPlayerDelegate> {
@private
    AVAudioPlayer *_avAudioPlayer;
    NSMutableArray *_currentPlaylistItems, *_shuffledPlaylistItems;
    PPLibraryPlaylistItemModel *_currentPlaylistItem;
    CADisplayLink *_displayLink;
    PPPlayerVisualizer *_visualizer;

    BOOL _shuffleEnabled, _repeatEnabled, _visualizationInsteadArtwork;
}
@end

@implementation PPPlayer
@synthesize shuffleEnabled = _shuffleEnabled;
@synthesize repeatEnabled = _repeatEnabled;

#pragma mark - Singleton

+ (PPPlayer *)sharedPlayer {
    static PPPlayer *_instance = nil;

    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }

    return _instance;
}

#pragma mark - Init

- (void)_init {
    //configure session until success
    NSError *error = [self _configurateSession];

    while (error) {
        error = [self _configurateSession];
    }

    _visualizationInsteadArtwork = NO;
    _visualizer = [PPPlayerVisualizer new];
}

- (NSError *)_configurateSession {
    NSError *error = nil;

    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                           error:&error];
    [[AVAudioSession sharedInstance] setActive:YES
                                         error:&error];

    return error;
}

#pragma mark - Lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        [self _init];
    }

    return self;
}

- (void)dealloc {
    [_avAudioPlayer stop];
    _avAudioPlayer = nil;

    [_displayLink invalidate];
    _displayLink = nil;

    _currentPlaylistItems = nil;
    _shuffledPlaylistItems = nil;
    _currentPlaylistItem = nil;
}

#pragma mark - Internal

- (void)_updateState {
    [[NSNotificationCenter defaultCenter] postNotificationName:PPPlayerStateChangedNotificationName
                                                        object:self];
    [self _updateRemoteControlsState];
}

- (void)_updateTrackingState {
    [[NSNotificationCenter defaultCenter] postNotificationName:PPPlayerStateTrackingChangedNotificationName
                                                        object:self];
    [self _updateRemoteControlsState];
}

- (void)_updateNowPlayingItemState {
    [[NSNotificationCenter defaultCenter] postNotificationName:PPPlayerStateNowPlayingItemChangedNotificationName
                                                        object:self];
}

- (void)_updateRemoteControlsState {
    if (self == [PPPlayer sharedPlayer]) {
        NSMutableDictionary *songInfo = [[NSMutableDictionary alloc] init];

        songInfo[MPMediaItemPropertyTitle] = _currentPlaylistItem.trackModel.title.length > 0 ?
                _currentPlaylistItem.trackModel.title :
                titlePlaceholder();
        songInfo[MPMediaItemPropertyArtist] = _currentPlaylistItem.trackModel.albumModel.artistModel.title.length +
                _currentPlaylistItem.trackModel.albumModel.title.length > 0 ?
                [NSString stringWithFormat:@"%@ - %@", _currentPlaylistItem.trackModel.albumModel.artistModel.title, _currentPlaylistItem.trackModel.albumModel.title] :
                subTitlePlaceholder();

        songInfo[MPMediaItemPropertyPlaybackDuration] = @(self.totalItemTime);
        songInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(self.currentItemTime);

        songInfo[MPMediaItemPropertyArtwork] = [[MPMediaItemArtwork alloc] initWithImage:self.currentArtwork];

        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:songInfo];
    }
}

#pragma mark - Setters / Getters

- (PPLibraryPlaylistItemModel *)currentPlaylistItem {
    return _currentPlaylistItem;
}

- (void)setCurrentPlaylistItems:(NSArray *)currentPlaylistItems {
    NSMutableArray *newPlaylistItems = [NSMutableArray array];
    [currentPlaylistItems enumerateObjectsUsingBlock:^(PPLibraryPlaylistItemModel *iterItem, NSUInteger idx, BOOL *stop) {
        if ([iterItem isKindOfClass:[PPLibraryPlaylistItemModel class]]) {
            [newPlaylistItems addObject:iterItem];
        }
    }];

    _currentPlaylistItems = newPlaylistItems;

    if (_shuffleEnabled) {
        _shuffledPlaylistItems = [NSMutableArray array];
    }

    [self _updateState];
}

- (NSArray *)currentPlaylistItems {
    return _currentPlaylistItems;
}

#pragma mark -

- (BOOL)plaing {
    return _avAudioPlayer.playing;
}

- (BOOL)prevTrackExists {
    if (_currentPlaylistItems != nil) {
        NSMutableArray *currentSourceOfItems;
        currentSourceOfItems = !_shuffleEnabled ? _currentPlaylistItems : _shuffledPlaylistItems;

        NSUInteger indexOfCurrentItem = [currentSourceOfItems indexOfObject:_currentPlaylistItem];

        if (currentSourceOfItems != nil && indexOfCurrentItem != NSNotFound) {
            return _repeatEnabled ? _currentPlaylistItems.count > 0 : (indexOfCurrentItem > 0);
        }
    }

    return NO;
}

- (BOOL)nextTrackExists {
    if (_currentPlaylistItems != nil) {
        NSMutableArray *currentSourceOfItems;
        NSUInteger extraIndex = 0;
        if (!_shuffleEnabled) {
            currentSourceOfItems = _currentPlaylistItems;
        } else {
            currentSourceOfItems = _shuffledPlaylistItems;

            if (_shuffledPlaylistItems.count < _currentPlaylistItems.count) {
                extraIndex = 1;
            }
        }

        NSUInteger indexOfCurrentItem = [currentSourceOfItems indexOfObject:_currentPlaylistItem];

        if (currentSourceOfItems != nil && indexOfCurrentItem != NSNotFound) {
            return _repeatEnabled ? _currentPlaylistItems.count > 0 : (indexOfCurrentItem < (_currentPlaylistItems.count - 1 + extraIndex));
        }
    }

    return NO;
}

#pragma mark -

- (void)setCurrentItemTime:(NSTimeInterval)currentItemTime {
    if (currentItemTime >= 0 && currentItemTime < self.totalItemTime) {
        _avAudioPlayer.currentTime = currentItemTime;
    }
}

- (NSTimeInterval)currentItemTime {
    return _avAudioPlayer.currentTime;
}

- (NSTimeInterval)totalItemTime {
    return _avAudioPlayer.duration;
}

#pragma mark -

- (UIImage *)currentArtwork {
    if (_visualizationInsteadArtwork) {
        [_avAudioPlayer updateMeters];

        NSMutableArray *channelsValues = [NSMutableArray array];

        for (int c = 0; c < _avAudioPlayer.numberOfChannels; c++) {
            float level = [_avAudioPlayer averagePowerForChannel:(NSUInteger) c];
            [channelsValues addObject:@(level)];
        }

        [_visualizer setChannelsValues:channelsValues];

        return [_visualizer currentSnapshot];
    }

    return artworkPlaceholder();
}

#pragma mark -

- (BOOL)visualizationInsteadArtwork {
    return _visualizationInsteadArtwork;
}

- (void)setVisualizationInsteadArtwork:(BOOL)visualizationInsteadArtwork {
    _visualizationInsteadArtwork = visualizationInsteadArtwork;
    _avAudioPlayer.meteringEnabled = _visualizationInsteadArtwork;
}

#pragma mark - Playback Control

- (void)startPlaingItem:(PPLibraryPlaylistItemModel *)playlistItem {
    [_avAudioPlayer stop];
    _avAudioPlayer = nil;

    [_displayLink invalidate];
    _displayLink = nil;

    NSError *error;
    _currentPlaylistItem = playlistItem;

    if (_currentPlaylistItem) {
        if (_shuffleEnabled && ![_shuffledPlaylistItems containsObject:_currentPlaylistItem]) {
            [_shuffledPlaylistItems addObject:_currentPlaylistItem];
        }

        _avAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[PPLibraryProvider trackURLForID:playlistItem.trackModel.id]
                                                                error:&error];
        _avAudioPlayer.delegate = self;
        _avAudioPlayer.meteringEnabled = _visualizationInsteadArtwork;

        if (!error) {
            [_avAudioPlayer play];
            _displayLink = [CADisplayLink displayLinkWithTarget:self
                                                       selector:@selector(onDisplay)];
            [_displayLink addToRunLoop:[NSRunLoop currentRunLoop]
                               forMode:NSDefaultRunLoopMode];

            [self _updateNowPlayingItemState];
        }
    }

    [self _updateState];
    [self _updateTrackingState];
}

- (void)togglePlaing {
    if (_avAudioPlayer) {
        _avAudioPlayer.playing ? [_avAudioPlayer pause] : [_avAudioPlayer play];
        [self _updateState];
    }
}

- (void)nextTrack {
    if ([self nextTrackExists]) {
        if (_currentPlaylistItems != nil) {
            NSMutableArray *currentSourceOfItems;
            if (!_shuffleEnabled) {
                currentSourceOfItems = _currentPlaylistItems;
            } else {
                currentSourceOfItems = _shuffledPlaylistItems;

                if (_shuffledPlaylistItems.count < _currentPlaylistItems.count) {
                    NSUInteger randomIndexOfNextShuffledTrack = 0;
                    while ([_shuffledPlaylistItems containsObject:_currentPlaylistItems[randomIndexOfNextShuffledTrack]]) {
                        randomIndexOfNextShuffledTrack = arc4random_uniform((unsigned int) _currentPlaylistItems.count);
                    }
                    [_shuffledPlaylistItems addObject:_currentPlaylistItems[randomIndexOfNextShuffledTrack]];
                }
            }

            NSUInteger indexOfCurrentItem = [currentSourceOfItems indexOfObject:_currentPlaylistItem];

            if (indexOfCurrentItem == NSNotFound) {
                [self _updateState];
                return;
            }

            NSUInteger indexOfNextItem = indexOfCurrentItem + 1;
            BOOL inBounds = NSLocationInRange(indexOfNextItem, NSMakeRange(0, currentSourceOfItems.count));

            if (inBounds) {
                [self startPlaingItem:currentSourceOfItems[indexOfNextItem]];
                return;
            } else if (_repeatEnabled && currentSourceOfItems.count > 0) {
                [self startPlaingItem:[currentSourceOfItems firstObject]];
                return;
            }
        }
    }

    [self _updateState];
}

- (void)prevTrack {
    if ([self prevTrackExists]) {
        if (_currentPlaylistItems != nil) {
            NSMutableArray *currentSourceOfItems;
            if (!_shuffleEnabled) {
                currentSourceOfItems = _currentPlaylistItems;
            } else {
                currentSourceOfItems = _shuffledPlaylistItems;
            }

            NSUInteger indexOfCurrentItem = [currentSourceOfItems indexOfObject:_currentPlaylistItem];

            if (indexOfCurrentItem == NSNotFound) {
                [self _updateState];
                return;
            }

            NSUInteger indexOfNextItem = indexOfCurrentItem - 1;
            BOOL inBounds = NSLocationInRange(indexOfNextItem, NSMakeRange(0, currentSourceOfItems.count));

            if (inBounds) {
                [self startPlaingItem:currentSourceOfItems[indexOfNextItem]];
                return;
            } else if (_repeatEnabled && currentSourceOfItems.count > 0) {
                [self startPlaingItem:[currentSourceOfItems lastObject]];
                return;
            }
        }
    }

    [self _updateState];
}

- (void)toggleShuffle {
    _shuffleEnabled = !_shuffleEnabled;
    _shuffledPlaylistItems = _shuffleEnabled ? [NSMutableArray array] : nil;

    if (_currentPlaylistItem) {
        [_shuffledPlaylistItems addObject:_currentPlaylistItem];
    }

    [self _updateState];
}

- (void)toggleRepeat {
    _repeatEnabled = !_repeatEnabled;
    [self _updateState];
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [self nextTrack];
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    [self nextTrack];
}

- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player {
    [self _updateState];
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player {
    if (!player.playing) {
        [player play];
    }
    [self _updateState];
}

#pragma mark - CADisplayLink Callback

- (void)onDisplay {
    [self _updateTrackingState];
}

@end