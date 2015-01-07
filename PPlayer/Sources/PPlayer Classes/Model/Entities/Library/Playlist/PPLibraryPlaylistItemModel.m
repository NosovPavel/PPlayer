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

#import "PPLibraryPlaylistItemModel.h"
#import "PPLibraryTrackModel.h"

@implementation PPLibraryPlaylistItemModel
- (BOOL)isEqual:(id)other {
    if ([other isKindOfClass:[self class]]) {
        PPLibraryPlaylistItemModel *otherModel = other;
        if (self.id == otherModel.id) {
            return YES;
        }
    }

    if (other == self)
        return YES;
    if (!other || ![[other class] isEqual:[self class]])
        return NO;

    return [self isEqualToModel:other];
}

- (BOOL)isEqualToModel:(PPLibraryPlaylistItemModel *)model {
    if (self.id == model.id)
        return YES;
    if (model == nil)
        return NO;
    if (self.trackModel != model.trackModel && ![self.trackModel isEqual:model.trackModel])
        return NO;
    if (self.id != model.id)
        return NO;
    return !(self.title != model.title && ![self.title isEqualToString:model.title]);
}

- (NSUInteger)hash {
    NSUInteger hash = (NSUInteger) self.id;
    hash = hash * 31u + [self.trackModel hash];
    hash = hash * 31u + [self.title hash] + [NSStringFromClass([self class]) hash];
    return hash;
}

@end