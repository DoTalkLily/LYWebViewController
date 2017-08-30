//
//  LYUIWebViewController.h
//  LYUIWebViewController
//
//  Created by 01 on 17/7/12.
//  Copyright © 2017年 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LYWebViewMacros.h"
#import "LYWebViewControllerDelegate.h"
#import "UIProgressView+WebKit.h"

@interface LYUIWebViewController : UIViewController <UIWebViewDelegate, LYWebViewProgressDelegate>

@property(assign, nonatomic) id<LYWebViewControllerDelegate>delegate;
@property(readonly, nonatomic) NSURL *URL;
@property(readonly, nonatomic) UIWebView *webView;
@property(assign, nonatomic) BOOL showsToolBar;
@property(assign, nonatomic) BOOL showsBackgroundLabel;
@property(assign, nonatomic) BOOL reviewsAppInAppStore;
@property(assign, nonatomic) NSUInteger maxAllowedTitleLength;
@property(assign, nonatomic) NSTimeInterval timeoutInternal;
@property(assign, nonatomic) NSURLRequestCachePolicy cachePolicy;
@property(assign, nonatomic) LYWebViewControllerNavigationType navigationType;
@property(readwrite, nonatomic) UIBarButtonItem *navigationCloseItem;

- (instancetype)initWithURL:(NSURL*)URL;

- (instancetype)initWithAddress:(NSString*)urlString;

- (instancetype)initWithRequest:(NSURLRequest *)request;

- (instancetype)initWithHTMLString:(NSString*)HTMLString baseURL:(NSURL*)baseURL;

- (void)loadURL:(NSURL*)URL;

- (void)loadHTMLString:(NSString *)HTMLString baseURL:(NSURL *)baseURL;

@end

/**
 WebCache clearing.
 */
@interface LYUIWebViewController (WebCache)

+ (void)clearWebCacheCompletion:(dispatch_block_t _Nullable)completion;

@end
