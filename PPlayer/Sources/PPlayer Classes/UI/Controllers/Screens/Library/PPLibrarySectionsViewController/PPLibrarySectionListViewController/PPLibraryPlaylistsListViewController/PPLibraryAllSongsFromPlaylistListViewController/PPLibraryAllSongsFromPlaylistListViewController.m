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

@interface PPLibraryAllSongsFromPlaylistListViewController () {
@private
    UIBarButtonItem *_addTracksItem;
}
@end

@implementation PPLibraryAllSongsFromPlaylistListViewController

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

#pragma mark - Lifecycle

- (void)loadView {
    [super loadView];

    _addTracksItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                   target:self action:@selector(_addTracksTapped)];
    self.navigationItem.rightBarButtonItem = _addTracksItem;
}

- (void)dealloc {
    _addTracksItem = nil;
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
    }];

    [self presentViewController:libraryRootViewController
                       animated:YES
                     completion:nil];
}

#pragma mark - Reloading

- (void)reloadDataWithCompletionBlock:(void (^)())block {
    __block typeof(self) selfRef = self;
    [[PPLibraryProvider sharedLibrary].fetcher tracksListFromPlaylist:_playlistModel
                                                  withCompletionBlock:^(NSArray *tracksList) {
                                                      selfRef->_sourceArray = [tracksList mutableCopy];
                                                      [selfRef->_sourceTableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                                                                               withRowAnimation:UITableViewRowAnimationFade];
                                                      if (block) {
                                                          block();
                                                      }
                                                  }];
}

@end