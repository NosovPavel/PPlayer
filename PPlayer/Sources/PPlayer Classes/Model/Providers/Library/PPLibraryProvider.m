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
#import "NSString+EncodingFixing.h"
#import <AVFoundation/AVFoundation.h>

@interface PPLibraryModule () {
@protected
    FMDatabaseQueue *_libraryDBQueue;
}
@property(atomic, strong, readonly) FMDatabaseQueue *libraryDBQueue;

- (void)_init;

- (instancetype)initWithLibraryDBQueue:(FMDatabaseQueue *)libraryDBQueue;

+ (instancetype)moduleWithLibraryDBQueue:(FMDatabaseQueue *)libraryDBQueue;

@end

@implementation PPLibraryModule
@synthesize libraryDBQueue = _libraryDBQueue;

- (void)_init {
    //
}

- (void)dealloc {
    _libraryDBQueue = nil;
}

- (instancetype)initWithLibraryDBQueue:(FMDatabaseQueue *)libraryDBQueue {
    self = [super init];
    if (self) {
        _libraryDBQueue = libraryDBQueue;
        [self _init];
    }

    return self;
}

+ (instancetype)moduleWithLibraryDBQueue:(FMDatabaseQueue *)libraryDBQueue {
    return [[self alloc] initWithLibraryDBQueue:libraryDBQueue];
}

@end

@implementation PPLibraryFetcher

#pragma mark - Tracks

- (void)tracksListWithCompletionBlock:(void (^)(NSArray *tracksList))block {
    __block typeof(self) selfRef = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [selfRef->_libraryDBQueue inDatabase:^(FMDatabase *db) {
            FMResultSet *resultSet = [db executeQuery:@"SELECT tracks.id as track_id, tracks.title as track_title, \n"
                    "albums.id as track_album_id, albums.title as track_album_title, albums.artist_id as track_album_artist_id, artists.title as track_album_artist_title,\n"
                    "genres.id as track_genre_id, genres.title as track_genre_title\n"
                    "FROM tracks, artists, albums, genres\n"
                    "WHERE tracks.album_id = albums.id AND albums.artist_id = artists.id AND tracks.genre_id = genres.id"];

            NSMutableArray *tracks = [NSMutableArray array];
            while ([resultSet next]) {
                int64_t trackID = [resultSet longLongIntForColumn:@"track_id"];
                NSString *trackTitle = [resultSet stringForColumn:@"track_title"];

                int64_t trackGenreID = [resultSet longLongIntForColumn:@"track_genre_id"];
                NSString *trackGenreTitle = [resultSet stringForColumn:@"track_genre_title"];

                int64_t trackAlbumArtistID = [resultSet longLongIntForColumn:@"track_album_artist_id"];
                NSString *trackAlbumArtistTitle = [resultSet stringForColumn:@"track_album_artist_title"];
                int64_t trackAlbumID = [resultSet longLongIntForColumn:@"track_album_id"];
                NSString *trackAlbumTitle = [resultSet stringForColumn:@"track_album_title"];

                PPLibraryGenreModel *genreModel = [PPLibraryGenreModel modelWithId:trackGenreID title:trackGenreTitle];
                PPLibraryAlbumModel *albumModel = [PPLibraryAlbumModel modelWithId:trackAlbumID title:trackAlbumTitle
                                                                       artistModel:[PPLibraryArtistModel modelWithId:trackAlbumArtistID
                                                                                                               title:trackAlbumArtistTitle]];
                PPLibraryTrackModel *trackModel = [PPLibraryTrackModel modelWithId:trackID title:trackTitle
                                                                        albumModel:albumModel
                                                                        genreModel:genreModel];

                [tracks addObject:trackModel];
            }
            [resultSet close];

            if (block) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    block([tracks copy]);
                });
            }
        }];
    });
}

