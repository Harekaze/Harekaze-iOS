/**
*
* ChinachuCodecSelectionViewController.swift
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

struct TranscodeOptionParameter {
	var text: String!
	var detail: String!
	var resolution: String!
	var bitrate: Int!
}

class ChinachuCodecSelectionViewController: MaterialContentAlertViewController, UITableViewDelegate, UITableViewDataSource {

	// MARK: - Instance fields
	var tableView: UITableView!
	var dataSource: [TranscodeOptionParameter] = []
	var mode: String!

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
		case "video":
			dataSource.append(TranscodeOptionParameter(text: "Full HD", detail: "H.264 1080p 3Mbps", resolution: "1920x1080", bitrate: 3192))
			dataSource.append(TranscodeOptionParameter(text: "HD", detail: "H.264 720p 1Mbps", resolution: "1280x720", bitrate: 1024))
			dataSource.append(TranscodeOptionParameter(text: "SD", detail: "H.264 480p 512kbps", resolution: "853x480", bitrate: 512))
		case "audio":
			dataSource.append(TranscodeOptionParameter(text: "High quality", detail: "AAC 192kbps", resolution: "", bitrate: 192))
			dataSource.append(TranscodeOptionParameter(text: "Middle quality", detail: "AAC 128kbps", resolution: "", bitrate: 128))
			dataSource.append(TranscodeOptionParameter(text: "Low quality", detail: "AAC 64kbps", resolution: "", bitrate: 64))
		default: break
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

		cell.titleLabel?.text = service.text
		cell.detailLabel?.text = service.detail
		cell.lockIcon = nil

		return cell
	}

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if indexPath.row == dataSource.count {
			return
		}
		switch mode {
		case "video":
			ChinachuAPI.videoBitrate = dataSource[indexPath.row].bitrate
			ChinachuAPI.videoResolution = dataSource[indexPath.row].resolution
		case "audio":
			ChinachuAPI.audioBitrate = dataSource[indexPath.row].bitrate
		default:
			break
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

	convenience init(title: String, mode: String) {
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
