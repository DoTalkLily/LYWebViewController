//
//  LYWKWebViewController.m
//  LYWKWebViewController
//
//  Created by 01 on 17/7/12.
//  Copyright © 2017年 bytedance. All rights reserved.
//

#import "LYWKWebViewController.h"
#import "LYWebViewControllerActivity.h"
#import <objc/runtime.h>
#import <StoreKit/StoreKit.h>
#import <objc/runtime.h>

@interface LYWKWebViewController ()
{
    BOOL _loading;
    WKWebViewConfiguration *_configuration;
}

@property(nonatomic, assign) NSTimeInterval timeoutInternal;
@property(nonatomic, assign) NSURLRequestCachePolicy cachePolicy;
@property(nonatomic, assign) NSUInteger maxAllowedTitleLength;
@property(nonatomic, readwrite) WKWebView *webView;
@property(readonly, nonatomic) UIView *containerView;
@property(nonatomic, strong) WKNavigation *navigation;

@end

@implementation LYWKWebViewController

#pragma mark - Life cycle

- (instancetype)init {
    if (self = [super init]) {
        _maxAllowedTitleLength = 10;
        _enabledWebViewUIDelegate = YES;
        self.automaticallyAdjustsScrollViewInsets = NO;
        self.extendedLayoutIncludesOpaqueBars = YES;
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)URL
             configuration:(WKWebViewConfiguration *)configuration
{
    if (self = [super initWithURL:URL]) {
        _configuration = configuration;
    }
    return self;
}

- (instancetype)initWithRequest:(NSURLRequest *)request
                 configuration:(WKWebViewConfiguration *)configuration
{
    if (self = [super initWithRequest:request]) {
        _configuration = configuration;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.progressView removeFromSuperview];
}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item
{
    if ([self.navigationController.topViewController isKindOfClass:[LYWKWebViewController class]]) {
        LYWKWebViewController* webVC = (LYWKWebViewController*)self.navigationController.topViewController;
        if (webVC.webView.canGoBack) {
            if (webVC.webView.isLoading) {
                [webVC.webView stopLoading];
            }
            [webVC.webView goBack];
            return NO;
        }else{
            if (webVC.navigationType == LYWebViewControllerNavigationBarItem && [webVC.navigationItem.leftBarButtonItems containsObject:webVC.navigationCloseItem]) {
                [webVC updateNavigationItems];
                return NO;
            }
        }
    }
    return YES;
}

- (void)dealloc
{
    [self.webView stopLoading];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    self.webView.UIDelegate = nil;
    self.webView.navigationDelegate = nil;
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
    [self.webView removeObserver:self forKeyPath:@"scrollView.contentOffset"];
    [self.webView removeObserver:self forKeyPath:@"title"];
}

#pragma mark - Override.
- (void)setAutomaticallyAdjustsScrollViewInsets:(BOOL)automaticallyAdjustsScrollViewInsets
{
    [super setAutomaticallyAdjustsScrollViewInsets:NO];
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSString *,id> *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        if (self.navigationController && self.progressView.superview != self.navigationController.navigationBar) {
            [self updateFrameOfProgressView];
            [self.navigationController.navigationBar addSubview:self.progressView];
        }
        [self.progressView setProgress:self.webView.estimatedProgress animated:YES];
    } else if ([keyPath isEqualToString:@"scrollView.contentOffset"]) {
        CGPoint contentOffset = [change[NSKeyValueChangeNewKey] CGPointValue];
        self.backgroundLabel.transform = CGAffineTransformMakeTranslation(0, -contentOffset.y-self.webView.scrollView.contentInset.top);
    } else if ([keyPath isEqualToString:@"title"]) {
        [self _updateTitleOfWebVC];
        if (self.navigationType == LYWebViewControllerNavigationBarItem) {
            [self updateNavigationItems];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Setters
- (void)setAllowsLinkPreview:(BOOL)allowsLinkPreview
{
    self.webView.allowsLinkPreview = allowsLinkPreview;
}

#pragma mark - Getters
- (WKWebView *)webView
{
    if (_webView) return _webView;
    WKWebViewConfiguration *config = _configuration;
    
    if (!config) {
        config = [[WKWebViewConfiguration alloc] init];
        config.preferences.minimumFontSize = 9.0;
        
        if ([config respondsToSelector:@selector(setAllowsInlineMediaPlayback:)]) {
            [config setAllowsInlineMediaPlayback:YES];
        }
        if ([UIDevice currentDevice].systemVersion.floatValue >= 9.0) {
            if ([config respondsToSelector:@selector(setApplicationNameForUserAgent:)]) {
                [config setApplicationNameForUserAgent:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"]];
            }
        }
        if ([UIDevice currentDevice].systemVersion.floatValue >= 10.0 && [config respondsToSelector:@selector(setMediaTypesRequiringUserActionForPlayback:)]) {
            [config setMediaTypesRequiringUserActionForPlayback:WKAudiovisualMediaTypeNone];
        } else if ([UIDevice currentDevice].systemVersion.floatValue >= 9.0 && [config respondsToSelector:@selector(setRequiresUserActionForMediaPlayback:)]) {
            [config setRequiresUserActionForMediaPlayback:NO];
        } else if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0 && [config respondsToSelector:@selector(setMediaPlaybackRequiresUserAction:)]) {
            [config setMediaPlaybackRequiresUserAction:NO];
        }
    }
    
    _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
    _webView.allowsBackForwardNavigationGestures = YES;
    _webView.backgroundColor = [UIColor clearColor];
    _webView.scrollView.backgroundColor = [UIColor clearColor];
    _webView.translatesAutoresizingMaskIntoConstraints = NO;
    
    if (_enabledWebViewUIDelegate) {
        _webView.UIDelegate = self;
    }
    
    if (self.refreshHeader) {
        _webView.scrollView.mj_header = self.refreshHeader;
    }
   
    _webView.navigationDelegate = self;
    [_webView addObserver:self forKeyPath:@"scrollView.contentOffset" options:NSKeyValueObservingOptionNew context:NULL];
    [_webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];
    return _webView;
}

- (UIView *)containerView
{
    return [self.view viewWithTag:kContainerViewTag];
}

#pragma mark - Setter

- (void)setEnabledWebViewUIDelegate:(BOOL)enabledWebViewUIDelegate
{
    _enabledWebViewUIDelegate = enabledWebViewUIDelegate;
    if (_enabledWebViewUIDelegate) {
        self.webView.UIDelegate = self;
    } else {
        self.webView.UIDelegate = nil;
    }
}

- (void)setTimeoutInternal:(NSTimeInterval)timeoutInternal
{
    _timeoutInternal = timeoutInternal;
    NSMutableURLRequest *request = [self.request mutableCopy];
    request.timeoutInterval = _timeoutInternal;
    _navigation = [self.webView loadRequest:request];
    self.request = [request copy];
}

- (void)setCachePolicy:(NSURLRequestCachePolicy)cachePolicy
{
    _cachePolicy = cachePolicy;
    NSMutableURLRequest *request = [self.request mutableCopy];
    request.cachePolicy = _cachePolicy;
    _navigation = [self.webView loadRequest:request];
    self.request = [request copy];
}

- (void)setMaxAllowedTitleLength:(NSUInteger)maxAllowedTitleLength
{
    _maxAllowedTitleLength = maxAllowedTitleLength;
    [self _updateTitleOfWebVC];
}

#pragma mark - Public
- (void)loadURL:(NSURL *)pageURL
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:pageURL];
    request.timeoutInterval = _timeoutInternal;
    request.cachePolicy = _cachePolicy;
    _navigation = [self.webView loadRequest:request];
}

- (void)loadURLRequest:(NSURLRequest *)request
{
    NSMutableURLRequest *_request = [request mutableCopy];
    _navigation = [self.webView loadRequest:_request];
}

- (void)loadHTMLString:(NSString *)HTMLString baseURL:(NSURL *)baseURL
{
    self.baseURL = baseURL;
    self.HTMLString = HTMLString;
    _navigation = [self.webView loadHTMLString:HTMLString baseURL:baseURL];
}

- (void)didStartLoad
{
    self.backgroundLabel.text = LYWebViewControllerLocalizedString(@"loading", @"Loading");
    self.navigationItem.title = LYWebViewControllerLocalizedString(@"loading", @"Loading");
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    if (self.navigationType == LYWebViewControllerNavigationBarItem) {
        [self updateNavigationItems];
    }
    if (self.navigationType == LYWebViewControllerNavigationToolItem) {
        [self updateToolbarItems];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(didStartLoad:)]) {
        [self.delegate didStartLoad];
    }
    _loading = YES;
}