- (void)tracksListFromPLaylist:(PPLibraryPlaylistModel *)playlistModel
           withCompletionBlock:(void (^)(NSArray *tracksList))block {
    __block typeof(self) selfRef = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [selfRef->_libraryDBQueue inDatabase:^(FMDatabase *db) {
            FMResultSet *resultSet = [db executeQuery:[NSString stringWithFormat:@"SELECT \n"
                                                                                         "tracks.id as track_id, tracks.title as track_title,\n"
                                                                                         "albums.id as album_id, albums.title as album_title,\n"
                                                                                         "artists.id as artist_id, artists.title as artist_title,\n"
                                                                                         "genres.id as genre_id, genres.title as genre_title,\n"
                                                                                         "playlist%lld.id as playlist_item_id"
                                                                                         "\n"
                                                                                         "FROM\n"
                                                                                         "albums, tracks, artists, genres, playlist%lld\n"
                                                                                         "\n"
                                                                                         "WHERE\n"
                                                                                         "tracks.album_id = albums.id\n"
                                                                                         "AND\n"
                                                                                         "albums.artist_id = artists.id\n"
                                                                                         "AND\n"
                                                                                         "tracks.genre_id = genres.id\n"
                                                                                         "AND \n"
                                                                                         "tracks.id = playlist%lld.track_id", playlistModel.id, playlistModel.id, playlistModel.id]];

            NSMutableArray *tracks = [NSMutableArray array];
            while ([resultSet next]) {
                int64_t trackID = [resultSet longLongIntForColumn:@"track_id"];
                NSString *trackTitle = [resultSet stringForColumn:@"track_title"];

                int64_t genreID = [resultSet longLongIntForColumn:@"genre_id"];
                NSString *genreTitle = [resultSet stringForColumn:@"genre_title"];

                int64_t artistID = [resultSet longLongIntForColumn:@"artist_id"];
                NSString *artistTitle = [resultSet stringForColumn:@"artist_title"];
                int64_t albumID = [resultSet longLongIntForColumn:@"album_id"];
                NSString *albumTitle = [resultSet stringForColumn:@"album_title"];

                PPLibraryGenreModel *genreModel = [PPLibraryGenreModel modelWithId:genreID title:genreTitle];
                PPLibraryAlbumModel *albumModel = [PPLibraryAlbumModel modelWithId:albumID title:albumTitle
                                                                       artistModel:[PPLibraryArtistModel modelWithId:artistID
                                                                                                               title:artistTitle]];
                PPLibraryTrackModel *trackModel = [PPLibraryTrackModel modelWithId:trackID title:trackTitle
                                                                        albumModel:albumModel
                                                                        genreModel:genreModel];

                [tracks addObject:trackModel];
            }
            [resultSet close];

            if (block) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    block([tracks copy]);
                });
            }
        }];
    });
}

#pragma mark - Artists

- (void)artistsListWithCompletionBlock:(void (^)(NSArray *artistsList))block {
    __block typeof(self) selfRef = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [selfRef->_libraryDBQueue inDatabase:^(FMDatabase *db) {
            FMResultSet *resultSet = [db executeQuery:@"SELECT \n"
                    "artists.id as artist_id, artists.title as artist_title,\n"
                    "\n"
                    "COUNT(DISTINCT albums.id) as albums_count,\n"
                    "COUNT(DISTINCT tracks.id) as tracks_count\n"
                    "\n"
                    "FROM \n"
                    "artists, albums, tracks\n"
                    "\n"
                    "WHERE\n"
                    "albums.artist_id = artists.id\n"
                    "AND\n"
                    "tracks.album_id = albums.id\n"
                    "\n"
                    "GROUP BY \n"
                    "artist_id, artist_title"];

            NSMutableArray *artists = [NSMutableArray array];
            while ([resultSet next]) {
                int64_t artistID = [resultSet longLongIntForColumn:@"artist_id"];
                NSString *artistTitle = [resultSet stringForColumn:@"artist_title"];

                int64_t albumsCount = [resultSet longLongIntForColumn:@"albums_count"];
                int64_t tracksCount = [resultSet longLongIntForColumn:@"tracks_count"];

                PPLibraryArtistModel *artistModel = [PPLibraryArtistModel modelWithId:artistID title:artistTitle];
                artistModel.albumsCount = albumsCount;
                artistModel.tracksCount = tracksCount;

                [artists addObject:artistModel];
            }
            [resultSet close];

            if (block) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    block([artists copy]);
                });
            }
        }];
    });
}

