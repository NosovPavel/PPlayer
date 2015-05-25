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

#import "PPLibraryAllAlbumsListViewController.h"
#import "PPLibraryProvider.h"
#import "PPLibraryAlbumsWithTracksListViewController.h"

static const CGFloat cellsHeight = 100.0f;
static NSString *albumCellIdentifier = @"albumCellIdentifier";

static const CGFloat leftImageShift = 10.0f;
static const CGFloat leftTextShift = 0.0f;

@interface PPLibraryAllAlbumsCell () {
@private
    UILabel *_middleLabel;
}
@end

@implementation PPLibraryAllAlbumsCell
@synthesize middleLabel = _middleLabel;

#pragma mark - Init

- (void)_init {
    [self.imageView setContentMode:UIViewContentModeCenter];

    [self.textLabel setFont:[UIFont boldSystemFontOfSize:17.0f]];
    [self.detailTextLabel setFont:[UIFont systemFontOfSize:13.0f]];

    [self setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];

    _middleLabel = [[UILabel alloc] init];
    [_middleLabel setFont:[UIFont systemFontOfSize:16.0f]];

    [self addSubview:_middleLabel];
    [self bringSubviewToFront:_middleLabel];
}

#pragma mark - Lifecycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self _init];
    }

    return self;
}

- (void)dealloc {
    _middleLabel = nil;
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];

    self.accessoryView.backgroundColor = [UIColor redColor];

    CGRect imageViewFrame = self.imageView.frame;
    imageViewFrame.origin.x -= leftImageShift;
    self.imageView.frame = imageViewFrame;

    CGRect titleViewFrame = self.textLabel.frame;
    titleViewFrame.origin.x -= leftImageShift + leftTextShift;
    self.textLabel.frame = titleViewFrame;

    CGRect subTitleViewFrame = self.detailTextLabel.frame;
    subTitleViewFrame.origin.x -= leftImageShift + leftTextShift;
    self.detailTextLabel.frame = subTitleViewFrame;

    [_middleLabel setFrame:self.textLabel.frame];
    [_middleLabel setCenter:CGPointMake(self.textLabel.frame.origin.x + self.textLabel.bounds.size.width / 2.0f, _middleLabel.superview.bounds.size.height / 2.0f)];
    [_middleLabel setFrame:CGRectMake(_middleLabel.frame.origin.x, _middleLabel.frame.origin.y, self.bounds.size.width - _middleLabel.frame.origin.x, _middleLabel.bounds.size.height)];

    [self.textLabel setFrame:CGRectMake(_middleLabel.frame.origin.x,
            _middleLabel.frame.origin.y - self.textLabel.bounds.size.height,
            self.textLabel.bounds.size.width, self.textLabel.bounds.size.height)];
    [self.detailTextLabel setFrame:CGRectMake(_middleLabel.frame.origin.x,
            _middleLabel.frame.origin.y + _middleLabel.bounds.size.height,
            self.detailTextLabel.bounds.size.width, self.detailTextLabel.bounds.size.height)];

    self.separatorInset = UIEdgeInsetsMake(0.0f, self.textLabel.frame.origin.x, 0.0f, 0.0f);
}

@end

@implementation PPLibraryAllAlbumsListViewController

#pragma mark - Init

- (void)commonInit {
    [super commonInit];
    _sourceTableView.rowHeight = cellsHeight;
}

#pragma mark - Reloading

- (void)reloadDataWithCompletionBlock:(void (^)())block {
    __block typeof(self) selfRef = self;
    [[PPLibraryProvider sharedLibrary].fetcher albumsListWithCompletionBlock:^(NSArray *albumsList) {
        selfRef->_sourceArray = [albumsList mutableCopy];
        [selfRef->_sourceTableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                                 withRowAnimation:UITableViewRowAnimationFade];
        if (block) {
            block();
        }
    }];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:albumCellIdentifier];

    if (!cell) {
        cell = [[PPLibraryAllAlbumsCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                             reuseIdentifier:albumCellIdentifier];
        [cell.imageView setImage:[UIImage imageNamed:@"ArtworkPlaceHolderArtist.png"]];
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(PPLibraryAllAlbumsCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    PPLibraryAlbumModel *albumModel = _sourceArray[(NSUInteger) indexPath.row];

    NSString *title = albumModel.title;
    NSString *middleTitle = albumModel.artistModel.title;
    NSMutableAttributedString *subtitle = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: %lld", NSLocalizedString(@"Tracks_count.albums", nil), albumModel.tracksCount]
                                                                                 attributes:@{NSForegroundColorAttributeName : [UIColor darkGrayColor]}];

    [cell.textLabel setText:title];
    [cell.middleLabel setText:middleTitle];
    [cell.detailTextLabel setAttributedText:subtitle];
};

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    PPLibraryAlbumModel *albumModel = _sourceArray[(NSUInteger) indexPath.row];
    PPLibraryAlbumsWithTracksListViewController *albumsWithTracksListViewController = [PPLibraryAlbumsWithTracksListViewController
            controllerWithAlbumModel:albumModel];
    albumsWithTracksListViewController.title = albumModel.title;

    [self.navigationController pushViewController:albumsWithTracksListViewController animated:YES];
}

@end