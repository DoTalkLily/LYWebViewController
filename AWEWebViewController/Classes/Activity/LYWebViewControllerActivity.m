//
//  AWEWebViewControllerActivity.m
//  AWEWebViewController
//
//  Created by 01 on 17/7/12.
//  Copyright © 2017年 01. All rights reserved.
//

#import "AWEWebViewControllerActivity.h"

@implementation AWEWebViewControllerActivity
- (NSString *)activityType {
    return NSStringFromClass([self class]);
}

- (UIImage *)activityImage {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return [UIImage imageNamed:[NSString stringWithFormat:@"AWEWebViewController.bundle/%@",[self.activityType stringByAppendingString:@"-iPad"]]];
    else
        return [UIImage imageNamed:[NSString stringWithFormat:@"AWEWebViewController.bundle/%@",self.activityType]];
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    for (id activityItem in activityItems) {
        if ([activityItem isKindOfClass:[NSURL class]]) {
            self.URL = activityItem;
        }
    }
}
@end

@implementation AWEWebViewControllerActivityChrome
- (NSString *)schemePrefix {
    return @"googlechrome://";
}

- (NSString *)activityTitle {
    return AWEWebViewControllerLocalizedString(@"OpenInChrome", @"Open in Chrome");
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    for (id activityItem in activityItems) {
        if ([activityItem isKindOfClass:[NSURL class]] && [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:self.schemePrefix]]) {
            return YES;
        }
    }
    return NO;
}

- (void)performActivity {
    NSString *openingURL;
    if ([UIDevice currentDevice].systemVersion.floatValue >= 9.0) {
        openingURL = [self.URL.absoluteString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    } else {
        openingURL = [self.URL.absoluteString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }

    NSURL *activityURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", self.schemePrefix, openingURL]];
    
    if ([UIDevice currentDevice].systemVersion.floatValue >= 10.0) {
        [[UIApplication sharedApplication] openURL:activityURL options:@{} completionHandler:nil];
    } else {
        [[UIApplication sharedApplication] openURL:activityURL options:@{} completionHandler:nil];
    }
    
    [self activityDidFinish:YES];
}
@end

@implementation AWEWebViewControllerActivitySafari
- (NSString *)activityTitle {
    return AWEWebViewControllerLocalizedString(@"OpenInSafari", @"Open in Safari");
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    for (id activityItem in activityItems) {
        if ([activityItem isKindOfClass:[NSURL class]] && [[UIApplication sharedApplication] canOpenURL:activityItem]) {
            return YES;
        }
    }
    return NO;
}

- (void)performActivity {
    [[UIApplication sharedApplication] openURL:self.URL options:@{} completionHandler:^(BOOL success) {
         [self activityDidFinish:success];
    }];
}
@end
