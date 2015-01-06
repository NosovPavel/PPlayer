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

@interface PPLibraryAllAlbumsListViewController () <UITableViewDataSource, UITableViewDelegate> {
@private
    //Data
    NSMutableArray *_albumsArray;
    PPNavigationBarMenuViewAction *_deleteAction;

    //Visual
    UITableView *_albumsTableView;
}
@end

@implementation PPLibraryAllAlbumsListViewController

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
    [self.menuNavigationViewController setMenuHidden:NO animated:YES];
    [self _reloadArtists];
}

- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];

    _albumsTableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                                    style:UITableViewStylePlain];
    _albumsTableView.dataSource = self;
    _albumsTableView.delegate = self;
    _albumsTableView.rowHeight = cellsHeight;

    [self.view addSubview:_albumsTableView];
}

- (void)dealloc {
    _albumsTableView = nil;
    _albumsArray = nil;

    _deleteAction = nil;
}

#pragma mark - Layout

- (void)performLayout {
    [super performLayout];
    [_albumsTableView setFrame:self.view.bounds];
}

#pragma mark - Reloading

- (void)_reloadArtists {
    [self startLoading];

    __block typeof(self) selfRef = self;
    [[PPLibraryProvider sharedLibrary].fetcher albumsListWithCompletionBlock:^(NSArray *albumsList) {
        selfRef->_albumsArray = [albumsList mutableCopy];
        [selfRef->_albumsTableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                                 withRowAnimation:UITableViewRowAnimationFade];
        [selfRef endLoading];
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _albumsArray.count;
}

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
    PPLibraryAlbumModel *albumModel = _albumsArray[(NSUInteger) indexPath.row];

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
}

#pragma mark - PPSelectableActionsViewController Logic

- (BOOL)canPerformAction:(PPNavigationBarMenuViewAction *)action {
    return NO;
}

- (BOOL)canPerformSelection {
    return _albumsArray.count > 0;
}

- (void)selectTapped {
    [super selectTapped];
    [_albumsTableView reloadData];
}

- (void)doneTapped {
    [super doneTapped];
    [_albumsTableView reloadData];
}

@end