- (void)didFinishLoad{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    if (self.navigationType == LYWebViewControllerNavigationBarItem) {
        [self updateNavigationItems];
    }
    if (self.navigationType == LYWebViewControllerNavigationToolItem) {
        [self updateToolbarItems];
    }
    
    [self _updateTitleOfWebVC];
    
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *bundle = ([infoDictionary objectForKey:@"CFBundleDisplayName"]?:[infoDictionary objectForKey:@"CFBundleName"])?:[infoDictionary objectForKey:@"CFBundleIdentifier"];
    NSString *host = self.webView.URL.host;
    self.backgroundLabel.text = [NSString stringWithFormat:@"%@\"%@\"%@.", LYWebViewControllerLocalizedString(@"web page",@""), host?:bundle, LYWebViewControllerLocalizedString(@"provided",@"")];
    if (self.delegate && [self.delegate respondsToSelector:@selector(didFinishLoad)]) {
        [self.delegate didFinishLoad];
    }
    _loading = NO;
}

- (void)didFailLoadWithError:(NSError *)error{
    if (error.code == NSURLErrorCannotFindHost) {// 404
        [self loadURL:[NSURL fileURLWithPath:kLY404NotFoundHTMLPath]];
    } else {
        [self loadURL:[NSURL fileURLWithPath:kLYNetworkErrorHTMLPath]];
    }

    self.backgroundLabel.text = [NSString stringWithFormat:@"%@%@",LYWebViewControllerLocalizedString(@"load failed:", nil) , error.localizedDescription];
    self.navigationItem.title = LYWebViewControllerLocalizedString(@"load failed", nil);
    if (self.navigationType == LYWebViewControllerNavigationBarItem) {
        [self updateNavigationItems];
    }
    if (self.navigationType == LYWebViewControllerNavigationToolItem) {
        [self updateToolbarItems];
    }
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    if (self.delegate && [self.delegate respondsToSelector:@selector(didFailLoadWithError:)]) {
        [self.delegate didFailLoadWithError:error];
    }
    [self.progressView setProgress:0.9 animated:YES];
}

