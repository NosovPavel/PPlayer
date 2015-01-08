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
    return 25.0f * screenK();
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

@interface PPPlayerTrackSliderView () {
@private
    UISlider *_trackSlider;
}
@end

@implementation PPPlayerTrackSliderView

#pragma mark - Init

- (void)_init {
    [super _init];

    self.backgroundColor = barTintColor();

    _trackSlider = [[UISlider alloc] init];
    [self addSubview:_trackSlider];
}

#pragma mark - Lifecycle

- (void)dealloc {
    _trackSlider = nil;
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];

    [_trackSlider sizeToFit];
    [_trackSlider setFrame:CGRectMake(sidePadding(), sidePadding() - _trackSlider.bounds.size.height / 2.0f,
            _trackSlider.superview.bounds.size.width - sidePadding() * 2.0f, _trackSlider.bounds.size.height)];
}

#pragma mark - Preferred Size

- (CGFloat)preferredSideSize {
    return sideSize();
}

@end