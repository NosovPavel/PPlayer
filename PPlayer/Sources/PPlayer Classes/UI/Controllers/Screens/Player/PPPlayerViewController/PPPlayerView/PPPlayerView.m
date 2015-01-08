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

#import "PPPlayerView.h"
#import "PPPlayerCoverView.h"
#import "PPPlayerPlaybackView.h"
#import "PPPlayerTrackSliderView.h"
#import "PPPlayerTrackTitleView.h"

@implementation PPView

- (void)_init {
    //
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self _init];
    }

    return self;
}

@end

@interface PPPlayerView () {
@private
    PPPlayerCoverView *_coverView;
    PPPlayerTrackSliderView *_trackSliderView;
    PPPlayerTrackTitleView *_trackTitleView;
    PPPlayerPlaybackView *_playbackView;
}
@end

@implementation PPPlayerView
@synthesize coverView = _coverView;
@synthesize trackSliderView = _trackSliderView;
@synthesize trackTitleView = _trackTitleView;
@synthesize playbackView = _playbackView;

#pragma mark - Init

- (void)_init {
    [super _init];

    _coverView = [[PPPlayerCoverView alloc] init];
    [self addSubview:_coverView];

    _trackSliderView = [[PPPlayerTrackSliderView alloc] init];
    [self addSubview:_trackSliderView];

    _trackTitleView = [[PPPlayerTrackTitleView alloc] init];
    [self addSubview:_trackTitleView];

    _playbackView = [[PPPlayerPlaybackView alloc] init];
    [self addSubview:_playbackView];
}

#pragma mark - Lifecycle

- (void)dealloc {
    _coverView = nil;
    _trackSliderView = nil;
    _trackTitleView = nil;
    _playbackView = nil;
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat playbackHeight = [_playbackView preferredSideSize];
    [_playbackView setFrame:CGRectMake(0.0f, _playbackView.superview.bounds.size.height - playbackHeight,
            _playbackView.superview.bounds.size.width, playbackHeight)];

    CGFloat trackTitleHeight = [_trackTitleView preferredSideSize];
    [_trackTitleView setFrame:CGRectMake(0.0f, _trackTitleView.superview.bounds.size.height - (playbackHeight + trackTitleHeight),
            _trackSliderView.superview.bounds.size.width, trackTitleHeight)];

    CGFloat trackSliderHeight = [_trackSliderView preferredSideSize];
    [_trackSliderView setFrame:CGRectMake(0.0f, _trackSliderView.superview.bounds.size.height - (playbackHeight + trackSliderHeight + trackTitleHeight),
            _trackSliderView.superview.bounds.size.width, trackSliderHeight)];

    [_coverView setFrame:CGRectMake(0.0f, 0.0f,
            _coverView.superview.bounds.size.width, _coverView.superview.bounds.size.height - (playbackHeight + trackSliderHeight + trackTitleHeight))];
}

@end