- (void)clearWebCacheCompletion:(dispatch_block_t)completion {
    if ([UIDevice currentDevice].systemVersion.floatValue >= 9.0) {
        NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
        NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
        [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:completion];
    } else {
        NSString *libraryDir = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0];
        NSString *bundleId  =  [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
        NSString *webkitFolderInLib = [NSString stringWithFormat:@"%@/WebKit",libraryDir];
        NSString *webKitFolderInCaches = [NSString stringWithFormat:@"%@/Caches/%@/WebKit",libraryDir,bundleId];
        
        NSError *error;
        /* iOS8.0 WebView Cache path */
        [[NSFileManager defaultManager] removeItemAtPath:webKitFolderInCaches error:&error];
        [[NSFileManager defaultManager] removeItemAtPath:webkitFolderInLib error:nil];
        
        if (completion) {
            completion();
        }
    }
}

#pragma mark - Actions
- (void)goBackClicked:(UIBarButtonItem *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(willGoBack)]) {
        [self.delegate willGoBack];
    }
    if ([self.webView canGoBack]) {
        _navigation = [self.webView goBack];
    }
}
- (void)goForwardClicked:(UIBarButtonItem *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(willGoForward)]) {
        [self.delegate willGoForward];
    }
    if ([self.webView canGoForward]) {
        _navigation = [self.webView goForward];
    }
}
- (void)reloadClicked:(UIBarButtonItem *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(willReload)]) {
        [self.delegate willReload];
    }
    _navigation = [self.webView reload];
}
- (void)stopClicked:(UIBarButtonItem *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(willStop)]) {
        [self.delegate willStop];
    }
    [self.webView stopLoading];
}

