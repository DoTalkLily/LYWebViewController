//
//  LYWebViewController.m
//  LYWebViewController
//
//  Created by 01 on 17/7/12.
//  Copyright © 2017年 bytedance. All rights reserved.
//

#import "LYUIWebViewController.h"
#import <StoreKit/StoreKit.h>
#import "LYWebViewControllerActivity.h"
#import "LYURLCacheUtil.h"

@interface LYUIWebViewController () <UIWebViewDelegate, UIScrollViewDelegate, LYWebViewProgressDelegate, SKStoreProductViewControllerDelegate>
{
    BOOL _loading;
}

@property(nonatomic, assign) BOOL isSwipingBack;
@property(nonatomic, readwrite) UIWebView *webView;
@property(nonatomic, strong) NSMutableArray *snapshots;
@property(nonatomic, assign) NSUInteger maxAllowedTitleLength;
@property(nonatomic, assign) NSTimeInterval timeoutInternal;
@property(nonatomic, assign) NSURLRequestCachePolicy cachePolicy;
@property(nonatomic, strong) UIPanGestureRecognizer *swipePanGesture;
@property(nonatomic, strong) UIView *currentSnapshotView;
@property(nonatomic, strong) UIView *previousSnapshotView;
@property(nonatomic, strong) UIView *swipingBackgoundView;

@end

@implementation LYUIWebViewController

#pragma mark - Life cycle

- (instancetype)init
{
    if (self = [super init]) {
        _timeoutInternal = 30.0;
        _maxAllowedTitleLength = 10;
        _cachePolicy = NSURLRequestReloadRevalidatingCacheData;
    }
    return self;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (self.navigationController) {
        [self.progressView removeFromSuperview];
    }
    
    if (self.navigationType == LYWebViewControllerNavigationBarItem) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    }
}

- (BOOL)navigationBar:(UINavigationBar *)navigationBar shouldPopItem:(UINavigationItem *)item
{
    if ([self.navigationController.topViewController isKindOfClass:[LYUIWebViewController class]]){
        LYUIWebViewController* webVC = (LYUIWebViewController*)self.navigationController.topViewController;
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
            return YES;
        }
    }
    return YES;
}

- (void)dealloc
{
    [self.webView stopLoading];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    self.webView.delegate = nil;
    self.webView.scrollView.delegate = nil;
}

#pragma mark - Setters
- (void)setAllowsLinkPreview:(BOOL)allowsLinkPreview
{
    self.webView.allowsLinkPreview = allowsLinkPreview;
}

- (void)setTimeoutInternal:(NSTimeInterval)timeoutInternal
{
    _timeoutInternal = timeoutInternal;
    NSMutableURLRequest *request = [self.webView.request mutableCopy];
    request.timeoutInterval = _timeoutInternal;
    [self.webView loadRequest:request];
}

- (void)setCachePolicy:(NSURLRequestCachePolicy)cachePolicy
{
    _cachePolicy = cachePolicy;
    NSMutableURLRequest *request = [self.webView.request mutableCopy];
    request.cachePolicy = _cachePolicy;
    [self.webView loadRequest:request];
}

- (void)setMaxAllowedTitleLength:(NSUInteger)maxAllowedTitleLength
{
    _maxAllowedTitleLength = maxAllowedTitleLength;
    [self _updateTitleOfWebVC];
}

#pragma mark - Getters
- (UIWebView*)webView
{
    if (!_webView) {
        _webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
        _webView.backgroundColor = [UIColor clearColor];
        _webView.delegate = self;
        _webView.scrollView.delegate = self;
        _webView.scalesPageToFit = YES;
        [_webView addGestureRecognizer:self.swipePanGesture];
        _webView.translatesAutoresizingMaskIntoConstraints = NO;
        if (self.refreshHeader) {
            _webView.scrollView.mj_header = self.refreshHeader;
        }
    }
    return _webView;
}

