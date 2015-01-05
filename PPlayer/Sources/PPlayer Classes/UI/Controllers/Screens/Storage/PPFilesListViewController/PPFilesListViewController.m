//
//  Copyright © 2014 Alexander Orlov
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

#import "PPFilesListViewController.h"
#import "PPFilesProvider.h"
#import "PPLibraryProvider.h"

#import "LLACircularProgressView.h"

static const CGFloat cellsHeight = 60.0f;
static const CGFloat progressViewSize = 60.0f;

static NSString *fileCellIdentifier = @"fileCellIdentifier";
static NSString *folderCellIdentifier = @"folderCellIdentifier";

@interface PPProgressView : UIView {
@private
    LLACircularProgressView *_progressView;
}
- (void)setProgress:(float)progress animated:(BOOL)animated;
@end

@implementation PPProgressView

#pragma mark - Init

- (void)_init {
    _progressView = [[LLACircularProgressView alloc] initWithFrame:CGRectZero];
    [self addSubview:_progressView];
}

#pragma mark - Lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        [self _init];
    }

    return self;
}

- (void)dealloc {
    _progressView = nil;
}

#pragma mark - Interface

- (void)setProgress:(float)progress animated:(BOOL)animated {
    [_progressView setProgress:progress animated:animated];
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];

    [_progressView setFrame:CGRectMake(0, 0, progressViewSize, progressViewSize)];
    [_progressView setCenter:[self convertPoint:self.center fromView:self.superview]];
    [_progressView setCenter:CGPointMake(_progressView.center.x, _progressView.center.y - progressViewSize / 4.0f)];
    [_progressView setBackgroundColor:[self backgroundColor]];
}

@end

@interface PPFilesListViewController () <UITableViewDataSource, UITableViewDelegate> {
@private
    BOOL nowSelectFiles;
    NSMutableArray *_displaingFiles;
    NSMutableDictionary *_selectedFiles;

    PPNavigationBarMenuViewAction *_importToLibraryAction, *_deleteAction;

    PPFilesProvider *_filesProvider;

    //Visual
    UITableView *_filesTableView;
}
@end

@implementation PPFilesListViewController

#pragma mark - Init

- (void)designedInit {
    [super designedInit];

    _filesProvider = [PPFilesProvider new];

    _deleteAction = [PPNavigationBarMenuViewAction actionWithIcon:[UIImage imageNamed:@"NavMenuIconDelete.png"]
                                                          handler:^{
                                                              [self _deleteSelectedFiles];
                                                          } title:NSLocalizedString(@"Delete", nil)];
    _importToLibraryAction = [PPNavigationBarMenuViewAction actionWithIcon:[UIImage imageNamed:@"NavMenuIconToLibrary.png"]
                                                                   handler:^{
                                                                       [self _importSelectedFiles];
                                                                   } title:NSLocalizedString(@"Import to Library", nil)];
    _actionsWhenSelected = @[_importToLibraryAction, _deleteAction];
}

- (void)commonInit {
    [super commonInit];
}

#pragma mark - Lifecycle

- (instancetype)initWithRootURL:(NSURL *)rootURL {
    self = [super init];
    if (self) {
        self.rootURL = rootURL;
        [self designedInit];
    }

    return self;
}

+ (instancetype)controllerWithRootURL:(NSURL *)rootURL {
    return [[self alloc] initWithRootURL:rootURL];
}

- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];

    _filesTableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                                   style:UITableViewStylePlain];
    _filesTableView.dataSource = self;
    _filesTableView.delegate = self;
    _filesTableView.rowHeight = cellsHeight;

    [self.view addSubview:_filesTableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self _reloadFilesList];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)dealloc {
    _filesTableView = nil;
    _displaingFiles = nil;
    _selectedFiles = nil;
    _filesProvider = nil;
    _deleteAction = nil;
    _importToLibraryAction = nil;
}

#pragma mark - Layout

