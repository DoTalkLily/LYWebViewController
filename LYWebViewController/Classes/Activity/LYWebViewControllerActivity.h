//
//  LYWebViewControllerActivity.h
//  LYWebViewController
//
//  Created by 01 on 17/7/12.
//  Copyright © 2017年 01. All rights reserved.
//

#import "LYWebViewMacros.h"

@interface LYWebViewControllerActivity : UIActivity
/// URL to open.
@property (nonatomic, strong) NSURL *URL;
/// Scheme prefix value.
@property (nonatomic, strong) NSString *scheme;
@end

@interface LYWebViewControllerActivityChrome : LYWebViewControllerActivity @end
@interface LYWebViewControllerActivitySafari : LYWebViewControllerActivity @end
