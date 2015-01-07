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

@interface PPNavigationBar : UIView {
@private
    UINavigationBar *_navigationBar;
    PPNavigationBarMenuView *_navigationBarMenuView;

    BOOL _menuHidden;
    BOOL _needToLayoutFromObservation;
}
@property(atomic, strong) PPNavigationBarMenuView *navigationBarMenuView;

- (void)setMenuHidden:(BOOL)hidden animated:(BOOL)animated;

@end

@implementation PPNavigationBar
@synthesize navigationBarMenuView = _navigationBarMenuView;

#pragma mark - Hack

- (CGSize)sizeThatFits:(CGSize)size {
    CGSize amendedSize = [_navigationBar sizeThatFits:size];
    amendedSize.height += _menuHidden ?: navigationBarMenuHeight;

    return amendedSize;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return CGRectContainsPoint(CGRectMake(0.0f, 0.0f, self.bounds.size.width,
            self.bounds.size.height + [UIApplication sharedApplication].statusBarFrame.size.height), point);
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    NSMethodSignature *signature = [super methodSignatureForSelector:selector];
    if (!signature) {
        signature = [_navigationBar methodSignatureForSelector:selector];
    }
    return signature;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    SEL selector = [anInvocation selector];

    if ([_navigationBar respondsToSelector:selector]) {
        [anInvocation invokeWithTarget:_navigationBar];
    } else {
        [super forwardInvocation:anInvocation];
    }
}

#pragma mark - Init

- (void)_init {
    _navigationBar = [[UINavigationBar alloc] init];
    _navigationBarMenuView = [PPNavigationBarMenuView viewWithActions:nil];

    [_navigationBar setAutoresizingMask:UIViewAutoresizingNone];
    [_navigationBarMenuView setAutoresizingMask:UIViewAutoresizingNone];

    [self addSubview:_navigationBarMenuView];
    [self addSubview:_navigationBar];

    _needToLayoutFromObservation = YES;
    [_navigationBar addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:NULL];
}

#pragma mark - Lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        [self _init];
    }
    return self;
}

- (void)dealloc {
    [_navigationBar removeObserver:self forKeyPath:@"frame"];

    _navigationBarMenuView = nil;
    _navigationBar = nil;
}

#pragma mark - Layout

- (void)layoutSubviews {
    [self sizeToFit];
    [super layoutSubviews];

    [self setFrame:CGRectMake(self.frame.origin.x, 0.0f,
            self.bounds.size.width,
            self.bounds.size.height)];

    _needToLayoutFromObservation = NO;
    [_navigationBar setFrame:CGRectMake(0.0f, [UIApplication sharedApplication].statusBarFrame.size.height,
            self.bounds.size.width,
            self.bounds.size.height - (_menuHidden ?: navigationBarMenuHeight))];
    _needToLayoutFromObservation = YES;
    [_navigationBarMenuView setFrame:CGRectMake(0.0f, _navigationBar.frame.origin.y + _navigationBar.bounds.size.height - (_menuHidden ? navigationBarMenuHeight : 0.0f),
            self.bounds.size.width, navigationBarMenuHeight)];
}

#pragma mark - Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == _navigationBar && [keyPath isEqualToString:@"frame"]) {
        if (_needToLayoutFromObservation) {
            [self layoutSubviews];
        }
    }
}

#pragma mark - Interface

- (void)setMenuHidden:(BOOL)hidden animated:(BOOL)animated {
    if (_menuHidden != hidden) {
        _menuHidden = hidden;
        [UIView animateWithDuration:animated ? (1.0f / 3.0f) : 0.0f animations:^{
            [self layoutSubviews];
        }                completion:nil];
    }
}

@end

@interface PPMenuNavigationViewController ()
@end

@implementation PPMenuNavigationViewController

#pragma mark - Init

- (void)designedInit {
    [self setValue:[[PPNavigationBar alloc] init] forKey:[NSString stringWithFormat:@"navigationBar"]];
}

- (void)commonInit {
    //
}

#pragma mark - Lifecycle

- (instancetype)init {
    self = [self initWithNavigationBarClass:[UINavigationBar class] toolbarClass:[UIToolbar class]];
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
    //
}

#pragma mark - Setters / Getters

- (NSArray *)navigationMenuActions {
    PPNavigationBar *navigationBar = (PPNavigationBar *) self.navigationBar;

    return navigationBar.navigationBarMenuView.actions;
}

- (void)setNavigationMenuActions:(NSArray *)actions animated:(BOOL)animated {
    PPNavigationBar *navigationBar = (PPNavigationBar *) self.navigationBar;
    [navigationBar.navigationBarMenuView setActions:actions animated:animated];
}

- (void)setMenuHidden:(BOOL)hidden animated:(BOOL)animated {
    PPNavigationBar *navigationBar = (PPNavigationBar *) self.navigationBar;
    [navigationBar setMenuHidden:hidden animated:animated];
}

@end

@implementation UIViewController (PPMenuNavigationViewController)
- (PPMenuNavigationViewController *)menuNavigationViewController {
    if ([self.navigationController isKindOfClass:[PPMenuNavigationViewController class]]) {
        __weak PPMenuNavigationViewController *weakMenuNavigation = ((PPMenuNavigationViewController *) self.navigationController);
        return weakMenuNavigation;
    }

    return nil;
}
@end