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
#import "PPMenuNavigationViewController.h"

static const CGFloat cellsHeight = 60.0f;
static const CGFloat leftImageShift = 16.5f;
static const CGFloat leftTextShift = 5.0f;
static NSString *tracksCellIdentifier = @"tracksCellIdentifier";

@interface PPLibraryAllSongsCell : UITableViewCell
@end

@implementation PPLibraryAllSongsCell

- (void)layoutSubviews {
    [super layoutSubviews];

    CGRect imageViewFrame = self.imageView.frame;
    imageViewFrame.origin.x -= leftImageShift;
    self.imageView.frame = imageViewFrame;

    CGRect titleViewFrame = self.textLabel.frame;
    titleViewFrame.origin.x -= leftImageShift + leftTextShift;
    self.textLabel.frame = titleViewFrame;

    CGRect subTitleViewFrame = self.detailTextLabel.frame;
    subTitleViewFrame.origin.x -= leftImageShift + leftTextShift;
    self.detailTextLabel.frame = subTitleViewFrame;

    self.separatorInset = UIEdgeInsetsMake(0.0f, self.textLabel.frame.origin.x, 0.0f, 0.0f);
}

@end

@interface PPLibraryAllSongsListViewController () <UITableViewDataSource, UITableViewDelegate> {
@private
    //Data
    NSMutableArray *_tracksArray;
    PPNavigationBarMenuViewAction *_selectElementsAction;
    PPNavigationBarMenuViewAction *_loadingAction, *_deleteAction, *_cancelAction;

    BOOL _isSelecting, _isLoading;

    //Visual
    UITableView *_tracksTableView;
}
@end

@implementation PPLibraryAllSongsListViewController

#pragma mark - Init

- (void)designedInit {
    [super designedInit];

    _isSelecting = NO;
    _isLoading = NO;
}

- (void)commonInit {
    [super commonInit];
}

#pragma mark - Lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.menuNavigationViewController setMenuHidden:NO animated:animated];
    [self _reloadTracks];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.menuNavigationViewController setMenuHidden:YES animated:animated];
}

- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];

    _tracksTableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                                    style:UITableViewStylePlain];
    _tracksTableView.dataSource = self;
    _tracksTableView.delegate = self;
    _tracksTableView.rowHeight = cellsHeight;

    [self.view addSubview:_tracksTableView];
}

- (void)dealloc {
    _tracksTableView = nil;
    _tracksArray = nil;

    _selectElementsAction = nil;
    _loadingAction = nil;
    _deleteAction = nil;
    _cancelAction = nil;
}

#pragma mark - Layout

- (void)performLayout {
    [super performLayout];
    [_tracksTableView setFrame:self.view.bounds];
}

#pragma mark - Reloading

- (void)_reloadTracks {
    _isLoading = YES;
    [self _actionsStateChanged];

    __block typeof(self) selfRef = self;
    [[PPLibraryProvider sharedLibrary] tracksListWithCompletionBlock:^(NSArray *tracksList) {
        selfRef->_tracksArray = [tracksList mutableCopy];

        selfRef->_isLoading = NO;
        [selfRef _actionsStateChanged];
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _tracksArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tracksCellIdentifier];

    if (!cell) {
        cell = [[PPLibraryAllSongsCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                            reuseIdentifier:tracksCellIdentifier];
        [cell.imageView setContentMode:UIViewContentModeCenter];
        [cell.imageView setImage:[UIImage imageNamed:@"ArtworkPlaceHolderIcon.png"]];
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    PPLibraryTrackModel *track = _tracksArray[(NSUInteger) indexPath.row];

    NSString *title = track.title;
    NSMutableAttributedString *subtitle = [[NSMutableAttributedString alloc] initWithString:track.albumModel.artistModel.title];
    NSAttributedString *albumName = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@" %@", track.albumModel.title]
                                                                    attributes:@{NSForegroundColorAttributeName : [UIColor lightGrayColor]}];
    [subtitle appendAttributedString:albumName];

    [cell.textLabel setText:title];
    [cell.detailTextLabel setAttributedText:subtitle];
};

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Actions Setting Up

- (void)_setupActualActionsAnimated:(BOOL)animated {
    if (_isLoading) {
        [self _setupLoadingStateActionsAnimated:animated];
    } else {
        _isSelecting ? [self _setupSelectedStateActionsAnimated:animated] : [self _setupUnselectedStateActionsAnimated:animated];
    }
}

- (void)_setupLoadingStateActionsAnimated:(BOOL)animated {
    if (!_loadingAction) {
        _loadingAction = [PPNavigationBarMenuViewAction actionWithIcon:nil
                                                               handler:^{
                                                                   //
                                                               } title:NSLocalizedString(@"Refreshing...", nil)];
    }

    [self _updateActionsEnabledState];
    [self.menuNavigationViewController setNavigationMenuActions:@[_loadingAction] animated:animated];
}

- (void)_setupUnselectedStateActionsAnimated:(BOOL)animated {
    __block typeof(self) selfRef = self;
    if (!_selectElementsAction) {
        _selectElementsAction = [PPNavigationBarMenuViewAction actionWithIcon:[UIImage imageNamed:@"NavMenuIconSelect.png"]
                                                                      handler:^{
                                                                          selfRef->_isSelecting = YES;
                                                                          [selfRef _setupActualActionsAnimated:YES];
                                                                          [selfRef->_tracksTableView reloadData];
                                                                      } title:NSLocalizedString(@"Select items...", nil)];
    }

    [self _updateActionsEnabledState];
    [self.menuNavigationViewController setNavigationMenuActions:@[_selectElementsAction] animated:animated];
}

- (void)_setupSelectedStateActionsAnimated:(BOOL)animated {
    __block typeof(self) selfRef = self;
    if (!_deleteAction) {
        _deleteAction = [PPNavigationBarMenuViewAction actionWithIcon:[UIImage imageNamed:@"NavMenuIconDelete.png"]
                                                              handler:^{
                                                                  //
                                                              } title:NSLocalizedString(@"Delete", nil)];
    }
    if (!_cancelAction) {
        _cancelAction = [PPNavigationBarMenuViewAction actionWithIcon:[UIImage imageNamed:@"NavMenuIconDone.png"]
                                                              handler:^{
                                                                  selfRef->_isSelecting = NO;
                                                                  [selfRef _setupActualActionsAnimated:YES];
                                                              }
                                                                title:NSLocalizedString(@"Done", nil)];
    }

    [self _updateActionsEnabledState];
    [self.menuNavigationViewController setNavigationMenuActions:@[_deleteAction, _cancelAction]
                                                       animated:animated];
}

#pragma mark - Navigation Bar Actions Enabled State

- (void)_updateActionsEnabledState {
    if (_isLoading) {
        _loadingAction.enabled = NO;

        _selectElementsAction.enabled = NO;
        _deleteAction.enabled = NO;
        _cancelAction.enabled = NO;
    } else {
        if (_isSelecting) {
            _selectElementsAction.enabled = NO;
            _cancelAction.enabled = YES;

            _deleteAction.enabled = NO;
        } else {
            _selectElementsAction.enabled = _tracksArray.count > 0;

            _cancelAction.enabled = NO;
            _deleteAction.enabled = NO;
        }
    }
}

#pragma mark - Selecting State Changing

- (void)_actionsStateChanged {
    [self _setupActualActionsAnimated:YES];

    [_tracksTableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                    withRowAnimation:UITableViewRowAnimationFade];
}

@end