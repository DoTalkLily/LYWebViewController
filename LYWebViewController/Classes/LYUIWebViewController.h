//
//  LYUIWebViewController.h
//  LYUIWebViewController
//
//  Created by 01 on 17/7/12.
//  Copyright © 2017年 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LYWebViewMacros.h"
#import "LYWebViewControllerProtocal.h"
#import "UIProgressView+WebKit.h"

@interface LYUIWebViewController : LYWebViewController <UIWebViewDelegate, LYWebViewProgressDelegate>

@property(nonatomic, readonly) UIWebView *webView;

- (instancetype)init;

- (void)loadURL:(NSURL*)URL;

- (void)loadHTMLString:(NSString *)HTMLString baseURL:(NSURL *)baseURL;

- (void)setURL:(NSURL *)URL;

- (void)setRequest:(NSURLRequest *)request;

- (void)setURLString:(NSString *)urlString;

- (void)setHTMLString:(NSString *)HTMLString baseURL:(NSURL *)baseURL;

// clear cache
- (void)clearWebCacheCompletion:(dispatch_block_t _Nullable)completion;

@end