-(UIView*)swipingBackgoundView
{
    if (!_swipingBackgoundView) {
        _swipingBackgoundView = [[UIView alloc] initWithFrame:self.view.bounds];
        _swipingBackgoundView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.3];
    }
    return _swipingBackgoundView;
}

-(NSMutableArray*)snapshots
{
    if (!_snapshots) {
        _snapshots = [NSMutableArray array];
    }
    return _snapshots;
}

-(BOOL)isSwipingBack
{
    if (!_isSwipingBack) {
        _isSwipingBack = NO;
    }
    return _isSwipingBack;
}

-(UIPanGestureRecognizer*)swipePanGesture
{
    if (!_swipePanGesture) {
        _swipePanGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(swipePanGestureHandler:)];
    }
    return _swipePanGesture;
}

#pragma mark - Public
- (void)loadURL:(NSURL *)pageURL
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:pageURL];
    request.timeoutInterval = _timeoutInternal;
    request.cachePolicy = _cachePolicy;
    [self.webView loadRequest:request];
}

- (void)loadURLRequest:(NSURLRequest *)request
{
    NSMutableURLRequest *__request = [request mutableCopy];
    [self.webView loadRequest:__request];
}

- (void)loadHTMLString:(NSString *)HTMLString baseURL:(NSURL *)baseURL
{
    self.baseURL = baseURL;
    self.HTMLString = HTMLString;
    [self.webView loadHTMLString:HTMLString baseURL:baseURL];
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
    
    self.progressView.progress = 0.0;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didStartLoad)]) {
        [self.delegate didStartLoad];
    }
    _loading = YES;
}

- (void)didFinishLoad
{
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
    NSString *host;
    host = self.webView.request.URL.host;
    self.backgroundLabel.text = [NSString stringWithFormat:@"%@\"%@\"%@.", LYWebViewControllerLocalizedString(@"web page",@""), host?:bundle, LYWebViewControllerLocalizedString(@"provided",@"")];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(didFinishLoad)]) {
        [self.delegate didFinishLoad];
    }
    
    _loading = NO;
    [self.progressView setProgress:0.9 animated:YES];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.progressView.progress != 1.0) {
            [self.progressView setProgress:1.0 animated:YES];
        }
    });
    
    //scroll to last read position if there was
    CGFloat offsetY = 0;
    offsetY = [[LYURLCacheUtil sharedInstance] getYPositionForURL:self.webView.request.URL.absoluteString];
    
    if (offsetY) {
        [UIView animateWithDuration:0.5 delay:1.5 options:UIViewAnimationOptionCurveEaseIn animations:^{
            [self.webView.scrollView setContentOffset:CGPointMake(0, offsetY) animated:NO];
        } completion:^(BOOL finished) {}];
    }
}

- (void)didFailLoadWithError:(NSError *)error
{
    if (error.code == NSURLErrorCannotFindHost) {// 404
        self.URL = [NSURL fileURLWithPath:kLY404NotFoundHTMLPath];
        [self loadURL:self.URL];
    } else {
        self.URL = [NSURL fileURLWithPath:kLYNetworkErrorHTMLPath];
        [self loadURL:self.URL];
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

- (void)clearWebCacheCompletion:(dispatch_block_t)completion
{
    NSString *libraryDir = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES)[0];
    NSString *bundleId  =  [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    NSString *webkitFolderInLib = [NSString stringWithFormat:@"%@/WebKit",libraryDir];
    NSString *webKitFolderInCaches = [NSString stringWithFormat:@"%@/Caches/%@/WebKit",libraryDir,bundleId];
    NSString *webKitFolderInCachesfs = [NSString stringWithFormat:@"%@/Caches/%@/fsCachedData",libraryDir,bundleId];
    
    NSError *error;
    /* iOS8.0 WebView Cache path */
    [[NSFileManager defaultManager] removeItemAtPath:webKitFolderInCaches error:&error];
    [[NSFileManager defaultManager] removeItemAtPath:webkitFolderInLib error:nil];
    
    /* iOS7.0 WebView Cache path */
    [[NSFileManager defaultManager] removeItemAtPath:webKitFolderInCachesfs error:&error];
    if (completion) {
        completion();
    }
}

#pragma mark - Actions
- (void)goBackClicked:(UIBarButtonItem *)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(willGoBack)]) {
        [self.delegate willGoBack];
    }
    if ([self.webView canGoBack]) {
        [self.webView goBack];
    }
}
- (void)goForwardClicked:(UIBarButtonItem *)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(willGoForward)]) {
        [self.delegate willGoForward];
    }
    if ([self.webView canGoForward]) {
        [self.webView goForward];
    }
}
- (void)reloadClicked:(UIBarButtonItem *)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(willReload)]) {
        [self.delegate willReload];
    }
    [self.webView reload];
}
- (void)stopClicked:(UIBarButtonItem *)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(willStop)]) {
        [self.delegate willStop];
    }
    [self.webView stopLoading];
}

