//
//  UIProgressView+Webkit.m
//  Pods
//
//  Created by 01 on 17/8/25.
//
//

#import <UIKit/UIKit.h>
#import "UIProgressView+Webkit.h"
#import <objc/runtime.h>

@implementation UIProgressView (WebKit)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method originalMethod = class_getInstanceMethod(self, @selector(setProgress:));
        Method swizzledMethod = class_getInstanceMethod(self, @selector(ly_setProgress:));
        method_exchangeImplementations(originalMethod, swizzledMethod);
        
        originalMethod = class_getInstanceMethod(self, @selector(setProgress:animated:));
        swizzledMethod = class_getInstanceMethod(self, @selector(ly_setProgress:animated:));
        method_exchangeImplementations(originalMethod, swizzledMethod);
    });
}

- (void)ly_setProgress:(float)progress {
    [self ly_setProgress:progress];
    
    [self checkHiddenWhenProgressApproachFullSize];
}

- (void)ly_setProgress:(float)progress animated:(BOOL)animated {
    [self ly_setProgress:progress animated:animated];
    
    [self checkHiddenWhenProgressApproachFullSize];
}

- (void)checkHiddenWhenProgressApproachFullSize {
    if (!self.ly_hiddenWhenProgressApproachFullSize) {
        return;
    }
    
    float progress = self.progress;
    if (progress < 1) {
        if (self.hidden) {
            self.hidden = NO;
        }
    } else if (progress >= 1) {
        [UIView animateWithDuration:0.35 delay:0.15 options:7 animations:^{
            self.alpha = 0.0;
        } completion:^(BOOL finished) {
            if (finished) {
                self.hidden = YES;
                self.progress = 0.0;
                self.alpha = 1.0;
                if (self.delegate && [self.delegate respondsToSelector:@selector(updateBarItemStatus)]) {
                    [self.delegate updateBarItemStatus];
                }
            }
        }];
    }
}

- (BOOL)ly_hiddenWhenProgressApproachFullSize {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setLy_hiddenWhenProgressApproachFullSize:(BOOL)ly_hiddenWhenProgressApproachFullSize {
    objc_setAssociatedObject(self, @selector(ly_hiddenWhenProgressApproachFullSize), @(ly_hiddenWhenProgressApproachFullSize), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id<LYWebViewProgressDelegate>)delegate
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setDelegate:(id<LYWebViewProgressDelegate>)delegate
{
    objc_setAssociatedObject(self, @selector(delegate), delegate, OBJC_ASSOCIATION_ASSIGN);
}

@end
