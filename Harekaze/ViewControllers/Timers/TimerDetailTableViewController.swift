/**
*
* TimerDetailTableViewController.swift
* Harekaze
* Created by Yuki MIZUNO on 2016/08/14.
*
* Copyright (c) 2016-2017, Yuki MIZUNO
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

class TimerDetailTableViewController: UITableViewController, UIGestureRecognizerDelegate {

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
		self.tableView.tableFooterView?.backgroundColor = Material.Color.white

		// Set navigation title
		navigationItem.titleLabel.textAlignment = .left
		navigationItem.titleLabel.font = RobotoFont.medium(with: 20)
		navigationItem.titleLabel.textColor = Material.Color.white
		navigationItem.title = timer.fullTitle

		// Navigation buttons
		castButton = IconButton(image: UIImage(named: "ic_cast_white"))

		moreButton = IconButton(image: UIImage(named: "ic_more_vert_white"))
		moreButton.addTarget(self, action: #selector(handleMoreButton), for: .touchUpInside)

		navigationItem.rightViews = [castButton, moreButton]

		// DropDown menu
		dropDown = DropDown(anchorView: moreButton)
		dropDown.cellNib = UINib(nibName: "DropDownMaterialTableViewCell", bundle: nil)
		dropDown.transform = CGAffineTransform(translationX: -8, y: 0)
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
		self.tableView.register(UINib(nibName: "ProgramDetailInfoTableViewCell", bundle: nil), forCellReuseIdentifier: "ProgramDetailInfoCell")
		self.tableView.estimatedRowHeight = 48
		self.tableView.rowHeight = UITableViewAutomaticDimension
		self.tableView.reloadData()

		// Setup table view data source
		dataSource.append(["ic_description": { timer in timer.detail != "" ? timer.detail : " "}])
		dataSource.append(["ic_inbox": { timer in timer.genre.capitalized}])
		dataSource.append(["ic_schedule": { timer in
			let dateFormatter = DateFormatter()
			dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
			return dateFormatter.string(from: timer.startTime as Date)
			}]
		)
		if timer.episode > 0 {
			dataSource.append(["ic_subscriptions": { timer in "Episode \(timer.episode)"}])
		}
		dataSource.append(["ic_dvr": { timer in "\(timer.channel!.name) [\(timer.channel!.channel)]"}])
		dataSource.append(["ic_timer": { timer in "\(Int(timer.duration/Double(60))) min."}])
		dataSource.append(["ic_label": { timer in timer.id.uppercased()}])
		dataSource.append(["ic_video_label": { timer in timer.fullTitle}])
		if timer.manual {
			dataSource.append(["ic_fiber_manual_record": { _ in "Manual Recording"}])
		} else {
			dataSource.append(["ic_fiber_smart_record": { timer in "Smart Recording\(timer.skip ? " (Disabled)" : "")"}])
		}
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		// Disable navigation drawer
		navigationDrawerController?.isEnabled = false
	}

	// MARK: - View deinitialization

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		// Enable navigation drawer
		navigationDrawerController?.isEnabled = true
	}

	// MARK: - Event handler

	internal func handleMoreButton() {
		dropDown.show()
	}

	func confirmDeleteTimer() {
		let confirmDialog = MaterialAlertViewController(title: "Delete timer?",
		                                                message: "Are you sure you want to delete the timer \(timer.fullTitle)?",
														preferredStyle: .alert)
		let deleteAction = MaterialAlertAction(title: "DELETE", style: .destructive, handler: {_ in
			confirmDialog.dismiss(animated: true, completion: nil)
			UIApplication.shared.isNetworkActivityIndicatorVisible = true
			let request = ChinachuAPI.TimerDeleteRequest(id: self.timer.id)
			Session.send(request) { result in
				UIApplication.shared.isNetworkActivityIndicatorVisible = false
				switch result {
				case .success(_):
					let realm = try! Realm()
					try! realm.write {
						realm.delete(self.timer)
					}
					let _ = self.navigationController?.popViewController(animated: true)
				case .failure(let error):
					let dialog = MaterialAlertViewController.generateSimpleDialog("Delete timer failed", message: ChinachuAPI.parseErrorMessage(error))
					self.navigationController?.present(dialog, animated: true, completion: nil)
				}
			}

		})
		let cancelAction = MaterialAlertAction(title: "CANCEL", style: .cancel, handler: {_ in
			confirmDialog.dismiss(animated: true, completion: nil)
		})
		confirmDialog.addAction(cancelAction)
		confirmDialog.addAction(deleteAction)

		self.navigationController?.present(confirmDialog, animated: true, completion: nil)
	}

	// MARK: - UIGestureRecognizer delegate
	func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		// Enable swipe to pop view
		return true
	}

	// MARK: - Deinitialization

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	// MARK: - Memory/resource management

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	// MARK: - Table view data source

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return dataSource.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "ProgramDetailInfoCell", for: indexPath) as? ProgramDetailInfoTableViewCell else {
			return UITableViewCell()
		}
		let data = dataSource[(indexPath as NSIndexPath).row].first!
		cell.contentLabel.text = data.1(timer)
		cell.iconImageView.image = UIImage(named: data.0)
		return cell
	}

}