#pragma mark - Albums

- (void)albumsListWithCompletionBlock:(void (^)(NSArray *albumsList))block {
    __block typeof(self) selfRef = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [selfRef->_libraryDBQueue inDatabase:^(FMDatabase *db) {
            FMResultSet *resultSet = [db executeQuery:@"SELECT \n"
                    "albums.id as album_id, albums.title as album_title,\n"
                    "artists.id as artist_id, artists.title as artist_title,\n"
                    "\n"
                    "COUNT(DISTINCT tracks.id) as tracks_count\n"
                    "\n"
                    "FROM \n"
                    "artists, albums, tracks\n"
                    "\n"
                    "WHERE\n"
                    "albums.artist_id = artists.id\n"
                    "AND\n"
                    "tracks.album_id = albums.id\n"
                    "\n"
                    "GROUP BY \n"
                    "album_id, album_title"];

            NSMutableArray *albums = [NSMutableArray array];
            while ([resultSet next]) {
                int64_t albumID = [resultSet longLongIntForColumn:@"album_id"];
                NSString *albumTitle = [resultSet stringForColumn:@"album_title"];

                int64_t artistID = [resultSet longLongIntForColumn:@"artist_id"];
                NSString *artistTitle = [resultSet stringForColumn:@"artist_title"];

                int64_t tracksCount = [resultSet longLongIntForColumn:@"tracks_count"];

                PPLibraryArtistModel *artistModel = [PPLibraryArtistModel modelWithId:artistID title:artistTitle];
                PPLibraryAlbumModel *albumModel = [PPLibraryAlbumModel modelWithId:albumID title:albumTitle artistModel:artistModel];
                albumModel.tracksCount = tracksCount;

                [albums addObject:albumModel];
            }
            [resultSet close];

            if (block) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    block([albums copy]);
                });
            }
        }];
    });
}

#pragma mark - Genres

- (void)genresListWithCompletionBlock:(void (^)(NSArray *genresList))block {
    __block typeof(self) selfRef = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [selfRef->_libraryDBQueue inDatabase:^(FMDatabase *db) {
            FMResultSet *resultSet = [db executeQuery:@"SELECT \n"
                    "genres.id as genre_id, genres.title as genre_title,\n"
                    "\n"
                    "COUNT(DISTINCT tracks.id) as tracks_count\n"
                    "\n"
                    "FROM \n"
                    "genres, tracks\n"
                    "\n"
                    "WHERE\n"
                    "tracks.genre_id = genres.id\n"
                    "\n"
                    "GROUP BY \n"
                    "genre_id, genre_title"];

            NSMutableArray *genres = [NSMutableArray array];
            while ([resultSet next]) {
                int64_t genreID = [resultSet longLongIntForColumn:@"genre_id"];
                NSString *genreTitle = [resultSet stringForColumn:@"genre_title"];

                int64_t tracksCount = [resultSet longLongIntForColumn:@"tracks_count"];

                PPLibraryGenreModel *genreModel = [PPLibraryGenreModel modelWithId:genreID title:genreTitle];
                genreModel.tracksCount = tracksCount;

                [genres addObject:genreModel];
            }
            [resultSet close];

            if (block) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    block([genres copy]);
                });
            }
        }];
    });
}

#pragma mark - Playlists