- (void)performLayout {
    [super performLayout];

    [_filesTableView setFrame:self.view.bounds];
}

#pragma mark - Files Management

- (void)_reloadFilesList {
    _isLoading = YES;
    [self updateActions];

    _displaingFiles = [[_filesProvider filesModelsAtURL:_rootURL] mutableCopy];
    [_filesTableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];

    _isLoading = NO;
    [self updateActions];
}

#pragma mark - Deleting

- (void)_deleteSelectedFiles {
    NSMutableArray *selectedIndexPaths = [NSMutableArray array];
    [_selectedFiles enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *currentIndexPath, PPFileModel *currentFile, BOOL *stop) {
        NSUInteger index = [_displaingFiles indexOfObject:currentFile];

        if (index != NSNotFound) {
            [_displaingFiles removeObjectAtIndex:index];
            [_filesProvider removeFileAtURL:currentFile.url];

            [selectedIndexPaths addObject:currentIndexPath];
        }
    }];

    [_filesTableView beginUpdates];
    [_filesTableView deleteRowsAtIndexPaths:selectedIndexPaths
                           withRowAnimation:UITableViewRowAnimationLeft];
    [_filesTableView endUpdates];

    _selectedFiles = [@{} mutableCopy];

    [self updateActionsState];
}

#pragma mark - Importing

- (void)_importSelectedFiles {
    NSMutableArray *selectedIndexPaths = [NSMutableArray array];
    NSMutableArray *filesToImport = [NSMutableArray array];
    [_selectedFiles enumerateKeysAndObjectsUsingBlock:^(NSIndexPath *currentIndexPath, PPFileModel *currentFile, BOOL *stop) {
        NSUInteger index = [_displaingFiles indexOfObject:currentFile];

        if (index != NSNotFound) {
            [_displaingFiles removeObjectAtIndex:index];

            [filesToImport addObject:currentFile];
            [selectedIndexPaths addObject:currentIndexPath];
        }
    }];

    [_filesTableView beginUpdates];
    [_filesTableView deleteRowsAtIndexPaths:selectedIndexPaths
                           withRowAnimation:UITableViewRowAnimationFade];
    [_filesTableView endUpdates];

    _selectedFiles = [@{} mutableCopy];

    [self updateActionsState];

    __block PPProgressView *progressView = [[PPProgressView alloc] init];
    [progressView setBackgroundColor:[UIColor clearColor]];

    __block UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Importing", nil)
                                                                message:NSLocalizedString(@"Importing_message", nil)
                                                               delegate:nil
                                                      cancelButtonTitle:nil
                                                      otherButtonTitles:nil];

    @try {
        [alertView setValue:progressView forKey:[NSString stringWithFormat:@"accessoryView"]];
    } @catch (NSException *execption) {
        //
    }

    [alertView show];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.0f / 3.0f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [[PPLibraryProvider sharedLibrary] importFiles:filesToImport
                                     withProgressBlock:^(float progress) {
                                         [progressView setProgress:progress animated:YES];
                                     }
                                    andCompletionBlock:^{
                                        [alertView dismissWithClickedButtonIndex:-1 animated:YES];

                                        alertView = nil;
                                        progressView = nil;
                                    }];
    });
}

#pragma mark - UITableView DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _displaingFiles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;

    PPFileModel *currentFile = _displaingFiles[((NSUInteger) indexPath.row)];
    switch (currentFile.type) {
        case PPFileTypeFileAudio:
        case PPFileTypeFile: {
            cell = [tableView dequeueReusableCellWithIdentifier:fileCellIdentifier];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                              reuseIdentifier:fileCellIdentifier];
                cell.imageView.image = [UIImage imageNamed:@"CellIconFile.png"];
            }
        }
            break;
        case PPFileTypeFolder: {
            cell = [tableView dequeueReusableCellWithIdentifier:folderCellIdentifier];
            if (!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                              reuseIdentifier:folderCellIdentifier];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.imageView.image = [UIImage imageNamed:@"CellIconFolder.png"];
            }
        }
            break;

        case PPFileTypeUnknown:
        default: {
            //
        };
            break;
    }

    return cell;
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView
  willDisplayCell:(UITableViewCell *)cell
