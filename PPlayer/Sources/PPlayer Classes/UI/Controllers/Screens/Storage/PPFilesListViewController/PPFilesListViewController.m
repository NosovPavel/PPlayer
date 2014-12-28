//
// Created by Alexander Orlov on 28.12.14.
// Copyright (c) 2014 Alexander Orlov. All rights reserved.
//

#import "PPFilesListViewController.h"

@implementation PPFilesListViewController

#pragma mark - Init

- (void)designedInit {
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

- (void)dealloc {
    //
}

@end