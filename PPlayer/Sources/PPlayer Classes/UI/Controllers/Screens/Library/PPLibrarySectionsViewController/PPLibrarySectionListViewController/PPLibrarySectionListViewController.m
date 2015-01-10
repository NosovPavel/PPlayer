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

#import "PPLibrarySectionListViewController.h"
#import "PPLibraryRootViewController.h"
#import "PPLibraryPlaylistItemModel.h"
#import "PPLibraryTrackModel.h"
#import "PPPlayer.h"

@implementation PPLibrarySectionListViewController

#pragma mark - Init

- (void)designedInit {
    [super designedInit];

    _deleteAction = [PPNavigationBarMenuViewAction actionWithIcon:[UIImage imageNamed:@"NavMenuIconDelete.png"]
                                                          handler:^{
                                                              //
                                                          } title:NSLocalizedString(@"Delete", nil)];

    _editAction = [PPNavigationBarMenuViewAction actionWithIcon:[UIImage imageNamed:@"NavMenuIconEdit.png"]
                                                        handler:^{
                                                            //
                                                        } title:NSLocalizedString(@"Edit", nil)];

    _actionsWhenSelected = @[_editAction, _deleteAction];
    _pickedArray = [NSMutableArray array];
}

- (void)commonInit {
    [super commonInit];
}

#pragma mark - Lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self updateDoneButtonState];

    if (self.libraryRootViewController.tracksPickerMode) {
        [self.libraryRootViewController.tracksPickerDoneItem setTarget:self];
        [self.libraryRootViewController.tracksPickerDoneItem setAction:@selector(_pickerDoneTapped)];
    }

    [self.menuNavigationViewController setMenuHidden:NO animated:YES];

    [self _subscribeOnCurrentPlayerItemChange];

    [self _reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.libraryRootViewController.tracksPickerDoneItem setTarget:nil];
    [self.libraryRootViewController.tracksPickerDoneItem setAction:nil];

    [self _unsubscribeFromCurrentPlayerItemChange];

    [super viewWillDisappear:animated];
}

- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];

    _sourceTableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                                    style:UITableViewStylePlain];
    _sourceTableView.dataSource = self;
    _sourceTableView.delegate = self;

    [self.view addSubview:_sourceTableView];
}

- (void)dealloc {
    _sourceArray = nil;
    _pickedArray = nil;

    _editAction = nil;
    _deleteAction = nil;

    _sourceTableView = nil;
}

#pragma mark - NSNotificationCenter Observing

- (void)_subscribeOnCurrentPlayerItemChange {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_currentPlayingItemChanged)
                                                 name:PPPlayerStateNowPlayingItemChangedNotificationName
                                               object:NULL];
}

- (void)_unsubscribeFromCurrentPlayerItemChange {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:PPPlayerStateNowPlayingItemChangedNotificationName
                                                  object:NULL];
}

#pragma mark - Layout

- (void)performLayout {
    [super performLayout];
    [_sourceTableView setFrame:self.view.bounds];
}

#pragma mark - Reloading

- (void)_reloadData {
    [self startLoading];

    __block typeof(self) selfRef = self;
    [self reloadDataWithCompletionBlock:^{
        [selfRef endLoading];
    }];
}

- (void)reloadDataWithCompletionBlock:(void (^)())block {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (block) {
            block();
        }
    });
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _sourceArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell <PPLibraryPickingCellProtocol, PPLibraryNowPlaingCellProtocol> *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ((self.tracksPickerMode || _selectingMode) && [cell conformsToProtocol:@protocol(PPLibraryPickingCellProtocol)]) {
        cell.checked = [self isPickedIndexPath:indexPath];
    } else {
        if ([cell conformsToProtocol:@protocol(PPLibraryNowPlaingCellProtocol)]) {
            cell.nowPlaing = [self isNowPlayingIndexPath:indexPath];
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (self.tracksPickerMode || _selectingMode) {
        NSObject *track = [self pickedItemAtIndexPath:indexPath];
        BOOL picked = [_pickedArray containsObject:track];
        if (picked) {
            [_pickedArray removeObject:track];
        } else {
            [_pickedArray addObject:track];
        }

        [tableView reloadRowsAtIndexPaths:@[indexPath]
                         withRowAnimation:UITableViewRowAnimationNone];

        if (self.tracksPickerMode && !_selectingMode) {
            [self updateDoneButtonState];
        }
    } else {
        [[PPPlayer sharedPlayer] setCurrentPlaylistItems:[self playlistItemsForCurrentContent]];
        [[PPPlayer sharedPlayer] startPlaingItem:[self playlistItemForIndexPath:indexPath]];

        [tableView selectRowAtIndexPath:indexPath
                               animated:NO
                         scrollPosition:UITableViewScrollPositionNone];
        [tableView deselectRowAtIndexPath:indexPath
                                 animated:YES];
    }
}

#pragma mark - NSNotificationCenter Callbacks

- (void)_currentPlayingItemChanged {
    [_sourceTableView reloadRowsAtIndexPaths:[_sourceTableView indexPathsForVisibleRows]
                            withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - PPSelectableActionsViewController Logic

- (BOOL)canPerformAction:(PPNavigationBarMenuViewAction *)action {
    return NO;
}

- (BOOL)canPerformSelection {
    if (self.libraryRootViewController.tracksPickerMode) {
        return NO;
    }

    return _sourceArray.count > 0;
}

- (void)selectTapped {
    [super selectTapped];

    _selectingMode = YES;
    _pickedArray = [NSMutableArray array];

    [_sourceTableView reloadRowsAtIndexPaths:[_sourceTableView indexPathsForVisibleRows]
                            withRowAnimation:UITableViewRowAnimationFade];
}

- (void)doneTapped {
    [super doneTapped];

    _selectingMode = NO;
    _pickedArray = nil;

    [_sourceTableView reloadRowsAtIndexPaths:[_sourceTableView indexPathsForVisibleRows]
                            withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - Picker Mode Logic

- (BOOL)tracksPickerMode {
    return self.libraryRootViewController.tracksPickerMode;
}

- (void)updateDoneButtonState {
    self.libraryRootViewController.tracksPickerDoneItem.enabled = _pickedArray.count > 0;

    if (self.libraryRootViewController.tracksPickerDoneItem.enabled) {
        self.libraryRootViewController.tracksPickerDoneItem.title = [NSString stringWithFormat:@"%@ (%d)", NSLocalizedString(@"Add", nil), (int) _pickedArray.count];
    } else {
        self.libraryRootViewController.tracksPickerDoneItem.title = NSLocalizedString(@"Add", nil);
    }
}

- (NSObject *)pickedItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self trackForIndexPath:indexPath];
}

- (BOOL)isPickedIndexPath:(NSIndexPath *)indexPath {
    return [_pickedArray containsObject:[self pickedItemAtIndexPath:indexPath]];
}

- (void)_pickerDoneTapped {
    if (self.libraryRootViewController.tracksPickerBlock) {
        self.libraryRootViewController.tracksPickerBlock([_pickedArray copy]);
    }
}

#pragma mark - Configuration

- (PPLibraryTrackModel *)trackForIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (NSArray *)playlistItemsForCurrentContent {
    return nil;
}

- (PPLibraryPlaylistItemModel *)playlistItemForIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

#pragma mark - Now Playing

- (BOOL)isNowPlayingIndexPath:(NSIndexPath *)indexPath {
    return [self trackForIndexPath:indexPath].id == [PPPlayer sharedPlayer].currentPlaylistItem.trackModel.id;
}

@end