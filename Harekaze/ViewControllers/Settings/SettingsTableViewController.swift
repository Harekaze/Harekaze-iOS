/**
*
* SettingsTableViewController.swift
* Harekaze
* Created by Yuki MIZUNO on 2018/01/13.
*
* Copyright (c) 2016-2018, Yuki MIZUNO
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice,
*	this list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice,
*	this list of conditions and the following disclaimer in the documentation
*	 and/or other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors
*	may be used to endorse or promote products derived from this software
*	without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
* AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
* IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
* ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
* LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
* CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
* SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
* INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
* CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
* THE POSSIBILITY OF SUCH DAMAGE.
*/

import UIKit
import InAppSettingsKit
import SwiftyUserDefaults

// MARK: - UserDefaults keys

extension DefaultsKeys {
	static let oneFingerHorizontalSwipeMode = DefaultsKey<String>("HorizontalSwipeAction")
	static let resumeFromLastPlayedDownloaded = DefaultsKey<Bool>("ResumeFromLastPlayedDownloaded")
}

class SettingsTableViewController: IASKAppSettingsViewController, IASKSettingsDelegate {

	// MARK: - View initialization

	override func viewDidLoad() {
		super.viewDidLoad()
		self.delegate = self
		NotificationCenter.default.addObserver(self, selector: #selector(SettingsTableViewController.settingDidChange(_:)), name: NSNotification.Name(rawValue: kIASKAppSettingChanged), object: nil)
		UISwitch.appearance().tintColor = UIColor(red: 0.05, green: 0.51, blue: 0.96, alpha: 1.0)
		UISwitch.appearance().onTintColor = UIColor(red: 0.05, green: 0.51, blue: 0.96, alpha: 1.0)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if Defaults[.transcode] {
			self.setHiddenKeys(nil, animated: true)
		} else {
			self.setHiddenKeys(["TranscodeQuality"], animated: true)
		}
		Defaults.set(ChinachuAPI.password, forKey: "ChinachuWUIPassword")
	}

	// MARK: - InAppSettingViewController delegate

	func settingsViewControllerDidEnd(_ sender: IASKAppSettingsViewController!) {
		sender.presentingViewController?.dismiss(animated: true, completion: nil)
		ChinachuAPI.password = Defaults.string(forKey: "ChinachuWUIPassword") ?? ""
		Defaults.set(Defaults[.username].isEmpty ? "" : "********", forKey: "ChinachuWUIPassword")
		switch Defaults.string(forKey: "TranscodeQuality") ?? "" {
		case "high":
			ChinachuAPI.Config[.videoResolution] = "1920x1080"
			ChinachuAPI.Config[.videoBitrate] = 3192
			ChinachuAPI.Config[.audioBitrate] = 256
		case "mid":
			ChinachuAPI.Config[.videoResolution] = "1280x720"
			ChinachuAPI.Config[.videoBitrate] = 1024
			ChinachuAPI.Config[.audioBitrate] = 128
		case "low":
			ChinachuAPI.Config[.videoResolution] = "853x480"
			ChinachuAPI.Config[.videoBitrate] = 512
			ChinachuAPI.Config[.audioBitrate] = 64
		default:
			ChinachuAPI.Config[.videoResolution] = "1280x720"
			ChinachuAPI.Config[.videoBitrate] = 1024
			ChinachuAPI.Config[.audioBitrate] = 128
		}
		Defaults[.resumeFromLastPlayedDownloaded] = Defaults.string(forKey: "ResumeFrom") == "last"
	}

	func settingsViewController(_ sender: IASKAppSettingsViewController!, titlesFor specifier: IASKSpecifier!) -> [Any]! {
		return []
	}

	func tableView(_ tableView: UITableView!, cellFor specifier: IASKSpecifier!) -> UITableViewCell! {
		return IASKPSTextFieldSpecifierViewCell()
	}

	// MARK: - kIASKAppSettingChanged notification

	@objc func settingDidChange(_ notification: Notification!) {
		guard let settingsTableViewController = notification.object as? SettingsTableViewController else {
			return
		}
		guard let newValue = notification.userInfo as? [String: Any] else {
			return
		}
		if newValue.isEmpty {
			return
		}
		switch newValue.first!.key {
		case "PlaybackTranscoding":
			let transcoding = newValue.first!.value as? Bool ?? false
			if transcoding {
				settingsTableViewController.setHiddenKeys(nil, animated: true)
			} else {
				settingsTableViewController.setHiddenKeys(["TranscodeQuality"], animated: true)
			}
		default:
			return
		}
	}
}
