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

#import "PPLibraryProvider.h"
#import "FMDB.h"

@interface PPLibraryProvider () {
@private
    FMDatabaseQueue *_libraryDBQueue;
    NSFileManager *_fileManager;
}
@end

@implementation PPLibraryProvider

#pragma mark - Preparing

+ (void)initialize {
    if (![[NSFileManager defaultManager] fileExistsAtPath:[[[self class] rootDirectory] absoluteString]]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:[[[self class] rootDirectory] absoluteString]
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:NULL];
    }
}

#pragma mark - Paths

+ (NSURL *)rootDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths lastObject];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"/.Library"];

    return [NSURL fileURLWithPath:dataPath];
}

+ (NSURL *)libraryDBPath {
    NSString *rootPath = [[[self class] rootDirectory] absoluteString];
    NSString *dataPath = [rootPath stringByAppendingPathComponent:@"/library.sqlite"];

    return [NSURL fileURLWithPath:dataPath];
}

#pragma mark - Init

- (void)_init {
    _fileManager = [[NSFileManager alloc] init];
    _libraryDBQueue = [FMDatabaseQueue databaseQueueWithPath:[[[self class] libraryDBPath] absoluteString]];
}

#pragma mark - Lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        [self _init];
    }

    return self;
}

- (void)dealloc {
    [_libraryDBQueue close];

    _libraryDBQueue = nil;
    _fileManager = nil;
}

#pragma mark - Internal

#pragma mark - Interface
#pragma mark -
#pragma mark - Import

- (void)importFilesURLs:(NSArray *)filesURLs
      withProgressBlock:(void (^)(float progress))progressBlock
     andCompletionBlock:(void (^)())block {

}

#pragma mark - Tracks

- (void)tracksListWithCompletionBlock:(void (^)(NSArray *tracksList))block {

}


@end