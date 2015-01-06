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

#import "PPLibraryAllArtistsListViewController.h"
#import "PPLibraryProvider.h"

static const CGFloat cellsHeight = 100.0f;
static NSString *artistCellIdentifier = @"tracksCellIdentifier";

static const CGFloat leftImageShift = 10.0f;
static const CGFloat leftTextShift = 0.0f;

@implementation PPLibraryAllArtistsCell

#pragma mark - Init

- (void)_init {
    [self.imageView setContentMode:UIViewContentModeCenter];
    [self.textLabel setFont:[UIFont systemFontOfSize:20.0f]];
    [self.detailTextLabel setFont:[UIFont systemFontOfSize:15.0f]];
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

#pragma mark - Layout

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

@interface PPLibraryAllArtistsListViewController () <UITableViewDataSource, UITableViewDelegate> {
@private
    //Data
    NSMutableArray *_artistsArray;
    PPNavigationBarMenuViewAction *_deleteAction;

    //Visual
    UITableView *_artistsTableView;
}
@end

@implementation PPLibraryAllArtistsListViewController

#pragma mark - Init

- (void)designedInit {
    [super designedInit];

    _deleteAction = [PPNavigationBarMenuViewAction actionWithIcon:[UIImage imageNamed:@"NavMenuIconDelete.png"]
                                                          handler:^{
                                                              //
                                                          } title:NSLocalizedString(@"Delete", nil)];
    _actionsWhenSelected = @[_deleteAction];
}

- (void)commonInit {
    [super commonInit];
}

#pragma mark - Lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self _reloadArtists];
}

- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];

    _artistsTableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                                     style:UITableViewStylePlain];
    _artistsTableView.dataSource = self;
    _artistsTableView.delegate = self;
    _artistsTableView.rowHeight = cellsHeight;

    [self.view addSubview:_artistsTableView];
}

- (void)dealloc {
    _artistsTableView = nil;
    _artistsArray = nil;

    _deleteAction = nil;
}

#pragma mark - Layout

- (void)performLayout {
    [super performLayout];
    [_artistsTableView setFrame:self.view.bounds];
}

#pragma mark - Reloading

- (void)_reloadArtists {
    [self startLoading];

    __block typeof(self) selfRef = self;
    [[PPLibraryProvider sharedLibrary].fetcher artistsListWithCompletionBlock:^(NSArray *artistsList) {
        selfRef->_artistsArray = [artistsList mutableCopy];
        [selfRef->_artistsTableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                                  withRowAnimation:UITableViewRowAnimationFade];
        [selfRef endLoading];
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _artistsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:artistCellIdentifier];

    if (!cell) {
        cell = [[PPLibraryAllArtistsCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                              reuseIdentifier:artistCellIdentifier];
        [cell.imageView setImage:[UIImage imageNamed:@"ArtworkPlaceHolderArtist.png"]];
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    PPLibraryArtistModel *artistModel = _artistsArray[(NSUInteger) indexPath.row];

    NSString *title = artistModel.title;
    NSMutableAttributedString *subtitle = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: %lld, ", NSLocalizedString(@"Albums_count", nil), artistModel.albumsCount]
                                                                                 attributes:@{NSForegroundColorAttributeName : [UIColor darkGrayColor]}];
    NSAttributedString *albumName = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: %lld", NSLocalizedString(@"Tracks_count", nil), artistModel.tracksCount]
                                                                    attributes:@{NSForegroundColorAttributeName : [UIColor lightGrayColor]}];
    [subtitle appendAttributedString:albumName];

    [cell.textLabel setText:title];
    [cell.detailTextLabel setAttributedText:subtitle];
};

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - PPSelectableActionsViewController Logic

- (BOOL)canPerformAction:(PPNavigationBarMenuViewAction *)action {
    return NO;
}

- (BOOL)canPerformSelection {
    return _artistsArray.count > 0;
}

- (void)selectTapped {
    [super selectTapped];
    [_artistsTableView reloadData];
}

- (void)doneTapped {
    [super doneTapped];
    [_artistsTableView reloadData];
}

@end