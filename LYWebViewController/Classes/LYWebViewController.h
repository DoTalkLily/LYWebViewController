//
//  LYWebViewController.h
//  Pods
//
//  Created by 01 on 17/8/30.
//
//

#import <UIKit/UIKit.h>
#import "LYWebViewControllerProtocal.h"
#import "MJRefreshHeader.h"

typedef NS_ENUM(NSInteger, LYWebViewControllerType) {
    LYWKWebViewControllerType,
    LYUIWebViewControllerType
};

typedef NS_ENUM(NSInteger, LYWebViewControllerNavigationType) {
    LYWebViewControllerNavigationBarItem,
    LYWebViewControllerNavigationToolItem
};

@interface LYWebViewController : UIViewController

@property(nonatomic, assign) BOOL showsToolBar;
@property(nonatomic, assign) BOOL allowsLinkPreview;
@property(nonatomic, assign) BOOL reviewsAppInAppStore;
@property(nonatomic, assign) BOOL showsBackgroundLabel;
@property(nonatomic, strong) NSURL *URL;
@property(nonatomic, strong) NSURL *baseURL;
@property(nonatomic, strong) NSString *HTMLString;
@property(nonatomic, strong) NSURLRequest *request;
@property(nonatomic, assign) id<LYWebViewDelegate> delegate;
@property(nonatomic, assign) LYWebViewControllerType type;
@property(nonatomic, assign) LYWebViewControllerNavigationType navigationType;
// UI
@property(nonatomic, strong) UILabel *backgroundLabel;
@property(nonatomic, strong) UIProgressView *progressView;
@property(nonatomic, strong) MJRefreshHeader *refreshHeader;
@property(nonatomic, strong) UIBarButtonItem *backBarButtonItem;
@property(nonatomic, strong) UIBarButtonItem *stopBarButtonItem;
@property(nonatomic, strong) UIBarButtonItem *actionBarButtonItem;
@property(nonatomic, strong) UIBarButtonItem *forwardBarButtonItem;
@property(nonatomic, strong) UIBarButtonItem *refreshBarButtonItem;
@property(strong, nonatomic) UIBarButtonItem *navigationBackItem;
@property(nonatomic, strong) UIBarButtonItem *navigationCloseItem;

- (instancetype)initWithURL:(NSURL*)URL;

- (instancetype)initWithAddress:(NSString*)urlString;

- (instancetype)initWithRequest:(NSURLRequest *)request;

- (instancetype)initWithHTMLString:(NSString*)HTMLString baseURL:(NSURL*)baseURL;

- (void)loadURL:(NSURL*)URL;

- (void)loadURLRequest:(NSURLRequest *)request;

- (void)loadHTMLString:(NSString *)HTMLString baseURL:(NSURL *)baseURL;

// setter
- (void)setURL:(NSURL *)URL;

- (void)setRequest:(NSURLRequest *)request;

- (void)setURLString:(NSString *)urlString;

- (void)setHTMLString:(NSString *)HTMLString baseURL:(NSURL *)baseURL;

// clear cache
- (void)clearWebCacheCompletion:(dispatch_block_t _Nullable)completion;

// subclass
- (void)setupSubviews;

- (void)updateToolbarItems;

- (void)updateNavigationItems;

- (void)updateFrameOfProgressView;


@end
