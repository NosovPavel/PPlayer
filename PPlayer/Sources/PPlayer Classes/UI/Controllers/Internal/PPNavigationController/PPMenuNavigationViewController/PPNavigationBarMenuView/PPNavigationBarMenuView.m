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

#import "PPNavigationBarMenuView.h"

static const CGFloat actionsButtonsFontSize = 14.0f;

UIEdgeInsets actionsButtonsTitleInset() {
    return UIEdgeInsetsMake(0.0f, 13.0f, 0.0f, 0.0f);
}

@interface PPNavigationBarMenuView () {
@private
    //Data
    NSArray *_actions;
    NSMutableArray *_actionsHandlers;
    NSMutableArray *_actionsButtons;

    //Visual
    UINavigationBar *_tintingNavBar;
}
@end

@implementation PPNavigationBarMenuView

#pragma mark - Setters / Getters

- (NSArray *)actions {
    return _actions;
}

- (void)setActions:(NSArray *)actions animated:(BOOL)animated {
    [self _resetObservations];

    //TODO:
    //Do it animated when need
    _actions = actions;
    [self _updateActionsButtons];
}

#pragma mark - Lifecycle

- (instancetype)initWithActions:(NSArray *)actions {
    self = [super init];
    if (self) {
        [self setActions:actions animated:NO];
    }

    return self;
}

+ (instancetype)viewWithActions:(NSArray *)actions {
    return [[self alloc] initWithActions:actions];
}

- (void)dealloc {
    [self _resetObservations];

    _actions = nil;
    _actionsButtons = nil;
    _actionsHandlers = nil;
    _tintingNavBar = nil;
}

#pragma mark - Internal

- (void)_resetObservations {
    [_actions enumerateObjectsUsingBlock:^(PPNavigationBarMenuViewAction *currentAction, NSUInteger idx, BOOL *stop) {
        [currentAction removeObserver:self forKeyPath:@"enabled"];
    }];
}

- (void)_resetSubviews {
    [self.subviews enumerateObjectsUsingBlock:^(UIView *currentSubview, NSUInteger idx, BOOL *stop) {
        if ([currentSubview isKindOfClass:[UIButton class]]) {
            [currentSubview removeFromSuperview];
        }
    }];
}

- (void)_updateActionsButtons {
    [self _resetSubviews];

    _actionsButtons = [NSMutableArray array];
    _actionsHandlers = [NSMutableArray array];

    [_actions enumerateObjectsUsingBlock:^(PPNavigationBarMenuViewAction *currentAction, NSUInteger idx, BOOL *stop) {
        if ([currentAction isKindOfClass:[PPNavigationBarMenuViewAction class]]) {
            [currentAction addObserver:self
                            forKeyPath:@"enabled"
                               options:NSKeyValueObservingOptionNew
                               context:NULL];

            UIButton *actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [actionButton setTitle:currentAction.title forState:UIControlStateNormal];
            [actionButton setImage:[currentAction.icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]
                          forState:UIControlStateNormal];
            [actionButton.titleLabel setFont:[UIFont systemFontOfSize:actionsButtonsFontSize]];
            [actionButton setTitleEdgeInsets:actionsButtonsTitleInset()];
            [actionButton addTarget:self
                             action:@selector(_buttonTouchedUp:)
                   forControlEvents:UIControlEventTouchUpInside];

            [self addSubview:actionButton];

            [_actionsButtons addObject:actionButton];
            [_actionsHandlers addObject:currentAction.handler];

            [self _updateActionButtonState:currentAction];
        }
    }];

    [self layoutSubviews];
}

- (void)_updateActionButtonState:(PPNavigationBarMenuViewAction *)action {
    NSUInteger indexOfHandler = [_actionsHandlers indexOfObject:action.handler];
    if (indexOfHandler != NSNotFound) {
        UIButton *actionButton = _actionsButtons[indexOfHandler];

        BOOL enabled = action.enabled;
        UIColor *tintColor = enabled ? [self tintColor] : [UIColor lightGrayColor];

        [actionButton setUserInteractionEnabled:enabled];
        [actionButton setTintColor:tintColor];
        [actionButton setTitleColor:tintColor
                           forState:UIControlStateNormal];
    }
}

#pragma mark - Layout

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat itemWidth = self.bounds.size.width / _actionsButtons.count;
    __block CGFloat lastX = 0.0f;

    [_actionsButtons enumerateObjectsUsingBlock:^(UIButton *currentActionButton, NSUInteger idx, BOOL *stop) {
        CGRect currentFrame = CGRectMake(lastX, 0.0f, itemWidth, self.bounds.size.height);
        [currentActionButton setFrame:currentFrame];

        lastX += itemWidth;
    }];

    if (!_tintingNavBar) {
        _tintingNavBar = [[UINavigationBar alloc] init];

        [self addSubview:_tintingNavBar];
        [self sendSubviewToBack:_tintingNavBar];
    }

    if (_tintingNavBar.bounds.size.height >= self.bounds.size.height) {
        [_tintingNavBar setFrame:CGRectMake(0.0f, 0.0f,
                self.bounds.size.width, _tintingNavBar.bounds.size.height)];
    } else {
        [_tintingNavBar setFrame:self.bounds];
    }
}

#pragma mark - Actions Calling

- (void)_buttonTouchedUp:(UIButton *)sender {
    NSUInteger index = [_actionsButtons indexOfObject:sender];
    if (index != NSNotFound) {
        if (_actions.count > index) {
            void (^handler)() = _actionsHandlers[index];

            if (handler) {
                handler();
            }
        }
    }
}

#pragma mark - Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([_actions containsObject:object] &&
            [object isKindOfClass:[PPNavigationBarMenuViewAction class]] &&
            [keyPath isEqualToString:@"enabled"]) {
        [self _updateActionButtonState:object];
    }
}

@end

@implementation PPNavigationBarMenuViewAction

#pragma mark - Lifecycle

- (instancetype)initWithIcon:(UIImage *)icon handler:(void (^)())handler title:(NSString *)title {
    self = [super init];
    if (self) {
        self.icon = icon;
        self.handler = handler;
        self.title = title;
        self.enabled = YES;
    }

    return self;
}

+ (instancetype)actionWithIcon:(UIImage *)icon handler:(void (^)())handler title:(NSString *)title {
    return [[self alloc] initWithIcon:icon handler:handler title:title];
}

- (void)dealloc {
    //
}

@end