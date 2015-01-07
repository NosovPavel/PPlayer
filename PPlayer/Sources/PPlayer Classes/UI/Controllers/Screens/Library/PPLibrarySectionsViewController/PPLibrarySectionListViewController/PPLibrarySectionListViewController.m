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

#import "PPLibrarySectionListViewController.h"
#import "PPLibraryRootViewController.h"

@implementation PPLibrarySectionListViewController

#pragma mark - Init

- (void)designedInit {
    [super designedInit];

    _deleteAction = [PPNavigationBarMenuViewAction actionWithIcon:[UIImage imageNamed:@"NavMenuIconDelete.png"]
                                                          handler:^{
                                                              //
                                                          } title:NSLocalizedString(@"Delete", nil)];

    _editEction = [PPNavigationBarMenuViewAction actionWithIcon:[UIImage imageNamed:@"NavMenuIconEdit.png"]
                                                        handler:^{
                                                            //
                                                        } title:NSLocalizedString(@"Edit", nil)];

    _actionsWhenSelected = @[_editEction, _deleteAction];
    _pickedArray = [NSMutableArray array];
}

- (void)commonInit {
    [super commonInit];
}

#pragma mark - Lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.libraryRootViewController.tracksPickerDoneItem.enabled = NO;
    self.libraryRootViewController.tracksPickerDoneItem.title = NSLocalizedString(@"Add", nil);

    if (self.libraryRootViewController.tracksPickerMode) {
        [self.libraryRootViewController.tracksPickerDoneItem setTarget:self];
        [self.libraryRootViewController.tracksPickerDoneItem setAction:@selector(_pickerDoneTapped)];
    }

    [self.menuNavigationViewController setMenuHidden:NO animated:YES];

    [self _reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.libraryRootViewController.tracksPickerDoneItem setTarget:nil];
    [self.libraryRootViewController.tracksPickerDoneItem setAction:nil];
}

- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];

    _sourceTableView = [[UITableView alloc] initWithFrame:self.view.bounds
                                                    style:UITableViewStylePlain];
    _sourceTableView.dataSource = self;
    _sourceTableView.delegate = self;

    [self.view addSubview:_sourceTableView];
}

- (void)dealloc {
    _sourceTableView = nil;
    _sourceArray = nil;
    _pickedArray = nil;

    _editEction = nil;
    _deleteAction = nil;
}

#pragma mark - Layout

- (void)performLayout {
    [super performLayout];
    [_sourceTableView setFrame:self.view.bounds];
}

#pragma mark - Reloading

- (void)_reloadData {
    [self startLoading];

    __block typeof(self) selfRef = self;
    [self reloadDataWithCompletionBlock:^{
        [selfRef endLoading];
    }];
}

- (void)reloadDataWithCompletionBlock:(void (^)())block {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (block) {
            block();
        }
    });
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _sourceArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - PPSelectableActionsViewController Logic

- (BOOL)canPerformAction:(PPNavigationBarMenuViewAction *)action {
    return NO;
}

- (BOOL)canPerformSelection {
    if (self.libraryRootViewController.tracksPickerMode) {
        return NO;
    }

    return _sourceArray.count > 0;
}

- (void)selectTapped {
    [super selectTapped];
    [_sourceTableView reloadData];
}

- (void)doneTapped {
    [super doneTapped];
    [_sourceTableView reloadData];
}

#pragma mark - Picker Mode Logic

- (BOOL)tracksPickerMode {
    return self.libraryRootViewController.tracksPickerMode;
}

- (void)updateDoneButtonState {
    self.libraryRootViewController.tracksPickerDoneItem.enabled = _pickedArray.count > 0;

    if (self.libraryRootViewController.tracksPickerDoneItem.enabled) {
        self.libraryRootViewController.tracksPickerDoneItem.title = [NSString stringWithFormat:@"%@ (%d)", NSLocalizedString(@"Add", nil), (int) _pickedArray.count];
    } else {
        self.libraryRootViewController.tracksPickerDoneItem.title = NSLocalizedString(@"Add", nil);
    }
}

- (void)_pickerDoneTapped {
    if (self.libraryRootViewController.tracksPickerBlock) {
        self.libraryRootViewController.tracksPickerBlock([_pickedArray copy]);
    }
}

@end