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
}
@end

@implementation PPPlayerTrackSliderView

#pragma mark - Init

- (void)_init {
    [super _init];

    self.backgroundColor = barTintColor();

    _trackSlider = [[UISlider alloc] init];
    _trackSlider.userInteractionEnabled = NO;
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

@end