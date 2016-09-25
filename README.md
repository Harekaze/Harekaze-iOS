![Harekaze for iOS](.github/banner.png)

[![Travis](https://img.shields.io/travis/Harekaze/Harekaze-iOS.svg?maxAge=2592000&style=flat-square)](https://travis-ci.org/Harekaze/Harekaze-iOS)
[![GitHub issues](https://img.shields.io/github/issues/Harekaze/Harekaze-iOS.svg?style=flat-square)](https://github.com/Harekaze/Harekaze-iOS/issues)
[![GitHub forks](https://img.shields.io/github/forks/Harekaze/Harekaze-iOS.svg?style=flat-square)](https://github.com/Harekaze/Harekaze-iOS/network)
[![GitHub stars](https://img.shields.io/github/stars/Harekaze/Harekaze-iOS.svg?style=flat-square)](https://github.com/Harekaze/Harekaze-iOS/stargazers)
[![GitHub license](https://img.shields.io/badge/license-New%20BSD-blue.svg?style=flat-square)](https://raw.githubusercontent.com/Harekaze/Harekaze-iOS/master/LICENSE.md)
[![Swift 2.2](https://img.shields.io/badge/swift-2.2-orange.svg?style=flat-square)](https://developer.apple.com/swift/)
[![Platform iOS](https://img.shields.io/badge/platform-ios-lightgrey.svg?style=flat-square)](https://developer.apple.com/ios/)
[![Twitter @HarekazeApp](https://img.shields.io/badge/twitter-@HarekazeApp-1FB7F7.svg?style=flat-square)](https://twitter.com/HarekazeApp)

A mobile app for Japanese PVR service.

## Description
わたし岬明乃!ブルーマーメイドを目指して海洋学校に入学したけど、初の実習でクラスのみんなが暇つぶしに困ってるの!
艦長として晴風のみんなの願いを叶えたい!! Harekaze for iOS、オープンソースで公開! 

## Features
- [x] Playback recoding videos
- [x] AirPlay support
- [x] Search videos 
- [x] Timer control
- [x] Transcoding playback
- [x] Download recodings

and more... 


## Build
### Requirement
- [CocoaPods](https://cocoapods.org)
- [Fabric](https://get.fabric.io/)

### Enviromnent
- Xcode 8.0
- Swift 3.0
- Cocoapods 1.1.0.rc.2

### Step
1. Install developer tools
2. Run `pod install` to install depended modules and to create workspace
3. Set secret keys to config files in .config directory
4. Open Harekaze.xcworkspace with Xcode
5. Build and run

> NOTE: If you want to test this app on physical device, you need to turn off **Enable Bitcode** option.
Open _Build Settings_ in Project and set the value **NO** to **Enable Bitcode** in _Build Options_.

## Usage
1. Run app

> MEMO: If you can't find PVR service, check your PVR service version and try upgrade.

## Contribution
Contribution guideline is comming soon...

## ChangeLog
See [ChangeLog.md](ChangeLog.md)

## LICENSE
[Modified BSD 3-clause License](LICENSE.md)
