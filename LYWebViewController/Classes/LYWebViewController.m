//
//  LYWebViewController.m
//  Pods
//
//  Created by 01 on 17/8/30.
//
//

#import "LYWebViewController.h"
#import "UIProgressView+WebKit.h"
#import "LYWebViewMacros.h"
#import <StoreKit/StoreKit.h>

@interface LYWebViewController()<SKStoreProductViewControllerDelegate>
{
    UIBarButtonItem * __weak _doneItem;
}

@end

@implementation LYWebViewController

- (instancetype)init
{
    if (self = [super init]) {
        _showsToolBar = YES;
        _showsBackgroundLabel = YES;
    }
    return self;
}

- (instancetype)initWithAddress:(NSString *)urlString
{
    if (self = [self init]) {
        NSString *urlStr = [self.class encodeWithURL:urlString];
        _URL = [NSURL URLWithString:urlStr];
    }
    return self;
}

- (instancetype)initWithURL:(NSURL*)pageURL
{
    if(self = [self init]) {
        NSString *urlStr = [self.class encodeWithURL:pageURL.absoluteString];
        _URL = [NSURL URLWithString:urlStr];
    }
    return self;
}

- (instancetype)initWithRequest:(NSURLRequest *)request
{
    if (self = [self init]) {
        NSString *urlStr = [self.class encodeWithURL:request.URL.absoluteString];
        _request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
    }
    return self;
}

- (instancetype)initWithHTMLString:(NSString *)HTMLString baseURL:(NSURL *)baseURL
{
    if (self = [self init]) {
        NSString *urlStr = [self.class encodeWithURL:baseURL.absoluteString];
        _HTMLString = HTMLString;
        _baseURL = [NSURL URLWithString:urlStr];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.navigationController) {
        [self updateFrameOfProgressView];
        [self.navigationController.navigationBar addSubview:self.progressView];
    }
    
    if (self.navigationType == LYWebViewControllerNavigationToolItem) {
        [self updateToolbarItems];
    }
    
    if (self.navigationType == LYWebViewControllerNavigationBarItem) {
        [self updateNavigationItems];
    }
    
    if (self.navigationController && [self.navigationController isBeingPresented]) {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                       target:self
                                       action:@selector(doneButtonClicked:)];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            self.navigationItem.leftBarButtonItem = doneButton;
        else
            self.navigationItem.rightBarButtonItem = doneButton;
        _doneItem = doneButton;
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && self.showsToolBar && self.navigationType == LYWebViewControllerNavigationToolItem) {
        [self.navigationController setToolbarHidden:NO animated:NO];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.navigationItem setLeftBarButtonItems:nil animated:NO];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && self.showsToolBar && self.navigationType == LYWebViewControllerNavigationToolItem) {
        [self.navigationController setToolbarHidden:YES animated:animated];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:[UIDevice currentDevice]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupSubviews];
   
    if (_request) {
        [self loadURLRequest:_request];
    } else if (self.URL) {
        [self loadURL:self.URL];
    } else if (_baseURL && _HTMLString) {
        [self loadHTMLString:_HTMLString baseURL:_baseURL];
    }
    
    self.navigationItem.leftItemsSupplementBackButton = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    self.progressView.progressTintColor = self.navigationController.navigationBar.tintColor;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (self.navigationType == LYWebViewControllerNavigationBarItem) {
        [self updateNavigationItems];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    UIDevice *device = [UIDevice currentDevice];
    [device beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:device];
}

- (UIBarButtonItem *)backBarButtonItem
{
    if (_backBarButtonItem) return _backBarButtonItem;
    _backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"LYWebViewController.bundle/images/LYWebViewControllerBack"] style:UIBarButtonItemStylePlain target:self action:@selector(goBackClicked:)];
    _backBarButtonItem.width = 18.0f;
    return _backBarButtonItem;
}

- (UIBarButtonItem *)forwardBarButtonItem
{
    if (_forwardBarButtonItem) return _forwardBarButtonItem;
    _forwardBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"LYWebViewController.bundle/images/LYWebViewControllerNext"] style:UIBarButtonItemStylePlain target:self action:@selector(goForwardClicked:)];
    _forwardBarButtonItem.width = 18.0f;
    return _forwardBarButtonItem;
}

