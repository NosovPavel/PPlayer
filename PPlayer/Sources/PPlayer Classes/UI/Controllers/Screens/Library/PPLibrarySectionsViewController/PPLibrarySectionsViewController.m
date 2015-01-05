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

static const CGFloat cellsHeight = 60.0f;
static NSString *sectionCellIdentifier = @"fileCellIdentifier";

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
    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 0: {
                    cell.textLabel.text = NSLocalizedString(@"Artists", nil);
                }
                    break;

                case 1: {
                    cell.textLabel.text = NSLocalizedString(@"Albums", nil);
                }
                    break;

                case 2: {
                    cell.textLabel.text = NSLocalizedString(@"Genres", nil);
                }
                    break;

                default: {
                    cell.textLabel.text = @"";
                }
                    break;
            }
        }
            break;

        case 1: {
            switch (indexPath.row) {
                case 0: {
                    cell.textLabel.text = NSLocalizedString(@"All songs", nil);
                }
                    break;
                default: {
                    cell.textLabel.text = @"";
                }
                    break;
            }
        }
            break;

        default: {
            cell.textLabel.text = @"";
        }
            break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


@end