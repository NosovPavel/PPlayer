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

#import "PPSelectableActionsViewController.h"

@interface PPSelectableActionsViewController () {
@private
    PPNavigationBarMenuViewAction *_selectElementsAction;
    PPNavigationBarMenuViewAction *_loadingAction, *_cancelAction;

    BOOL _isSelecting, _isLoading;
}
@end;

@implementation PPSelectableActionsViewController

#pragma mark - Init

- (void)designedInit {
    [super designedInit];

    _isSelecting = NO;
    _isLoading = NO;
}

#pragma mark - Lifecycle

- (void)dealloc {
    _selectElementsAction = nil;
    _loadingAction = nil;
    _cancelAction = nil;
    _actionsWhenSelected = nil;
}

#pragma mark - Actions Setting Up

- (void)_setupActualActionsAnimated:(BOOL)animated {
    if (_isLoading) {
        [self _setupLoadingStateActionsAnimated:animated];
    } else {
        _isSelecting ? [self _setupSelectedStateActionsAnimated:animated] : [self _setupUnselectedStateActionsAnimated:animated];
    }
}

- (void)_setupLoadingStateActionsAnimated:(BOOL)animated {
    if (!_loadingAction) {
        _loadingAction = [PPNavigationBarMenuViewAction actionWithIcon:nil
                                                               handler:^{
                                                                   //
                                                               } title:NSLocalizedString(@"Refreshing...", nil)];
    }

    [self updateActionsState];
    [self.menuNavigationViewController setNavigationMenuActions:@[_loadingAction] animated:animated];
}

- (void)_setupUnselectedStateActionsAnimated:(BOOL)animated {
    __block typeof(self) selfRef = self;
    if (!_selectElementsAction) {
        _selectElementsAction = [PPNavigationBarMenuViewAction actionWithIcon:[UIImage imageNamed:@"NavMenuIconSelect.png"]
                                                                      handler:^{
                                                                          selfRef->_isSelecting = YES;
                                                                          [selfRef _setupActualActionsAnimated:YES];
                                                                          [selfRef selectTapped];
                                                                      } title:NSLocalizedString(@"Select items...", nil)];
    }

    [self updateActionsState];
    [self.menuNavigationViewController setNavigationMenuActions:@[_selectElementsAction] animated:animated];
}

- (void)_setupSelectedStateActionsAnimated:(BOOL)animated {
    __block typeof(self) selfRef = self;

    if (!_cancelAction) {
        _cancelAction = [PPNavigationBarMenuViewAction actionWithIcon:[UIImage imageNamed:@"NavMenuIconDone.png"]
                                                              handler:^{
                                                                  selfRef->_isSelecting = NO;
                                                                  [selfRef _setupActualActionsAnimated:YES];
                                                                  [selfRef doneTapped];
                                                              }
                                                                title:NSLocalizedString(@"Done", nil)];
    }

    [self updateActionsState];
    [self.menuNavigationViewController setNavigationMenuActions:[_actionsWhenSelected arrayByAddingObject:_cancelAction]
                                                       animated:animated];
}

#pragma mark - Navigation Bar Actions Enabled State

- (void)updateActionsState {
    if (_isLoading) {
        _loadingAction.enabled = NO;

        _selectElementsAction.enabled = NO;
        _cancelAction.enabled = NO;
    } else {
        if (_isSelecting) {
            _selectElementsAction.enabled = NO;
            _cancelAction.enabled = YES;

            [_actionsWhenSelected enumerateObjectsUsingBlock:^(PPNavigationBarMenuViewAction *action, NSUInteger idx, BOOL *stop) {
                action.enabled = [self canPerformAction:action];
            }];
        } else {
            _selectElementsAction.enabled = [self canPerformSelection];

            _cancelAction.enabled = NO;
        }
    }
}

#pragma mark - Interface

- (void)startLoading {
    _isLoading = YES;
    [self updateActions];
}

- (void)endLoading {
    _isLoading = NO;
    [self updateActions];
}

- (void)updateActions {
    [self _setupActualActionsAnimated:YES];
}

- (BOOL)canPerformAction:(PPNavigationBarMenuViewAction *)action {
    return YES;
}

- (BOOL)canPerformSelection {
    return YES;
}

- (void)selectTapped {
    //
}

- (void)doneTapped {
    //
}

@end