- (UIBarButtonItem *)refreshBarButtonItem
{
    if (_refreshBarButtonItem) return _refreshBarButtonItem;
    _refreshBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadClicked:)];
    return _refreshBarButtonItem;
}

- (UIBarButtonItem *)stopBarButtonItem
{
    if (_stopBarButtonItem) return _stopBarButtonItem;
    _stopBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(stopClicked:)];
    return _stopBarButtonItem;
}

- (UIBarButtonItem *)actionBarButtonItem
{
    if (_actionBarButtonItem) return _actionBarButtonItem;
    _actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionButtonClicked:)];
    return _actionBarButtonItem;
}

- (UIProgressView *)progressView
{
    if (_progressView) return _progressView;
    CGFloat progressBarHeight = 2.0f;
    CGRect navigationBarBounds = self.navigationController.navigationBar.bounds;
    CGRect barFrame = CGRectMake(0, navigationBarBounds.size.height - progressBarHeight, navigationBarBounds.size.width, progressBarHeight);
    _progressView = [[UIProgressView alloc] initWithFrame:barFrame];
    _progressView.trackTintColor = [UIColor clearColor];
    _progressView.ly_hiddenWhenProgressApproachFullSize = YES;
    _progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    __weak typeof(self) wself = self;
    _progressView.delegate = wself;
    return _progressView;
}

