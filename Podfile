platform :ios, '11.0'

target 'Harekaze' do
  use_frameworks!

  # Pods for Harekaze
    ## Swift 3 and 4
  pod 'Material', '2.12.17'
  pod 'ObjectMapper', '3.1.0'
  pod 'Alamofire', '4.5.1'
  pod 'RealmSwift', '3.0.2'
  pod 'Kingfisher', '4.4.0'
  pod 'KeychainAccess', '3.1.0'
  pod 'SpringIndicator', '3.0.0'
  pod 'StatefulViewController', '3.0'
  pod 'APIKit', '3.1.1'
  pod 'Hero', '1.0.1'
  pod 'SwiftDate', '4.5.0'
  pod 'FileKit', '5.0.0'
  pod 'SwiftyUserDefaults', '3.0.0'
  pod 'MobileVLCKit-unstable', '3.0.0a50'
  pod 'Fabric', '1.7.2'
  pod 'Crashlytics', '3.9.3'
  pod '1PasswordExtension', '1.8.4'
  pod 'G3GridView', '0.4.0'
  pod 'LicensePlist', '1.8.2'
  pod 'KafkaRefresh', '0.8'
  pod 'KOAlertController', '1.0.1'
  pod 'iTunesSearchAPI', '0.4.1'
  pod 'InAppSettingsKit', '2.9'

  # devtools
  pod 'SwiftLint', '0.24.0'

  post_install do | installer |
    system("Pods/LicensePlist/license-plist --output-path Harekaze/Settings.bundle")

    installer.pods_project.build_configurations.each do |config|
        config.build_settings['SWIFT_VERSION'] = '4.0'
    end

    installer.pods_project.targets.each do |target|
      if ['G3GridView'].include? target.name
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
