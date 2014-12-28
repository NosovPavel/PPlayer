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

#import "PPRootViewController.h"
#import "PPNavigationController.h"
#import "PPTabBarController.h"

@implementation PPRootViewController {
@private
    PPTabBarController *_tabBarController;
}

#pragma mark - UIViewController Lifecycle

- (void)loadView {
    [self setView:[[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]]];
    [[self view] setBackgroundColor:[UIColor whiteColor]];

    [self addChildViewController:_tabBarController];
    [[self view] addSubview:[_tabBarController view]];
}

- (void)dealloc {
    [[_tabBarController view] removeFromSuperview];
    [_tabBarController removeFromParentViewController];
    _tabBarController = nil;
}

#pragma mark - VPViewController Implementation

- (void)designedInit {
    [super designedInit];

    //Storage
    UIViewController *storageRootViewController = [[UIViewController alloc] init];
    PPNavigationController *storageNavigationController = [[PPNavigationController alloc]
            initWithRootViewController:storageRootViewController];
    UITabBarItem *storageItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Storage",
                    nil)
                                                              image:nil
                                                      selectedImage:nil];
    [storageNavigationController setTabBarItem:storageItem];

    //Library
    UIViewController *libraryRootViewController = [[UIViewController alloc] init];
    PPNavigationController *libraryNavigationController = [[PPNavigationController alloc]
            initWithRootViewController:libraryRootViewController];
    UITabBarItem *libraryItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Library",
                    nil)
                                                              image:nil
                                                      selectedImage:nil];
    [libraryNavigationController setTabBarItem:libraryItem];

    //Playlists
    UIViewController *playlistsRootViewController = [[UIViewController alloc] init];
    PPNavigationController *playlistsNavigationController = [[PPNavigationController alloc]
            initWithRootViewController:playlistsRootViewController];
    UITabBarItem *playlistsItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Playlists",
                    nil)
                                                                image:nil
                                                        selectedImage:nil];
    [playlistsNavigationController setTabBarItem:playlistsItem];

    //Player
    UIViewController *playerRootViewController = [[UIViewController alloc] init];
    PPNavigationController *playerNavigationController = [[PPNavigationController alloc]
            initWithRootViewController:playerRootViewController];
    UITabBarItem *playerItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Player",
                    nil)
                                                             image:nil
                                                     selectedImage:nil];
    [playerNavigationController setTabBarItem:playerItem];

    //Settings
    UIViewController *settingsRootViewController = [[UIViewController alloc] init];
    PPNavigationController *settingsNavigationController = [[PPNavigationController alloc]
            initWithRootViewController:settingsRootViewController];
    UITabBarItem *settingsItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Settings",
                    nil)
                                                               image:nil
                                                       selectedImage:nil];
    [settingsNavigationController setTabBarItem:settingsItem];

    PPTabBarController *tabBarController = [[PPTabBarController alloc] init];
    [tabBarController setViewControllers:@[storageNavigationController, libraryNavigationController,
            playlistsNavigationController, playerNavigationController, settingsNavigationController]];

    _tabBarController = tabBarController;
}

- (void)performLayout {
    [super performLayout];
    [[_tabBarController view] setFrame:[[self view] bounds]];
}

@end