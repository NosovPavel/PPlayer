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

#import "PPPlayerVisualizer.h"

static const CGSize snapshotSize() {
    return CGSizeMake(350.0f, 350.0f);
}

@implementation PPPlayerVisualizer

#pragma mark - Setters / Getters

- (UIImage *)currentSnapshot {
    UIImage *snapshot = nil;

    UIGraphicsBeginImageContextWithOptions(snapshotSize(), NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetBlendMode(context, kCGBlendModeMultiply);

    CGFloat margin = 0.0f;
    for (int c = 0; c < _channelsValues.count; c++) {
        float width = snapshotSize().width / _channelsValues.count - margin;
        float x = width * c;
        float height = snapshotSize().height;

        float normalizedLevel = (float) ((([_channelsValues[(NSUInteger) c] floatValue] + 160) / 160.f) * 0.85);
        float levelHeight = height * normalizedLevel;

        CGContextSetFillColorWithColor(context, [[UIColor greenColor] CGColor]);
        CGContextFillRect(context, CGRectMake(x, height - levelHeight, width, levelHeight));
    }

    snapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return snapshot;
}

@end