forRowAtIndexPath:(NSIndexPath *)indexPath {
    PPFileModel *currentFile = _displaingFiles[((NSUInteger) indexPath.row)];

    if (nowSelectFiles) {
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        if ([_selectedFiles[indexPath] isEqual:currentFile]) {
            cell.imageView.image = [[UIImage imageNamed:@"CellIconCheckMarkFilled.png"]
                    imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        } else {
            cell.imageView.image = [[UIImage imageNamed:@"CellIconCheckMarkEmpty.png"]
                    imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        }
    } else {
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }

    switch (currentFile.type) {
        case PPFileTypeFile: {
            if (!nowSelectFiles) {
                cell.imageView.image = [UIImage imageNamed:@"CellIconFile.png"];
            }
        }
            break;
        case PPFileTypeFileAudio: {
            if (!nowSelectFiles) {
                cell.imageView.image = [UIImage imageNamed:@"CellIconFileAudio.png"];
            }
        }
            break;
        case PPFileTypeFolder: {
            [cell.detailTextLabel setText:NSLocalizedString(@"Files folder", nil)];

            if (!nowSelectFiles) {
                cell.imageView.image = [UIImage imageNamed:@"CellIconFolder.png"];
            }
        }
            break;

        case PPFileTypeUnknown:
        default: {
            //
        };
            break;
    }

    [cell.textLabel setText:currentFile.title];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    PPFileModel *currentFile = _displaingFiles[((NSUInteger) indexPath.row)];

    if (nowSelectFiles) {
        _selectedFiles[indexPath] ? ([_selectedFiles removeObjectForKey:indexPath]) :
                (_selectedFiles[indexPath] = currentFile);
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];

        [self updateActionsState];

        return;
    }

    if (currentFile.type == PPFileTypeFolder) {
        PPFilesListViewController *folderListVC = [PPFilesListViewController controllerWithRootURL:currentFile.url];
        folderListVC.title = currentFile.title;

        [self.menuNavigationViewController pushViewController:folderListVC animated:YES];
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (nowSelectFiles) {
        return YES;
    }

    PPFileModel *currentFile = _displaingFiles[((NSUInteger) indexPath.row)];
    return currentFile.type == PPFileTypeFolder;
}

#pragma mark -

- (BOOL)canPerformAction:(PPNavigationBarMenuViewAction *)action {
    if ([action isEqual:_deleteAction]) {
        return _selectedFiles.count > 0;
    }

    if ([action isEqual:_importToLibraryAction]) {
        __block BOOL selectedFilesContainsNonAudio = NO;
        [_selectedFiles enumerateKeysAndObjectsUsingBlock:^(id key, PPFileModel *currentFile, BOOL *stop) {
            if ([currentFile isKindOfClass:[PPFileModel class]]) {
                if (!currentFile.isSupportedToPlay) {
                    selectedFilesContainsNonAudio = YES;
                    *stop = YES;
                }
            }
        }];

        return (_selectedFiles.count > 0) && (!selectedFilesContainsNonAudio);
    }

    return [super canPerformAction:action];
}

- (BOOL)canPerformSelection {
    return _displaingFiles.count > 0;
}

- (void)selectTapped {
    [super selectTapped];

    nowSelectFiles = YES;

    _selectedFiles = [@{} mutableCopy];
    [_filesTableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                   withRowAnimation:UITableViewRowAnimationFade];
}

- (void)doneTapped {
    [super doneTapped];

    nowSelectFiles = NO;

    _selectedFiles = [@{} mutableCopy];
    [_filesTableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                   withRowAnimation:UITableViewRowAnimationFade];
}


@end