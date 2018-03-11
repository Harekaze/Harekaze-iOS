platform :ios, '11.0'

target 'Harekaze' do
  use_frameworks!

  # Pods for Harekaze
  pod 'ObjectMapper', '3.1.0'
  pod 'Alamofire', '4.7.0'
  pod 'RealmSwift', '3.1.1'
  pod 'Kingfisher', '4.6.3'
  pod 'SpringIndicator', '3.0.0'
  pod 'APIKit', '3.2.1'
  pod 'Hero', '1.1.0'
  pod 'SwiftDate', '4.5.1'
  pod 'FileKit', '5.0.0'
  pod 'SwiftyUserDefaults', '3.0.1'
  pod 'MobileVLCKit-custom', :podspec => 'MobileVLCKit-custom.podspec'
  pod 'Fabric', '1.7.5'
  pod 'Crashlytics', '3.10.1'
  pod 'G3GridView', '0.4.0'
  pod 'LicensePlist', '1.8.3'
  pod 'KafkaRefresh', '1.0.0'
  pod 'KOAlertController', '1.0.2'
  pod 'iTunesSearchAPI', '0.4.1'
  pod 'InAppSettingsKit', '2.9'
  pod 'FTLinearActivityIndicator', '1.0.4'
  pod 'StatusAlert', '0.10.1'
  pod 'Sparrow/LaunchAnimation', :git => 'https://github.com/IvanVorobei/Sparrow.git', :commit => 'd3becbdd5d'
  pod 'NFDownloadButton', '0.0.3'
  pod 'DZNEmptyDataSet', '1.8.1'
  pod 'AppVersionMonitor', '1.3.1'
  pod 'TransitionableTab', '0.1.2'
  pod 'PKHUD', '5.0'
  pod 'Dropdowns', '2.0.0'

  # devtools
  pod 'SwiftLint', '0.25.0'

  post_install do | installer |
    system("Pods/LicensePlist/license-plist --output-path Harekaze/Settings.bundle")

    installer.pods_project.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '4.0'
    end

    installer.pods_project.targets.each do |target|
      if ['G3GridView'].include? target.name
        target.build_configurations.each do |config|
          config.build_settings['SWIFT_VERSION'] = '3.0'
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
