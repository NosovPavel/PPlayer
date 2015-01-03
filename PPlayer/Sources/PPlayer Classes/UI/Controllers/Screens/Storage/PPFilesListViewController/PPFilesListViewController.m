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

static const CGFloat cellsHeight = 60.0f;

static NSString *fileCellIdentifier = @"fileCellIdentifier";
static NSString *folderCellIdentifier = @"folderCellIdentifier";

typedef NS_ENUM(NSInteger, PPFileType) {
    PPFileTypeUnknown = -1,

    PPFileTypeFile,
    PPFileTypeFolder
};

@interface PPFileModel : NSObject
@property(atomic, strong) NSURL *url;
@property(atomic, strong) NSString *title;
@property(atomic) PPFileType type;

#pragma mark - Init

- (instancetype)initWithUrl:(NSURL *)url title:(NSString *)title type:(PPFileType)type;

+ (instancetype)modelWithUrl:(NSURL *)url title:(NSString *)title type:(PPFileType)type;

@end

@implementation PPFileModel

#pragma mark - Init

- (instancetype)initWithUrl:(NSURL *)url title:(NSString *)title type:(PPFileType)type {
    self = [super init];
    if (self) {
        self.url = url;
        self.title = title;
        self.type = type;
    }

    return self;
}

+ (instancetype)modelWithUrl:(NSURL *)url title:(NSString *)title type:(PPFileType)type {
    return [[self alloc] initWithUrl:url title:title type:type];
}

@end

@interface PPFilesListViewController () <UITableViewDataSource, UITableViewDelegate> {
@private
    BOOL _isSelecting;
    NSMutableArray *_displaingFiles;
    NSMutableDictionary *_selectedFiles;

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
}

- (void)commonInit {
    [super commonInit];

    //Load files if we can
    [self _reloadFilesList];
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self _setupActualActionsAnimated:NO];
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

    _displaingFiles = [NSMutableArray array];
    NSArray *filesList = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:_rootURL
                                                       includingPropertiesForKeys:nil
                                                                          options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                            error:NULL];
    NSMutableArray *directoriesOnly = [NSMutableArray array];
    [filesList enumerateObjectsUsingBlock:^(NSURL *currentURL, NSUInteger idx, BOOL *stop) {
        PPFileType type;

        NSNumber *isDirectory;
        BOOL success = [currentURL getResourceValue:&isDirectory
                                             forKey:NSURLIsDirectoryKey
                                              error:nil];

        if (success && [isDirectory boolValue]) {
            type = PPFileTypeFolder;
        } else {
            type = PPFileTypeFile;
        }

        NSString *name = [NSString stringWithFormat:@"%@", [[currentURL absoluteString] lastPathComponent]];
        while (![[name stringByDeletingPathExtension] isEqualToString:name]) {
            name = [name stringByDeletingPathExtension];
        }
        name = [name stringByRemovingPercentEncoding];

        PPFileModel *fileModel = [PPFileModel modelWithUrl:currentURL
                                                     title:name
                                                      type:type];

        if (type == PPFileTypeFolder) {
            [directoriesOnly addObject:fileModel];
        } else {
            [_displaingFiles addObject:fileModel];
        }
    }];

    [_displaingFiles insertObjects:directoriesOnly
                         atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, directoriesOnly.count)]];

    [_filesTableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                   withRowAnimation:UITableViewRowAnimationLeft];
}

#pragma mark - Actions Setting Up

- (void)_setupActualActionsAnimated:(BOOL)animated {
    _isSelecting ? [self _setupSelectedStateActionsAnimated:animated] : [self _setupUnselectedStateActionsAnimated:animated];
}

- (void)_setupUnselectedStateActionsAnimated:(BOOL)animated {
    __block typeof(self) selfRef = self;
    PPNavigationBarMenuViewAction *selectElementsAction = [PPNavigationBarMenuViewAction actionWithIcon:[UIImage imageNamed:@"NavMenuIconSelect.png"]
                                                                                                handler:^{
                                                                                                    selfRef->_isSelecting = YES;
                                                                                                    [selfRef _selectingStateChanged];
                                                                                                } title:NSLocalizedString(@"Select items...", nil)];

    [self.storageViewController setNavigationMenuActions:@[selectElementsAction] animated:animated];
}

- (void)_setupSelectedStateActionsAnimated:(BOOL)animated {
    __block typeof(self) selfRef = self;
    PPNavigationBarMenuViewAction *importToLibraryAction = [PPNavigationBarMenuViewAction actionWithIcon:[UIImage imageNamed:@"NavMenuIconToLibrary.png"]
                                                                                                 handler:^{
                                                                                                     //
                                                                                                 } title:NSLocalizedString(@"Import to Library", nil)];
    PPNavigationBarMenuViewAction *deleteAction = [PPNavigationBarMenuViewAction actionWithIcon:[UIImage imageNamed:@"NavMenuIconDelete.png"]
                                                                                        handler:^{
                                                                                            [selfRef _deleteSelectedFiles];
                                                                                        } title:NSLocalizedString(@"Delete", nil)];
    PPNavigationBarMenuViewAction *cancelAction = [PPNavigationBarMenuViewAction actionWithIcon:[UIImage imageNamed:@"NavMenuIconDone.png"]
                                                                                        handler:^{
                                                                                            selfRef->_isSelecting = NO;
                                                                                            [selfRef _selectingStateChanged];
                                                                                        }
                                                                                          title:NSLocalizedString(@"Done", nil)];

    [self.storageViewController setNavigationMenuActions:@[importToLibraryAction, deleteAction, cancelAction]
                                                animated:animated];
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
            [selectedIndexPaths addObject:currentIndexPath];
            [[NSFileManager defaultManager] removeItemAtURL:currentFile.url error:NULL];
        }
    }];

    [_filesTableView beginUpdates];
    [_filesTableView deleteRowsAtIndexPaths:selectedIndexPaths
                           withRowAnimation:UITableViewRowAnimationLeft];
    [_filesTableView endUpdates];

    _selectedFiles = [@{} mutableCopy];
}

#pragma mark - UITableView DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _displaingFiles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;

    PPFileModel *currentFile = _displaingFiles[((NSUInteger) indexPath.row)];
    switch (currentFile.type) {
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