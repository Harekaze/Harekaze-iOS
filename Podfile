platform :ios, '10.0'

target 'Harekaze' do
  use_frameworks!

  # Pods for Harekaze
    ## Swift 3 (stable)
  pod 'Material', '2.1.2'
  pod 'ObjectMapper', '2.1.0'
  pod 'Alamofire', '4.0.1'
  pod 'RealmSwift', '2.0.2'
  pod 'Kingfisher', '3.1.3'
  pod 'DropDown', '2'
  pod 'KeychainAccess', '3.0.1'
  pod 'SJSegmentedScrollView', '1.2.2'
  pod 'ARNTransitionAnimator', '2.0.2'
  pod 'SpringIndicator', '1.4.1'
  pod 'StatefulViewController', '2.0'
    ## Swift 3 (beta)
  pod 'APIKit', :git => 'https://github.com/ishkawa/APIKit', :tag => '3.0.0-beta.2'
  pod 'StretchHeader', :git => 'https://github.com/y-hryk/StretchHeader', :tag => '1.1.0'
    ## Objective-C
  pod 'MobileVLCKit-prod', '2.7.9'
  pod 'Fabric', '1.6.10'
  pod 'Crashlytics', '3.8.3'
  pod '1PasswordExtension', '1.8.4'
  pod 'JTMaterialTransition', '1.0.5'
  pod 'CarbonKit', '2.1.9'
  pod 'DRCellSlideGestureRecognizer', '1.0.0'
    ## Swift 2.x
  # pod 'EECellSwipeGestureRecognizer', '1.0.1'

  post_install do | installer |
    require 'fileutils'
    FileUtils.cp_r('Pods/Target Support Files/Pods-Harekaze/Pods-Harekaze-acknowledgements.plist', 'Harekaze/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
  end

  target 'HarekazeTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'HarekazeUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end
