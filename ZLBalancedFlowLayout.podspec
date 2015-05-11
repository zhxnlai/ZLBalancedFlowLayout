Pod::Spec.new do |s|
  s.name         = "ZLBalancedFlowLayout"
  s.version      = "0.0.3"
  s.summary      = "A UICollectionViewFlowLayout subclass that scales items to take up space, optimized for large item set, inspired by NHBalancedFlowLayout."
  s.homepage     = "https://github.com/zhxnlai/ZLBalancedFlowLayout"
  s.screenshots  = "https://raw.githubusercontent.com/zhxnlai/ZLBalancedFlowLayout/master/Previews/vertical.png", "https://raw.githubusercontent.com/zhxnlai/ZLBalancedFlowLayout/master/Previews/horizontalLandscape.png"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Zhixuan Lai" => "zhxnlai@gmail.com" }
  s.social_media_url   = "http://twitter.com/ZhixuanLai"

  s.ios.deployment_target = '8.0'

  s.source       = { :git => "https://github.com/zhxnlai/ZLBalancedFlowLayout.git", :tag => "0.0.3" }
  s.source_files = 'ZLBalancedFlowLayout/*.swift'

  s.framework  = "UIKit"

  s.requires_arc = true
end
