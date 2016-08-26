![Harekaze for iOS](.github/banner.png)

[![GitHub issues](https://img.shields.io/github/issues/Harekaze/Harekaze-iOS.svg?style=flat-square)](https://github.com/Harekaze/Harekaze-iOS/issues)
[![GitHub forks](https://img.shields.io/github/forks/Harekaze/Harekaze-iOS.svg?style=flat-square)](https://github.com/Harekaze/Harekaze-iOS/network)
[![GitHub stars](https://img.shields.io/github/stars/Harekaze/Harekaze-iOS.svg?style=flat-square)](https://github.com/Harekaze/Harekaze-iOS/stargazers)
[![GitHub license](https://img.shields.io/badge/license-New%20BSD-blue.svg?style=flat-square)](https://raw.githubusercontent.com/Harekaze/Harekaze-iOS/master/LICENSE.md)

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
- Xcode 7.3
- Swift 2.2

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
