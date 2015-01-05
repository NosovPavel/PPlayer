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

static const CGFloat cellsHeight = 60.0f;
static NSString *tracksCellIdentifier = @"tracksCellIdentifier";

@interface PPLibraryAllSongsListViewController () <UITableViewDataSource, UITableViewDelegate> {
@private
    //Data
    NSMutableArray *_tracksArray;

    //Visual
    UITableView *_tracksTableView;
}
@end

@implementation PPLibraryAllSongsListViewController

#pragma mark - Init

- (void)designedInit {
    [super designedInit];
}

- (void)commonInit {
    [super commonInit];
}

#pragma mark - Lifecycle

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];
    [self _reloadTracks];
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
}

#pragma mark - Layout

- (void)performLayout {
    [super performLayout];
    [_tracksTableView setFrame:self.view.bounds];
}

#pragma mark - Reloading

- (void)_reloadTracks {
    __block typeof(self) selfRef = self;
    [[PPLibraryProvider sharedLibrary] tracksListWithCompletionBlock:^(NSArray *tracksList) {
        selfRef->_tracksArray = [tracksList mutableCopy];
        [selfRef->_tracksTableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                                 withRowAnimation:UITableViewRowAnimationFade];
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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:tracksCellIdentifier];
        [cell.imageView setImage:[UIImage imageNamed:@"CellIconFileAudio.png"]];
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

@end