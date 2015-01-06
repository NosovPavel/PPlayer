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

#import "PPLibraryAlbumsWithTracksListViewController.h"
#import "PPLibraryProvider.h"
#import "PPLibraryAlbumModel.h"
#import "PPLibraryGenreModel.h"

static const CGFloat cellsHeight = 50.0f;
static NSString *tracksCellIdentifier = @"tracksCellIdentifier";

static const CGFloat headersHeight = 100.0f;
static NSString *albumsHeaderIdentifier = @"albumsHeaderIdentifier";

@implementation PPLibraryAlbumsWithTracksCell

#pragma mark - Init

- (void)_init {
    [self.imageView setContentMode:UIViewContentModeCenter];
    [self.textLabel setFont:[UIFont boldSystemFontOfSize:17.0f]];
    [self.detailTextLabel setFont:[UIFont systemFontOfSize:13.0f]];
}

#pragma mark - Lifecycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self _init];
    }

    return self;
}

@end

@implementation PPLibraryAlbumsWithTracksHeaderView
@end

@interface PPLibraryAlbumsWithTracksListViewController () {
@private
    NSMutableArray *_tracksArray;
}
@end

@implementation PPLibraryAlbumsWithTracksListViewController

#pragma mark - Init

- (instancetype)initWithArtistModel:(PPLibraryArtistModel *)artistModel {
    self = [super init];
    if (self) {
        self.artistModel = artistModel;
    }

    return self;
}

- (instancetype)initWithAlbumModel:(PPLibraryAlbumModel *)albumModel {
    self = [super init];
    if (self) {
        self.albumModel = albumModel;
    }

    return self;
}

- (instancetype)initWithGenreModel:(PPLibraryGenreModel *)genreModel {
    self = [super init];
    if (self) {
        self.genreModel = genreModel;
    }

    return self;
}

+ (instancetype)controllerWithGenreModel:(PPLibraryGenreModel *)genreModel {
    return [[self alloc] initWithGenreModel:genreModel];
}

+ (instancetype)controllerWithAlbumModel:(PPLibraryAlbumModel *)albumModel {
    return [[self alloc] initWithAlbumModel:albumModel];
}

+ (instancetype)controllerWithArtistModel:(PPLibraryArtistModel *)artistModel {
    return [[self alloc] initWithArtistModel:artistModel];
}

- (void)commonInit {
    [super commonInit];
    _sourceTableView.rowHeight = cellsHeight;
}

#pragma mark - Reloading

- (void)reloadDataWithCompletionBlock:(void (^)())block {
    __block typeof(self) selfRef = self;

    void (^completionBlock)(NSArray *albumsList, NSArray *tracksListsList) = ^(NSArray *albumsList, NSArray *tracksListsList) {
        selfRef->_sourceArray = [albumsList mutableCopy];
        selfRef->_tracksArray = [tracksListsList mutableCopy];
        [selfRef->_sourceTableView reloadData];
        if (block) {
            block();
        }
    };

    if (_artistModel) {
        [[PPLibraryProvider sharedLibrary].fetcher albumsWithTracksByArtist:_artistModel
                                                        withCompletionBlock:completionBlock];
        return;
    } else if (_albumModel) {
        [[PPLibraryProvider sharedLibrary].fetcher albumsWithTracksByAlbum:_albumModel
                                                       withCompletionBlock:completionBlock];
        return;
    } else if (_genreModel) {
        [[PPLibraryProvider sharedLibrary].fetcher albumsWithTracksByGenre:_genreModel
                                                       withCompletionBlock:completionBlock];
        return;
    }

    if (block) {
        block();
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _sourceArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSMutableArray *tracks = _tracksArray[(NSUInteger) section];
    return tracks.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return headersHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    PPLibraryAlbumsWithTracksHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:albumsHeaderIdentifier];

    if (!headerView) {
        headerView = [[PPLibraryAlbumsWithTracksHeaderView alloc] initWithReuseIdentifier:albumsHeaderIdentifier];
    }

    return headerView;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tracksCellIdentifier];

    if (!cell) {
        cell = [[PPLibraryAlbumsWithTracksCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                                    reuseIdentifier:tracksCellIdentifier];
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSMutableArray *tracks = _tracksArray[(NSUInteger) indexPath.section];
    PPLibraryTrackModel *track = tracks[(NSUInteger) indexPath.row];

    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d  ", indexPath.row + 1]
                                                                              attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:17.0f]}];
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:track.title]];

    [cell.textLabel setAttributedText:title];
};

@end