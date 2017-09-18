### 基于WKWebView和UIWebView实现的仿微信WebView功能的页面加载库

我们知道比起原生开发，H5有良好的跨平台性（很好地节约人力成本），升级灵活迅速，非常适合产品功能迭代频繁的业务模块，方便实现定制化的页面（千人千面），可以用来外投引流等优点，但是H5页面打开依赖原生的webview作为承载，目前多数产品基于UIWebView打开网页，没有有好的进度条提示，并且没有导航功能（目前在各自的项目中封装个UIViewController实现简单的“返回”按钮），页面加载完成会嘭地出现，尤其在图片、样式和脚本比较多的页面，用户体验上有较大提升空间。介于以上问题，提供一个功能更加完善的webview库使页面展示和浏览器相关操作上能对用户更加友好，同时能允许前端同学更加灵活定制样式和导航等功能。

#### Usage

在Podfile中加一行：  
```
 target 'MyApp' do
    pod 'LYWebViewController', '~> 0.2'
 -end
```
然后pod install


目前业界主要的三种打开网页的方式：
+ UIWebView
+ WKWebView (entered on iOS 8)
+ SFSafariViewController (entered on iOS 9)

三者对比如下表所示：
<br/>
<img src="https://github.com/DoTalkLily/LYWebViewController/blob/master/demo_images/diff.png" width=450/>
<br/>
图2 三者功能对比

目前业界比较推荐的做法是用WKWebView，但WKWebView在使用过程中会有很多坑，于是在尽量patch这些坑的前提下，实现UI和手势自定义，同时为了兼容iOS 8以下的应用，选择同时基于UIWebView和WKWebView封装实现以上功能的webview库，以便项目中方便根据使用场景进行选择。


### 设计与实现

下面我将逐一介绍目前实现的功能：

#### 1 . 支持UIWebView和WKWebView

可以依据业务场景选择使用哪种，使用方式如下：
创建一个基于WKWebView实现的webviewcontroller：

```
LYWebViewController *webVC = [[LYWKWebViewController alloc] initWithAddress:@"https://github.com/DoTalkLily/LYWebViewController"];
webVC.showsToolBar = NO;
webVC.showsBackgroundLabel = NO;
[self.navigationController pushViewController:webVC animated:YES];

```

创建一个基于UIWebView实现的webviewcontroller：

```
LYWebViewController *webVC = [[LYUIWebViewController alloc] initWithAddress:@"https://github.com/DoTalkLily/LYWebViewController"];
webVC.showsToolBar = NO;
webVC.navigationType = LYWebViewControllerNavigationBarItem;
[self.navigationController pushViewController:webVC animated:YES];
```

#### 2. 页面加载进度条
WKWebView 提供一个estimatedProgress属性代表页面加载进度，可以通过KVO方式监听这个属性来更新进度条。
```
[self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
```
UIWebView没有提供可以监听加载进度的属性，因此普遍的实现方式是fake一个进度条，即先慢慢滑到90%，然后等待加载完毕，完毕后瞬间进度到100%，为了方便实现和体验更好一些，可以用NJKWebViewProgress库，原理上也是fake进度进度条的方式。弱网环境下在微信中打开文章，通常是一个白屏但是进度条在推进，最后到80-90%左右卡主如果页面能打卡瞬间滑到100%，如果最终请求超时进度条也不动了，推测也是通过fake实现的。为了减少依赖库，LYWebViewController采用上述思路自己实现。两者效果如下：

WKWebView：
<br/>
<img src="https://github.com/DoTalkLily/LYWebViewController/blob/master/demo_images/progress_wk.gif" width=450/>
<br/>

UIWebView：
<br/>
<img src="https://github.com/DoTalkLily/LYWebViewController/blob/master/demo_images/progress_ui.gif" width=450/>
<br/>

#### 3. 顶部导航（类似微信的返回、关闭等）& 底部toolbar（仿浏览器）
原生的UIWebView和WKWebView没有提供导航功能，但是提供了判断是否可以前进后退的函数来封装这些功能。LYWebViewController通过增加导航按钮根据webview提供的canGoBack、goBack、canGoForward、goForward等函数实现顶部导航和底部toolbar导航，同时暴露钩子函数给使用者添加相应逻辑。