- (void)actionButtonClicked:(id)sender {
    NSArray *activities = @[[LYWebViewControllerActivitySafari new], [LYWebViewControllerActivityChrome new]];
    NSURL *URL = self.webView.URL;
    
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[URL] applicationActivities:activities];
    [self presentViewController:activityController animated:YES completion:nil];
}

- (void)navigationItemHandleBack:(UIBarButtonItem *)sender {
    if ([self.webView canGoBack]) {
        _navigation = [self.webView goBack];
        return;
    }
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - WKUIDelegate
- (nullable WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    WKFrameInfo *frameInfo = navigationAction.targetFrame;
    if (![frameInfo isMainFrame]) {
        if (navigationAction.request) {
            [webView loadRequest:navigationAction.request];
        }
    }
    return nil;
}
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
- (void)webViewDidClose:(WKWebView *)webView {
}
#endif
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    // Get host name of url.
    NSString *host = webView.URL.host;
    // Init the alert view controller.
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:host?:LYWebViewControllerLocalizedString(@"messages", nil) message:message preferredStyle: UIAlertControllerStyleAlert];
    // Init the cancel action.
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LYWebViewControllerLocalizedString(@"cancel", @"cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        if (completionHandler != NULL) {
            completionHandler();
        }
    }];
    // Init the ok action.
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LYWebViewControllerLocalizedString(@"confirm", @"confirm") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
        if (completionHandler != NULL) {
            completionHandler();
        }
    }];
    
    // Add actions.
    [alert addAction:cancelAction];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:NULL];
}
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler {
    // Get the host name.
    NSString *host = webView.URL.host;
    // Initialize alert view controller.
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:host?:LYWebViewControllerLocalizedString(@"messages", nil) message:message preferredStyle:UIAlertControllerStyleAlert];
    // Initialize cancel action.
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LYWebViewControllerLocalizedString(@"cancel", @"cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
        if (completionHandler != NULL) {
            completionHandler(NO);
        }
    }];
    // Initialize ok action.
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LYWebViewControllerLocalizedString(@"confirm", @"confirm") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
        if (completionHandler != NULL) {
            completionHandler(YES);
        }
    }];
    // Add actions.
    [alert addAction:cancelAction];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:NULL];
}
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * __nullable result))completionHandler {
    NSString *host = webView.URL.host;
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:prompt?:LYWebViewControllerLocalizedString(@"messages", nil) message:host preferredStyle:UIAlertControllerStyleAlert];
    // Add text field.
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = defaultText?:LYWebViewControllerLocalizedString(@"input", nil);
        textField.font = [UIFont systemFontOfSize:12];
    }];
    // Initialize cancel action.
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LYWebViewControllerLocalizedString(@"cancel", @"cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
        // Get inputed string.
        NSString *string = [alert.textFields firstObject].text;
        if (completionHandler != NULL) {
            completionHandler(string?:defaultText);
        }
    }];
    // Initialize ok action.
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LYWebViewControllerLocalizedString(@"confirm", @"confirm") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
        // Get inputed string.
        NSString *string = [alert.textFields firstObject].text;
        if (completionHandler != NULL) {
            completionHandler(string?:defaultText);
        }
    }];
    // Add actions.
    [alert addAction:cancelAction];
    [alert addAction:okAction];
}
#pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    // Disable all the '_blank' target in page's target.
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView evaluateJavaScript:@"var a = document.getElementsByTagName('a');for(var i=0;i<a.length;i++){a[i].setAttribute('target','');}" completionHandler:nil];
    }
    NSURLComponents *components = [[NSURLComponents alloc] initWithString:navigationAction.request.URL.absoluteString];
    // For appstore and system defines. This action will jump to AppStore app or the system apps.
    if ([[NSPredicate predicateWithFormat:@"SELF BEGINSWITH[cd] 'https://itunes.apple.com/' OR SELF BEGINSWITH[cd] 'mailto:' OR SELF BEGINSWITH[cd] 'tel:' OR SELF BEGINSWITH[cd] 'telprompt:'"] evaluateWithObject:components.URL.absoluteString]) {
        if ([[NSPredicate predicateWithFormat:@"SELF BEGINSWITH[cd] 'https://itunes.apple.com/'"] evaluateWithObject:components.URL.absoluteString] && !self.reviewsAppInAppStore) {
            SKStoreProductViewController *productVC = [[SKStoreProductViewController alloc] init];
            productVC.delegate = self;
            NSError *error;
            NSRegularExpression *regex = [[NSRegularExpression alloc] initWithPattern:@"id[1-9]\\d*" options:NSRegularExpressionCaseInsensitive error:&error];
            NSTextCheckingResult *result = [regex firstMatchInString:components.URL.absoluteString options:NSMatchingReportCompletion range:NSMakeRange(0, components.URL.absoluteString.length)];
            
            if (!error && result) {
                NSRange range = NSMakeRange(result.range.location+2, result.range.length-2);
                [productVC loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier: @([[components.URL.absoluteString substringWithRange:range] integerValue])} completionBlock:^(BOOL result, NSError * _Nullable error) {
                }];
                [self presentViewController:productVC animated:YES completion:NULL];
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            }
        }
        if ([[UIApplication sharedApplication] canOpenURL:components.URL]) {
            [UIApplication.sharedApplication openURL:components.URL options:@{} completionHandler:NULL];
        }
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    } else if (![[NSPredicate predicateWithFormat:@"SELF MATCHES[cd] 'https' OR SELF MATCHES[cd] 'http' OR SELF MATCHES[cd] 'file' OR SELF MATCHES[cd] 'about'"] evaluateWithObject:components.scheme]) {// For any other schema but not `https`、`http` and `file`.
        if ([[UIApplication sharedApplication] canOpenURL:components.URL]) {
            [UIApplication.sharedApplication openURL:components.URL options:@{} completionHandler:NULL];
        }
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    
    // URL actions for 404 and Errors:
    if ([navigationAction.request.URL.absoluteString isEqualToString:kLY404NotFoundURLKey] || [navigationAction.request.URL.absoluteString isEqualToString:kLYNetworkErrorURLKey]) {
        // Reload the original URL.
        [self loadURL:self.URL];
    }
    // Update the items.
    if (self.navigationType == LYWebViewControllerNavigationBarItem) {
        [self updateNavigationItems];
    }
    if (self.navigationType == LYWebViewControllerNavigationToolItem) {
        [self updateToolbarItems];
    }
    // Call the decision handler to allow to load web page.
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    decisionHandler(WKNavigationResponsePolicyAllow);
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation
{
    [self didStartLoad];
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation {}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
    if (error.code == NSURLErrorCancelled) {
        [webView reloadFromOrigin];
        return;
    }
    [self didFailLoadWithError:error];
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation {}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation
{
    [self didFinishLoad];
}
- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error
{
//    if (error.code == NSURLErrorCancelled) {
//        [webView reloadFromOrigin];
//        return;
//    }
//    [self didFailLoadWithError:error];
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView
{
    NSString *host = webView.URL.host;
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:host?:LYWebViewControllerLocalizedString(@"messages", nil) message:LYWebViewControllerLocalizedString(@"terminate", nil) preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LYWebViewControllerLocalizedString(@"cancel", @"cancel") style:UIAlertActionStyleCancel handler:NULL];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LYWebViewControllerLocalizedString(@"confirm", @"confirm") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [alert dismissViewControllerAnimated:YES completion:NULL];
    }];
    [alert addAction:cancelAction];
    [alert addAction:okAction];
}
#endif

