/**
 *
 * TimersTableViewController.swift
 * Harekaze
 * Created by Yuki MIZUNO on 2016/08/02.
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
import APIKit
import CarbonKit
import StatefulViewController
import RealmSwift
import Crashlytics

class TimersTableViewController: CommonProgramTableViewController, UITableViewDelegate, UITableViewDataSource {

	// MARK: - Private instance fileds
	fileprivate var dataSource: Results<(Timer)>!

	// MARK: - View initialization

	override func viewDidLoad() {
		// Table
		self.tableView.register(UINib(nibName: "TimerItemMaterialTableViewCell", bundle: nil), forCellReuseIdentifier: "TimerItemCell")

		super.viewDidLoad()

		// Set empty view message
		if let emptyView = emptyView as? EmptyDataView {
			emptyView.messageLabel.text = "You have no timers"
		}

		// Refresh data stored list
		refreshDataSource()

		// Setup initial view state
		setupInitialViewState()

		// Load timer list to realm
		let predicate = NSPredicate(format: "startTime > %@", Date(timeIntervalSinceNow: 0) as CVarArg)
		let realm = try! Realm()
		dataSource = realm.objects(Timer).filter(predicate).sorted("startTime", ascending: true)

		// Realm notification
		notificationToken = dataSource.addNotificationBlock(updateNotificationBlock())
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		// Set navigation title
		if let bottomNavigationController = self.navigationController!.viewControllers.first as? BottomNavigationController {
			bottomNavigationController.navigationItem.title = "Timers"
		}
	}

	// MARK: - Resource updater

	override func refreshDataSource() {
		super.refreshDataSource()

		let request = ChinachuAPI.TimerRequest()
		Session.sendRequest(request) { result in
			switch result {
			case .Success(let data):
				// Store timer list to realm
				dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
					let realm = try! Realm()
					try! realm.write {
						realm.add(data, update: true)
						let objectsToDelete = realm.objects(Timer).filter { data.indexOf($0) == nil }
						realm.delete(objectsToDelete)
					}
					dispatch_async(dispatch_get_main_queue()) {
						self.refresh.endRefreshing()
						UIApplication.sharedApplication().networkActivityIndicatorVisible = false
						if data.count == 0 {
							self.endLoading()
						}
					}
				}

			case .Failure(let error):
				Answers.logCustomEventWithName("Timer request failed", customAttributes: ["error": error as NSError, "file": #file, "function": #function, "line": #line])
				if let errorView = self.errorView as? EmptyDataView {
					errorView.messageLabel.text = ChinachuAPI.parseErrorMessage(error)
				}
				self.refresh.endRefreshing()
				self.endLoading(error: error)
				UIApplication.sharedApplication().networkActivityIndicatorVisible = false
			}
		}
	}

	// MARK: - Table view data source

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell: TimerItemMaterialTableViewCell = tableView.dequeueReusableCell(withIdentifier: "TimerItemCell", for: indexPath) as! TimerItemMaterialTableViewCell

		let item = dataSource[indexPath.row]
		cell.setCellEntities(item, navigationController: self.navigationController)

		return cell
	}


	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return dataSource?.count ?? 0
	}


	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let timerDetailViewController = self.storyboard!.instantiateViewController(withIdentifier: "TimerDetailTableViewController") as! TimerDetailTableViewController

		timerDetailViewController.timer = dataSource[indexPath.row]

		self.navigationController?.pushViewController(timerDetailViewController, animated: true)
	}
	
}
