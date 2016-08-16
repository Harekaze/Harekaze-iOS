/**
*
* TimerDetailTableViewController.swift
* Harekaze
* Created by Yuki MIZUNO on 2016/08/14.
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
import DropDown
import APIKit
import RealmSwift

class TimerDetailTableViewController: UITableViewController, UIViewControllerTransitioningDelegate, UIGestureRecognizerDelegate {

	// MARK: - Instance fileds

	var timer: Timer! = nil
	var castButton: IconButton!
	var moreButton: IconButton!
	var dropDown: DropDown!
	var dataSource: [[String: (Timer) -> String]] = []

	// MARK: - View initialization

	override func viewDidLoad() {
		super.viewDidLoad()
		self.extendedLayoutIncludesOpaqueBars = false
		self.navigationController?.interactivePopGestureRecognizer?.delegate = self

		self.tableView.tableFooterView = UIView()
		self.tableView.tableFooterView?.backgroundColor = MaterialColor.white

		// Set navigation title
		navigationItem.titleLabel.textAlignment = .Left
		navigationItem.titleLabel.font = RobotoFont.mediumWithSize(20)
		navigationItem.titleLabel.textColor = MaterialColor.white
		navigationItem.title = timer.fullTitle

		// Navigation buttons
		castButton = IconButton()
		castButton.setImage(UIImage(named: "ic_cast_white"), forState: .Normal)
		castButton.setImage(UIImage(named: "ic_cast_white"), forState: .Highlighted)

		moreButton = IconButton()
		moreButton.setImage(UIImage(named: "ic_more_vert_white"), forState: .Normal)
		moreButton.setImage(UIImage(named: "ic_more_vert_white"), forState: .Highlighted)
		moreButton.addTarget(self, action: #selector(handleMoreButton), forControlEvents: .TouchUpInside)

		navigationItem.rightControls = [castButton, moreButton]

		// DropDown menu
		dropDown = DropDown()
		// DropDown appearance configuration
		dropDown.backgroundColor = UIColor.whiteColor()
		dropDown.cellHeight = 48
		dropDown.textFont = RobotoFont.regularWithSize(16)
		dropDown.cornerRadius = 2.0
		dropDown.direction = .Bottom
		dropDown.animationduration = 0.2
		dropDown.width = 56 * 3
		dropDown.anchorView = moreButton
		dropDown.cellNib = UINib(nibName: "DropDownMaterialTableViewCell", bundle: nil)
		dropDown.transform = CGAffineTransformMakeTranslation(-8, 0)
		dropDown.selectionAction = { (index, content) in
			switch content {
			case "Delete":
				self.confirmDeleteTimer()
			default:
				break
			}
		}
		dropDown.dataSource = ["Share"]
		if timer.manual {
			dropDown.dataSource.append("Delete")
		}

		// Setup table view
		self.tableView.delegate = self
		self.tableView.dataSource = self
		self.tableView.registerNib(UINib(nibName: "ProgramDetailInfoTableViewCell", bundle: nil), forCellReuseIdentifier: "ProgramDetailInfoCell")
		self.tableView.estimatedRowHeight = 48
		self.tableView.rowHeight = UITableViewAutomaticDimension
		self.tableView.reloadData()

		// Setup table view data source
		dataSource.append(["ic_description": { timer in timer.detail != "" ? timer.detail : " "}])
		dataSource.append(["ic_inbox": { timer in timer.genre.capitalizedString}])
		dataSource.append(["ic_schedule": { timer in
			let dateFormatter = NSDateFormatter()
			dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
			return dateFormatter.stringFromDate(timer.startTime)
			}]
		)
		if timer.episode > 0 {
			dataSource.append(["ic_subscriptions": { timer in "Episode \(timer.episode)"}])
		}
		dataSource.append(["ic_dvr": { timer in "\(timer.channel!.name) [\(timer.channel!.channel)]"}])
		dataSource.append(["ic_timer": { timer in "\(Int(timer.duration/60)) min."}])
		dataSource.append(["ic_label": { timer in timer.id.uppercaseString}])
		dataSource.append(["ic_video_label": { timer in timer.fullTitle}])
		if timer.manual {
			dataSource.append(["ic_fiber_manual_record": { _ in "Manual Recording"}])
		} else {
			dataSource.append(["ic_fiber_smart_record": { timer in "Smart Recording\(timer.skip ? " (Disabled)" : "")"}])
		}
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		// Disable navigation drawer
		navigationDrawerController?.enabled = false
	}


	// MARK: - View deinitialization

	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		// Enable navigation drawer
		navigationDrawerController?.enabled = true
	}

	// MARK: - Event handler

	internal func handleMoreButton() {
		dropDown.show()
	}

	func confirmDeleteTimer() {
		let confirmDialog = MaterialAlertViewController(title: "Delete timer?", message: "Are you sure you want to delete the timer \(timer.fullTitle)?", preferredStyle: .Alert)
		let deleteAction = MaterialAlertAction(title: "DELETE", style: .Destructive, handler: {(action: MaterialAlertAction!) -> Void in
			confirmDialog.dismissViewControllerAnimated(true, completion: nil)
			UIApplication.sharedApplication().networkActivityIndicatorVisible = true
			let request = ChinachuAPI.TimerDeleteRequest(id: self.timer.id)
			Session.sendRequest(request) { result in
				UIApplication.sharedApplication().networkActivityIndicatorVisible = false
				switch result {
				case .Success(_):
					let realm = try! Realm()
					try! realm.write {
						realm.delete(self.timer)
					}
					self.navigationController?.popViewControllerAnimated(true)
				case .Failure(let error):
					let dialog = MaterialAlertViewController.generateSimpleDialog("Delete timer failed", message: ChinachuAPI.parseErrorMessage(error))
					self.navigationController?.presentViewController(dialog, animated: true, completion: nil)
				}
			}

		})
		let cancelAction = MaterialAlertAction(title: "CANCEL", style: .Cancel, handler: {(action: MaterialAlertAction!) in
			confirmDialog.dismissViewControllerAnimated(true, completion: nil)
		})
		confirmDialog.addAction(cancelAction)
		confirmDialog.addAction(deleteAction)

		self.navigationController?.presentViewController(confirmDialog, animated: true, completion: nil)
	}

	// MARK: - UIGestureRecognizer delegate
	func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
		// Enable swipe to pop view
		return true
	}

	// MARK: - Deinitialization
	
	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}


	// MARK: - Memory/resource management

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	// MARK: - Table view data source

	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return dataSource.count
	}

	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("ProgramDetailInfoCell", forIndexPath: indexPath) as! ProgramDetailInfoTableViewCell
		let data = dataSource[indexPath.row].first!
		cell.contentLabel.text = data.1(timer)
		cell.iconImageView.image = UIImage(named: data.0)
		return cell
	}
	
}
