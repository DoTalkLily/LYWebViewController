//
//  LYWebViewMacros.h
//  Pods
//
//  Created by 01 on 17/8/25.
//
//
#import "LYWebViewController.h"

#ifndef LYWebViewControllerLocalizedString
#define LYWebViewControllerLocalizedString(key, comment) \
NSLocalizedStringFromTableInBundle(key, @"LYWebViewController",  [NSBundle bundleWithPath:[[[NSBundle bundleForClass:[LYWebViewController class]] resourcePath] stringByAppendingPathComponent:@"LYWebViewController.bundle"]], comment)
#endif

#ifndef kLY404NotFoundHTMLPath
#define kLY404NotFoundHTMLPath [[NSBundle bundleForClass:NSClassFromString(@"LYWebViewController")] pathForResource:@"LYWebViewController.bundle/html.bundle/404" ofType:@"html"]
#endif

#ifndef kLYNetworkErrorHTMLPath
#define kLYNetworkErrorHTMLPath [[NSBundle bundleForClass:NSClassFromString(@"LYWebViewController")] pathForResource:@"LYWebViewController.bundle/html.bundle/neterror" ofType:@"html"]
#endif

/// URL key for 404 not found page.
static NSString *const kLY404NotFoundURLKey = @"html.bundle/404.html";
/// URL key for network error page.
static NSString *const kLYNetworkErrorURLKey = @"html.bundle/neterror.html";
/// Tag value for container view.
static NSUInteger const kContainerViewTag = 0x893147;
