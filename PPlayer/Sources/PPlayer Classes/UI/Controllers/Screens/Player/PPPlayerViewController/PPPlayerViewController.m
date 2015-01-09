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

#import "PPPlayerViewController.h"
#import "PPMenuNavigationViewController.h"
#import "PPPlayerView.h"
#import "PPPlayer.h"
#import "PPPlayerPlaybackView.h"
#import "PPPlayerTrackTitleView.h"
#import "PPLibraryPlaylistItemModel.h"
#import "PPLibraryTrackModel.h"
#import "PPPlayerTrackSliderView.h"

@interface PPPlayerViewController () {
@private
    UIBarButtonItem *_currentPlaylistItem;
    PPPlayerView *_playerView;

    int64_t _lastPlayedItemID;
}
@end

@implementation PPPlayerViewController

#pragma mark - Init

- (void)designedInit {
    [super designedInit];
}

- (void)commonInit {
    [super commonInit];
    [self.menuNavigationViewController setMenuHidden:YES animated:NO];
}

#pragma mark - Lifecycle

- (void)loadView {
    [super loadView];

    _playerView = [[PPPlayerView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
    [_playerView setAutoresizingMask:UIViewAutoresizingNone];
    [self.view addSubview:_playerView];

    _currentPlaylistItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"CellIconPlaylist.png"]
                                                            style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(_currentPlaylistTapped)];
    self.navigationItem.rightBarButtonItem = _currentPlaylistItem;

    [_playerView.playbackView.repeatButton addTarget:self
                                              action:@selector(_toggleRepeatTapped)
                                    forControlEvents:UIControlEventTouchUpInside];
    [_playerView.playbackView.shuffleButton addTarget:self
                                               action:@selector(_toggleShuffleTapped)
                                     forControlEvents:UIControlEventTouchUpInside];

    [_playerView.playbackView.prevButton addTarget:self
                                            action:@selector(_prevButtonTapped)
                                  forControlEvents:UIControlEventTouchUpInside];
    [_playerView.playbackView.nextButton addTarget:self
                                            action:@selector(_nextButtonTapped)
                                  forControlEvents:UIControlEventTouchUpInside];
    [_playerView.playbackView.playPauseButton addTarget:self
                                                 action:@selector(_togglePlayPauseTapped)
                                       forControlEvents:UIControlEventTouchUpInside];
    [_playerView.trackSliderView.trackSlider addTarget:self
                                                action:@selector(_setPlayerCurrentTime)
                                      forControlEvents:UIControlEventTouchUpOutside];
    [_playerView.trackSliderView.trackSlider addTarget:self
                                                action:@selector(_setPlayerCurrentTime)
                                      forControlEvents:UIControlEventTouchUpInside];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.menuNavigationViewController setMenuHidden:YES animated:YES];

    [self _updatePlayerState];
    [self _startObservingPlayerState];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self _stopObservingPlayerState];
}

- (void)dealloc {
    _currentPlaylistItem = nil;
    _playerView = nil;
}

#pragma mark - Layout

- (void)performLayout {
    [super performLayout];

    CGFloat statusBarHeightReduction = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGFloat navbarHeightReduction = (self.navigationController.navigationBar.translucent ? self.navigationController.navigationBar.bounds.size.height : 0.0f);
    CGFloat tabbarHeightReduction = (self.tabBarController.tabBar.translucent ? self.tabBarController.tabBar.bounds.size.height : 0.0f);
    CGFloat heightReduction = navbarHeightReduction + tabbarHeightReduction + statusBarHeightReduction;

    [_playerView setFrame:CGRectMake(0.0f, -1.0f + navbarHeightReduction + statusBarHeightReduction,
            _playerView.superview.bounds.size.width, 1.0f + _playerView.superview.bounds.size.height - heightReduction)];
}

#pragma mark - Actions

- (void)_toggleRepeatTapped {
    [[PPPlayer sharedPlayer] toggleRepeat];
}

- (void)_toggleShuffleTapped {
    [[PPPlayer sharedPlayer] toggleShuffle];
}

- (void)_prevButtonTapped {
    [[PPPlayer sharedPlayer] prevTrack];
}

- (void)_nextButtonTapped {
    [[PPPlayer sharedPlayer] nextTrack];
}

- (void)_togglePlayPauseTapped {
    [[PPPlayer sharedPlayer] togglePlaing];
}

- (void)_setPlayerCurrentTime {
    [[PPPlayer sharedPlayer] setCurrentItemTime:_playerView.trackSliderView.trackSlider.value];
}

- (void)_currentPlaylistTapped {
    //
}

#pragma mark - NSNotificationCenter Observing

- (void)_startObservingPlayerState {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_updatePlayerVisualStateByNotificaion:)
                                                 name:PPPlayerStateChangedNotificationName
                                               object:NULL];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_updatePlayerVisualTrackingStateByNotificaion:)
                                                 name:PPPlayerStateTrackingChangedNotificationName
                                               object:NULL];
}

- (void)_stopObservingPlayerState {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)_updatePlayerVisualTrackingStateByNotificaion:(NSNotification *)notification {
    [self _updatePlayerVisualTrackingState:notification.object forced:NO];
}

- (void)_updatePlayerVisualStateByNotificaion:(NSNotification *)notification {
    [self _updatePlayerVisualState:notification.object];
}

#pragma mark - Updating Visual State

- (void)_updatePlayerState {
    [self _updatePlayerVisualState:[PPPlayer sharedPlayer]];
    [self _updatePlayerVisualTrackingState:[PPPlayer sharedPlayer] forced:NO];
}

- (void)_updatePlayerVisualState:(PPPlayer *)player {
    _playerView.playbackView.repeatButton.selected = player.repeatEnabled;
    _playerView.playbackView.shuffleButton.selected = player.shuffleEnabled;

    _playerView.playbackView.prevButton.enabled = player.prevTrackExists;
    _playerView.playbackView.nextButton.enabled = player.nextTrackExists;

    _playerView.playbackView.playPauseButton.enabled = player.currentPlaylistItem != nil;
    _playerView.playbackView.playPauseButton.selected = player.plaing;

    [_playerView.trackTitleView setTrackTitle:player.currentPlaylistItem.trackModel.title
                                  trackArtist:player.currentPlaylistItem.trackModel.albumModel.artistModel.title
                                andTrackAlbum:player.currentPlaylistItem.trackModel.albumModel.title];

    _playerView.trackSliderView.trackSlider.enabled = player.currentPlaylistItem != nil;

    if (_lastPlayedItemID != player.currentPlaylistItem.id) {
        [self _updatePlayerVisualTrackingState:player
                                        forced:YES];
    }
    _lastPlayedItemID = player.currentPlaylistItem.id;
}

- (void)_updatePlayerVisualTrackingState:(PPPlayer *)player forced:(BOOL)forced {
    [_playerView.trackSliderView setupCurrentTime:player.currentItemTime
                                         andTotal:player.totalItemTime
                                           forced:forced];
}

@end