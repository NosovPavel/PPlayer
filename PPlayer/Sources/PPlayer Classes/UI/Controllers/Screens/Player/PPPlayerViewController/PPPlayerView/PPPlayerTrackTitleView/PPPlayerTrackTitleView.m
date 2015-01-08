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

static const CGFloat sidePadding() {
    return 25.0f;
}

static CGFloat sideSize() {
    return 90;
}

static const CGFloat labelsPadding() {
    return 7.0f;
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
    [_titleLabel setTextAlignment:NSTextAlignmentCenter];
    [_titleLabel setFont:[UIFont systemFontOfSize:17.0f]];
    [_titleLabel setTextColor:[UIColor blackColor]];
    [self addSubview:_titleLabel];

    _subtitleLabel = [[UILabel alloc] init];
    [_subtitleLabel setTextAlignment:NSTextAlignmentCenter];
    [_subtitleLabel setFont:[UIFont systemFontOfSize:13.0f]];
    [_subtitleLabel setTextColor:[UIColor lightGrayColor]];
    [self addSubview:_subtitleLabel];

    [_titleLabel setText:@"I Hate Everything All About You"];
    [_subtitleLabel setText:@"Three Days Grace - One X"];
}

#pragma mark - Lifecycle

- (void)dealloc {
    _titleLabel = nil;
    _subtitleLabel = nil;
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];

    [_titleLabel sizeToFit];
    [_titleLabel setFrame:CGRectMake(sidePadding(),
            1.0f + [_titleLabel.superview convertPoint:_titleLabel.superview.center fromView:_titleLabel.superview.superview].y - _titleLabel.bounds.size.height - (labelsPadding() / 2.0f),
            _titleLabel.superview.bounds.size.width - sidePadding() * 2.0f,
            _titleLabel.bounds.size.height)];

    [_subtitleLabel sizeToFit];
    [_subtitleLabel setFrame:CGRectMake(sidePadding(),
            1.0f + [_subtitleLabel.superview convertPoint:_subtitleLabel.superview.center fromView:_subtitleLabel.superview.superview].y + (labelsPadding() / 2.0f),
            _subtitleLabel.superview.bounds.size.width - sidePadding() * 2.0f,
            _subtitleLabel.bounds.size.height)];
}

#pragma mark - Preferred Size

- (CGFloat)preferredSideSize {
    return sideSize();
}

@end