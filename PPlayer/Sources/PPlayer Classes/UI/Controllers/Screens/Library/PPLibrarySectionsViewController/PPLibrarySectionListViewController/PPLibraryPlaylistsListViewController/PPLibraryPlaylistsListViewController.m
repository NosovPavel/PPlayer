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
#import "UIAlertView+Blocks.h"
#import "PPLibraryAllSongsFromPlaylistListViewController.h"

static const CGFloat cellsHeight = 60.0f;
static NSString *playlistCellIdentifier = @"playlistsCellIdentifier";
static NSString *playlistCreatingCellIdentifier = @"playlistsCreatingCellIdentifier";

@interface PPLibraryPlaylistCell ()
- (void)_init;
@end

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

@interface PPLibraryPlaylistCreatingCell : PPLibraryPlaylistCell
@end

@implementation PPLibraryPlaylistCreatingCell
- (void)_init {
    [super _init];

    [self.textLabel setTextColor:[UIColor lightGrayColor]];
    [self.imageView setImage:[[UIImage imageNamed:@"CellIconPlaylist.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    [self.imageView setTintColor:self.textLabel.textColor];
    [self setAccessoryType:UITableViewCellAccessoryNone];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
}

@end

@interface PPLibraryPlaylistsListViewController () {
@private
    NSMutableArray *_placeholdersArray;
    UIBarButtonItem *_addBarItem;
}
@end

@implementation PPLibraryPlaylistsListViewController

#pragma mark - Init

- (void)designedInit {
    [super designedInit];
    _placeholdersArray = [NSMutableArray array];
}

- (void)commonInit {
    [super commonInit];
    _sourceTableView.rowHeight = cellsHeight;
}

#pragma mark - Lifecycle

- (void)loadView {
    [super loadView];

    _addBarItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                                                                target:self action:@selector(_createPlaylistTapped)];
    self.navigationItem.rightBarButtonItem = _addBarItem;
}

- (void)dealloc {
    _placeholdersArray = nil;
    _addBarItem = nil;
}

#pragma mark - Add playlist

- (void)_createPlaylistTapped {
    __block typeof(self) selfRef = self;

    UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"New playlist", nil)
                                                 message:NSLocalizedString(@"Assign the name to this playlist", nil)
                                                delegate:nil
                                       cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                       otherButtonTitles:NSLocalizedString(@"Save", nil), nil];

    av.alertViewStyle = UIAlertViewStylePlainTextInput;
    av.shouldEnableFirstOtherButtonBlock = ^BOOL(UIAlertView *alertView) {
        [[alertView textFieldAtIndex:0] setAutocapitalizationType:UITextAutocapitalizationTypeSentences];
        [[alertView textFieldAtIndex:0] setReturnKeyType:UIReturnKeyDone];
        [[alertView textFieldAtIndex:0] setEnablesReturnKeyAutomatically:YES];

        return ([[[alertView textFieldAtIndex:0] text] length] > 0);
    };
    [av setTapBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex == alertView.firstOtherButtonIndex) {
            NSString *newPlaylistTitle = [[alertView textFieldAtIndex:0] text];

            //detect last placeholder
            int64_t idOfLastPlaceholder = -1;
            NSUInteger indexOfLastPlaceholder = selfRef->_placeholdersArray.count - 1;
            PPLibraryPlaylistModel *lastPlaceholder = [selfRef->_placeholdersArray lastObject];
            if (lastPlaceholder) {
                idOfLastPlaceholder = lastPlaceholder.id;
            }

            //create and insert new placeholder
            PPLibraryPlaylistModel *newPlaceholder = [PPLibraryPlaylistModel modelWithId:idOfLastPlaceholder - 1
                                                                                   title:[NSString stringWithFormat:@"[%@] %@", NSLocalizedString(@"Creating", nil), newPlaylistTitle]];
            [selfRef->_placeholdersArray addObject:newPlaceholder];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:indexOfLastPlaceholder + 1
                                                        inSection:1];
            [selfRef->_sourceTableView insertRowsAtIndexPaths:@[indexPath]
                                             withRowAnimation:UITableViewRowAnimationFade];
            [selfRef->_sourceTableView scrollToRowAtIndexPath:indexPath
                                             atScrollPosition:UITableViewScrollPositionMiddle
                                                     animated:YES];

            //create new playlist
            [[PPLibraryProvider sharedLibrary].editor createPlaylist:[PPLibraryPlaylistModel modelWithId:idOfLastPlaceholder - 1
                                                                                                   title:newPlaylistTitle]
                                                 withCompletionBlock:^(PPLibraryPlaylistModel *createdPlaylist) {
                                                     NSUInteger indexOfPlaceholder;
                                                     indexOfPlaceholder = [selfRef->_placeholdersArray indexOfObject:newPlaceholder];

                                                     if (indexOfPlaceholder != NSNotFound) {
                                                         NSIndexPath *placeholderiPath = [NSIndexPath indexPathForRow:indexOfPlaceholder
                                                                                                            inSection:1];

                                                         [selfRef->_placeholdersArray removeObjectAtIndex:indexOfPlaceholder];
                                                         [selfRef->_sourceTableView deleteRowsAtIndexPaths:@[placeholderiPath]
                                                                                          withRowAnimation:UITableViewRowAnimationFade];
                                                     }

                                                     if (createdPlaylist && ![selfRef->_sourceArray containsObject:createdPlaylist]) {
                                                         NSUInteger lastPlaylistIndex = selfRef->_sourceArray.count - 1;
                                                         [selfRef->_sourceArray addObject:createdPlaylist];

                                                         NSIndexPath *createdPlaylistIndexPath = [NSIndexPath indexPathForRow:lastPlaylistIndex + 1
                                                                                                                    inSection:0];
                                                         [selfRef->_sourceTableView insertRowsAtIndexPaths:@[createdPlaylistIndexPath]
                                                                                          withRowAnimation:UITableViewRowAnimationFade];
                                                         [selfRef->_sourceTableView scrollToRowAtIndexPath:createdPlaylistIndexPath
                                                                                          atScrollPosition:UITableViewScrollPositionMiddle
                                                                                                  animated:YES];
                                                     }

                                                     if (!createdPlaylist) {
                                                         UIAlertView *errorAV = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                                                                           message:NSLocalizedString(@"You cant`t create playlists with same name", nil)
                                                                                                          delegate:nil
                                                                                                 cancelButtonTitle:NSLocalizedString(@"Close", nil)
                                                                                                 otherButtonTitles:nil];
                                                         [errorAV show];
                                                     }

                                                     [selfRef updateActionsState];
                                                 }];
        }
    }];

    [av show];
}

