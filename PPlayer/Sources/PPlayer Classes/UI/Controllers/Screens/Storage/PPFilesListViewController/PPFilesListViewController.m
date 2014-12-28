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

@interface PPFilesListViewController () {
@private
    BOOL _isSelecting;

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

    //
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

    _filesTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [self.view addSubview:_filesTableView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self _setupActualActionsAnimated:NO];
}

- (void)dealloc {
    _filesTableView = nil;
}

#pragma mark - Layout

- (void)performLayout {
    [super performLayout];

    [_filesTableView setFrame:self.view.bounds];
}

#pragma mark - Internal

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
                                                                                            //
                                                                                        } title:NSLocalizedString(@"Delete", nil)];
    PPNavigationBarMenuViewAction *cancelAction = [PPNavigationBarMenuViewAction actionWithIcon:[UIImage imageNamed:@"NavMenuIconCancel.png"]
                                                                                        handler:^{
                                                                                            selfRef->_isSelecting = NO;
                                                                                            [selfRef _selectingStateChanged];
                                                                                        }
                                                                                          title:NSLocalizedString(@"Cancel", nil)];

    [self.storageViewController setNavigationMenuActions:@[importToLibraryAction, deleteAction, cancelAction]
                                                animated:animated];
}

#pragma mark - Selecting State Changing

- (void)_selectingStateChanged {
    [self _setupActualActionsAnimated:YES];
}

@end