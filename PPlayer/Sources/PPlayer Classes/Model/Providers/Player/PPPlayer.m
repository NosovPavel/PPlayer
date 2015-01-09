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

#import <AVFoundation/AVFoundation.h>

@interface PPPlayer () {
@private
    AVAudioPlayer *_avAudioPlayer;
    NSMutableArray *_currentPlaylistItems;
    PPLibraryPlaylistItemModel *_currentPlaylistItem;

    BOOL _shuffleEnabled, _repeatEnabled;
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
    NSError *error = [NSError new];
    while (error) {
        [[AVAudioSession sharedInstance] setActive:YES
                                             error:&error];
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                               error:&error];
    }
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

    _currentPlaylistItems = nil;
    _currentPlaylistItem = nil;
}

#pragma mark - Internal

- (void)_updateState {
    //
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
    [self _updateState];
}

- (NSArray *)currentPlaylistItems {
    return _currentPlaylistItems;
}

- (BOOL)plaing {
    return _avAudioPlayer.playing;
}

- (BOOL)prevTrackExists {
    NSUInteger indexOfCurrentItem = [_currentPlaylistItems indexOfObject:_currentPlaylistItem];

    if (indexOfCurrentItem != NSNotFound) {
        return _repeatEnabled ? _currentPlaylistItems.count > 0 : indexOfCurrentItem > 0;
    }

    return NO;
}

- (BOOL)nextTrackExists {
    NSUInteger indexOfCurrentItem = [_currentPlaylistItems indexOfObject:_currentPlaylistItem];

    if (indexOfCurrentItem != NSNotFound) {
        return _repeatEnabled ? _currentPlaylistItems.count > 0 : indexOfCurrentItem < (_currentPlaylistItems.count - 1);
    }

    return NO;
}

#pragma mark - Playback Control

- (void)startPlaingItem:(PPLibraryPlaylistItemModel *)playlistItem {
    [_avAudioPlayer stop];
    _avAudioPlayer = nil;

    NSError *error;
    _currentPlaylistItem = playlistItem;
    _avAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[PPLibraryProvider trackURLForID:playlistItem.trackModel.id]
                                                            error:&error];

    if (!error) {
        [_avAudioPlayer play];
    }

    [self _updateState];
}

- (void)togglePlaing {

    [self _updateState];
}

- (void)nextTrack {

    [self _updateState];
}

- (void)prevTrack {

    [self _updateState];
}

- (void)toggleShuffle {
    _shuffleEnabled = !_shuffleEnabled;
    [self _updateState];
}

- (void)toggleRepeat {
    _repeatEnabled = !_repeatEnabled;
    [self _updateState];
}

@end