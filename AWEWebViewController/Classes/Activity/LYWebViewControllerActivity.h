//
//  AWEWebViewControllerActivity.h
//  AWEWebViewController
//
//  Created by 01 on 17/7/12.
//  Copyright © 2017年 01. All rights reserved.
//

#import "AWEWebViewMacros.h"

@interface AWEWebViewControllerActivity : UIActivity
/// URL to open.
@property (nonatomic, strong) NSURL *URL;
/// Scheme prefix value.
@property (nonatomic, strong) NSString *scheme;
@end

@interface AWEWebViewControllerActivityChrome : AWEWebViewControllerActivity @end
@interface AWEWebViewControllerActivitySafari : AWEWebViewControllerActivity @end
