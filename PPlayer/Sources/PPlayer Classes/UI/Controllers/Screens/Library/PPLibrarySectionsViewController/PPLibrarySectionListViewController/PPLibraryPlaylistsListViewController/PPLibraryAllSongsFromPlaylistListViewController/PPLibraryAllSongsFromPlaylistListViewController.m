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

#import "PPLibraryAllSongsFromPlaylistListViewController.h"
#import "PPLibraryProvider.h"
#import "PPLibraryRootViewController.h"
#import "PPPlayer.h"

static NSString *tracksPlaceholderIdentifier = @"tracksPlaceholderIdentifier";

@interface PPLibraryAllSongsPlaceholderCell : PPLibraryAllSongsCell
@end

@implementation PPLibraryAllSongsPlaceholderCell
- (void)_init {
    [super _init];

    [self.textLabel setTextColor:[UIColor lightGrayColor]];
    [self setAccessoryType:UITableViewCellAccessoryNone];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
}

- (void)setNeedsDisplay {
    [super setNeedsDisplay];
    self.accessoryView = nil;
}

- (void)setSelected:(BOOL)selected {
    return;
}

@end

@interface PPLibraryAllSongsFromPlaylistListViewController () {
@private
    UIBarButtonItem *_addTracksItem;
    NSMutableArray *_placeholdersArray;
}
@end

@implementation PPLibraryAllSongsFromPlaylistListViewController

#pragma mark - initWith:

- (instancetype)initWithPlaylistModel:(PPLibraryPlaylistModel *)playlistModel {
    self = [super init];
    if (self) {
        self.playlistModel = playlistModel;
    }

    return self;
}

+ (instancetype)controllerWithPlaylistModel:(PPLibraryPlaylistModel *)playlistModel {
    return [[self alloc] initWithPlaylistModel:playlistModel];
}

#pragma mark - Init

- (void)designedInit {
    [super designedInit];
    _placeholdersArray = [NSMutableArray array];
}

#pragma mark - Lifecycle

- (void)loadView {
    [super loadView];

    _addTracksItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                   target:self action:@selector(_addTracksTapped)];
    self.navigationItem.rightBarButtonItem = _addTracksItem;
}

- (void)dealloc {
    _addTracksItem = nil;
    _placeholdersArray = nil;
}

#pragma mark - Adding tracks