- (void)playlistsListWithCompletionBlock:(void (^)(NSArray *playlistsList))block {
    __block typeof(self) selfRef = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [selfRef->_libraryDBQueue inDatabase:^(FMDatabase *db) {
            FMResultSet *resultSet = [db executeQuery:@"SELECT \n"
                    "playlists.id as playlist_id, playlists.title as playlist_title"
                    "\n"
                    "FROM \n"
                    "playlists"];

            NSMutableArray *playlists = [NSMutableArray array];
            while ([resultSet next]) {
                int64_t playlistID = [resultSet longLongIntForColumn:@"playlist_id"];
                NSString *playlistTitle = [resultSet stringForColumn:@"playlist_title"];

                PPLibraryPlaylistModel *playlistModel = [PPLibraryPlaylistModel modelWithId:playlistID
                                                                                      title:playlistTitle];

                [playlists addObject:playlistModel];
            }
            [resultSet close];

            if (block) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    block([playlists copy]);
                });
            }
        }];
    });
}

#pragma mark - Complex

- (void)_albumsWithTracksFromResultSet:(FMResultSet *)resultSet
                   withcompletionBlock:(void (^)(NSArray *albumsList, NSArray *tracksListsList))block {
    NSMutableArray *albumsList = [NSMutableArray array];
    NSMutableArray *tracksListsList = [NSMutableArray array];

    while ([resultSet next]) {
        int64_t trackID = [resultSet longLongIntForColumn:@"track_id"];
        NSString *trackTitle = [resultSet stringForColumn:@"track_title"];

        int64_t genreID = [resultSet longLongIntForColumn:@"genre_id"];
        NSString *genreTitle = [resultSet stringForColumn:@"genre_title"];

        int64_t artistID = [resultSet longLongIntForColumn:@"artist_id"];
        NSString *artistTitle = [resultSet stringForColumn:@"artist_title"];

        int64_t albumID = [resultSet longLongIntForColumn:@"album_id"];
        NSString *albumTitle = [resultSet stringForColumn:@"album_title"];

        PPLibraryGenreModel *genreModel = [PPLibraryGenreModel modelWithId:genreID title:genreTitle];
        PPLibraryArtistModel *artistModelFetched = [PPLibraryArtistModel modelWithId:artistID title:artistTitle];

        __block PPLibraryAlbumModel *albumModel = nil;
        __block NSUInteger indexOfAlbum = NSNotFound;
        [albumsList enumerateObjectsUsingBlock:^(PPLibraryAlbumModel *currentAlbum, NSUInteger idx, BOOL *stop) {
            if (currentAlbum.id == albumID) {
                albumModel = currentAlbum;
                indexOfAlbum = idx;
                *stop = YES;
            }
        }];

        if (!albumModel) {
            albumModel = [PPLibraryAlbumModel modelWithId:albumID
                                                    title:albumTitle
                                              artistModel:artistModelFetched];
            [albumsList addObject:albumModel];
            [tracksListsList addObject:[NSMutableArray array]];

            indexOfAlbum = albumsList.count - 1;
        }

        PPLibraryTrackModel *trackModel = [PPLibraryTrackModel
                modelWithId:trackID
                      title:trackTitle
                 albumModel:albumModel
                 genreModel:genreModel];

        NSMutableArray *tracks = tracksListsList[indexOfAlbum];
        [tracks addObject:trackModel];
    }

    [resultSet close];

    if (block) {
        dispatch_async(dispatch_get_main_queue(), ^{
            block([albumsList copy], [tracksListsList copy]);
        });
    }
}

- (void)albumsWithTracksByArtist:(PPLibraryArtistModel *)artistModel
             withCompletionBlock:(void (^)(NSArray *albumsList, NSArray *tracksListsList))block {
    __block typeof(self) selfRef = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [selfRef->_libraryDBQueue inDatabase:^(FMDatabase *db) {
            FMResultSet *resultSet = [db executeQuery:@"SELECT \n"
                                                              "tracks.id as track_id, tracks.title as track_title,\n"
                                                              "albums.id as album_id, albums.title as album_title,\n"
                                                              "artists.id as artist_id, artists.title as artist_title,\n"
                                                              "genres.id as genre_id, genres.title as genre_title\n"
                                                              "\n"
                                                              "FROM\n"
                                                              "albums, tracks, artists, genres\n"
                                                              "\n"
                                                              "WHERE\n"
                                                              "tracks.album_id = albums.id\n"
                                                              "AND\n"
                                                              "albums.artist_id = artists.id\n"
                                                              "AND\n"
                                                              "tracks.genre_id = genres.id\n"
                                                              "AND\n"
                                                              "albums.artist_id = ?", @(artistModel.id)];

            [selfRef _albumsWithTracksFromResultSet:resultSet
                                withcompletionBlock:block];
        }];
    });
}

