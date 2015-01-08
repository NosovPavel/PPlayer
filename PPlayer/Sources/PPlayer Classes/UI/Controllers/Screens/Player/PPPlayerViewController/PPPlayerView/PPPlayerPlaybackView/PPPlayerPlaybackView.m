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
    return 25.0f * screenK();
}

static const CGFloat buttonsPadding() {
    return 25.0f * screenK();
}

static CGFloat sideSize() {
    return 100.0f * screenK();
}

static CGFloat borderWidth() {
    return sideSize() / 60.0f;
}

static CGFloat playButtonSize() {
    return sideSize() - (1.0f / 3.0f) * sideSize();
}

static CGFloat prevNextButtonsSize() {
    return (3.0f / 4.0f) * playButtonSize();
};

static CGFloat supportButtonsSize() {
    return 25.0f * screenK();
}

@interface PPPlayerPlaybackView () {
@private
    UIButton *_repeatButton, *_shuffleButton;
    UIButton *_prevButton, *_playPauseButton, *_nextButton;
}
@end

@implementation PPPlayerPlaybackView

#pragma mark - Init

- (void)_init {
    [super _init];

    self.backgroundColor = [UIColor whiteColor];

    //repeat and shuffle
    _repeatButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_repeatButton setImage:[UIImage imageNamed:@"PlayerIconRepeat.png"]
                   forState:UIControlStateNormal];
    [_repeatButton setBackgroundColor:[UIColor whiteColor]];
    [_repeatButton setAutoresizingMask:UIViewAutoresizingNone];
    [self addSubview:_repeatButton];

    _shuffleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_shuffleButton setImage:[UIImage imageNamed:@"PlayerIconShuffle.png"]
                    forState:UIControlStateNormal];
    [_shuffleButton setBackgroundColor:[UIColor whiteColor]];
    [_shuffleButton setAutoresizingMask:UIViewAutoresizingNone];
    [self addSubview:_shuffleButton];

    //playback
    _playPauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    /*[_playPauseButton setImage:[UIImage imageNamed:@"PlayerIconPlay.png"]
                   forState:UIControlStateNormal];
    [_playPauseButton setImage:[UIImage imageNamed:@"PlayerIconPause.png"]
                      forState:UIControlStateSelected];*/
    [_playPauseButton setClipsToBounds:YES];
    [_playPauseButton.layer setBorderColor:[UIColor blackColor].CGColor];
    [_playPauseButton.layer setBorderWidth:borderWidth()];
    [_playPauseButton.layer setCornerRadius:playButtonSize() / 2.0f];
    [_playPauseButton setBackgroundColor:[UIColor whiteColor]];
    [_playPauseButton setAutoresizingMask:UIViewAutoresizingNone];
    [self addSubview:_playPauseButton];

    _prevButton = [UIButton buttonWithType:UIButtonTypeCustom];
    /*[_prevButton setImage:[UIImage imageNamed:@"PlayerIconPrev.png"]
                      forState:UIControlStateNormal];*/
    [_prevButton setClipsToBounds:YES];
    [_prevButton.layer setBorderColor:[UIColor blackColor].CGColor];
    [_prevButton.layer setBorderWidth:borderWidth()];
    [_prevButton.layer setCornerRadius:prevNextButtonsSize() / 2.0f];
    [_prevButton setBackgroundColor:[UIColor whiteColor]];
    [_prevButton setAutoresizingMask:UIViewAutoresizingNone];
    [self addSubview:_prevButton];

    _nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    /*[_nextButton setImage:[UIImage imageNamed:@"PlayerIconNext.png"]
                 forState:UIControlStateNormal];*/
    [_nextButton setClipsToBounds:YES];
    [_nextButton.layer setBorderColor:[UIColor blackColor].CGColor];
    [_nextButton.layer setBorderWidth:borderWidth()];
    [_nextButton.layer setCornerRadius:prevNextButtonsSize() / 2.0f];
    [_nextButton setBackgroundColor:[UIColor whiteColor]];
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
    [_playPauseButton setFrame:CGRectMake(0.0f, 0.0f, playButtonSize(), playButtonSize())];
    [_playPauseButton setCenter:[_playPauseButton.superview convertPoint:_playPauseButton.superview.center
                                                                fromView:_playPauseButton.superview.superview]];

    [_prevButton setFrame:CGRectMake(_playPauseButton.frame.origin.x - buttonsPadding() - prevNextButtonsSize(),
            0.0f,
            prevNextButtonsSize(), prevNextButtonsSize())];
    [_prevButton setCenter:CGPointMake(_prevButton.frame.origin.x + prevNextButtonsSize() / 2.0f,
            _playPauseButton.center.y)];

    [_nextButton setFrame:CGRectMake(_playPauseButton.frame.origin.x + _playPauseButton.bounds.size.width + buttonsPadding(),
            0.0f,
            prevNextButtonsSize(), prevNextButtonsSize())];
    [_nextButton setCenter:CGPointMake(_nextButton.frame.origin.x + prevNextButtonsSize() / 2.0f,
            _playPauseButton.center.y)];
}

#pragma mark - Preferred Size

- (CGFloat)preferredSideSize {
    return sideSize();
}

@end