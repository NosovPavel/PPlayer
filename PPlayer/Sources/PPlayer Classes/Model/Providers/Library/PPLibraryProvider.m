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
#import <AVFoundation/AVFoundation.h>

@interface PPLibraryProvider () {
@private
    FMDatabaseQueue *_libraryDBQueue;
    PPFilesProvider *_filesProvider;
}
@end

@implementation PPLibraryProvider

#pragma mark - Preparing

+ (void)load {
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

    return [[NSURL alloc] initWithString:dataPath];
}

+ (NSURL *)libraryDBPath {
    NSString *rootPath = [[[self class] rootDirectory] absoluteString];
    NSString *dataPath = [rootPath stringByAppendingPathComponent:@"library.sqlite"];

    return [[NSURL alloc] initWithString:dataPath];
}

#pragma mark - Singleton

+ (PPLibraryProvider *)sharedLibrary {
    static PPLibraryProvider *_instance = nil;

    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }

    return _instance;
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

- (void)_importFile:(PPFileModel *)file withCompletionBlock:(void (^)())block {
    dispatch_barrier_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:file.url options:nil];

        NSArray *titles = [AVMetadataItem metadataItemsFromArray:asset.commonMetadata withKey:AVMetadataCommonKeyTitle keySpace:AVMetadataKeySpaceCommon];
        NSArray *artists = [AVMetadataItem metadataItemsFromArray:asset.commonMetadata withKey:AVMetadataCommonKeyArtist keySpace:AVMetadataKeySpaceCommon];
        NSArray *albumNames = [AVMetadataItem metadataItemsFromArray:asset.commonMetadata withKey:AVMetadataCommonKeyAlbumName keySpace:AVMetadataKeySpaceCommon];
        NSArray *genres = [AVMetadataItem metadataItemsFromArray:asset.commonMetadata withKey:AVMetadataCommonKeyType keySpace:AVMetadataKeySpaceCommon];

        AVMetadataItem *title = [titles firstObject];
        AVMetadataItem *artist = [artists firstObject];
        AVMetadataItem *albumName = [albumNames firstObject];
        AVMetadataItem *genre = [genres firstObject];

        NSString *currentSongTitle = (NSString *) [title.value copyWithZone:nil];
        NSString *currentSongArtist = (NSString *) [artist.value copyWithZone:nil];
        NSString *currentSongAlbumName = (NSString *) [albumName.value copyWithZone:nil];
        NSString *currentSongGenre = (NSString *) [genre.value copyWithZone:nil];

        if (block) {
            block();
        }
    });
}

#pragma mark - Import

- (void)importFiles:(NSArray *)files
  withProgressBlock:(void (^)(float progress))progressBlock
 andCompletionBlock:(void (^)())block {
    __block typeof(self) selfRef = self;
    __block float percent = 0.0f;

    dispatch_group_t importGroup = dispatch_group_create();

    NSMutableArray *reallyFiles = [NSMutableArray array];
    [files enumerateObjectsUsingBlock:^(PPFileModel *currentFile, NSUInteger idx, BOOL *stop) {
        if ([currentFile isKindOfClass:[PPFileModel class]]) {
            [reallyFiles addObject:currentFile];
        }
    }];

    float overall = (float) reallyFiles.count;
    float onePart = (1.0f / overall);
    __block float parts = 0;

    [reallyFiles enumerateObjectsUsingBlock:^(PPFileModel *currentFile, NSUInteger idx, BOOL *stop) {
        dispatch_group_enter(importGroup);
        dispatch_barrier_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (currentFile.type == PPFileTypeFolder) {
                NSArray *filesModelsAtURL = [selfRef->_filesProvider filesModelsAtURL:currentFile.url];
                [selfRef importFiles:filesModelsAtURL
                   withProgressBlock:^(float partProgress) {
                       percent = (parts + partProgress) * onePart;

                       float percentSnapshot = percent;
                       if (progressBlock) {
                           dispatch_barrier_async(dispatch_get_main_queue(), ^{
                               progressBlock(percentSnapshot);
                           });
                       }
                   }
                  andCompletionBlock:^{
                      parts++;
                      percent = parts * onePart;

                      float percentSnapshot = percent;
                      if (progressBlock) {
                          dispatch_barrier_async(dispatch_get_main_queue(), ^{
                              progressBlock(percentSnapshot);
                          });
                      }

                      dispatch_group_leave(importGroup);
                  }];
            } else {
                parts++;
                percent += onePart;

                [selfRef _importFile:currentFile withCompletionBlock:^{
                    float percentSnapshot = percent;
                    if (progressBlock) {
                        dispatch_barrier_async(dispatch_get_main_queue(), ^{
                            progressBlock(percentSnapshot);
                        });
                    }

                    dispatch_group_leave(importGroup);
                }];
            }
        });
    }];

    dispatch_group_notify(importGroup, dispatch_get_main_queue(), ^{
        if (block) {
            block();
        }
    });
}

#pragma mark - Tracks

- (void)tracksListWithCompletionBlock:(void (^)(NSArray *tracksList))block {

}

@end