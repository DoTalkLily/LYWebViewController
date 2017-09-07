//
//  LYWKWebViewController.h
//  LYWKWebViewController
//
//  Created by 01 on 17/7/12.
//  Copyright © 2017年 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "UIProgressView+WebKit.h"
#import "LYWebViewMacros.h"
#import "LYWebViewControllerProtocal.h"

NS_ASSUME_NONNULL_BEGIN

@interface LYWKWebViewController : LYWebViewController

@property(assign, nonatomic) BOOL enabledWebViewUIDelegate;
@property(nonatomic, readonly) WKWebView *webView;

- (instancetype)init;

- (instancetype)initWithURL:(NSURL *)URL configuration:(WKWebViewConfiguration *)configuration;

- (instancetype)initWithRequest:(NSURLRequest *)request configuration:(WKWebViewConfiguration *)configuration;

- (void)loadURL:(NSURL*)URL;

- (void)loadHTMLString:(NSString *)HTMLString baseURL:(NSURL *)baseURL;

// setter
- (void)setURL:(NSURL *)URL;

- (void)setRequest:(NSURLRequest *)request;

- (void)setURLString:(NSString *)urlString;

- (void)setHTMLString:(NSString *)HTMLString baseURL:(NSURL *)baseURL;

// clear cache
- (void)clearWebCacheCompletion:(dispatch_block_t _Nullable)completion;

@end

NS_ASSUME_NONNULL_END