- (void)albumsWithTracksByAlbum:(PPLibraryAlbumModel *)albumModel
            withCompletionBlock:(void (^)(NSArray *albumsList, NSArray *tracksListsList))block {
    __block typeof(self) selfRef = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [selfRef->_libraryDBQueue inDatabase:^(FMDatabase *db) {
            FMResultSet *resultSet = [db executeQuery:@"SELECT \n"
                                                              "tracks.id as track_id, tracks.title as track_title,\n"
                                                              "albums.id as album_id, albums.title as album_title,\n"
                                                              "artists.id as artist_id, artists.title as artist_title,\n"
                                                              "genres.id as genre_id, genres.title as genre_title\n"
                                                              "\n"
                                                              "FROM\n"
                                                              "albums, tracks, artists, genres\n"
                                                              "\n"
                                                              "WHERE\n"
                                                              "tracks.album_id = albums.id\n"
                                                              "AND\n"
                                                              "albums.artist_id = artists.id\n"
                                                              "AND\n"
                                                              "tracks.genre_id = genres.id\n"
                                                              "AND\n"
                                                              "albums.id = ?", @(albumModel.id)];

            [selfRef _albumsWithTracksFromResultSet:resultSet
                                withcompletionBlock:block];
        }];
    });
}

- (void)albumsWithTracksByGenre:(PPLibraryGenreModel *)genreModel
            withCompletionBlock:(void (^)(NSArray *albumsList, NSArray *tracksListsList))block {
    __block typeof(self) selfRef = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [selfRef->_libraryDBQueue inDatabase:^(FMDatabase *db) {
            FMResultSet *resultSet = [db executeQuery:@"SELECT \n"
                                                              "tracks.id as track_id, tracks.title as track_title,\n"
                                                              "albums.id as album_id, albums.title as album_title,\n"
                                                              "artists.id as artist_id, artists.title as artist_title,\n"
                                                              "genres.id as genre_id, genres.title as genre_title\n"
                                                              "\n"
                                                              "FROM\n"
                                                              "albums, tracks, artists, genres\n"
                                                              "\n"
                                                              "WHERE\n"
                                                              "tracks.album_id = albums.id\n"
                                                              "AND\n"
                                                              "albums.artist_id = artists.id\n"
                                                              "AND\n"
                                                              "tracks.genre_id = genres.id\n"
                                                              "AND\n"
                                                              "tracks.genre_id = ?", @(genreModel.id)];

            [selfRef _albumsWithTracksFromResultSet:resultSet
                                withcompletionBlock:block];
        }];
    });
}


@end

@interface PPLibraryEditor () {
@private
    PPFilesProvider *_filesProvider;
}
@end

@implementation PPLibraryEditor

#pragma mark - Init

- (void)_init {
    [super _init];
    _filesProvider = [[PPFilesProvider alloc] init];
}

#pragma mark - Lifecycle

- (void)dealloc {
    _filesProvider = nil;
}

#pragma mark - Internal

- (int64_t)_createPlaylist:(PPLibraryPlaylistModel *)playlistModel inDatabase:(FMDatabase *)database {
    if (!playlistModel.title) {
        return -1;
    }

    [database executeUpdate:@"create table if not exists playlists(id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, title TEXT NOT NULL)"];
    [database executeUpdate:@"CREATE UNIQUE INDEX if not exists playlists_idx ON playlists(title)"];

    BOOL success = [database executeUpdate:@"insert or FAIL into playlists(title) values (?)", playlistModel.title];
    int64_t resultID = -1;

    if (success) {
        FMResultSet *resultSet = [database executeQuery:@"SELECT id FROM playlists WHERE title = ?", playlistModel.title];

        while ([resultSet next]) {
            resultID = [resultSet longLongIntForColumn:@"id"];
            break;
        }
        [resultSet close];
    }

    return resultID;
}

