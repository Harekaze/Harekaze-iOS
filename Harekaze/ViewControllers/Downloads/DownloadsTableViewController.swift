/**
*
* DownloadsTableViewController.swift
* Harekaze
* Created by Yuki MIZUNO on 2016/08/21.
*
* Copyright (c) 2016-2018, Yuki MIZUNO
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
import APIKit
import StatefulViewController
import RealmSwift
import Crashlytics
import FileKit
import KOAlertController

class DownloadsTableViewController: CommonProgramTableViewController, UITableViewDelegate, UITableViewDataSource {

	// MARK: - Private instance fileds
	private var dataSource: Results<(Download)>!

	// MARK: - View initialization

	override func viewDidLoad() {
		// On-filesystem persistent realm store
		let config = Realm.configuration(class: Download.self)

		// Delete uncompleted download program from realm
		let realm = try! Realm(configuration: config)
		let downloadUncompleted = realm.objects(Download.self).filter { $0.size == 0 && DownloadManager.shared.progressRequest($0.program!.id) == nil}
		if !downloadUncompleted.isEmpty {
			try! realm.write {
				realm.delete(downloadUncompleted)
			}
		}

		// Table
		self.tableView.register(UINib(nibName: "DownloadItemTableViewCell", bundle: nil), forCellReuseIdentifier: "DownloadItemCell")

		super.viewDidLoad()

		// Disable refresh control
		refresh.removeFromSuperview()
		refresh = nil

		// Set empty view message
		if let emptyView = emptyView as? EmptyDataView {
			emptyView.messageLabel.text = "You have no downloads"
		}

		// Load downloaded program list from realm
		dataSource = realm.objects(Download.self)

		// Realm notification
		notificationToken = dataSource.observe(updateNotificationBlock())

		// Setup initial view state
		setupInitialViewState()

	}

	// MARK: - Resource updater / metadata recovery

	override func refreshDataSource() {
		startLoading()

		// File metadata recovery
		let config = Realm.configuration(class: Download.self)

		do {
			let realm = try Realm(configuration: config)
			let contents = Path.userDocuments.find(searchDepth: 1) {path in path.isDirectory}
			for item in contents {
				let filepath = item + "file.m2ts"
				let metadataExists = !realm.objects(Download.self).filter { $0.id == item.fileName }.isEmpty
				if filepath.exists && !metadataExists {
					// Receive metadata from server
					let request = ChinachuAPI.RecordingDetailRequest(id: item.fileName)
					Session.send(request) { result in
						switch result {
						case .success(let data):
							let download = Download()
							try! realm.write {
								download.id = item.fileName
								download.program = realm.create(Program.self, value: data, update: true)
								download.size = filepath.attributes[FileAttributeKey.size] as? Int ?? 0
								realm.add(download, update: true)
							}
						case .failure(let error):
							let alertController = KOAlertController("Receiving metadatafailed", ChinachuAPI.parseErrorMessage(error))
							alertController.addAction(KOAlertButton(.default, title: "OK")) {}
							self.navigationController?.parent?.present(alertController, animated: false) {}
							Answers.logCustomEvent(withName: "Receiving metadata failed",
													customAttributes: ["error": error as NSError, "message": ChinachuAPI.parseErrorMessage(error)])
						}
					}
				}
			}
		} catch let error as NSError {
			let alertController = KOAlertController("Metadata recovery failed", error.localizedDescription)
			alertController.addAction(KOAlertButton(.default, title: "OK")) {}
			self.navigationController?.parent?.present(alertController, animated: false) {}

			Answers.logCustomEvent(withName: "Metadata recovery failed", customAttributes: ["error": error])
		}

		self.refresh.endRefreshing()
		endLoading()
	}

	// MARK: - Table view data source

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "DownloadItemCell", for: indexPath) as? DownloadItemTableViewCell else {
			return UITableViewCell()
		}

		let item = dataSource[indexPath.row]
		cell.setCellEntities(download: item, navigationController: self.navigationController!)

		return cell
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return dataSource?.count ?? 0
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		if dataSource[indexPath.row].size == 0 {
			return
		}
		guard let programDetailViewController = self.storyboard!.instantiateViewController(withIdentifier: "ProgramDetailTableViewController") as?
			ProgramDetailTableViewController else {
			return
		}

		programDetailViewController.program = dataSource[indexPath.row].program

		self.navigationController?.pushViewController(programDetailViewController, animated: true)
	}

	func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		let download = dataSource[indexPath.row]
		let deleteAction = UIContextualAction(style: .destructive,
											  title: "Delete",
											  handler: { (_: UIContextualAction, _: UIView, completion: @escaping (Bool) -> Void) in
												let confirmDialog = UIAlertController(title: "Delete downloaded program?",
																					  message: "Are you sure you want to delete downloaded program \(download.program!.fullTitle)?",
													preferredStyle: .alert)
												let deleteAction = UIAlertAction(title: "DELETE", style: .destructive, handler: {_ in
													confirmDialog.dismiss(animated: true, completion: nil)

													let filepath = Path.userDocuments + download.program!.id + "file.m2ts"

													do {
														try filepath.deleteFile()
														// Realm configuration
														let config = Realm.configuration(class: Download.self)

														// Delete downloaded program from realm
														let realm = try! Realm(configuration: config)
														try! realm.write {
															realm.delete(download)
														}
														completion(true)
													} catch let error as NSError {
														Answers.logCustomEvent(withName: "Delete downloaded program error", customAttributes: ["error": error])

														let alertController = KOAlertController("Delete downloaded program failed", error.localizedDescription)
														alertController.addAction(KOAlertButton(.default, title: "OK")) {}
														self.navigationController?.parent?.present(alertController, animated: false) {}
														completion(false)
													}
												})
												let cancelAction = UIAlertAction(title: "CANCEL", style: .cancel, handler: {_ in
													confirmDialog.dismiss(animated: true, completion: nil)
													completion(false)
												})
												confirmDialog.addAction(cancelAction)
												confirmDialog.addAction(deleteAction)
												self.navigationController?.present(confirmDialog, animated: true, completion: nil)
		})
		deleteAction.image = #imageLiteral(resourceName: "trash")

		return UISwipeActionsConfiguration(actions: [deleteAction])
	}
}
