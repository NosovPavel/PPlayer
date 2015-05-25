//
//  Copyright © 2014-2015 Alexander Orlov
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

#import "PPFilesProvider.h"

#import <MobileCoreServices/MobileCoreServices.h>

@interface PPFilesProvider () {
@private
    NSFileManager *_fileManager;
}
@end

@implementation PPFilesProvider

#pragma mark - Preparing

+ (void)load {
    if (![[NSFileManager defaultManager] fileExistsAtPath:[[[self class] urlInboxRoot] path]]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:[[[self class] urlInboxRoot] path]
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:NULL];
    }
}

#pragma mark - Init

- (void)_init {
    _fileManager = [[NSFileManager alloc] init];
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
    _fileManager = nil;
}

#pragma mark - Interface

+ (NSURL *)urlInboxRoot {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths lastObject];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"/Inbox"];

    return [NSURL fileURLWithPath:dataPath];
}

- (void)filesModelsAtURL:(NSURL *)rootURL withCompletionBlock:(void (^)(NSArray *files))block {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *resultArray = [NSMutableArray array];
        NSArray *filesList = [_fileManager contentsOfDirectoryAtURL:rootURL
                                         includingPropertiesForKeys:nil
                                                            options:NSDirectoryEnumerationSkipsHiddenFiles
                                                              error:NULL];
        NSMutableArray *directoriesOnly = [NSMutableArray array];
        [filesList enumerateObjectsUsingBlock:^(NSURL *currentURL, NSUInteger idx, BOOL *stop) {
            PPFileType type;

            NSNumber *isDirectory;
            BOOL success = [currentURL getResourceValue:&isDirectory
                                                 forKey:NSURLIsDirectoryKey
                                                  error:nil];

            if (success && [isDirectory boolValue]) {
                type = PPFileTypeFolder;
            } else {
                type = PPFileTypeFile;

                NSString *file = [[currentURL absoluteString] copy];
                CFStringRef fileExtension = (__bridge CFStringRef) [file pathExtension];
                CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);

                if (UTTypeConformsTo(fileUTI, kUTTypeAudio)) {
                    type = PPFileTypeFileAudio;
                }

                CFRelease(fileUTI);
            }

            NSString *name = [NSString stringWithFormat:@"%@", [[currentURL absoluteString] lastPathComponent]];
            PPFileModel *fileModel = [PPFileModel modelWithUrl:currentURL
                                                         title:name
                                                          type:type];

            if (fileModel.isSupportedToPlay) {
                fileModel.title = [fileModel.title stringByDeletingPathExtension];
            }

            fileModel.title = [fileModel.title stringByRemovingPercentEncoding];

            if (type == PPFileTypeFolder) {
                [directoriesOnly addObject:fileModel];
            } else {
                [resultArray addObject:fileModel];
            }
        }];

        [resultArray insertObjects:directoriesOnly
                         atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, directoriesOnly.count)]];

        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block([resultArray copy]);
            });
        }
    });
}

- (void)removeFileAtURL:(NSURL *)url {
    [_fileManager removeItemAtURL:url error:NULL];
}

- (void)moveFileFromURL:(NSURL *)srcUrl toURL:(NSURL *)destUrl {
    if ([_fileManager fileExistsAtPath:[destUrl path]]) {
        [self removeFileAtURL:destUrl];
    }

    [_fileManager moveItemAtURL:srcUrl toURL:destUrl error:NULL];
}

@end