- (void)actionButtonClicked:(id)sender
{
    NSArray *activities = @[[LYWebViewControllerActivitySafari new], [LYWebViewControllerActivityChrome new]];
    NSURL *URL = self.webView.request.URL;
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[URL] applicationActivities:activities];
    [self presentViewController:activityController animated:YES completion:nil];
}

- (void)navigationItemHandleBack:(UIBarButtonItem *)sender
{
    if ([self.webView canGoBack]) {
        [self.webView goBack];
        return;
    }
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)swipePanGestureHandler:(UIPanGestureRecognizer*)panGesture
{
    CGPoint translation = [panGesture translationInView:self.webView];
    CGPoint location = [panGesture locationInView:self.webView];
    
    if (panGesture.state == UIGestureRecognizerStateBegan) {
        if (location.x <= 50 && translation.x >= 0) {  //开始动画
            [self startPopSnapshotView];
        }
    }else if (panGesture.state == UIGestureRecognizerStateCancelled || panGesture.state == UIGestureRecognizerStateEnded){
        [self endPopSnapShotView];
    }else if (panGesture.state == UIGestureRecognizerStateChanged){
        [self popSnapShotViewWithPanGestureDistance:translation.x];
    }
}

#pragma mark - LYWebViewProgressDelegate
- (void)updateBarItemStatus {
    if (self.navigationType == LYWebViewControllerNavigationBarItem) {
        [self updateNavigationItems];
    } else {
        [self updateToolbarItems];
    }
}

