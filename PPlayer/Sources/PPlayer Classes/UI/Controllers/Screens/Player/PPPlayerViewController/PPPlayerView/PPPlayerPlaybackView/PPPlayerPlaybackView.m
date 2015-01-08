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

#import "PPPlayerPlaybackView.h"

static const CGFloat sidePadding() {
    return 25.0f;
}

static const CGFloat buttonsPadding() {
    return 50.0f;
}

static CGFloat sideSize() {
    return 80.0f;
}

static CGFloat borderWidth() {
    return sideSize() / 75.0f;
}

static CGFloat playButtonBorderSize() {
    return sideSize() - (1.0f / 3.0f) * sideSize();
}

static CGFloat playbackButtonsSize() {
    return 25.0f;
};

static CGFloat supportButtonsSize() {
    return 25.0f * (2.0f / 3.0f);
}

static UIColor *barTintColor() {
    return [UIColor colorWithRed:(CGFloat) (247.0f / 255.0)
                           green:(CGFloat) (247.0f / 255.0)
                            blue:(CGFloat) (247.0f / 255.0)
                           alpha:1];
}

@interface PPPlayerPlaybackView () {
@private
    UIButton *_repeatButton, *_shuffleButton;
    UIButton *_prevButton, *_playPauseButton, *_nextButton;
    UIView *_playCircle;
}
@end

@implementation PPPlayerPlaybackView

#pragma mark - Init

- (void)_init {
    [super _init];

    self.backgroundColor = barTintColor();

    //repeat and shuffle
    _repeatButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_repeatButton setImage:[UIImage imageNamed:@"PlayerIconRepeat.png"]
                   forState:UIControlStateNormal];
    [_repeatButton setBackgroundColor:self.backgroundColor];
    [_repeatButton setAutoresizingMask:UIViewAutoresizingNone];
    [self addSubview:_repeatButton];

    _shuffleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_shuffleButton setImage:[UIImage imageNamed:@"PlayerIconShuffle.png"]
                    forState:UIControlStateNormal];
    [_shuffleButton setBackgroundColor:self.backgroundColor];
    [_shuffleButton setAutoresizingMask:UIViewAutoresizingNone];
    [self addSubview:_shuffleButton];

    //playback
    _playCircle = [[UIView alloc] init];
    [_playCircle setClipsToBounds:YES];
    [_playCircle.layer setBorderColor:[UIColor blackColor].CGColor];
    [_playCircle.layer setBorderWidth:borderWidth()];
    [_playCircle.layer setCornerRadius:playButtonBorderSize() / 2.0f];
    [self addSubview:_playCircle];

    _playPauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_playPauseButton setImage:[UIImage imageNamed:@"PlayerIconPlay.png"]
                   forState:UIControlStateNormal];
    [_playPauseButton setImage:[UIImage imageNamed:@"PlayerIconPause.png"]
                      forState:UIControlStateSelected];
    [_playPauseButton setBackgroundColor:self.backgroundColor];
    [_playPauseButton setAutoresizingMask:UIViewAutoresizingNone];
    [self addSubview:_playPauseButton];

    _prevButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_prevButton setImage:[UIImage imageNamed:@"PlayerIconPrev.png"]
                 forState:UIControlStateNormal];
    [_prevButton setBackgroundColor:self.backgroundColor];
    [_prevButton setAutoresizingMask:UIViewAutoresizingNone];
    [self addSubview:_prevButton];

    _nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_nextButton setImage:[UIImage imageNamed:@"PlayerIconNext.png"]
                 forState:UIControlStateNormal];
    [_nextButton setBackgroundColor:self.backgroundColor];
    [_nextButton setAutoresizingMask:UIViewAutoresizingNone];
    [self addSubview:_nextButton];
}

#pragma mark - Lifecycle

- (void)dealloc {
    _repeatButton = nil;
    _shuffleButton = nil;

    _prevButton = nil;
    _playPauseButton = nil;
    _nextButton = nil;
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];

    //repeat and shuffle
    [_repeatButton setFrame:CGRectMake(sidePadding(), 0.0f,
            supportButtonsSize(), supportButtonsSize())];
    [_repeatButton setCenter:CGPointMake(_repeatButton.center.x, _repeatButton.superview.bounds.size.height / 2.0f)];

    [_shuffleButton setFrame:CGRectMake(_shuffleButton.superview.bounds.size.width - sidePadding() - supportButtonsSize(),
            supportButtonsSize(),
            supportButtonsSize(),
            supportButtonsSize())];
    [_shuffleButton setCenter:CGPointMake(_shuffleButton.center.x, _shuffleButton.superview.bounds.size.height / 2.0f)];

    //playback
    [_playPauseButton setFrame:CGRectMake(0.0f, 0.0f, playbackButtonsSize(), playbackButtonsSize())];
    [_playPauseButton setCenter:[_playPauseButton.superview convertPoint:_playPauseButton.superview.center
                                                                fromView:_playPauseButton.superview.superview]];
    [_playCircle setFrame:CGRectMake(0.0f, 0.0f, playButtonBorderSize(), playButtonBorderSize())];
    [_playCircle setCenter:_playPauseButton.center];

    [_prevButton setFrame:CGRectMake(_playPauseButton.frame.origin.x - buttonsPadding() - playbackButtonsSize(),
            0.0f,
            playbackButtonsSize(), playbackButtonsSize())];
    [_prevButton setCenter:CGPointMake(_prevButton.frame.origin.x + playbackButtonsSize() / 2.0f,
            _playPauseButton.center.y)];

    [_nextButton setFrame:CGRectMake(_playPauseButton.frame.origin.x + _playPauseButton.bounds.size.width + buttonsPadding(),
            0.0f,
            playbackButtonsSize(), playbackButtonsSize())];
    [_nextButton setCenter:CGPointMake(_nextButton.frame.origin.x + playbackButtonsSize() / 2.0f,
            _playPauseButton.center.y)];
}

#pragma mark - Preferred Size

- (CGFloat)preferredSideSize {
    return sideSize();
}

@end