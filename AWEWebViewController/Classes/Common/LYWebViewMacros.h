//
//  AWEWebViewMacros.h
//  Pods
//
//  Created by 01 on 17/8/25.
//
//
#import "AWEWebViewController.h"

#ifndef AWEWebViewControllerLocalizedString
#define AWEWebViewControllerLocalizedString(key, comment) \
NSLocalizedStringFromTableInBundle(key, @"AWEWebViewController",  [NSBundle bundleWithPath:[[[NSBundle bundleForClass:[AWEWebViewController class]] resourcePath] stringByAppendingPathComponent:@"AWEWebViewController.bundle"]], comment)
#endif

#ifndef kAWE404NotFoundHTMLPath
#define kAWE404NotFoundHTMLPath [[NSBundle bundleForClass:NSClassFromString(@"AWEWebViewController")] pathForResource:@"AWEWebViewController.bundle/html.bundle/404" ofType:@"html"]
#endif

#ifndef kAWENetworkErrorHTMLPath
#define kAWENetworkErrorHTMLPath [[NSBundle bundleForClass:NSClassFromString(@"AWEWebViewController")] pathForResource:@"AWEWebViewController.bundle/html.bundle/neterror" ofType:@"html"]
#endif

/// URL key for 404 not found page.
static NSString *const kAWE404NotFoundURLKey = @"awe_404_not_found";
/// URL key for network error page.
static NSString *const kAWENetworkErrorURLKey = @"awe_network_error";
/// Tag value for container view.
static NSUInteger const kContainerViewTag = 0x893147;
