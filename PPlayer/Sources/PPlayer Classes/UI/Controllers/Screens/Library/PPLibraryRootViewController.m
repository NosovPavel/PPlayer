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

#import "PPLibraryRootViewController.h"
#import "PPLibrarySectionsViewController.h"

@interface PPLibraryRootViewController () {
@private
    PPLibrarySectionsViewController *_sectionsViewController;
    UIBarButtonItem *_cancelItem, *_doneItem, *_spaceItem;

    BOOL _tracksPickerMode;
}
@end

@implementation PPLibraryRootViewController
@synthesize tracksPickerDoneItem = _doneItem;

#pragma mark - Init

- (void)designedInit {
    [super designedInit];

    _cancelItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil)
                                                   style:UIBarButtonItemStylePlain
                                                  target:self
                                                  action:@selector(_pickerCancelTapped)];
    _doneItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add", nil)
                                                 style:UIBarButtonItemStyleDone
                                                target:nil
                                                action:nil];
    _doneItem.enabled = NO;

    _spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                               target:nil
                                                               action:nil];

    _sectionsViewController = [[PPLibrarySectionsViewController alloc] init];
    _sectionsViewController.title = NSLocalizedString(@"Library", nil);

    [_sectionsViewController setToolbarItems:@[_cancelItem, _spaceItem, _doneItem]];
    [self setViewControllers:@[_sectionsViewController]];
}

#pragma mark - Picker Logic

- (void)_pickerCancelTapped {
    if (_tracksPickerBlock) {
        _tracksPickerBlock(nil);
    }
}

#pragma mark - Setters / Getters

- (BOOL)tracksPickerMode {
    return _tracksPickerMode;
}

- (void)setTracksPickerMode:(BOOL)tracksPickerMode {
    _tracksPickerMode = tracksPickerMode;

    [self setToolbarHidden:!_tracksPickerMode
                  animated:YES];
}

#pragma mark - Lifecycle

- (void)dealloc {
    _cancelItem = nil;
    _doneItem = nil;
    _spaceItem = nil;

    _sectionsViewController = nil;
}

#pragma mark - Hack

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    viewController.toolbarItems = ((UIViewController *) [self.viewControllers lastObject]).toolbarItems;
    [super pushViewController:viewController animated:animated];
}

- (NSArray *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    NSUInteger indexOf = [self.viewControllers indexOfObject:viewController];
    [self.viewControllers enumerateObjectsUsingBlock:^(UIViewController *vc, NSUInteger idx, BOOL *stop) {
        if (idx > indexOf) {
            [vc setToolbarItems:nil animated:YES];
        }
    }];

    return [super popToViewController:viewController animated:animated];
}

@end

@implementation UIViewController (PPLibraryRootViewController)
- (PPLibraryRootViewController *)libraryRootViewController {
    if ([self.navigationController isKindOfClass:[PPLibraryRootViewController class]]) {
        __weak PPLibraryRootViewController *weakLibrary = ((PPLibraryRootViewController *) self.navigationController);
        return weakLibrary;
    }

    return nil;
}

@end