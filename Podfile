platform :ios, '11.0'

target 'Harekaze' do
  use_frameworks!

  # Pods for Harekaze
    ## Swift 3 and 4
  pod 'Material', '2.12.10'
  pod 'ObjectMapper', '3.0.0'
  pod 'Alamofire', '4.5.1'
  pod 'RealmSwift', '3.0.1'
  pod 'Kingfisher', '4.2.0'
  pod 'DropDown', '2'
  pod 'KeychainAccess', '3.1.0'
  pod 'SJSegmentedScrollView', '1.3.8'
  pod 'ARNTransitionAnimator', '3.0.1'
  pod 'SpringIndicator', '3.0.0'
  pod 'StatefulViewController', '3.0'
  pod 'APIKit', '3.1.1'
  pod 'StretchHeader', '1.1.0'
  pod 'Hero', '1.0.0'
  pod 'SwiftDate', '4.4.2'
  pod 'FileKit', '5.0.0'
  pod 'SwiftyUserDefaults', '3.0.0'
    ## Objective-C
  pod 'MobileVLCKit-unstable', '3.0.0a43'
  pod 'Fabric', '1.7.1'
  pod 'Crashlytics', '3.9.0'
  pod '1PasswordExtension', '1.8.4'
  pod 'CarbonKit', '2.2.2'
  pod 'DRCellSlideGestureRecognizer', '1.0.0'
    ## Swift 2.x
  # pod 'EECellSwipeGestureRecognizer', '1.0.1'

  # devtools
  pod 'SwiftLint', '0.23.1'

  post_install do | installer |
    require 'fileutils'
    FileUtils.cp_r('Pods/Target Support Files/Pods-Harekaze/Pods-Harekaze-acknowledgements.plist', 'Harekaze/Settings.bundle/Acknowledgements.plist', :remove_destination => true)

    installer.pods_project.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '4.0'
    end

    installer.pods_project.targets.each do |target|
      if ['DropDown'].include? target.name
        target.build_configurations.each do |config|
          config.build_settings['SWIFT_VERSION'] = '3.2'
        end
      else
        target.build_configurations.each do |config|
          config.build_settings.delete('SWIFT_VERSION')
        end
      end
    end
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
