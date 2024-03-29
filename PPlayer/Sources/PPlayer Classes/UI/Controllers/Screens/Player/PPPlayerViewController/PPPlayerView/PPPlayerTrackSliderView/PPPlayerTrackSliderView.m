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

#import "PPPlayerTrackSliderView.h"

static NSString *displayValueFromSeconds(long seconds) {
    return seconds > 9 ? [NSString stringWithFormat:@"%ld", seconds] : [NSString stringWithFormat:@"0%ld", seconds];
}

static NSString *displayMinSecValueFromSeconds(long seconds) {
    long min = seconds / 60;
    long secondsReminder = seconds % 60;

    return [NSString stringWithFormat:@"%ld:%@", min, displayValueFromSeconds(secondsReminder)];
}

static const CGFloat sidePadding() {
    return 25.0f;
}

static const CGFloat timePadding() {
    return 10.0f;
}

static CGFloat sideSize() {
    return 2.0f + sidePadding() * 2;
}

static UIColor *barTintColor() {
    return [UIColor colorWithRed:(CGFloat) (247.0f / 255.0)
                           green:(CGFloat) (247.0f / 255.0)
                            blue:(CGFloat) (247.0f / 255.0)
                           alpha:1];
}

static NSString *timeLabelsPlaceholder = @"0:00";

@interface PPPlayerTrackSliderView () {
@private
    UISlider *_trackSlider;
    UILabel *_pastTimeLabel, *_remindsTimeLabel;

    BOOL _ignoreTriesToSetupSliderValueProgramatically;
}
@end

@implementation PPPlayerTrackSliderView
@synthesize trackSlider = _trackSlider;

#pragma mark - Init

- (void)_init {
    [super _init];

    self.backgroundColor = barTintColor();

    _trackSlider = [[UISlider alloc] init];
    _trackSlider.enabled = NO;
    [_trackSlider addTarget:self
                     action:@selector(_sliderValueChanged)
           forControlEvents:UIControlEventValueChanged];
    [_trackSlider addTarget:self
                     action:@selector(_sliderStartsScrubbing)
           forControlEvents:UIControlEventTouchDown];
    [_trackSlider addTarget:self
                     action:@selector(_sliderEndsScrubbing)
           forControlEvents:UIControlEventTouchUpInside];
    [_trackSlider addTarget:self
                     action:@selector(_sliderEndsScrubbing)
           forControlEvents:UIControlEventTouchUpOutside];
    [_trackSlider addTarget:self
                     action:@selector(_sliderEndsScrubbing)
           forControlEvents:UIControlEventTouchCancel];
    [self addSubview:_trackSlider];

    _pastTimeLabel = [[UILabel alloc] init];
    [_pastTimeLabel setTextAlignment:NSTextAlignmentRight];
    [_pastTimeLabel setFont:[UIFont systemFontOfSize:12.0f]];
    [_pastTimeLabel setTextColor:[UIColor blackColor]];
    [self addSubview:_pastTimeLabel];

    _remindsTimeLabel = [[UILabel alloc] init];
    [_remindsTimeLabel setTextAlignment:NSTextAlignmentLeft];
    [_remindsTimeLabel setFont:[UIFont systemFontOfSize:12.0f]];
    [_remindsTimeLabel setTextColor:[UIColor blackColor]];
    [self addSubview:_remindsTimeLabel];

    [_pastTimeLabel setText:timeLabelsPlaceholder];
    [_remindsTimeLabel setText:timeLabelsPlaceholder];
}

#pragma mark - Lifecycle

- (void)dealloc {
    _trackSlider = nil;
    _pastTimeLabel = nil;
    _remindsTimeLabel = nil;
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];

    [_pastTimeLabel sizeToFit];
    [_pastTimeLabel setFrame:CGRectMake(sidePadding(), (_pastTimeLabel.superview.bounds.size.height - _pastTimeLabel.bounds.size.height) / 2.0f,
            _pastTimeLabel.bounds.size.width, _pastTimeLabel.bounds.size.height)];

    [_remindsTimeLabel sizeToFit];
    [_remindsTimeLabel setFrame:CGRectMake(_remindsTimeLabel.superview.bounds.size.width - sidePadding() - _remindsTimeLabel.bounds.size.width, (_remindsTimeLabel.superview.bounds.size.height - _remindsTimeLabel.bounds.size.height) / 2.0f,
            _remindsTimeLabel.bounds.size.width, _remindsTimeLabel.bounds.size.height)];

    [_trackSlider sizeToFit];
    [_trackSlider setFrame:CGRectMake(_pastTimeLabel.frame.origin.x + _pastTimeLabel.bounds.size.width + timePadding(), sidePadding() - _trackSlider.bounds.size.height / 2.0f,
            _trackSlider.superview.bounds.size.width - sidePadding() * 2.0f - timePadding() * 2.0f - _pastTimeLabel.bounds.size.width - _remindsTimeLabel.bounds.size.width, _trackSlider.bounds.size.height)];
}

#pragma mark - Preferred Size

- (CGFloat)preferredSideSize {
    return sideSize();
}

#pragma mark - Internal

- (void)_updateLabels {
    [_pastTimeLabel setText:displayMinSecValueFromSeconds(lroundf(_trackSlider.value))];
    [_remindsTimeLabel setText:displayMinSecValueFromSeconds(lroundf(_trackSlider.maximumValue))];

    [self layoutSubviews];
}

#pragma mark - Interface

- (void)setupCurrentTime:(NSTimeInterval)current andTotal:(NSTimeInterval)total forced:(BOOL)forced {
    if (_ignoreTriesToSetupSliderValueProgramatically && !forced) {
        return;
    }

    _trackSlider.minimumValue = 0.0f;
    _trackSlider.maximumValue = (float) total;
    _trackSlider.value = ((float) current);

    [self _updateLabels];
}

#pragma mark - Interaction

- (void)_sliderStartsScrubbing {
    _ignoreTriesToSetupSliderValueProgramatically = YES;
}

- (void)_sliderEndsScrubbing {
    _ignoreTriesToSetupSliderValueProgramatically = NO;
}

- (void)_sliderValueChanged {
    [self _updateLabels];
}

@end