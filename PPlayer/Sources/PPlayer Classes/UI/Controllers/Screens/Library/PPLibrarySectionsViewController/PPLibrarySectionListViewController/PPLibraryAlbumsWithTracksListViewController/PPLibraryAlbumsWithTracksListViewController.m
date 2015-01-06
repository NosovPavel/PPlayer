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

static const CGFloat cellsHeight = 50.0f;
static NSString *tracksCellIdentifier = @"tracksCellIdentifier";

static const CGFloat headersHeight = 80.0f;
static NSString *albumsHeaderIdentifier = @"albumsHeaderIdentifier";

UIEdgeInsets edgeInsets() {
    return UIEdgeInsetsMake(0.0f, 10.0f, 0.0f, 10.0f);
}

@implementation PPLibraryAlbumsWithTracksCell

#pragma mark - Init

- (void)_init {
    [self.imageView setContentMode:UIViewContentModeCenter];
    [self.textLabel setFont:[UIFont boldSystemFontOfSize:17.0f]];
    [self.detailTextLabel setFont:[UIFont systemFontOfSize:13.0f]];

    if ([self respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [self setPreservesSuperviewLayoutMargins:NO];
    }
    self.separatorInset = edgeInsets();
}

#pragma mark - Lifecycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self _init];
    }

    return self;
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
}


@end

@interface PPLibraryAlbumsWithTracksHeaderView () {
@private
    UIView *_bottomLine, *_topLine;
    UIImageView *_artworkView;
    UILabel *_titleLabel, *_subtitleLabel;
}
@property(atomic) float separatorInsetLeft;
@property(atomic, strong) UILabel *titleLabel, *subtitleLabel;
@end

@implementation PPLibraryAlbumsWithTracksHeaderView
@synthesize titleLabel = _titleLabel;
@synthesize subtitleLabel = _subtitleLabel;

#pragma mark - Init

- (void)_init {
    self.contentView.backgroundColor = [UIColor whiteColor];

    _bottomLine = [[UIView alloc] init];
    [_bottomLine setBackgroundColor:[UIColor colorWithWhite:0.89f alpha:1.0f]];

    [self.contentView addSubview:_bottomLine];

    _topLine = [[UIView alloc] init];
    [_topLine setBackgroundColor:[UIColor colorWithWhite:0.89f alpha:1.0f]];

    [self.contentView addSubview:_topLine];

    _artworkView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ArtworkPlaceHolderBig.png"]];
    [_artworkView setContentMode:UIViewContentModeScaleToFill];

    [self.contentView addSubview:_artworkView];

    _titleLabel = [[UILabel alloc] init];
    [self.contentView addSubview:_titleLabel];

    _subtitleLabel = [[UILabel alloc] init];
    [self.contentView addSubview:_subtitleLabel];

    [self.titleLabel setFont:[UIFont boldSystemFontOfSize:17.0f]];
    [self.subtitleLabel setFont:[UIFont systemFontOfSize:13.0f]];
}

#pragma mark - Lifecycle

- (instancetype)initWithReuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithReuseIdentifier:reuseIdentifier];
    if (self) {
        [self _init];
    }

    return self;
}

- (void)dealloc {
    _bottomLine = nil;
    _topLine = nil;
    _artworkView = nil;
    _titleLabel = nil;
    _subtitleLabel = nil;
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    [_bottomLine setFrame:CGRectMake(0.0f, self.contentView.bounds.size.height - 0.5f,
            self.contentView.bounds.size.width,
            0.5f)];
    [_topLine setFrame:CGRectMake(0.0f, 0.1f,
            self.contentView.bounds.size.width,
            0.5f)];

    CGFloat padding = _separatorInsetLeft;
    CGFloat artworkSize = (self.contentView.bounds.size.height - 1.0f) - padding * 2.0f;

    [_artworkView setFrame:CGRectMake(padding, padding,
            artworkSize, artworkSize)];

    [_titleLabel sizeToFit];
    [_subtitleLabel sizeToFit];

    [_titleLabel setFrame:CGRectMake(padding + artworkSize + padding,
            _artworkView.center.y - _titleLabel.bounds.size.height + 2.0f,
            self.contentView.bounds.size.width - padding - artworkSize - padding - padding,
            _titleLabel.bounds.size.height)];

    [_subtitleLabel setFrame:CGRectMake(padding + artworkSize + padding,
            _artworkView.center.y + 2.0f,
            self.contentView.bounds.size.width - padding - artworkSize - padding - padding,
            _subtitleLabel.bounds.size.height)];
}

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
    _sourceTableView.separatorInset = edgeInsets();
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

    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%lld  ", ((int64_t) (indexPath.row + 1))]
                                                                              attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:17.0f]}];
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:track.title]];

    [cell.textLabel setAttributedText:title];
};

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(PPLibraryAlbumsWithTracksHeaderView *)view forSection:(NSInteger)section {
    PPLibraryAlbumModel *currentAlbum = _sourceArray[(NSUInteger) section];
    NSArray *tracks = _tracksArray[(NSUInteger) section];

    view.separatorInsetLeft = tableView.separatorInset.left;
    [view.titleLabel setText:currentAlbum.title];
    [view.subtitleLabel setAttributedText:[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: %lld", NSLocalizedString(@"Tracks_count.albums", nil), (int64_t) tracks.count]
                                                                                 attributes:@{NSForegroundColorAttributeName : [UIColor darkGrayColor]}]];
}

@end