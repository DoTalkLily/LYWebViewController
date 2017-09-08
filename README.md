# LYWebViewController

基于WKWebView和UIWebView封装（根据项目需求选择哪种实现方式)

# feature list:
1. 支持UIWebView和WKWebView
2. 页面加载进度条
3. 顶部导航（类似微信的返回、关闭等）
4. 底部toolbar
5. 支持转场（手势左右滑动切换网页）
6. 支持唤起appstore下载
7. 国际化（支持英文、简体中文、繁体中文）
8. 兼容iPad
9. preview(>=iOS9）
10. 用chrome、safari打开网页
11. 暴露清缓存接口
12. 设置超时时长、缓存策略
13. 自定义UI（toolbar是否展示、进度条颜色等）
14. 下拉刷新（支持自定义样式）

demo:

<img src="https://github.com/DoTalkLily/LYWebViewController/blob/master/demo.gif" width=375 height=667/>

# License

This code is distributed under the terms and conditions of the [MIT license](https://github.com/DoTalkLily/LYWebViewController/blob/master/LICENSE).

# Usage


创建一个基于WKWebView实现的webviewcontroller：

```
 LYWebViewController *webVC = [[LYWKWebViewController alloc] initWithAddress:@"https://github.com/DoTalkLily/LYWebViewController"];
 webVC.showsToolBar = NO;
 webVC.showsBackgroundLabel = NO;
 if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0) {
     webVC.allowsLinkPreview = YES;
 }
 [self.navigationController pushViewController:webVC animated:YES];

```

创建一个基于UIWebView实现的webviewcontroller：

```
LYUIWebViewController *webVC = [[LYUIWebViewController alloc] initWithAddress:@"https://github.com/DoTalkLily/LYWebViewController"];
webVC.showsToolBar = NO;
webVC.navigationType = LYWebViewControllerNavigationBarItem;
[self.navigationController pushViewController:webVC animated:YES];
```

然后可以设置各种属性，导航按钮样式、下拉刷新样式、导航类型（底部工具条还是类似微信webview的顶部导航）、是否在webview中打开appstore还是跳转到appstore，加载网页的各阶段的钩子函数（delegate）等。

# 致谢

[AXWebViewController](https://github.com/devedbox/AXWebViewController) 为我提供了思路和参考。
[MJRefresh](https://github.com/CoderMJLee/MJRefresh) 用于实现下拉刷新功能，也是唯一依赖的库。


具体用法参见demo，欢迎提issue。