- (UIBarButtonItem *)navigationBackItem
{
    if (_navigationBackItem) return _navigationBackItem;
    UIImage* backItemImage = [[[UINavigationBar appearance] backIndicatorImage] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]?:[[UIImage imageNamed:@"LYWebViewController.bundle/images/backItemImage"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIGraphicsBeginImageContextWithOptions(backItemImage.size, NO, backItemImage.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0, backItemImage.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    CGRect rect = CGRectMake(0, 0, backItemImage.size.width, backItemImage.size.height);
    CGContextClipToMask(context, rect, backItemImage.CGImage);
    [[self.navigationController.navigationBar.tintColor colorWithAlphaComponent:0.5] setFill];
    CGContextFillRect(context, rect);
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    UIImage* backItemHlImage = newImage?:[[UIImage imageNamed:@"LYWebViewController.bundle/images/backItemImage-hl"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIButton* backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    NSDictionary *attr = [[UIBarButtonItem appearance] titleTextAttributesForState:UIControlStateNormal];
    if (attr) {
        [backButton setAttributedTitle:[[NSAttributedString alloc] initWithString:LYWebViewControllerLocalizedString(@"back", @"back") attributes:attr] forState:UIControlStateNormal];
        UIOffset offset = [[UIBarButtonItem appearance] backButtonTitlePositionAdjustmentForBarMetrics:UIBarMetricsDefault];
        backButton.titleEdgeInsets = UIEdgeInsetsMake(offset.vertical, offset.horizontal, 0, 0);
        backButton.imageEdgeInsets = UIEdgeInsetsMake(offset.vertical, offset.horizontal, 0, 0);
    } else {
        [backButton setTitle:LYWebViewControllerLocalizedString(@"back", @"back") forState:UIControlStateNormal];
        [backButton setTitleColor:self.navigationController.navigationBar.tintColor forState:UIControlStateNormal];
        [backButton setTitleColor:[self.navigationController.navigationBar.tintColor colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
        [backButton.titleLabel setFont:[UIFont systemFontOfSize:17]];
    }
    [backButton setImage:backItemImage forState:UIControlStateNormal];
    [backButton setImage:backItemHlImage forState:UIControlStateHighlighted];
    [backButton sizeToFit];
    
    [backButton addTarget:self action:@selector(navigationItemHandleBack:) forControlEvents:UIControlEventTouchUpInside];
    _navigationBackItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    return _navigationBackItem;
}

- (UIBarButtonItem *)navigationCloseItem
{
    if (_navigationCloseItem) return _navigationCloseItem;
    if (self.navigationItem.rightBarButtonItem == _doneItem && self.navigationItem.rightBarButtonItem != nil) {
        _navigationCloseItem = [[UIBarButtonItem alloc] initWithTitle:LYWebViewControllerLocalizedString(@"close", @"close") style:0 target:self action:@selector(doneButtonClicked:)];
    } else {
        _navigationCloseItem = [[UIBarButtonItem alloc] initWithTitle:LYWebViewControllerLocalizedString(@"close", @"close") style:0 target:self action:@selector(navigationIemHandleClose:)];
    }
    return _navigationCloseItem;
}

- (UILabel *)backgroundLabel
{
    if (_backgroundLabel) return _backgroundLabel;
    _backgroundLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _backgroundLabel.textColor = [UIColor colorWithRed:0.180 green:0.192 blue:0.196 alpha:1.00];
    _backgroundLabel.font = [UIFont systemFontOfSize:12];
    _backgroundLabel.numberOfLines = 0;
    _backgroundLabel.textAlignment = NSTextAlignmentCenter;
    _backgroundLabel.backgroundColor = [UIColor clearColor];
    _backgroundLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_backgroundLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    _backgroundLabel.hidden = !self.showsBackgroundLabel;
    return _backgroundLabel;
}

- (void)setShowsBackgroundLabel:(BOOL)showsBackgroundLabel
{
    _backgroundLabel.hidden = !showsBackgroundLabel;
    _showsBackgroundLabel = showsBackgroundLabel;
}

- (void)setShowsToolBar:(BOOL)showsToolBar
{
    _showsToolBar = showsToolBar;
    if (self.navigationType == LYWebViewControllerNavigationToolItem) {
        [self updateToolbarItems];
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return YES;
    }
    return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    if (self.navigationType == LYWebViewControllerNavigationBarItem) {
        [self updateNavigationItems];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    if ([super respondsToSelector:@selector(viewWillTransitionToSize:withTransitionCoordinator:)]) {
        [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    }
    if (self.navigationType == LYWebViewControllerNavigationBarItem) {
        [self updateNavigationItems];
    }
}

- (void)updateFrameOfProgressView
{
    CGFloat progressBarHeight = 2.0f;
    CGRect navigationBarBounds = self.navigationController.navigationBar.bounds;
    CGRect barFrame = CGRectMake(0, navigationBarBounds.size.height - progressBarHeight, navigationBarBounds.size.width, progressBarHeight);
    self.progressView.frame = barFrame;
}

- (void)navigationIemHandleClose:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)doneButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)orientationChanged:(NSNotification *)note
{
    if (self.navigationType == LYWebViewControllerNavigationToolItem) {
        [self updateToolbarItems];
    } else {
        [self updateNavigationItems];
    }
}

#pragma mark - SKStoreProductViewControllerDelegate.
- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController
{
    [viewController dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - for subclass inherit

- (void)setupSubviews {}

- (void)updateToolbarItems {}

- (void)updateNavigationItems {}

- (void)loadURL:(NSURL*)URL {}

- (void)loadURLRequest:(NSURLRequest *)request {}

- (void)loadHTMLString:(NSString *)HTMLString baseURL:(NSURL *)baseURL {}

- (void)clearWebCacheCompletion:(dispatch_block_t _Nullable)completion {}

- (void)actionButtonClicked:(id)sender {}

- (void)goBackClicked:(UIBarButtonItem *)sender {}

- (void)goForwardClicked:(UIBarButtonItem *)sender {}

- (void)reloadClicked:(UIBarButtonItem *)sender {}

- (void)stopClicked:(UIBarButtonItem *)sender {}

- (void)navigationItemHandleBack:(UIBarButtonItem *)sender {}

#pragma mark - helper
+ (NSString *)encodeWithURL:(NSString *)URLString
{
//    CFStringRef escaped = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)URLString, NULL, (CFStringRef)@"!*'();:@&=+$,/?%#[]",kCFStringEncodingUTF8);
//    NSString *encodedString = [NSString stringWithString:(__bridge NSString *)escaped];
//    CFRelease(escaped);//记得释放
//    return encodedString;
    return [URLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}
@end