- (void)_addTracksTapped {
    PPLibraryRootViewController *libraryRootViewController = [[PPLibraryRootViewController alloc] init];
    libraryRootViewController.tracksPickerMode = YES;

    NSString *promtString = [NSString stringWithFormat:@"%@ \"%@\"", NSLocalizedString(@"Add tracks to", nil), _playlistModel.title];
    libraryRootViewController.navigationBar.topItem.prompt = promtString;

    __block typeof(self) selfRef = self;
    [libraryRootViewController setTracksPickerBlock:^(NSArray *pickedTracks) {
        [selfRef dismissViewControllerAnimated:YES
                                    completion:nil];

        __block NSMutableArray *itemsToCreate = [NSMutableArray array];
        __block NSMutableArray *placeholdersToDelete = [NSMutableArray array];
        __block NSMutableArray *indexPathsForInsert1 = [NSMutableArray array];
        __block NSMutableArray *indexPathsForDelete = [NSMutableArray array];
        __block NSMutableArray *indexPathsForInsert2 = [NSMutableArray array];
        [pickedTracks enumerateObjectsUsingBlock:^(PPLibraryTrackModel *currentTrack, NSUInteger idx, BOOL *stop) {
            if ([currentTrack isKindOfClass:[PPLibraryTrackModel class]]) {
                //detect last placeholder
                int64_t idOfLastPlaceholder = -1;
                NSUInteger indexOfLastPlaceholder = selfRef->_placeholdersArray.count - 1;
                PPLibraryPlaylistItemModel *lastPlaceholder = [selfRef->_placeholdersArray lastObject];
                if (lastPlaceholder) {
                    idOfLastPlaceholder = lastPlaceholder.id;
                }

                //create item for adding to db
                PPLibraryPlaylistItemModel *newItem = [PPLibraryPlaylistItemModel modelWithId:idOfLastPlaceholder - 1
                                                                                        title:nil];
                newItem.trackModel = currentTrack;
                [itemsToCreate addObject:newItem];

                //create and insert new placeholder
                PPLibraryPlaylistItemModel *newPlaceholder = [PPLibraryPlaylistItemModel modelWithId:idOfLastPlaceholder - 1
                                                                                               title:nil];
                newPlaceholder.trackModel = [PPLibraryTrackModel modelWithId:currentTrack.id
                                                                       title:[NSString stringWithFormat:@"[%@] %@", NSLocalizedString(@"Adding", nil), currentTrack.title]
                                                                  albumModel:currentTrack.albumModel
                                                                  genreModel:currentTrack.genreModel];

                [placeholdersToDelete addObject:newPlaceholder];
                [selfRef->_placeholdersArray addObject:newPlaceholder];
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:indexOfLastPlaceholder + 1
                                                            inSection:1];
                [indexPathsForInsert1 addObject:indexPath];
            }
        }];

        [selfRef->_sourceTableView insertRowsAtIndexPaths:indexPathsForInsert1
                                         withRowAnimation:UITableViewRowAnimationFade];
        [selfRef->_sourceTableView scrollToRowAtIndexPath:[indexPathsForInsert1 lastObject]
                                         atScrollPosition:UITableViewScrollPositionMiddle
                                                 animated:YES];

        //insert in db
        [[PPLibraryProvider sharedLibrary].editor addPlaylistItems:itemsToCreate
                                                        toPlaylist:selfRef->_playlistModel
                                               withCompletionBlock:^(NSArray *createdItems) {
                                                   NSMutableArray *placeholdersToRemove = [NSMutableArray array];
                                                   [placeholdersToDelete enumerateObjectsUsingBlock:^(PPLibraryPlaylistItemModel *currentPlaceholder, NSUInteger idx, BOOL *stop) {
                                                       NSUInteger indexOfPlaceholder;
                                                       indexOfPlaceholder = [selfRef->_placeholdersArray indexOfObject:currentPlaceholder];

                                                       if (indexOfPlaceholder != NSNotFound) {
                                                           NSIndexPath *placeholderiPath = [NSIndexPath indexPathForRow:indexOfPlaceholder
                                                                                                              inSection:1];

                                                           [placeholdersToRemove addObject:selfRef->_placeholdersArray[indexOfPlaceholder]];
                                                           [indexPathsForDelete addObject:placeholderiPath];
                                                       }
                                                   }];

                                                   [createdItems enumerateObjectsUsingBlock:^(PPLibraryPlaylistItemModel *currentItem, NSUInteger idx, BOOL *stop) {
                                                       if (![selfRef->_sourceArray containsObject:currentItem.trackModel]) {
                                                           NSUInteger lastPlaylistIndex = selfRef->_sourceArray.count - 1;
                                                           [selfRef->_sourceArray addObject:currentItem];

                                                           NSIndexPath *createdPlaylistIndexPath = [NSIndexPath indexPathForRow:lastPlaylistIndex + 1
                                                                                                                      inSection:0];
                                                           [indexPathsForInsert2 addObject:createdPlaylistIndexPath];
                                                       }
                                                   }];

                                                   if (!createdItems) {
                                                       UIAlertView *errorAV = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                                                                                         message:NSLocalizedString(@"Unknown error occured, sorry :c", nil)
                                                                                                        delegate:nil
                                                                                               cancelButtonTitle:NSLocalizedString(@"Close", nil)
                                                                                               otherButtonTitles:nil];
                                                       [errorAV show];
                                                   }

                                                   [selfRef->_placeholdersArray removeObjectsInArray:placeholdersToRemove];

                                                   [selfRef->_sourceTableView beginUpdates];
                                                   [selfRef->_sourceTableView deleteRowsAtIndexPaths:indexPathsForDelete
                                                                                    withRowAnimation:UITableViewRowAnimationFade];
                                                   [selfRef->_sourceTableView insertRowsAtIndexPaths:indexPathsForInsert2
                                                                                    withRowAnimation:UITableViewRowAnimationFade];
                                                   [selfRef->_sourceTableView endUpdates];
                                                   [selfRef->_sourceTableView scrollToRowAtIndexPath:[indexPathsForInsert2 lastObject]
                                                                                    atScrollPosition:UITableViewScrollPositionMiddle
                                                                                            animated:YES];
                                                   [selfRef updateActionsState];
                                               }];
    }];

    [self presentViewController:libraryRootViewController
                       animated:YES
                     completion:nil];
}

#pragma mark - Reloading

- (void)reloadDataWithCompletionBlock:(void (^)())block {
    __block typeof(self) selfRef = self;
    [[PPLibraryProvider sharedLibrary].fetcher playlistsItemsFromPlaylist:_playlistModel
                                                      withCompletionBlock:^(NSArray *playlistsItemsList) {
                                                          selfRef->_sourceArray = [playlistsItemsList mutableCopy];
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
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }

    if (indexPath.section == 1) {
        cell = [tableView dequeueReusableCellWithIdentifier:tracksPlaceholderIdentifier];

        if (!cell) {
            cell = [[PPLibraryAllSongsPlaceholderCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                           reuseIdentifier:tracksPlaceholderIdentifier];
        }
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
    if (indexPath.section == 1) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - Picking Mode

- (NSObject *)pickedItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self playlistItemForIndexPath:indexPath];
}

#pragma mark - Configuration

- (PPLibraryTrackModel *)trackForIndexPath:(NSIndexPath *)indexPath {
    PPLibraryPlaylistItemModel *itemModel;
    if (indexPath.section == 0) {
        itemModel = _sourceArray[(NSUInteger) indexPath.row];
    }

    if (indexPath.section == 1) {
        itemModel = _placeholdersArray[(NSUInteger) indexPath.row];
    }

    return itemModel.trackModel;
}

- (NSArray *)playlistItemsForCurrentContent {
    return [_sourceArray copy];
}

- (PPLibraryPlaylistItemModel *)playlistItemForIndexPath:(NSIndexPath *)indexPath {
    PPLibraryPlaylistItemModel *itemModel;
    if (indexPath.section == 0) {
        itemModel = _sourceArray[(NSUInteger) indexPath.row];
    }

    if (indexPath.section == 1) {
        itemModel = _placeholdersArray[(NSUInteger) indexPath.row];
    }

    return itemModel;
}

#pragma mark - Now Playing

- (BOOL)isNowPlayingIndexPath:(NSIndexPath *)indexPath {
    return [super isNowPlayingIndexPath:indexPath] && [self playlistItemForIndexPath:indexPath].id == [PPPlayer sharedPlayer].currentPlaylistItem.id;
}

@end