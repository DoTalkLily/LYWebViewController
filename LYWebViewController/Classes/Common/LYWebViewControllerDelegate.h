//
//  LYWebViewControllerDelegate.h
//  Pods
//
//  Created by 01 on 17/8/28.
//
//

#import <Foundation/Foundation.h>

@class LYWebViewController;

@protocol LYWebViewControllerDelegate <NSObject>

@optional

- (void)webViewControllerWillGoBack:(LYWebViewController *)webViewController;

- (void)webViewControllerWillGoForward:(LYWebViewController *)webViewController;

- (void)webViewControllerWillReload:(LYWebViewController *)webViewController;

- (void)webViewControllerWillStop:(LYWebViewController *)webViewController;

- (void)webViewControllerDidStartLoad:(LYWebViewController *)webViewController;

- (void)webViewControllerDidFinishLoad:(LYWebViewController *)webViewController;

- (void)webViewController:(LYWebViewController *)webViewController didFailLoadWithError:(NSError *)error;

@end
