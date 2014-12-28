//
// Created by Alexander Orlov on 28.12.14.
// Copyright (c) 2014 Alexander Orlov. All rights reserved.
//

#import "PPViewController.h"

@interface PPFilesListViewController : PPViewController
@property(atomic, strong) NSURL *rootURL;

#pragma mark - Init

- (instancetype)initWithRootURL:(NSURL *)rootURL;

+ (instancetype)controllerWithRootURL:(NSURL *)rootURL;

@end