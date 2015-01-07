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

#import "PPLibraryPlaylistsListViewController.h"
#import "PPLibraryProvider.h"

static const CGFloat cellsHeight = 60.0f;
static NSString *playlistCellIdentifier = @"playlistsCellIdentifier";

@implementation PPLibraryPlaylistCell

#pragma mark - Init

- (void)_init {
    [self.textLabel setFont:[UIFont boldSystemFontOfSize:17.0f]];
    [self.detailTextLabel setFont:[UIFont systemFontOfSize:13.0f]];
    [self.imageView setImage:[UIImage imageNamed:@"CellIconPlaylist.png"]];
    [self setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
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

@implementation PPLibraryPlaylistsListViewController

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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:playlistCellIdentifier];

    if (!cell) {
        cell = [[PPLibraryPlaylistCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                            reuseIdentifier:playlistCellIdentifier];
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    PPLibraryTrackModel *track = _sourceArray[(NSUInteger) indexPath.row];

    NSString *title = track.title;

    [cell.textLabel setText:title];
};

@end