#pragma mark - UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([request.URL.absoluteString rangeOfString:kLY404NotFoundURLKey].location != NSNotFound ||
        [request.URL.absoluteString rangeOfString:kLYNetworkErrorURLKey].location != NSNotFound) {
        return NO;
    }
    
    NSURLComponents *components = [[NSURLComponents alloc] initWithString:request.URL.absoluteString];
    // For appstore.
    if ([[NSPredicate predicateWithFormat:@"SELF BEGINSWITH[cd] 'https://itunes.apple.com/' OR SELF BEGINSWITH[cd] 'mailto:' OR SELF BEGINSWITH[cd] 'tel:' OR SELF BEGINSWITH[cd] 'telprompt:'"] evaluateWithObject:request.URL.absoluteString]) {
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
                return NO;
            }
        }
        if ([[UIApplication sharedApplication] canOpenURL:request.URL]) {
            if (UIDevice.currentDevice.systemVersion.floatValue >= 10.0){
                [UIApplication.sharedApplication openURL:request.URL options:@{} completionHandler:NULL];
            } else {
                [[UIApplication sharedApplication] openURL:request.URL];
            }
        }
        return NO;
    } else if (![[NSPredicate predicateWithFormat:@"SELF MATCHES[cd] 'https' OR SELF MATCHES[cd] 'http' OR SELF MATCHES[cd] 'file' OR SELF MATCHES[cd] 'about'"] evaluateWithObject:components.scheme]) {// For any other schema.
        if ([[UIApplication sharedApplication] canOpenURL:request.URL]) {
            if (UIDevice.currentDevice.systemVersion.floatValue >= 10.0) {
                [UIApplication.sharedApplication openURL:request.URL options:@{} completionHandler:NULL];
            } else {
                [[UIApplication sharedApplication] openURL:request.URL];
            }
        }
        return NO;
    }
    
    if (navigationType == UIWebViewNavigationTypeLinkClicked ||
        navigationType == UIWebViewNavigationTypeFormSubmitted ||
        navigationType == UIWebViewNavigationTypeOther) {
        [self pushCurrentSnapshotViewWithRequest:request];
    }
    
    if (self.navigationType == LYWebViewControllerNavigationBarItem) {
        [self updateNavigationItems];
    }
    
    if (self.navigationType == LYWebViewControllerNavigationToolItem) {
        [self updateToolbarItems];
    }
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    [self didStartLoad];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self didFinishLoad];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
//    if (error.code == NSURLErrorCancelled) {
//        [webView reload]; return;
//    }
    [self didFailLoadWithError:error];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    CGFloat offsetY =  self.webView.scrollView.contentOffset.y;
    [[LYURLCacheUtil sharedInstance] insertURL:self.webView.request.URL.absoluteString
                                     yPosition:offsetY];
}