```
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

- (void)navigationItemHandleBack:(UIBarButtonItem *)sender
{
    if ([self.webView canGoBack]) {
        [self.webView goBack];
        return;
    }
    [self.navigationController popViewControllerAnimated:YES];
}
```

效果如下：

<br/>
<img src="https://github.com/DoTalkLily/LYWebViewController/blob/master/demo_images/navigation.gif" width=450/>
<br/>

#### 4.支持滑动导航
WKWebView 通过设置allowsBackForwardNavigationGestures属性可以实现右滑回退的功能，非常方便，但是UIWebView不支持，可以通过维护各网页的快照数组结合滑动手势来实现。
具体实现参见[这里](https://github.com/DoTalkLily/LYWebViewController/blob/308291e0aa4d481cf6321926c7bfcad080e4246a/LYWebViewController/Classes/LYUIWebViewController.m#L472)。

UIWebView+右滑回退效果如下：

<br/>
<img src="https://github.com/DoTalkLily/LYWebViewController/blob/master/demo_images/swap.gif" width=450/>
<br/>

#### 5. 支持唤起appstore下载
通常广告主会提供一个带各种下载按钮的H5页面，链接到“https://itunes.apple.com/” 开头的自己应用的页面，但原生WK和UIWebView不支持跳转到appstore，因此在UIWebView提供的“webView: shouldStartLoadWithRequest:navigationType:” 中解析拦截到的url，处理特殊跳转逻辑。（WKWebView是webView:decidePolicyForNavigationAction:decisionHandler:）
）
```
#pragma mark - UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([request.URL.absoluteString isEqualToString:kLY404NotFoundURLKey] ||
        [request.URL.absoluteString isEqualToString:kLYNetworkErrorURLKey]) {
        [self loadURL:self.URL];
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

```

可以实现跳转到appstore（手机中的appstore应用）或者在页面内打开appstore，以及打开邮件应用，打电话等。

效果如下：

<br/>
<img src="https://github.com/DoTalkLily/LYWebViewController/blob/master/demo_images/appstore.gif" width=450/>
<br/>

#### 6.记录上一次浏览位置
微信中打开网页有个很不错的功能，一个很长的网页看到一半关掉，下一次打开会自动跳到上一次看到的位置，非常方便。实现思路：将用户访问的url和每次退出时的页面滚动位置缓存起来，在UIWebView中的页面加载完成回调函数中（webViewDidFinishLoad）根据url查询是否有缓存的位置，有则取出来滚动到相应位置。在UIScrollViewDelegate的scrollViewDidEndDecelerating中实时记录滚动位置更新缓存。
效果如下(录屏软件bug导致导航文字不清晰)：

<br/>
<img src="https://github.com/DoTalkLily/LYWebViewController/blob/master/demo_images/remember.gif" width=450/>
<br/>

#### 7.下拉刷新
下拉刷新是来自前端的诉求，基于[MJRefresh](https://github.com/CoderMJLee/MJRefresh)实现，也是LYWebViewController唯一依赖的第三方库，暴露MJRefreshHeader属性，业务方可以根据MJRefresh使用说明设置自定义下拉刷新样式和事件。

除了上述功能，还实现以下功能，不一一赘述：
1. 国际化（支持英文、简体中文、繁体中文）
2. 样式兼容iPad，同时针对横竖屏样式调整
3. preview(>=iOS9）
4. share页提供用chrome、safari打开网页选项
5. 提供清缓存接口
6. 自定义UI（toolbar是否展示、进度条颜色等）

### What's next ?
+ 包含jsbridge；
+ 提供更多自定义UI；
+ 研究如何提升页面加载性能做进一步优化。

### 致谢

+ [AXWebViewController](https://github.com/devedbox/AXWebViewController) 为我提供了思路和参考。
+ [MJRefresh](https://github.com/CoderMJLee/MJRefresh) 用于实现下拉刷新功能，也是唯一依赖的库。
 
感谢阅读，欢迎提issue和pr~
