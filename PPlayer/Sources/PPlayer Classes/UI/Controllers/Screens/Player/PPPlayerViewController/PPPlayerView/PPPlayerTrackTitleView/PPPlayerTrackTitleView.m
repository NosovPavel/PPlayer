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
    return 90 * screenK();
}

@interface PPPlayerTrackTitleView () {
@private
    UILabel *_titleLabel, *_subtitleLabel;
}
@end

@implementation PPPlayerTrackTitleView

#pragma mark - Init

- (void)_init {
    [super _init];

    self.backgroundColor = [UIColor whiteColor];

    _titleLabel = [[UILabel alloc] init];
    [_titleLabel setFont:[UIFont systemFontOfSize:20.0f]];
    [_titleLabel setTextColor:[UIColor blackColor]];
    [self addSubview:_titleLabel];

    _subtitleLabel = [[UILabel alloc] init];
    [_subtitleLabel setFont:[UIFont systemFontOfSize:15.0f]];
    [_subtitleLabel setTextColor:[UIColor lightGrayColor]];
    [self addSubview:_subtitleLabel];
}

#pragma mark - Lifecycle

- (void)dealloc {
    _titleLabel = nil;
    _subtitleLabel = nil;
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
}

#pragma mark - Preferred Size

- (CGFloat)preferredSideSize {
    return sideSize();
}

@end