#pragma mark - Helper
- (void)_updateTitleOfWebVC
{
    NSString *title = self.title;
    title = title.length>0 ? title: [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    if (title.length > _maxAllowedTitleLength) {
        title = [[title substringToIndex:_maxAllowedTitleLength-1] stringByAppendingString:@"…"];
    }
    self.navigationItem.title = title.length>0 ? title : LYWebViewControllerLocalizedString(@"browsing the web", @"browsing the web");
}

-(void)pushCurrentSnapshotViewWithRequest:(NSURLRequest*)request
{
    NSURLRequest* lastRequest = (NSURLRequest*)[[self.snapshots lastObject] objectForKey:@"request"];
    
    // 如果url是很奇怪的就不push
    if ([request.URL.absoluteString isEqualToString:@"about:blank"]) {
        return;
    }
    //如果url一样就不进行push
    if ([lastRequest.URL.absoluteString isEqualToString:request.URL.absoluteString]) {
        return;
    }
    
    UIView* currentSnapshotView = [self.webView snapshotViewAfterScreenUpdates:YES];
    [self.snapshots addObject:
      @{
         @"request":request,
         @"snapShotView":currentSnapshotView
       }
    ];
}

-(void)startPopSnapshotView
{
    if (self.isSwipingBack) {
        return;
    }
    if (!self.webView.canGoBack) {
        return;
    }
    self.isSwipingBack = YES;
    //create a center of scrren
    CGPoint center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
    
    self.currentSnapshotView = [self.webView snapshotViewAfterScreenUpdates:YES];
    
    //add shadows just like UINavigationController
    self.currentSnapshotView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.currentSnapshotView.layer.shadowOffset = CGSizeMake(3, 3);
    self.currentSnapshotView.layer.shadowRadius = 5;
    self.currentSnapshotView.layer.shadowOpacity = 0.75;
    
    //move to center of screen
    self.currentSnapshotView.center = center;
    
    self.previousSnapshotView = (UIView*)[[self.snapshots lastObject] objectForKey:@"snapShotView"];
    center.x -= 60;
    self.previousSnapshotView.center = center;
    self.previousSnapshotView.alpha = 1;
    self.view.backgroundColor = [UIColor colorWithRed:0.180 green:0.192 blue:0.196 alpha:1.00];
    
    [self.view addSubview:self.previousSnapshotView];
    [self.view addSubview:self.swipingBackgoundView];
    [self.view addSubview:self.currentSnapshotView];
}

-(void)popSnapShotViewWithPanGestureDistance:(CGFloat)distance
{
    if (!self.isSwipingBack) {
        return;
    }
    
    if (distance <= 0) {
        return;
    }
    
    CGFloat boundsWidth = CGRectGetWidth(self.view.bounds);
    CGFloat boundsHeight = CGRectGetHeight(self.view.bounds);
    
    CGPoint currentSnapshotViewCenter = CGPointMake(boundsWidth/2, boundsHeight/2);
    currentSnapshotViewCenter.x += distance;
    CGPoint previousSnapshotViewCenter = CGPointMake(boundsWidth/2, boundsHeight/2);
    previousSnapshotViewCenter.x -= (boundsWidth - distance)*60/boundsWidth;
    
    self.currentSnapshotView.center = currentSnapshotViewCenter;
    self.previousSnapshotView.center = previousSnapshotViewCenter;
    self.swipingBackgoundView.alpha = (boundsWidth - distance)/boundsWidth;
}

-(void)endPopSnapShotView
{
    if (!self.isSwipingBack) {
        return;
    }
    
    //prevent the user touch for now
    self.view.userInteractionEnabled = NO;
    
    CGFloat boundsWidth = CGRectGetWidth(self.view.bounds);
    CGFloat boundsHeight = CGRectGetHeight(self.view.bounds);
    
    if (self.currentSnapshotView.center.x >= boundsWidth) {
        // pop success
        [UIView animateWithDuration:0.2 animations:^{
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            
            self.currentSnapshotView.center = CGPointMake(boundsWidth*3/2, boundsHeight/2);
            self.previousSnapshotView.center = CGPointMake(boundsWidth/2, boundsHeight/2);
            self.swipingBackgoundView.alpha = 0;
        }completion:^(BOOL finished) {
            [self.previousSnapshotView removeFromSuperview];
            [self.swipingBackgoundView removeFromSuperview];
            [self.currentSnapshotView removeFromSuperview];
            [self.webView goBack];
            [self.snapshots removeLastObject];
            self.view.userInteractionEnabled = YES;
            
            self.isSwipingBack = NO;
        }];
    }else{
        //pop fail
        [UIView animateWithDuration:0.2 animations:^{
            [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
            
            self.currentSnapshotView.center = CGPointMake(boundsWidth/2, boundsHeight/2);
            self.previousSnapshotView.center = CGPointMake(boundsWidth/2-60, boundsHeight/2);
            self.previousSnapshotView.alpha = 1;
        }completion:^(BOOL finished) {
            [self.previousSnapshotView removeFromSuperview];
            [self.swipingBackgoundView removeFromSuperview];
            [self.currentSnapshotView removeFromSuperview];
            self.view.userInteractionEnabled = YES;
            
            self.isSwipingBack = NO;
        }];
    }
}

- (void)setupSubviews
{
    [self.view insertSubview:self.backgroundLabel atIndex:0];
    [self.view addSubview:self.webView];
    UILabel *backgroundLabel = self.backgroundLabel;
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[backgroundLabel(<=width)]" options:0 metrics:@{@"width":@(self.view.bounds.size.width)} views:NSDictionaryOfVariableBindings(backgroundLabel)]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.backgroundLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_webView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_webView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_webView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_webView)]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[backgroundLabel]-20-[_webView]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(backgroundLabel, _webView)]];
    
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    [self.view bringSubviewToFront:self.backgroundLabel];
    self.progressView.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 2);
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
            [self.navigationItem setLeftBarButtonItems:@[spaceButtonItem, self.navigationBackItem, self.navigationCloseItem] animated:NO];
        } else {
            [self.navigationItem setLeftBarButtonItems:@[self.navigationCloseItem] animated:NO];
        }
    } else {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        [self.navigationItem setLeftBarButtonItems:nil animated:NO];
    }
}

@end

