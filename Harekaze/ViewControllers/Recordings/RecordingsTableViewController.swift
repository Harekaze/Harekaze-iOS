/**
 *
 * RecordingsTableViewController.swift
 * Harekaze
 * Created by Yuki MIZUNO on 2016/07/10.
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
import CoreSpotlight
import MobileCoreServices

class RecordingsTableViewController: CommonProgramTableViewController, UITableViewDelegate, UITableViewDataSource {

	// MARK: - Private instance fileds
	fileprivate var dataSource: Results<(Program)>!

	// MARK: - View initialization

	override func viewDidLoad() {
		// Table
		self.tableView.register(UINib(nibName: "ProgramItemMaterialTableViewCell", bundle: nil), forCellReuseIdentifier: "ProgramItemCell")

		super.viewDidLoad()

		// Set empty view message
		if let emptyView = emptyView as? EmptyDataView {
			emptyView.messageLabel.text = "You have no recordings"
		}

		// Refresh data stored list
		refreshDataSource()

		// Setup initial view state
		setupInitialViewState()

		// Load recording program list to realm
		let realm = try! Realm()
		dataSource = realm.objects(Program.self).sorted(byProperty: "startTime", ascending: false)

		// Realm notification
		notificationToken = dataSource.addNotificationBlock(updateNotificationBlock())
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		// Set navigation title
		if let bottomNavigationController = self.navigationController!.viewControllers.first as? BottomNavigationController {
			bottomNavigationController.navigationItem.title = "Recordings"
		}
	}

	// MARK: - Resource updater

	override func refreshDataSource() {
		super.refreshDataSource()

		let request = ChinachuAPI.RecordingRequest()
		Session.send(request) { result in
			switch result {
			case .success(let data):
				// Store recording program list to realm and spotlight
				DispatchQueue.global().async {

					// Add Spotlight search index
					var searchIndex: [CSSearchableItem] = []
					for content in data {
						let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
						attributeSet.title = content.title
						attributeSet.contentDescription = content.detail
						attributeSet.addedDate = content.startTime
						attributeSet.duration = content.duration as NSNumber?
						let item = CSSearchableItem(uniqueIdentifier: content.id, domainIdentifier: "recordings", attributeSet: attributeSet)
						searchIndex.append(item)
					}

					CSSearchableIndex.default().deleteAllSearchableItems {error in
						CSSearchableIndex.default().indexSearchableItems(searchIndex) { error in
							if let error = error {
								Answers.logCustomEvent(withName: "CSSearchableIndex indexing failed", customAttributes: ["error": error as NSError, "file": #file, "function": #function, "line": #line])
							}
						}
					}

					// Add local in-memory realm store
					let realm = try! Realm()
					try! realm.write {
						realm.add(data, update: true)
						let objectsToDelete = realm.objects(Program.self).filter { data.index(of: $0) == nil }
						realm.delete(objectsToDelete)
					}

					DispatchQueue.main.async {
						self.refresh.endRefreshing()
						UIApplication.shared.isNetworkActivityIndicatorVisible = false
						if data.count == 0 {
							self.endLoading()
						}
					}
				}

			case .failure(let error):
				Answers.logCustomEvent(withName: "Recording request failed", customAttributes: ["error": error as NSError, "file": #file, "function": #function, "line": #line])
				if let errorView = self.errorView as? EmptyDataView {
					errorView.messageLabel.text = ChinachuAPI.parseErrorMessage(error)
				}
				self.refresh.endRefreshing()
				self.endLoading(error: error)
				UIApplication.shared.isNetworkActivityIndicatorVisible = false
			}
		}
	}

	// MARK: - Table view data source

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell: ProgramItemMaterialTableViewCell = tableView.dequeueReusableCell(withIdentifier: "ProgramItemCell", for: indexPath) as! ProgramItemMaterialTableViewCell

		let item = dataSource[indexPath.row]
		cell.setCellEntities(item, navigationController: self.navigationController)

		return cell
	}


	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return dataSource?.count ?? 0
	}


	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let programDetailViewController = self.storyboard!.instantiateViewController(withIdentifier: "ProgramDetailTableViewController") as! ProgramDetailTableViewController

		programDetailViewController.program = dataSource[indexPath.row]

		self.navigationController?.pushViewController(programDetailViewController, animated: true)
	}

}