- (int64_t)_createGenre:(PPLibraryGenreModel *)genreModel inDatabase:(FMDatabase *)database {
    if (!genreModel.title) {
        return -1;
    }

    [database executeUpdate:@"create table if not exists genres(id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, title TEXT NOT NULL)"];
    [database executeUpdate:@"CREATE UNIQUE INDEX if not exists genres_idx ON genres(title)"];

    [database executeUpdate:@"insert or IGNORE into genres(title) values (?)", genreModel.title];

    FMResultSet *resultSet = [database executeQuery:@"SELECT id FROM genres WHERE title = ?", genreModel.title];

    int64_t resultID = -1;
    while ([resultSet next]) {
        resultID = [resultSet longLongIntForColumn:@"id"];
        break;
    }
    [resultSet close];

    return resultID;
}

- (int64_t)_createArtist:(PPLibraryArtistModel *)artistModel inDatabase:(FMDatabase *)database {
    if (!artistModel.title) {
        return -1;
    }

    [database executeUpdate:@"create table if not exists artists(id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, title TEXT NOT NULL)"];
    [database executeUpdate:@"CREATE UNIQUE INDEX if not exists artists_idx ON artists(title)"];

    [database executeUpdate:@"insert or IGNORE into artists(title) values (?)", artistModel.title];

    FMResultSet *resultSet = [database executeQuery:@"SELECT id FROM artists WHERE title = ?", artistModel.title];

    int64_t resultID = -1;
    while ([resultSet next]) {
        resultID = [resultSet longLongIntForColumn:@"id"];
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

    [database executeUpdate:@"create table if not exists albums(id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, title TEXT NOT NULL, artist_id INTEGER NOT NULL)"];
    [database executeUpdate:@"CREATE UNIQUE INDEX if not exists albums_idx ON albums(title, artist_id)"];

    [database executeUpdate:@"insert or IGNORE into albums(title, artist_id) values (?, ?)", albumModel.title, @(createdArtistID)];

    FMResultSet *resultSet = [database executeQuery:@"SELECT id FROM albums WHERE title = ? AND artist_id = ?", albumModel.title, @(createdArtistID)];

    int64_t resultID = -1;
    while ([resultSet next]) {
        resultID = [resultSet longLongIntForColumn:@"id"];
        break;
    }
    [resultSet close];

    return resultID;
}

- (int64_t)_createTrack:(PPLibraryTrackModel *)trackModel inDatabase:(FMDatabase *)database {
    int64_t createdGenreID = [self _createGenre:trackModel.genreModel inDatabase:database];
    int64_t createdAlbumID = [self _createAlbum:trackModel.albumModel inDatabase:database];

    if (createdGenreID < 0 ||
            createdAlbumID < 0) {
        return -1;
    }

    [database executeUpdate:@"create table if not exists tracks(id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, title TEXT NOT NULL, album_id INTEGER NOT NULL, genre_id INTEGER NOT NULL)"];
    [database executeUpdate:@"CREATE UNIQUE INDEX if not exists tracks_idx ON tracks(title, album_id)"];

    [database executeUpdate:@"insert or IGNORE into tracks(title, album_id, genre_id) values (?, ?, ?)",
                            trackModel.title,
                            @(createdAlbumID),
                            @(createdGenreID)];

    FMResultSet *resultSet = [database executeQuery:@"SELECT id FROM tracks WHERE title = ? AND album_id = ? AND genre_id = ?", trackModel.title, @(createdAlbumID), @(createdGenreID)];

    int64_t resultID = -1;
    while ([resultSet next]) {
        resultID = [resultSet longLongIntForColumn:@"id"];
        break;
    }
    [resultSet close];

    return resultID;
}

- (void)_moveTrackToLibrary:(PPFileModel *)track withID:(int64_t)trackID {
    NSURL *fromURL = track.url;
    NSURL *toURL = [[PPLibraryProvider class] trackURLForID:trackID];

    [_filesProvider moveFileFromURL:fromURL toURL:toURL];
}

- (void)_importFile:(PPFileModel *)file withCompletionBlock:(void (^)())block {
    __block typeof(self) selfRef = self;
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
                                           albumModel:albumModel
                                           genreModel:genreModel];
        [selfRef->_libraryDBQueue inDatabase:^(FMDatabase *db) {
            int64_t createdTrackID = [selfRef _createTrack:trackModel inDatabase:db];
            if (createdTrackID >= 0) {
                [selfRef _moveTrackToLibrary:file withID:createdTrackID];
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
                [selfRef->_filesProvider filesModelsAtURL:currentFile.url withCompletionBlock:^(NSArray *filesModelsAtURL) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
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
                                  [selfRef->_filesProvider removeFileAtURL:currentFile.url];

                                  parts++;
                                  percent = parts * onePartPercent;

                                  float percentSnapshot = percent;
                                  if (progressBlock) {
                                      progressBlock(percentSnapshot);
                                  }

                                  dispatch_group_leave(importGroup);
                              });
                          }];
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

#pragma mark - Creation

- (void)createPlaylist:(PPLibraryPlaylistModel *)playlistModel
   withCompletionBlock:(void (^)(PPLibraryPlaylistModel *createdPlaylist))block {
    __block typeof(self) selfRef = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [selfRef->_libraryDBQueue inDatabase:^(FMDatabase *db) {
            int64_t playlistID = [selfRef _createPlaylist:playlistModel inDatabase:db];

            PPLibraryPlaylistModel *libraryPlaylistModel = [PPLibraryPlaylistModel modelWithId:playlistID
                                                                                         title:playlistModel.title];

            if (playlistID < 0) {
                libraryPlaylistModel = nil;
            }

            if (block) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    block(libraryPlaylistModel);
                });
            }
        }];
    });
}


