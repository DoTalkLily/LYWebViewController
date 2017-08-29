//
//  TableViewController.m
//  LYWebViewController
//
//  Created by ai on 15/12/23.
//  Copyright © 2015年 AiXing. All rights reserved.
//

#import "TableViewController.h"
#import "LYWebViewController.h"
#import "LYUIWebViewController.h"

@interface TableViewController () <UITextFieldDelegate>

@end

@implementation TableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
   
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.row) {
        case 0:
        {
            LYWebViewController *webVC = [[LYWebViewController alloc] initWithURL:[NSURL fileURLWithPath:[NSBundle.mainBundle pathForResource:@"Swift" ofType:@"pdf"]]];
            webVC.title = @"Swift.pdf";
            webVC.showsToolBar = NO;
            if ([UIDevice currentDevice].systemVersion.floatValue >= 9.0) {
                webVC.webView.allowsLinkPreview = YES;
            }
            [self.navigationController pushViewController:webVC animated:YES];
        }
            break;
        case 1:
        {
            LYWebViewController *webVC = [[LYWebViewController alloc] initWithAddress:@"http://weibo.com/u/1945904165/home?wvr=5"];
            webVC.showsToolBar = NO;
            if ([UIDevice currentDevice].systemVersion.floatValue >= 9.0) {
                webVC.webView.allowsLinkPreview = YES;
            }
            [self.navigationController pushViewController:webVC animated:YES];
        }
            break;
        case 2:
        {
            LYWebViewController *webVC = [[LYWebViewController alloc] initWithAddress:@"http://weibo.com"];
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:webVC];
            nav.navigationBar.tintColor = [UIColor colorWithRed:0.322 green:0.322 blue:0.322 alpha:1.00];
            [self presentViewController:nav animated:YES completion:NULL];
            webVC.navigationType = LYWebViewControllerNavigationToolItem;
            webVC.showsToolBar = YES;
            webVC.navigationType = 1;
        }
            break;
        case 3: {
            LYWebViewController *webVC = [[LYWebViewController alloc] initWithAddress:@"http://weibo.com/"];
            webVC.showsToolBar = NO;
            webVC.showsBackgroundLabel = NO;
            if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0) {
                webVC.webView.allowsLinkPreview = YES;
            }
            [self.navigationController pushViewController:webVC animated:YES];
        } break;
        case 4: {
            LYWebViewController *webVC = [[LYWebViewController alloc] initWithAddress:@"https://github.com/devedbox/LYWebViewController/issues/10"];
            webVC.showsToolBar = NO;
            webVC.navigationType = LYWebViewControllerNavigationBarItem;
            if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0) {
                webVC.webView.allowsLinkPreview = YES;
            }
            [self.navigationController pushViewController:webVC animated:YES];
        } break;
        case 5: {
            LYUIWebViewController *webVC = [[LYUIWebViewController alloc] initWithAddress:@"https://github.com/Roxasora/RxWebViewController"];
            webVC.showsToolBar = NO;
            webVC.navigationType = LYWebViewControllerNavigationBarItem;
            [self.navigationController pushViewController:webVC animated:YES];
        } break;

        default:
            break;
    }
}

- (void)handle:(id)sender {
    NSURL *URL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"LYWebViewController.bundle/html.bundle/neterror" ofType:@"html" inDirectory:nil]];
    LYWebViewController *webVC = [[LYWebViewController alloc] initWithURL:URL];
    webVC.showsToolBar = NO;
    webVC.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.100f green:0.100f blue:0.100f alpha:0.800f];
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:0.996f green:0.867f blue:0.522f alpha:1.00f];
    [self.navigationController pushViewController:webVC animated:YES];
}

- (IBAction)clearCache:(id)sender {
    [LYWebViewController clearWebCacheCompletion:^{
    }];
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    // Get the text of text field.
    NSString *text = [textField.text copy];
    // Create an url object with the text string.
    NSURL *URL = [NSURL URLWithString:text];
    
    if (URL) {
        [self.view endEditing:YES];
        
        LYWebViewController *webVC = [[LYWebViewController alloc] initWithURL:URL];
        webVC.showsToolBar = NO;
        if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0) {
            webVC.webView.allowsLinkPreview = YES;
        }
        [self.navigationController pushViewController:webVC animated:YES];
    }
    
    return YES;
}
@end
