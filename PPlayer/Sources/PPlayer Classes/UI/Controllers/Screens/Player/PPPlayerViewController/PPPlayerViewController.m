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

#import "PPPlayerViewController.h"
#import "PPMenuNavigationViewController.h"
#import "PPPlayerView.h"

@interface PPPlayerViewController () {
@private
    UIBarButtonItem *_currentPlaylistItem;
    PPPlayerView *_playerView;
}
@end

@implementation PPPlayerViewController

#pragma mark - Init

- (void)designedInit {
    [super designedInit];
}

- (void)commonInit {
    [super commonInit];
    [self.menuNavigationViewController setMenuHidden:YES animated:NO];
}

#pragma mark - Lifecycle

- (void)loadView {
    [super loadView];

    _playerView = [[PPPlayerView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
    [_playerView setAutoresizingMask:UIViewAutoresizingNone];
    [self.view addSubview:_playerView];

    _currentPlaylistItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"CellIconPlaylist.png"]
                                                            style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(_currentPlaylistTapped)];
    self.navigationItem.rightBarButtonItem = _currentPlaylistItem;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.menuNavigationViewController setMenuHidden:YES animated:YES];
}

- (void)dealloc {
    _currentPlaylistItem = nil;
    _playerView = nil;
}

#pragma mark - Layout

- (void)performLayout {
    [super performLayout];

    CGFloat statusBarHeightReduction = [UIApplication sharedApplication].statusBarFrame.size.height;
    CGFloat navbarHeightReduction = (self.navigationController.navigationBar.translucent ? self.navigationController.navigationBar.bounds.size.height : 0.0f);
    CGFloat tabbarHeightReduction = (self.tabBarController.tabBar.translucent ? self.tabBarController.tabBar.bounds.size.height : 0.0f);
    CGFloat heightReduction = navbarHeightReduction + tabbarHeightReduction + statusBarHeightReduction;

    [_playerView setFrame:CGRectMake(0.0f, 0.0f + navbarHeightReduction + statusBarHeightReduction,
            _playerView.superview.bounds.size.width, _playerView.superview.bounds.size.height - heightReduction)];
}

#pragma mark - Actions

- (void)_currentPlaylistTapped {
    //
}

@end