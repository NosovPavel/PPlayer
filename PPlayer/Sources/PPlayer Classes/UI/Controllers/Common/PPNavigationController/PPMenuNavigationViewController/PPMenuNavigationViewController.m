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

#import "PPMenuNavigationViewController.h"

static const CGFloat navigationBarMenuHeight = 40.0f;

@interface PPNavigationBar : UINavigationBar {
@private
    BOOL _menuHidden;
}
@property(atomic, readonly, getter = isMenuHidden) BOOL menuHidden;

- (void)setExtraSizeHidden:(BOOL)hidden animated:(BOOL)animated;
@end

@implementation PPNavigationBar
@synthesize menuHidden = _menuHidden;

#pragma mark - Hack

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize amendedSize = [super sizeThatFits:size];
    amendedSize.height += _menuHidden ?: navigationBarMenuHeight;

    return amendedSize;
}

#pragma mark - Init

- (void)_init {
    //
}

#pragma mark - Lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        [self _init];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self _init];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self _init];
    }
    return self;
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];
    [self setTransform:CGAffineTransformMakeTranslation(0, -(_menuHidden ?: navigationBarMenuHeight))];
}

#pragma mark - Hack more

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return CGRectContainsPoint(CGRectMake(0.0f, 0.0f, self.bounds.size.width,
            self.bounds.size.height + (_menuHidden ?: navigationBarMenuHeight)), point);
}

#pragma mark - Interface

- (void)setExtraSizeHidden:(BOOL)hidden animated:(BOOL)animated {
    _menuHidden = hidden;
    [UIView animateWithDuration:animated ?: 1.0f / 3.0f
                     animations:^{
                         [self layoutSubviews];
                     } completion:nil];
}

@end

@interface PPMenuNavigationViewController () {
@private
    PPNavigationBarMenuView *_navigationBarMenuView;
}
@end

@implementation PPMenuNavigationViewController

#pragma mark - Init

- (void)designedInit {
    [self _setupNavigationBarMenu];
}

- (void)commonInit {
    //
}

#pragma mark - Lifecycle

- (instancetype)init {
    self = [self initWithNavigationBarClass:[PPNavigationBar class] toolbarClass:[UIToolbar class]];
    if (self) {
        [self designedInit];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self commonInit];
}

- (void)dealloc {
    _navigationBarMenuView = nil;
}

#pragma mark - Internal

- (void)_setupNavigationBarMenu {
    _navigationBarMenuView = [PPNavigationBarMenuView viewWithActions:nil];

    [_navigationBarMenuView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
    [_navigationBarMenuView setFrame:CGRectMake(0.0f, self.navigationBar.bounds.size.height,
            self.view.bounds.size.width, navigationBarMenuHeight)];

    [self.navigationBar setClipsToBounds:NO];
    [self.navigationBar addSubview:_navigationBarMenuView];
    [self.navigationBar sendSubviewToBack:_navigationBarMenuView];
}

#pragma mark - Setters / Getters

- (NSArray *)navigationMenuActions {
    return _navigationBarMenuView.actions;
}

- (void)setNavigationMenuActions:(NSArray *)actions animated:(BOOL)animated {
    [_navigationBarMenuView setActions:actions animated:animated];
}

- (void)setMenuHidden:(BOOL)hidden animated:(BOOL)animated {
    PPNavigationBar *navBar = (PPNavigationBar *) self.navigationBar;
    [navBar setExtraSizeHidden:hidden animated:animated];

    [UIView animateWithDuration:animated ? 1.0f / 3.0f : 0.0f animations:^{
        [_navigationBarMenuView setAlpha:hidden ? 0.0f : 1.0f];
        [_navigationBarMenuView setUserInteractionEnabled:!hidden];
    }                completion:nil];
}

@end

@implementation UIViewController (PPMenuNavigationViewController)
- (PPMenuNavigationViewController *)menuNavigationViewController {
    if (![self.navigationController isKindOfClass:[PPMenuNavigationViewController class]]) {
        return nil;
    }

    return ((PPMenuNavigationViewController *) self.navigationController);
}
@end