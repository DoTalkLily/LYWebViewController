//
//  AWEWebViewControllerDelegate.h
//  Pods
//
//  Created by 01 on 17/8/28.
//
//

#import <Foundation/Foundation.h>

@class AWEWebViewController;

@protocol AWEWebViewControllerDelegate <NSObject>

@optional

- (void)webViewControllerWillGoBack:(AWEWebViewController *)webViewController;

- (void)webViewControllerWillGoForward:(AWEWebViewController *)webViewController;

- (void)webViewControllerWillReload:(AWEWebViewController *)webViewController;

- (void)webViewControllerWillStop:(AWEWebViewController *)webViewController;

- (void)webViewControllerDidStartLoad:(AWEWebViewController *)webViewController;

- (void)webViewControllerDidFinishLoad:(AWEWebViewController *)webViewController;

- (void)webViewController:(AWEWebViewController *)webViewController didFailLoadWithError:(NSError *)error;

@end
