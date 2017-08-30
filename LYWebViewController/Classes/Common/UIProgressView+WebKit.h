//
//  UIProgressView+Webkit.h
//  Pods
//
//  Created by 01 on 17/8/25.
//
//

@protocol LYWebViewProgressDelegate <NSObject>

- (void)updateBarItemStatus;

@end

@interface UIProgressView (WebKit)

@property(assign, nonatomic) BOOL ly_hiddenWhenProgressApproachFullSize;
@property(assign, nonatomic) id<LYWebViewProgressDelegate> delegate;

@end
