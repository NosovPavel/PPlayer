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
    PPFilesProvider *_filesProvider;
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
    _filesProvider = [[PPFilesProvider alloc] init];
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
    _filesProvider = nil;
}

#pragma mark - Internal

- (void)importFile:(PPFileModel *)file {

}

#pragma mark - Import

- (void)importFiles:(NSArray *)files
  withProgressBlock:(void (^)(float progress))progressBlock
 andCompletionBlock:(void (^)())block {
    __block typeof(self) selfRef = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        __block float progress = 0.0f;
        dispatch_group_t importGroup = dispatch_group_create();
        [files enumerateObjectsUsingBlock:^(PPFileModel *currentFile, NSUInteger idx, BOOL *stop) {
            if ([currentFile isKindOfClass:[PPFileModel class]]) {
                float currentPart = 1.0f / (float) files.count;

                dispatch_group_enter(importGroup);
                if (currentFile.type == PPFileTypeFolder) {
                    NSArray *filesModelsAtURL = [selfRef->_filesProvider filesModelsAtURL:currentFile.url];
                    [selfRef importFiles:filesModelsAtURL
                       withProgressBlock:^(float partProgress) {
                           // :c its wrong, but anyway...
                           progress += currentPart * partProgress;
                           if (progressBlock) {
                               progressBlock(progress);
                           }
                       }
                      andCompletionBlock:^{
                          dispatch_group_leave(importGroup);
                      }];
                } else {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        progress += currentPart;

                        if (currentFile.type == PPFileTypeFileAudio) {
                            //import file
                            [selfRef importFile:currentFile];
                        }

                        if (progressBlock) {
                            progressBlock(progress);
                        }

                        dispatch_group_leave(importGroup);
                    });
                }
            }
        }];

        dispatch_group_notify(importGroup, dispatch_get_main_queue(), ^{
            if (block) {
                block();
            }
        });
    });
}

#pragma mark - Tracks

- (void)tracksListWithCompletionBlock:(void (^)(NSArray *tracksList))block {

}

@end