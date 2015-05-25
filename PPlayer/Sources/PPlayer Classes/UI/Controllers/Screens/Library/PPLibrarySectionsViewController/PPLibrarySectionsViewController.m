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

#import "PPLibrarySectionsViewController.h"

#import "PPLibraryAllSongsListViewController.h"
#import "PPLibraryAllArtistsListViewController.h"
#import "PPLibraryAllAlbumsListViewController.h"
#import "PPLibraryAllGenresListViewController.h"
#import "PPLibraryRootViewController.h"

static const CGFloat cellsHeight = 60.0f;
static NSString *sectionCellIdentifier = @"sectionCellIdentifier";

@interface PPLibrarySectionsViewController () <UITableViewDataSource, UITableViewDelegate> {
@private
    //Visual
    UITableView *_sectionsTableView;
}
@end

@implementation PPLibrarySectionsViewController

#pragma mark - Init

- (void)designedInit {
    [super designedInit];
}

- (void)commonInit {
    [super commonInit];
    [self.menuNavigationViewController setMenuHidden:YES animated:NO];
}

#pragma mark - Lifecycle

- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];

    _sectionsTableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                                      style:UITableViewStyleGrouped];
    _sectionsTableView.dataSource = self;
    _sectionsTableView.delegate = self;
    _sectionsTableView.rowHeight = cellsHeight;

    [self.view addSubview:_sectionsTableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.menuNavigationViewController setMenuHidden:YES animated:YES];
    self.libraryRootViewController.tracksPickerDoneItem.enabled = NO;
    self.libraryRootViewController.tracksPickerDoneItem.title = NSLocalizedString(@"Add", nil);
}

- (void)dealloc {
    _sectionsTableView = nil;
}

#pragma mark - Layout

- (void)performLayout {
    [super performLayout];
    [_sectionsTableView setFrame:self.view.bounds];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: {
            return 3;
        }

        case 1: {
            return 1;
        }

        default: {
            return 0;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:sectionCellIdentifier];

    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:sectionCellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return NSLocalizedString(@"Sections", nil);
    }

    if (section == 1) {
        return NSLocalizedString(@"Without sections", nil);
    }

    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.textLabel.text = @"";
    cell.imageView.image = nil;

    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 0: {
                    cell.textLabel.text = NSLocalizedString(@"Artists", nil);
                    cell.imageView.image = [UIImage imageNamed:@"CellIconLibrarySectionsArtists.png"];
                }
                    break;

                case 1: {
                    cell.textLabel.text = NSLocalizedString(@"Albums", nil);
                    cell.imageView.image = [UIImage imageNamed:@"CellIconLibrarySectionsAlbums.png"];
                }
                    break;

                case 2: {
                    cell.textLabel.text = NSLocalizedString(@"Genres", nil);
                    cell.imageView.image = [UIImage imageNamed:@"CellIconLibrarySectionsGenres.png"];
                }
                    break;

                default: {
                }
                    break;
            }
        }
            break;

        case 1: {
            switch (indexPath.row) {
                case 0: {
                    cell.textLabel.text = NSLocalizedString(@"All songs", nil);
                    cell.imageView.image = [UIImage imageNamed:@"CellIconLibrarySectionsAllSongs.png"];
                }
                    break;
                default: {
                }
                    break;
            }
        }
            break;

        default: {
        }
            break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 0: {
                    PPLibraryAllArtistsListViewController *artistsListViewController = [[PPLibraryAllArtistsListViewController alloc] init];
                    artistsListViewController.title = NSLocalizedString(@"Artists", nil);

                    [self.navigationController pushViewController:artistsListViewController animated:YES];
                }
                    break;

                case 1: {
                    PPLibraryAllAlbumsListViewController *albumsListViewController = [[PPLibraryAllAlbumsListViewController alloc] init];
                    albumsListViewController.title = NSLocalizedString(@"Albums", nil);

                    [self.navigationController pushViewController:albumsListViewController animated:YES];
                }
                    break;

                case 2: {
                    PPLibraryAllGenresListViewController *genresListViewController = [[PPLibraryAllGenresListViewController alloc] init];
                    genresListViewController.title = NSLocalizedString(@"Genres", nil);

                    [self.navigationController pushViewController:genresListViewController animated:YES];
                }
                    break;

                default: {
                }
                    break;
            }
        }
            break;

        case 1: {
            switch (indexPath.row) {
                case 0: {
                    PPLibraryAllSongsListViewController *songsListViewController = [[PPLibraryAllSongsListViewController alloc] init];
                    songsListViewController.title = NSLocalizedString(@"All songs", nil);

                    [self.navigationController pushViewController:songsListViewController animated:YES];
                }
                    break;
                default: {
                }
                    break;
            }
        }
            break;

        default: {
        }
            break;
    }
}

@end