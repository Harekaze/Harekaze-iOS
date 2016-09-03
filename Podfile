platform :ios, '9.0'

target 'Harekaze' do
  use_frameworks!

  # Pods for Harekaze
  pod 'Material', '= 1.42.9'
  pod 'APIKit', '= 2.0.4'
  pod 'ObjectMapper', '= 1.4.0'
  pod 'RealmSwift', '= 1.0.2'
  pod 'StretchHeader',  '= 1.0.4'
  pod 'Kingfisher', '= 2.5.0'
  pod 'MobileVLCKit-prod', '= 2.7.9'
  pod 'CarbonKit', '= 2.1.8'
  pod 'StatefulViewController', '= 1.2'
  pod 'SpringIndicator', '= 1.2.1'
  pod 'JTMaterialTransition', '= 1.0.5'
  pod 'DropDown', '= 1.0.1'
  pod 'ARNTransitionAnimator', '= 1.1.0'
  pod 'EECellSwipeGestureRecognizer', '= 1.0.1'
  pod 'Fabric', '= 1.6.8'
  pod 'Crashlytics', '= 3.8.0'
  pod 'KeychainAccess', '= 2.3.6'
  pod '1PasswordExtension', '= 1.8.3'
  pod 'Alamofire', '= 3.4.2'

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
