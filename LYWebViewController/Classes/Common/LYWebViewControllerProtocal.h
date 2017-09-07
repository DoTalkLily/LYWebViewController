//
//  LYWebViewControllerDelegate.h
//  Pods
//
//  Created by 01 on 17/8/28.
//
//

@protocol LYWebViewDelegate <NSObject>

@optional

- (void)willStop;

- (void)willGoBack;

- (void)willReload;

- (void)didStartLoad;

- (void)didFinishLoad;

- (void)willGoForward;

- (void)didFailLoadWithError:(NSError *)error;

@end
