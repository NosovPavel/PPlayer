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
    //Data
    BOOL _isSelecting;

    NSMutableArray *_displaingFiles;
    NSMutableDictionary *_selectedFiles;

    PPNavigationBarMenuViewAction *_selectElementsAction;
    PPNavigationBarMenuViewAction *_importToLibraryAction, *_deleteAction, *_cancelAction;

    PPFilesProvider *_filesProvider;

    //Visual
    UITableView *_filesTableView;
}
@end

@interface PPFilesListViewController (Private)
@property(atomic, strong, readonly) PPStorageRootViewController *storageViewController;
@end

@implementation PPFilesListViewController (Private)
- (PPStorageRootViewController *)storageViewController {
    if ([self.navigationController isKindOfClass:[PPStorageRootViewController class]]) {
        return ((PPStorageRootViewController *) self.navigationController);
    }

    return nil;
}
@end

@implementation PPFilesListViewController

#pragma mark - Init

- (void)designedInit {
    [super designedInit];

    _isSelecting = NO;
    _filesProvider = [PPFilesProvider new];
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

    _isSelecting = NO;
    [self _selectingStateChanged];
}

- (void)dealloc {
    _filesTableView = nil;
    _displaingFiles = nil;
    _selectedFiles = nil;
    _filesProvider = nil;
    _selectElementsAction = nil;
    _deleteAction = nil;
    _cancelAction = nil;
    _importToLibraryAction = nil;
}

#pragma mark - Layout

- (void)performLayout {
    [super performLayout];

    [_filesTableView setFrame:self.view.bounds];
}

#pragma mark - Files Management

- (void)_reloadFilesList {
    _isSelecting = NO;
    [self _selectingStateChanged];

    _displaingFiles = [[_filesProvider filesModelsAtURL:_rootURL] mutableCopy];
    [_filesTableView reloadData];
}

#pragma mark - Actions Setting Up

- (void)_setupActualActionsAnimated:(BOOL)animated {
    _isSelecting ? [self _setupSelectedStateActionsAnimated:animated] : [self _setupUnselectedStateActionsAnimated:animated];
}

- (void)_setupUnselectedStateActionsAnimated:(BOOL)animated {
    __block typeof(self) selfRef = self;
    if (!_selectElementsAction) {
        _selectElementsAction = [PPNavigationBarMenuViewAction actionWithIcon:[UIImage imageNamed:@"NavMenuIconSelect.png"]
                                                                      handler:^{
                                                                          selfRef->_isSelecting = YES;
                                                                          [selfRef _selectingStateChanged];
                                                                      } title:NSLocalizedString(@"Select items...", nil)];
    }

    [self _updateActionsEnabledState];
    [self.storageViewController setNavigationMenuActions:@[_selectElementsAction] animated:animated];
}

- (void)_setupSelectedStateActionsAnimated:(BOOL)animated {
    __block typeof(self) selfRef = self;
    if (!_importToLibraryAction) {
        _importToLibraryAction = [PPNavigationBarMenuViewAction actionWithIcon:[UIImage imageNamed:@"NavMenuIconToLibrary.png"]
                                                                       handler:^{
                                                                           [selfRef _importSelectedFiles];
                                                                       } title:NSLocalizedString(@"Import to Library", nil)];
    }
    if (!_deleteAction) {
        _deleteAction = [PPNavigationBarMenuViewAction actionWithIcon:[UIImage imageNamed:@"NavMenuIconDelete.png"]
                                                              handler:^{
                                                                  [selfRef _deleteSelectedFiles];
                                                              } title:NSLocalizedString(@"Delete", nil)];
    }
    if (!_cancelAction) {
        _cancelAction = [PPNavigationBarMenuViewAction actionWithIcon:[UIImage imageNamed:@"NavMenuIconDone.png"]
                                                              handler:^{
                                                                  selfRef->_isSelecting = NO;
                                                                  [selfRef _selectingStateChanged];
                                                              }
                                                                title:NSLocalizedString(@"Done", nil)];
    }

    [self _updateActionsEnabledState];
    [self.storageViewController setNavigationMenuActions:@[_importToLibraryAction, _deleteAction, _cancelAction]
                                                animated:animated];
}

#pragma mark - Navigation Bar Actions Enabled State

- (void)_updateActionsEnabledState {
    if (_isSelecting) {
        _selectElementsAction.enabled = NO;
        _cancelAction.enabled = YES;

        if (_selectedFiles.count > 0) {
            _deleteAction.enabled = YES;

            __block BOOL selectedFilesContainsNonAudio = NO;
            [_selectedFiles enumerateKeysAndObjectsUsingBlock:^(id key, PPFileModel *currentFile, BOOL *stop) {
                if ([currentFile isKindOfClass:[PPFileModel class]]) {
                    if (!currentFile.isSupportedToPlay) {
                        selectedFilesContainsNonAudio = YES;
                        *stop = YES;
                    }
                }
            }];

            _importToLibraryAction.enabled = !selectedFilesContainsNonAudio;
        } else {
            _deleteAction.enabled = NO;
            _importToLibraryAction.enabled = NO;
        }
    } else {
        _selectElementsAction.enabled = YES;

        _cancelAction.enabled = NO;
        _deleteAction.enabled = NO;
        _importToLibraryAction.enabled = NO;
    }
}

#pragma mark - Selecting State Changing

- (void)_selectingStateChanged {
    [self _setupActualActionsAnimated:YES];

    _selectedFiles = [@{} mutableCopy];
    [_filesTableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                   withRowAnimation:UITableViewRowAnimationFade];
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

    [self _updateActionsEnabledState];
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

    [self _updateActionsEnabledState];

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

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
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

    if (_isSelecting) {
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
            if (!_isSelecting) {
                cell.imageView.image = [UIImage imageNamed:@"CellIconFile.png"];
            }
        }
            break;
        case PPFileTypeFileAudio: {
            if (!_isSelecting) {
                cell.imageView.image = [UIImage imageNamed:@"CellIconFileAudio.png"];
            }
        }
            break;
        case PPFileTypeFolder: {
            [cell.detailTextLabel setText:NSLocalizedString(@"Files folder", nil)];

            if (!_isSelecting) {
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

    if (_isSelecting) {
        _selectedFiles[indexPath] ? ([_selectedFiles removeObjectForKey:indexPath]) :
                (_selectedFiles[indexPath] = currentFile);
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];

        [self _updateActionsEnabledState];

        return;
    }

    if (currentFile.type == PPFileTypeFolder) {
        PPFilesListViewController *folderListVC = [PPFilesListViewController controllerWithRootURL:currentFile.url];
        folderListVC.title = currentFile.title;

        [self.storageViewController pushViewController:folderListVC animated:YES];
    }
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_isSelecting) {
        return YES;
    }

    PPFileModel *currentFile = _displaingFiles[((NSUInteger) indexPath.row)];
    return currentFile.type == PPFileTypeFolder;
}

@end