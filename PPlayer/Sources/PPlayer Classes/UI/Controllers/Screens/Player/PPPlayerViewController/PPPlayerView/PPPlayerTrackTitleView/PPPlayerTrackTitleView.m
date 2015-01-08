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

#import "PPPlayerTrackTitleView.h"

static CGFloat sideSize() {
    return 128.0f * screenK();
}

@interface PPPlayerTrackTitleView () {
@private
    UISlider *_trackSlider;
}
@end

@implementation PPPlayerTrackTitleView

#pragma mark - Init

- (void)_init {
    [super _init];

    self.backgroundColor = [UIColor whiteColor];

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