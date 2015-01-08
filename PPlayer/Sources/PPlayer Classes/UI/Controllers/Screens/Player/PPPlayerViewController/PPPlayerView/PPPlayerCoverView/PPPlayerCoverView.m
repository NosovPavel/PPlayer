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

#import "PPPlayerCoverView.h"

@interface PPPlayerCoverView () {
@private
    UIImageView *_coverImageView;
}
@end

static CGFloat coverPadding() {
    return 25.0f * screenK();
}

@implementation PPPlayerCoverView

#pragma mark - Init

- (void)_init {
    [super _init];

    self.backgroundColor = [UIColor yellowColor];

    _coverImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ArtworkPlaceHolderBig.png"]];
    _coverImageView.contentMode = UIViewContentModeScaleAspectFit;
    _coverImageView.backgroundColor = [UIColor greenColor];
    [self addSubview:_coverImageView];
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];

    [_coverImageView setFrame:CGRectMake(coverPadding(), coverPadding(),
            self.bounds.size.width - coverPadding() * 2.0f, self.bounds.size.height - coverPadding() * 2.0f)];
}

#pragma mark - Setters / Getters

- (UIImage *)coverImage {
    return _coverImageView.image;
}

- (void)setCoverImage:(UIImage *)coverImage {
    _coverImageView.image = coverImage;
}

@end