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

#import "PPStorageRootViewController.h"
#import "PPLibraryRootViewController.h"
#import "PPPlaylistsRootViewController.h"
#import "PPPlayerRootViewController.h"

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
    PPStorageRootViewController *storageRootViewController = [[PPStorageRootViewController alloc] init];
    UITabBarItem *storageItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Storage",
                    nil)
                                                              image:[UIImage imageNamed:@"TabIconStorage.png"]
                                                      selectedImage:nil];
    [storageRootViewController setTabBarItem:storageItem];

    //Library
    PPLibraryRootViewController *libraryRootViewController = [[PPLibraryRootViewController alloc] init];
    UITabBarItem *libraryItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Library",
                    nil)
                                                              image:[UIImage imageNamed:@"TabIconLibrary.png"]
                                                      selectedImage:nil];
    [libraryRootViewController setTabBarItem:libraryItem];

    //Playlists
    PPPlaylistsRootViewController *playlistsRootViewController = [[PPPlaylistsRootViewController alloc] init];
    UITabBarItem *playlistsItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Playlists",
                    nil)
                                                                image:[UIImage imageNamed:@"TabIconPlaylist.png"]
                                                        selectedImage:nil];
    [playlistsRootViewController setTabBarItem:playlistsItem];

    //Player
    PPPlayerRootViewController *playerRootViewController = [[PPPlayerRootViewController alloc] init];
    UITabBarItem *playerItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Player",
                    nil)
                                                             image:[UIImage imageNamed:@"TabIconPlayer.png"]
                                                     selectedImage:nil];
    [playerRootViewController setTabBarItem:playerItem];

    //Settings
    UIViewController *settingsRootViewController = [[UIViewController alloc] init];
    PPNavigationController *settingsNavigationController = [[PPNavigationController alloc]
            initWithRootViewController:settingsRootViewController];
    UITabBarItem *settingsItem = [[UITabBarItem alloc] initWithTitle:NSLocalizedString(@"Settings",
                    nil)
                                                               image:[UIImage imageNamed:@"TabIconSettings.png"]
                                                       selectedImage:nil];
    [settingsNavigationController setTabBarItem:settingsItem];

    PPTabBarController *tabBarController = [[PPTabBarController alloc] init];
    [tabBarController setViewControllers:@[storageRootViewController, libraryRootViewController,
            playlistsRootViewController, playerRootViewController, settingsNavigationController]];

    _tabBarController = tabBarController;
}

- (void)performLayout {
    [super performLayout];
    [[_tabBarController view] setFrame:[[self view] bounds]];
}

@end