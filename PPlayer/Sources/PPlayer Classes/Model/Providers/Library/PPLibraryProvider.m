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

@interface NSString (AVMetadataItemEncodingFixing)
- (NSString *)fixedEncodingString;
@end

@implementation NSString (AVMetadataItemEncodingFixing)
- (NSString *)fixedEncodingString {
    if ([self canBeConvertedToEncoding:NSWindowsCP1252StringEncoding]) {
        const char *cString = [self cStringUsingEncoding:NSWindowsCP1252StringEncoding];
        return [NSString stringWithCString:cString encoding:NSWindowsCP1251StringEncoding];
    }

    return self;
}
@end

@interface PPLibraryProvider () {
@private
    FMDatabaseQueue *_libraryDBQueue;
    PPFilesProvider *_filesProvider;
}
@end

@implementation PPLibraryProvider

#pragma mark - Preparing

+ (void)load {
    if (![[NSFileManager defaultManager] fileExistsAtPath:[[[self class] rootDirectory] path]]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:[[[self class] rootDirectory] path]
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
    NSURL *libraryURL = [[[self class] rootDirectory] URLByAppendingPathComponent:@"library.sqlite"];

    return libraryURL;
}

+ (NSURL *)trackPathForID:(int64_t)trackID {
    NSURL *trackURL = [[[self class] rootDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"%lld.pptrack", trackID]];

    return trackURL;
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
    _libraryDBQueue = [FMDatabaseQueue databaseQueueWithPath:[[[self class] libraryDBPath] path]];
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

- (int64_t)_createGenre:(PPLibraryGenreModel *)genreModel inDatabase:(FMDatabase *)database {
    if (!genreModel.title) {
        return -1;
    }

    [database executeUpdate:@"create table if not exists genres(title TEXT NOT NULL)"];
    [database executeUpdate:@"CREATE UNIQUE INDEX if not exists genres_idx ON genres(title)"];

    [database executeUpdate:@"insert or IGNORE into genres(title) values (?)", genreModel.title];

    FMResultSet *resultSet = [database executeQuery:@"SELECT rowid FROM genres WHERE title = ?", genreModel.title];

    int64_t resultID = -1;
    while ([resultSet next]) {
        resultID = [resultSet longLongIntForColumn:@"rowid"];
        break;
    }
    [resultSet close];

    return resultID;
}

- (int64_t)_createArtist:(PPLibraryArtistModel *)artistModel inDatabase:(FMDatabase *)database {
    if (!artistModel.title) {
        return -1;
    }

    [database executeUpdate:@"create table if not exists artists(title TEXT NOT NULL)"];
    [database executeUpdate:@"CREATE UNIQUE INDEX if not exists artists_idx ON artists(title)"];

    [database executeUpdate:@"insert or IGNORE into artists(title) values (?)", artistModel.title];

    FMResultSet *resultSet = [database executeQuery:@"SELECT rowid FROM artists WHERE title = ?", artistModel.title];

    int64_t resultID = -1;
    while ([resultSet next]) {
        resultID = [resultSet longLongIntForColumn:@"rowid"];
        break;
    }
    [resultSet close];

    return resultID;
}

- (int64_t)_createAlbum:(PPLibraryAlbumModel *)albumModel inDatabase:(FMDatabase *)database {
    if (!albumModel.title) {
        return -1;
    }

    int64_t createdArtistID = [self _createArtist:albumModel.artistModel inDatabase:database];

    if (createdArtistID < 0) {
        return -1;
    }

    [database executeUpdate:@"create table if not exists albums(title TEXT NOT NULL, artist_id INTEGER NOT NULL)"];
    [database executeUpdate:@"CREATE UNIQUE INDEX if not exists albums_idx ON albums(title, artist_id)"];

    [database executeUpdate:@"insert or IGNORE into albums(title, artist_id) values (?, ?)", albumModel.title, @(createdArtistID)];

    FMResultSet *resultSet = [database executeQuery:@"SELECT rowid FROM albums WHERE title = ? AND artist_id = ?", albumModel.title, @(createdArtistID)];

    int64_t resultID = -1;
    while ([resultSet next]) {
        resultID = [resultSet longLongIntForColumn:@"rowid"];
        break;
    }
    [resultSet close];

    return resultID;
}

- (int64_t)_createTrack:(PPLibraryTrackModel *)trackModel inDatabase:(FMDatabase *)database {
    int64_t createdGenreID = [self _createGenre:trackModel.genreModel inDatabase:database];
    int64_t createdArtistID = [self _createArtist:trackModel.artistModel inDatabase:database];
    int64_t createdAlbumID = [self _createAlbum:trackModel.albumModel inDatabase:database];

    if (createdGenreID < 0 ||
            createdAlbumID < 0 ||
            createdArtistID < 0) {
        return -1;
    }

    [database executeUpdate:@"create table if not exists tracks(title TEXT NOT NULL, artist_id INTEGER NOT NULL, album_id INTEGER NOT NULL, genre_id INTEGER NOT NULL)"];
    [database executeUpdate:@"CREATE UNIQUE INDEX if not exists tracks_idx ON tracks(title, artist_id)"];

    [database executeUpdate:@"insert or IGNORE into tracks(title, artist_id, album_id, genre_id) values (?, ?, ?, ?)",
                            trackModel.title,
                            @(createdArtistID),
                            @(createdAlbumID),
                            @(createdGenreID)];

    FMResultSet *resultSet = [database executeQuery:@"SELECT rowid FROM tracks WHERE title = ? AND artist_id = ? AND album_id = ? AND genre_id = ?", trackModel.title, @(createdArtistID), @(createdAlbumID), @(createdGenreID)];

    int64_t resultID = -1;
    while ([resultSet next]) {
        resultID = [resultSet longLongIntForColumn:@"rowid"];
        break;
    }
    [resultSet close];

    return resultID;
}

- (void)_moveTrackToLibrary:(PPFileModel *)track withID:(int64_t)trackID {
    NSURL *fromURL = track.url;
    NSURL *toURL = [[self class] trackPathForID:trackID];

    [_filesProvider moveFileFromURL:fromURL toURL:toURL];
}

- (void)_importFile:(PPFileModel *)file withCompletionBlock:(void (^)())block {
    if (!file.type == PPFileTypeFileAudio) {
        if (block) {
            block();
        }

        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:file.url options:nil];

        NSArray *titles = [AVMetadataItem metadataItemsFromArray:asset.commonMetadata withKey:AVMetadataCommonKeyTitle keySpace:AVMetadataKeySpaceCommon];
        NSArray *artists = [AVMetadataItem metadataItemsFromArray:asset.commonMetadata withKey:AVMetadataCommonKeyArtist keySpace:AVMetadataKeySpaceCommon];
        NSArray *albumNames = [AVMetadataItem metadataItemsFromArray:asset.commonMetadata withKey:AVMetadataCommonKeyAlbumName keySpace:AVMetadataKeySpaceCommon];
        NSArray *genres = [AVMetadataItem metadataItemsFromArray:asset.commonMetadata withKey:AVMetadataCommonKeyType keySpace:AVMetadataKeySpaceCommon];

        AVMetadataItem *title = [titles firstObject];
        AVMetadataItem *artist = [artists firstObject];
        AVMetadataItem *albumName = [albumNames firstObject];
        AVMetadataItem *genre = [genres firstObject];

        NSString *currentSongTitle = [(NSString *) [title.value copyWithZone:nil] fixedEncodingString];
        NSString *currentSongArtist = [(NSString *) [artist.value copyWithZone:nil] fixedEncodingString];
        NSString *currentSongAlbumName = [(NSString *) [albumName.value copyWithZone:nil] fixedEncodingString];
        NSString *currentSongGenre = [(NSString *) [genre.value copyWithZone:nil] fixedEncodingString];

        PPLibraryGenreModel *genreModel;
        PPLibraryAlbumModel *albumModel;
        PPLibraryArtistModel *artistModel;
        PPLibraryTrackModel *trackModel;

        if (!currentSongGenre) {
            currentSongGenre = NSLocalizedString(@"Unknown genre", nil);
        }

        if (!currentSongArtist) {
            currentSongArtist = NSLocalizedString(@"Unknown artist", nil);
        }

        if (!currentSongAlbumName) {
            currentSongAlbumName = NSLocalizedString(@"Unknown album", nil);
        }

        if (!currentSongTitle) {
            currentSongTitle = NSLocalizedString(@"Unknown track", nil);
        }

        genreModel = [PPLibraryGenreModel modelWithId:-1 title:currentSongGenre];
        artistModel = [PPLibraryArtistModel modelWithId:-1 title:currentSongArtist];
        albumModel = [PPLibraryAlbumModel modelWithId:-1 title:currentSongAlbumName
                                          artistModel:artistModel];
        trackModel = [PPLibraryTrackModel modelWithId:-1 title:currentSongTitle
                                          artistModel:artistModel
                                           albumModel:albumModel
                                           genreModel:genreModel];
        [_libraryDBQueue inDatabase:^(FMDatabase *db) {
            int64_t createdTrackID = [self _createTrack:trackModel inDatabase:db];
            NSLog(@"Created ID == %lld", createdTrackID);
            if (createdTrackID >= 0) {
                [self _moveTrackToLibrary:file withID:createdTrackID];
            }

            if (block) {
                block();
            }
        }];
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
    float onePartPercent = (1.0f / overall);
    __block float parts = 0;

    [reallyFiles enumerateObjectsUsingBlock:^(PPFileModel *currentFile, NSUInteger idx, BOOL *stop) {
        dispatch_group_enter(importGroup);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (currentFile.type == PPFileTypeFolder) {
                NSArray *filesModelsAtURL = [selfRef->_filesProvider filesModelsAtURL:currentFile.url];
                [selfRef importFiles:filesModelsAtURL
                   withProgressBlock:^(float partProgress) {
                       dispatch_async(dispatch_get_main_queue(), ^{
                           percent = (parts + partProgress) * onePartPercent;

                           float percentSnapshot = percent;
                           if (progressBlock) {
                               progressBlock(percentSnapshot);
                           }
                       });
                   }
                  andCompletionBlock:^{
                      dispatch_async(dispatch_get_main_queue(), ^{
                          parts++;
                          percent = parts * onePartPercent;

                          float percentSnapshot = percent;
                          if (progressBlock) {
                              progressBlock(percentSnapshot);
                          }

                          dispatch_group_leave(importGroup);
                      });
                  }];
            } else {
                [selfRef _importFile:currentFile withCompletionBlock:^{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        parts++;
                        percent = parts * onePartPercent;

                        float percentSnapshot = percent;
                        if (progressBlock) {
                            progressBlock(percentSnapshot);
                        }

                        dispatch_group_leave(importGroup);
                    });
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