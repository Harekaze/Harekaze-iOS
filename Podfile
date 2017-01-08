platform :ios, '10.0'

target 'Harekaze' do
  use_frameworks!

  # Pods for Harekaze
    ## Swift 3 (stable)
  pod 'Material', '2.4.6'
  pod 'ObjectMapper', '2.2.2'
  pod 'Alamofire', '4.2.0'
  pod 'RealmSwift', '2.1.2'
  pod 'Kingfisher', '3.2.4'
  pod 'DropDown', '2'
  pod 'KeychainAccess', '3.0.1'
  pod 'SJSegmentedScrollView', '1.3.5'
  pod 'ARNTransitionAnimator', '2.0.3'
  pod 'SpringIndicator', '1.4.1'
  pod 'StatefulViewController', '3.0'
  pod 'APIKit', '3.1.1'
  pod 'StretchHeader', '1.1.0'
    ## Objective-C
  pod 'MobileVLCKit-prod', '2.7.9'
  pod 'Fabric', '1.6.11'
  pod 'Crashlytics', '3.8.3'
  pod '1PasswordExtension', '1.8.4'
  pod 'JTMaterialTransition', '2.0.1'
  pod 'CarbonKit', '2.1.9'
  pod 'DRCellSlideGestureRecognizer', '1.0.0'
    ## Swift 2.x
  # pod 'EECellSwipeGestureRecognizer', '1.0.1'

  # devtools
  pod 'SwiftLint', '0.15.0'

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
