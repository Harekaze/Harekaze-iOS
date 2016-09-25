platform :ios, '10.0'

target 'Harekaze' do
  use_frameworks!

  # Pods for Harekaze
    ## Swift 3 (stable)
  pod 'ObjectMapper', '2.0.0'
  pod 'Alamofire', '4.0.1'
  pod 'RealmSwift', '1.1.0'
  pod 'Kingfisher', '3.1.0'
  pod 'DropDown', '2'
  pod 'KeychainAccess', '3.0.0'
  pod ’SJSegmentedScrollView’, ‘1.2.1'
    ## Swift 3 (beta)
  pod 'Material', :git => 'https://github.com/CosmicMind/Material', :commit => '01df8779d36de0277da57e64e0c6c662283dd1e3'
  pod 'APIKit', :git => 'https://github.com/ishkawa/APIKit', :tag => '3.0.0-beta.2'
  pod 'ARNTransitionAnimator', :git => 'https://github.com/xxxAIRINxxx/ARNTransitionAnimator', :tag => '2.0.0'
  pod 'SpringIndicator', :git => 'https://github.com/KyoheiG3/SpringIndicator', :commit => 'd12c2727cb0b487cbe7460945be0aa596deb47a3'
  pod 'StatefulViewController', :git => 'https://github.com/aschuch/StatefulViewController', :commit => '9823aae66e7dc6c862a1365c68f46b5e5717811c'
  pod 'StretchHeader', :git => 'https://github.com/mzyy94/StretchHeader', :branch => 'swift3'
    ## Objective-C
  pod 'MobileVLCKit-prod', '2.7.9'
  pod 'Fabric', '1.6.8'
  pod 'Crashlytics', '3.8.2'
  pod '1PasswordExtension', '1.8.3'
  pod 'JTMaterialTransition', '1.0.5'
  pod 'CarbonKit', '2.1.8'
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
