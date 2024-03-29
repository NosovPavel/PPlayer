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

#import "PPSelectableActionsViewController.h"

@class PPLibraryRootViewController;
@class PPLibraryPlaylistItemModel;
@class PPLibraryTrackModel;

@protocol PPLibraryPickingCellProtocol <NSObject>
@required
@property BOOL checked;
@end

@protocol PPLibraryNowPlaingCellProtocol <NSObject>
@required
@property BOOL nowPlaing;
@end

@interface PPLibrarySectionListViewController : PPSelectableActionsViewController <UITableViewDataSource, UITableViewDelegate> {
@protected
    //Data
    NSMutableArray *_sourceArray;
    NSMutableArray *_pickedArray;
    PPNavigationBarMenuViewAction *_deleteAction;
    PPNavigationBarMenuViewAction *_editAction;

    BOOL _selectingMode;

    //Visual
    UITableView *_sourceTableView;
}

@property(atomic, readonly) BOOL tracksPickerMode;

#pragma mark - Reloading

- (void)reloadDataWithCompletionBlock:(void (^)())block;

#pragma mark - Picker Mode Logic

- (BOOL)isPickedIndexPath:(NSIndexPath *)indexPath;

- (NSObject *)pickedItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)updateDoneButtonState;

#pragma mark - Configuration

- (PPLibraryTrackModel *)trackForIndexPath:(NSIndexPath *)indexPath;

- (NSArray *)playlistItemsForCurrentContent;

- (PPLibraryPlaylistItemModel *)playlistItemForIndexPath:(NSIndexPath *)indexPath;

#pragma mark - Now Playing

- (BOOL)isNowPlayingIndexPath:(NSIndexPath *)indexPath;

@end