#pragma mark - Reloading

- (void)reloadDataWithCompletionBlock:(void (^)())block {
    __block typeof(self) selfRef = self;
    [[PPLibraryProvider sharedLibrary].fetcher playlistsListWithCompletionBlock:^(NSArray *playlistsList) {
        selfRef->_sourceArray = [playlistsList mutableCopy];
        [selfRef->_sourceTableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                                 withRowAnimation:UITableViewRowAnimationFade];
        if (block) {
            block();
        }
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return _sourceArray.count;
    }

    if (section == 1) {
        return _placeholdersArray.count;
    }

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;

    if (indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:playlistCellIdentifier];

        if (!cell) {
            cell = [[PPLibraryPlaylistCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                                reuseIdentifier:playlistCellIdentifier];
        }
    }

    if (indexPath.section == 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:playlistCreatingCellIdentifier];

        if (!cell) {
            cell = [[PPLibraryPlaylistCreatingCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                        reuseIdentifier:playlistCreatingCellIdentifier];
        }
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    PPLibraryPlaylistModel *playlistModel;

    if (indexPath.section == 0) {
        playlistModel = _sourceArray[(NSUInteger) indexPath.row];
    }

    if (indexPath.section == 1) {
        playlistModel = _placeholdersArray[(NSUInteger) indexPath.row];
    }

    NSString *title = playlistModel.title;
    [cell.textLabel setText:title];
};

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 0) {
        PPLibraryPlaylistModel *playlistModel = _sourceArray[(NSUInteger) indexPath.row];

        PPLibraryAllSongsFromPlaylistListViewController *allSongsFromPlaylistListViewController = [PPLibraryAllSongsFromPlaylistListViewController controllerWithPlaylistModel:playlistModel];
        allSongsFromPlaylistListViewController.title = playlistModel.title;

        [self.navigationController pushViewController:allSongsFromPlaylistListViewController
                                             animated:YES];
    }
}

@end