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
  s.summary          = 'A webview viewcontroller based on wkwebview.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/DoTalkLily/LYWebViewController'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = 'MIT'
  s.author           = { 'DoTalkLily' => 'lili.01@bytedance.com' }
  s.source           = { :git => 'https://github.com/DoTalkLily/LYWebViewController.git', :tag => s.version }

  s.ios.deployment_target = '8.0'

  s.source_files  = 'LYWebViewController/Classes/**/*.{h,m}'
  s.resource_bundle = { 'LYWebViewController' => ['LYWebViewController/Resources/*'] }
  s.requires_arc = true

  s.frameworks = "UIKit", "Foundation", "WebKit"

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency "MJRefresh"
end