#pragma mark - LYWebViewProgressDelegate
- (void)updateBarItemStatus
{
    if (self.navigationType == LYWebViewControllerNavigationBarItem) {
        [self updateNavigationItems];
    } else {
        [self updateToolbarItems];
    }
}

#pragma mark - Helper
- (void)_updateTitleOfWebVC
{
    NSString *title = self.title;
    title = title.length>0 ? title: [self.webView title];
    if (title.length > _maxAllowedTitleLength) {
        title = [[title substringToIndex:_maxAllowedTitleLength-1] stringByAppendingString:@"…"];
    }
    self.navigationItem.title = title.length>0 ? title : LYWebViewControllerLocalizedString(@"browsing the web", @"browsing the web");
}

- (void)setupSubviews
{
    id topLayoutGuide = self.topLayoutGuide;
    UIView *container = [UIView new];
    [container setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:container];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[container]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(container)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topLayoutGuide][container]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(topLayoutGuide, container)]];
    [container setTag:kContainerViewTag];

    [self.containerView addSubview:self.backgroundLabel];
    [self.containerView addSubview:self.webView];
    UILabel *backgroundLabel = self.backgroundLabel;

    [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[backgroundLabel(<=width)]" options:0 metrics:@{@"width":@(self.view.bounds.size.width)} views:NSDictionaryOfVariableBindings(backgroundLabel)]];
    [self.containerView addConstraint:[NSLayoutConstraint constraintWithItem:self.backgroundLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.containerView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    
    [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_webView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_webView)]];
    [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_webView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_webView)]];
    [self.containerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[backgroundLabel]-20-[_webView]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(backgroundLabel, _webView)]];
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    
    [self.containerView bringSubviewToFront:self.backgroundLabel];
    self.progressView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 2);
    [self.view addSubview:self.progressView];
    [self.view bringSubviewToFront:self.progressView];
}

