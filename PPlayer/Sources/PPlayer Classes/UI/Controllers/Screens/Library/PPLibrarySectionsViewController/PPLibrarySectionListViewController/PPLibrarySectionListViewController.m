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
}

- (void)commonInit {
    [super commonInit];
}

#pragma mark - Lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.menuNavigationViewController setMenuHidden:NO animated:YES];
    [self _reloadData];
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
        sleep(1);
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

@end