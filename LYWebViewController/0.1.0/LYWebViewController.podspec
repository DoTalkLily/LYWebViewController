#
# Be sure to run `pod lib lint AWEWebViewController.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'LYWebViewController'
  s.version          = '0.1.0'
  s.summary          = 'A solution for iOS WebView.'
  s.description      = <<-DESC
                       A solution for iOS WebView. It provides JSBridge and off-line resoure support for both UIWebView and WKWebView.
                       DESC

  s.homepage         = 'https://github.com/DoTalkLily/LYWebViewController'
  s.license          = 'MIT'
  s.author           = { 'DoTalkLily' => '343195590@qq.com' }
  s.source           = { :git => 'https://github.com/DoTalkLily/LYWebViewController.git', :tag => s.version }

  s.ios.deployment_target = '8.0'

  s.source_files  = 'LYWebViewController/Classes/**/*.{h,m}'
  s.resource_bundle = { 'LYWebViewController' => ['LYWebViewController/Resources/*'] }
  s.requires_arc = true


  s.frameworks = "UIKit", "Foundation", "WebKit"

  s.public_header_files = 'LYWebViewController/Classes/**/*.h'
  s.dependency "MJRefresh"
end

