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

#import "PPLibraryAllGenresListViewController.h"
#import "PPLibraryProvider.h"

static const CGFloat cellsHeight = 100.0f;
static NSString *genreCellIdentifier = @"genreCellIdentifier";

static const CGFloat leftImageShift = 10.0f;
static const CGFloat leftTextShift = 0.0f;

@implementation PPLibraryAllGenresCell

#pragma mark - Init

- (void)_init {
    [self.imageView setContentMode:UIViewContentModeCenter];

    [self.textLabel setFont:[UIFont boldSystemFontOfSize:17.0f]];
    [self.detailTextLabel setFont:[UIFont systemFontOfSize:13.0f]];

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

@interface PPLibraryAllGenresListViewController () <UITableViewDataSource, UITableViewDelegate> {
@private
    //Data
    NSMutableArray *_genresArray;
    PPNavigationBarMenuViewAction *_deleteAction;

    //Visual
    UITableView *_genresTableView;
}
@end

@implementation PPLibraryAllGenresListViewController

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

    _genresTableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                                    style:UITableViewStylePlain];
    _genresTableView.dataSource = self;
    _genresTableView.delegate = self;
    _genresTableView.rowHeight = cellsHeight;

    [self.view addSubview:_genresTableView];
}

- (void)dealloc {
    _genresTableView = nil;
    _genresArray = nil;

    _deleteAction = nil;
}

#pragma mark - Layout

- (void)performLayout {
    [super performLayout];
    [_genresTableView setFrame:self.view.bounds];
}

#pragma mark - Reloading

- (void)_reloadArtists {
    [self startLoading];

    __block typeof(self) selfRef = self;
    [[PPLibraryProvider sharedLibrary].fetcher genresListWithCompletionBlock:^(NSArray *genresList) {
        selfRef->_genresArray = [genresList mutableCopy];
        [selfRef->_genresTableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                                 withRowAnimation:UITableViewRowAnimationFade];
        [selfRef endLoading];
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _genresArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:genreCellIdentifier];

    if (!cell) {
        cell = [[PPLibraryAllGenresCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                             reuseIdentifier:genreCellIdentifier];
        [cell.imageView setImage:[UIImage imageNamed:@"ArtworkPlaceHolderArtist.png"]];
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    PPLibraryGenreModel *genreModel = _genresArray[(NSUInteger) indexPath.row];

    NSString *title = genreModel.title;
    NSMutableAttributedString *subtitle = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@: %lld", NSLocalizedString(@"Tracks_count.genres", nil), genreModel.tracksCount]
                                                                                 attributes:@{NSForegroundColorAttributeName : [UIColor darkGrayColor]}];

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
    return _genresArray.count > 0;
}

- (void)selectTapped {
    [super selectTapped];
    [_genresTableView reloadData];
}

- (void)doneTapped {
    [super doneTapped];
    [_genresTableView reloadData];
}

@end