- (void)updateToolbarItems
{
    self.backBarButtonItem.enabled = self.webView.canGoBack;
    self.forwardBarButtonItem.enabled = self.webView.canGoForward;
    self.actionBarButtonItem.enabled = !self.webView.isLoading;
    
    UIBarButtonItem *refreshStopBarButtonItem = self.webView.isLoading ? self.stopBarButtonItem : self.refreshBarButtonItem;
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        fixedSpace.width = 35.0f;
        
        NSArray *items = [NSArray arrayWithObjects:fixedSpace, refreshStopBarButtonItem, fixedSpace, self.backBarButtonItem, fixedSpace, self.forwardBarButtonItem, fixedSpace, self.actionBarButtonItem, nil];
        
        self.navigationItem.rightBarButtonItems = items.reverseObjectEnumerator.allObjects;
    } else {
        NSArray *items = [NSArray arrayWithObjects: fixedSpace, self.backBarButtonItem, flexibleSpace, self.forwardBarButtonItem, flexibleSpace, refreshStopBarButtonItem, flexibleSpace, self.actionBarButtonItem, fixedSpace, nil];
        
        self.navigationController.toolbar.barStyle = self.navigationController.navigationBar.barStyle;
        self.navigationController.toolbar.tintColor = self.navigationController.navigationBar.tintColor;
        self.navigationController.toolbar.barTintColor = self.navigationController.navigationBar.barTintColor;
        self.toolbarItems = items;
    }
}

- (void)updateNavigationItems
{
    [self.navigationItem setLeftBarButtonItems:nil animated:NO];
    if (self.webView.canGoBack) {
        UIBarButtonItem *spaceButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        spaceButtonItem.width = -6.5;
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
        if (self.navigationController.viewControllers.count == 1) {
            [self.navigationItem setLeftBarButtonItems:@[spaceButtonItem, self.navigationCloseItem, self.navigationCloseItem] animated:NO];
        } else {
            [self.navigationItem setLeftBarButtonItems:@[self.navigationCloseItem] animated:NO];
        }
    } else {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        [self.navigationItem setLeftBarButtonItems:nil animated:NO];
    }
}

@end

