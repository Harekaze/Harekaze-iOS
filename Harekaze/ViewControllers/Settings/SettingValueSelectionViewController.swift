/**
*
* SettingValueSelectionViewController.swift
* Harekaze
* Created by Yuki MIZUNO on 2016/08/16.
*
* Copyright (c) 2016, Yuki MIZUNO
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice,
*    this list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice,
*    this list of conditions and the following disclaimer in the documentation
*     and/or other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors
*    may be used to endorse or promote products derived from this software
*    without specific prior written permission.
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
import Material
import SpringIndicator

struct DataSourceItem {
	var title: String!
	var detail: String!
	var stringValue: String!
	var intValue: Int!
}

enum ValueSelectionMode {
	case VideoSize, VideoQuality, AudioQuality, OneFingerHorizontalSwipeMode
}

class SettingValueSelectionViewController: MaterialContentAlertViewController, UITableViewDelegate, UITableViewDataSource {

	// MARK: - Instance fields
	var tableView: UITableView!
	var dataSource: [DataSourceItem] = []
	var mode: ValueSelectionMode = .VideoSize

	// MARK: - View initialization
	override func viewDidLoad() {
		super.viewDidLoad()

		self.alertView.divider = true

		// Table view
		self.tableView.registerNib(UINib(nibName: "ChinachuWUIListTableViewCell", bundle: nil), forCellReuseIdentifier: "ChinachuWUIListTableViewCell")
		self.tableView.separatorInset = UIEdgeInsetsZero
		self.tableView.rowHeight = 72
		self.tableView.delegate = self
		self.tableView.dataSource = self
		self.tableView.backgroundColor = MaterialColor.clear

		switch mode {
		case .VideoSize:
			dataSource.append(DataSourceItem(title: "Full HD", detail: "1080p", stringValue: "1920x1080", intValue: 0))
			dataSource.append(DataSourceItem(title: "HD", detail: "720p", stringValue: "1280x720", intValue: 0))
			dataSource.append(DataSourceItem(title: "SD", detail: "480p", stringValue: "853x480", intValue: 0))
		case .VideoQuality:
			dataSource.append(DataSourceItem(title: "High quality", detail: "H.264 3Mbps", stringValue: "", intValue: 3192))
			dataSource.append(DataSourceItem(title: "Middle quality", detail: "H.264 1Mbps", stringValue: "", intValue: 1024))
			dataSource.append(DataSourceItem(title: "Low quality", detail: "H.264 512kbps", stringValue: "", intValue: 512))
		case .AudioQuality:
			dataSource.append(DataSourceItem(title: "High quality", detail: "AAC 192kbps", stringValue: "", intValue: 192))
			dataSource.append(DataSourceItem(title: "Middle quality", detail: "AAC 128kbps", stringValue: "", intValue: 128))
			dataSource.append(DataSourceItem(title: "Low quality", detail: "AAC 64kbps", stringValue: "", intValue: 64))
		case .OneFingerHorizontalSwipeMode:
			dataSource.append(DataSourceItem(title: "Change playback speed", detail: "Increase or decrease play rate", stringValue: "", intValue: 0))
			dataSource.append(DataSourceItem(title: "Seek +/- 30 seconds", detail: "30 seconds backward/forward skip", stringValue: "", intValue: 1))
			dataSource.append(DataSourceItem(title: "No action", detail: "No swipe gesture", stringValue: "", intValue: -1))
		}
		let constraint = NSLayoutConstraint(item: alertView, attribute: .Height, relatedBy: .LessThanOrEqual, toItem: nil, attribute: .Height, multiplier: 1, constant: 340)
		view.addConstraint(constraint)


	}

	// MARK: - Memory/resource management
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}


	// MARK: - Table view data source

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return dataSource.count
	}

	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}

	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 72
	}

	func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
		cell.separatorInset = UIEdgeInsetsZero
		cell.layoutMargins = UIEdgeInsetsZero
		cell.preservesSuperviewLayoutMargins = false
		cell.backgroundColor = MaterialColor.clear
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("ChinachuWUIListTableViewCell", forIndexPath: indexPath) as! ChinachuWUIListTableViewCell

		let service = dataSource[indexPath.row]

		cell.titleLabel?.text = service.title
		cell.detailLabel?.text = service.detail
		cell.lockIcon = nil

		return cell
	}

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if indexPath.row == dataSource.count {
			return
		}
		switch mode {
		case .VideoSize:
			ChinachuAPI.videoResolution = dataSource[indexPath.row].stringValue
		case .VideoQuality:
			ChinachuAPI.videoBitrate = dataSource[indexPath.row].intValue
		case .AudioQuality:
			ChinachuAPI.audioBitrate = dataSource[indexPath.row].intValue
		case .OneFingerHorizontalSwipeMode:
			let userDefaults = NSUserDefaults()
			userDefaults.setInteger(dataSource[indexPath.row].intValue, forKey: "OneFingerHorizontalSwipeMode")
			userDefaults.synchronize()
		}

		dismissViewControllerAnimated(true, completion: nil)

		guard let navigationController = presentingViewController as? NavigationController else {
			return
		}
		guard let settingsTableViewController = navigationController.viewControllers.first as? SettingsTableViewController else {
			return
		}
		settingsTableViewController.reloadSettingsValue()
	}

	// MARK: - Initialization

	override init() {
		super.init()
	}

	convenience init(title: String, mode: ValueSelectionMode) {
		self.init()
		_title = title
		self.mode = mode
		self.tableView = UITableView()
		self.contentView = self.tableView
		self.modalPresentationStyle = .OverCurrentContext
		self.modalTransitionStyle = .CrossDissolve
	}

	internal required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

}
