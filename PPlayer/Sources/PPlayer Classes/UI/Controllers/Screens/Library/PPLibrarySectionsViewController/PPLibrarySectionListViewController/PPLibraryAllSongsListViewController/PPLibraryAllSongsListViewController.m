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

#import "PPLibraryAllSongsListViewController.h"
#import "PPLibraryProvider.h"
#import "PPPlayer.h"

static const CGFloat cellsHeight = 60.0f;
static NSString *tracksCellIdentifier = @"tracksCellIdentifier";
static NSString *tracksPickingCellIdentifier = @"tracksPickingCellIdentifier";

static const CGFloat leftImageShift = 15.0f;
static const CGFloat leftTextShift = 5.0f;

@interface PPLibraryAllSongsCell ()
- (void)_init;
@end

@implementation PPLibraryAllSongsCell

#pragma mark - Init

- (void)_init {
    [self.imageView setContentMode:UIViewContentModeCenter];
    [self.imageView setImage:[UIImage imageNamed:@"ArtworkPlaceHolderIcon.png"]];
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

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];

    CGRect imageViewFrame = self.imageView.frame;
    imageViewFrame.origin.x -= leftImageShift;
    self.imageView.frame = imageViewFrame;

    CGRect titleViewFrame = self.textLabel.frame;
    titleViewFrame.origin.x -= leftImageShift + leftTextShift;
    titleViewFrame.size.width += leftImageShift + leftTextShift;
    self.textLabel.frame = titleViewFrame;

    CGRect subTitleViewFrame = self.detailTextLabel.frame;
    subTitleViewFrame.origin.x -= leftImageShift + leftTextShift;
    subTitleViewFrame.size.width += leftImageShift + leftTextShift;
    self.detailTextLabel.frame = subTitleViewFrame;

    self.separatorInset = UIEdgeInsetsMake(0.0f, self.textLabel.frame.origin.x, 0.0f, 0.0f);
}

@end

@interface PPLibraryAllSongsPickingCell : PPLibraryAllSongsCell {
@private
    UIImageView *_checkmarkEmptyImageView, *_checkmarkFilledImageView;
    BOOL _checked;
}
@property BOOL checked;
@end

@implementation PPLibraryAllSongsPickingCell

- (void)_init {
    [super _init];
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    _checkmarkEmptyImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"CellIconCheckMarkEmpty.png"]
            imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    _checkmarkFilledImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"CellIconCheckMarkFilled.png"]
            imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];

    self.accessoryView = _checkmarkEmptyImageView;
}

- (void)dealloc {
    _checkmarkEmptyImageView = nil;
    _checkmarkFilledImageView = nil;
}

- (BOOL)checked {
    return _checked;
}

- (void)setChecked:(BOOL)checked {
    if (checked != _checked) {
        _checked = checked;

        self.textLabel.textColor = _checked ? [UIColor lightGrayColor] : [UIColor blackColor];
        self.detailTextLabel.textColor = _checked ? [UIColor lightGrayColor] : [UIColor blackColor];
        self.accessoryView = _checked ? _checkmarkFilledImageView : _checkmarkEmptyImageView;
    }
}

@end

@implementation PPLibraryAllSongsListViewController

#pragma mark - Init

- (void)commonInit {
    [super commonInit];
    _sourceTableView.rowHeight = cellsHeight;
}

#pragma mark - Reloading

- (void)reloadDataWithCompletionBlock:(void (^)())block {
    __block typeof(self) selfRef = self;
    [[PPLibraryProvider sharedLibrary].fetcher tracksListWithCompletionBlock:^(NSArray *tracksList) {
        selfRef->_sourceArray = [tracksList mutableCopy];
        [selfRef->_sourceTableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                                 withRowAnimation:UITableViewRowAnimationFade];
        if (block) {
            block();
        }
    }];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;

    if (!self.tracksPickerMode) {
        cell = [tableView dequeueReusableCellWithIdentifier:tracksCellIdentifier];

        if (!cell) {
            cell = [[PPLibraryAllSongsCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                                reuseIdentifier:tracksCellIdentifier];

        }
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:tracksPickingCellIdentifier];

        if (!cell) {
            cell = [[PPLibraryAllSongsPickingCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                                       reuseIdentifier:tracksPickingCellIdentifier];

        }
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    PPLibraryTrackModel *track = [self trackForIndexPath:indexPath];

    NSString *title = track.title;
    NSMutableAttributedString *subtitle = [[NSMutableAttributedString alloc] initWithString:track.albumModel.artistModel.title
                                                                                 attributes:@{NSForegroundColorAttributeName : [UIColor darkGrayColor]}];
    NSAttributedString *albumName = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", track.albumModel.title]
                                                                    attributes:@{NSForegroundColorAttributeName : [UIColor lightGrayColor]}];
    [subtitle appendAttributedString:albumName];

    [cell.textLabel setText:title];
    [cell.detailTextLabel setAttributedText:subtitle];

    if (self.tracksPickerMode) {
        PPLibraryAllSongsPickingCell *pickingCell = (PPLibraryAllSongsPickingCell *) cell;
        BOOL picked = [_pickedArray containsObject:track];

        pickingCell.checked = picked;
    }
};

#pragma mark - Configuration

- (PPLibraryTrackModel *)trackForIndexPath:(NSIndexPath *)indexPath {
    return _sourceArray[(NSUInteger) indexPath.row];
}

- (NSArray *)playlistItemsForCurrentContent {
    NSMutableArray *playlistItems = [NSMutableArray array];

    [_sourceArray enumerateObjectsUsingBlock:^(PPLibraryTrackModel *currentTrack, NSUInteger idx, BOOL *stop) {
        PPLibraryPlaylistItemModel *item = [PPLibraryPlaylistItemModel modelWithId:-idx title:nil];
        item.trackModel = currentTrack;

        [playlistItems addObject:item];
    }];

    return playlistItems;
}

- (PPLibraryPlaylistItemModel *)playlistItemForIndexPath:(NSIndexPath *)indexPath {
    PPLibraryTrackModel *track = [self trackForIndexPath:indexPath];

    PPLibraryPlaylistItemModel *item = [PPLibraryPlaylistItemModel modelWithId:-indexPath.row title:nil];
    item.trackModel = track;

    return item;
}

@end