@end

@interface PPLibraryProvider () {
@private
    FMDatabaseQueue *_libraryDBQueue;

    PPLibraryFetcher *_fetcher;
    PPLibraryEditor *_editor;
}
@end

@implementation PPLibraryProvider
@synthesize fetcher = _fetcher;
@synthesize editor = _editor;

#pragma mark - Preparing

+ (void)load {
    if (![[NSFileManager defaultManager] fileExistsAtPath:[[[PPLibraryProvider class] _rootDirectoryURL] path]]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:[[[PPLibraryProvider class] _rootDirectoryURL] path]
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:NULL];
    }
}

#pragma mark - Paths

+ (NSURL *)_rootDirectoryURL {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths lastObject];
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"/.Library"];

    return [NSURL fileURLWithPath:dataPath];
}

+ (NSURL *)_libraryDBURL {
    NSURL *libraryURL = [[[PPLibraryProvider class] _rootDirectoryURL] URLByAppendingPathComponent:@"library.sqlite"];

    return libraryURL;
}

+ (NSURL *)trackURLForID:(int64_t)trackID {
    NSURL *trackURL = [[[PPLibraryProvider class] _rootDirectoryURL] URLByAppendingPathComponent:[NSString stringWithFormat:@"%lld.pptrack", trackID]];

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
    _libraryDBQueue = [FMDatabaseQueue databaseQueueWithPath:[[[PPLibraryProvider class] _libraryDBURL] path]];

    _fetcher = [PPLibraryFetcher moduleWithLibraryDBQueue:_libraryDBQueue];
    _editor = [PPLibraryEditor moduleWithLibraryDBQueue:_libraryDBQueue];
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
    _fetcher = nil;
    _editor = nil;
}

@end