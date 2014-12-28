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

static const CGFloat actionsButtonsFontSize = 13.0f;

@interface PPNavigationBarMenuView () {
@private
    //Data
    NSArray *_actions;
    NSMutableArray *_actionsHandlers;

    //Visual
    NSMutableArray *_actionsButtons;
    UINavigationBar *_tintingNavBar;
}
@end

@implementation PPNavigationBarMenuView

#pragma mark - Setters / Getters

- (NSArray *)actions {
    return _actions;
}

- (void)setActions:(NSArray *)actions animated:(BOOL)animated {
    //TODO:
    //Do it animated if need
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
    _actions = nil;
    _actionsButtons = nil;
    _actionsHandlers = nil;
    _tintingNavBar = nil;
}

#pragma mark - Internal

- (void)_updateActionsButtons {
    _actionsButtons = [NSMutableArray array];
    _actionsHandlers = [NSMutableArray array];
    [_actions enumerateObjectsUsingBlock:^(PPNavigationBarMenuViewAction *currentAction, NSUInteger idx, BOOL *stop) {
        if ([currentAction isKindOfClass:[PPNavigationBarMenuViewAction class]]) {
            UIButton *actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [actionButton setTitle:currentAction.title forState:UIControlStateNormal];
            [actionButton setImage:currentAction.icon forState:UIControlStateNormal];
            [actionButton setTitleColor:[self tintColor]
                               forState:UIControlStateNormal];
            [actionButton.titleLabel setFont:[UIFont systemFontOfSize:actionsButtonsFontSize]];

            [self addSubview:actionButton];

            [_actionsButtons addObject:actionButton];
            [_actionsHandlers addObject:currentAction.handler];
        }
    }];

    [self layoutSubviews];
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

        [_tintingNavBar setTransform:CGAffineTransformMakeRotation(((float) M_PI))];
        [_tintingNavBar setBackgroundColor:[UIColor clearColor]];

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

@end

@implementation PPNavigationBarMenuViewAction

#pragma mark - Lifecycle

- (instancetype)initWithIcon:(UIImage *)icon handler:(void (^)())handler title:(NSString *)title {
    self = [super init];
    if (self) {
        self.icon = icon;
        self.handler = handler;
        self.title = title;
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