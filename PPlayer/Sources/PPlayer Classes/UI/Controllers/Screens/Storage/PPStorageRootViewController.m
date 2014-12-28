//
// Created by Alexander Orlov on 28.12.14.
// Copyright (c) 2014 Alexander Orlov. All rights reserved.
//

#import "PPStorageRootViewController.h"
#import "PPFilesListViewController.h"

@interface PPStorageRootViewController () {
@private
    PPFilesListViewController *_filesListViewController;
}
@end

@implementation PPStorageRootViewController

#pragma mark - Init

- (void)designedInit {
    [super designedInit];

    _filesListViewController = [PPFilesListViewController controllerWithRootURL:nil];
    _filesListViewController.title = NSLocalizedString(@"Storage", nil);

    [self setViewControllers:@[_filesListViewController]];
}

- (void)commonInit {
    [super commonInit];
}

@end