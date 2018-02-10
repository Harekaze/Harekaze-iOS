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
import RealmSwift
import Crashlytics
import FileKit
import StatusAlert
import Kingfisher
import CoreSpotlight

class DownloadsTableViewController: MasterProgramTableViewController {

	// MARK: - Private instance fileds
	private var dataSource: Results<(Download)>!

	// MARK: - View initialization

	override func viewDidLoad() {
		// On-filesystem persistent realm store
		let config = Realm.configuration(class: Download.self)

		// Delete uncompleted download program from realm
		let realm = try! Realm(configuration: config)
		let downloadUncompleted = realm.objects(Download.self).filter { $0.size == 0 && DownloadManager.shared.progressRequest($0.recording!.id) == nil}
		if !downloadUncompleted.isEmpty {
			try! realm.write {
				realm.delete(downloadUncompleted)
			}
		}

		// Table
		self.tableView.register(UINib(nibName: "DownloadItemTableViewCell", bundle: nil), forCellReuseIdentifier: "DownloadItemCell")

		super.viewDidLoad()

		self.tableView.headRefreshControl = nil

		// Load downloaded program list from realm
		dataSource = realm.objects(Download.self)

		// Realm notification
		notificationToken = dataSource.observe(updateNotificationBlock())
	}

	// MARK: - Resource updater / metadata recovery

	override func refreshDataSource() {
		startLoading()

		// File metadata recovery
		let config = Realm.configuration(class: Download.self)

		do {
			let realm = try Realm(configuration: config)
			let contents = Path.userDocuments.find(searchDepth: 1) {path in path.isRegular}
			for item in contents {
				let metadataExists = !realm.objects(Download.self).filter { $0.id == item.fileName }.isEmpty
				if item.exists && !metadataExists {
					// Receive metadata from server
					let request = ChinachuAPI.RecordingDetailRequest(id: item.fileName)
					Session.sendIndicatable(request) { result in
						switch result {
						case .success(let data):
							let download = Download()
							try! realm.write {
								download.id = item.fileName
								download.recording = realm.create(Recording.self, value: data, update: true)
								download.size = Int64(item.fileSize ?? 0)
								realm.add(download, update: true)
							}
						case .failure(let error):
							StatusAlert.instantiate(withImage: #imageLiteral(resourceName: "error"),
													title: "Receiving metadata failed",
													message: ChinachuAPI.parseErrorMessage(error),
													canBePickedOrDismissed: false).showInKeyWindow()
							Answers.logCustomEvent(withName: "Receiving metadata failed",
													customAttributes: ["error": error, "message": ChinachuAPI.parseErrorMessage(error)])
						}
					}
				}
			}
		} catch let error as NSError {
			StatusAlert.instantiate(withImage: #imageLiteral(resourceName: "error"),
									title: "Metadata recovery failed",
									message: error.localizedDescription,
									canBePickedOrDismissed: false).showInKeyWindow()
			Answers.logCustomEvent(withName: "Metadata recovery failed", customAttributes: ["error": error])
		}
		endLoading()
	}

	// MARK: - Table view data source

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "DownloadItemCell", for: indexPath) as? DownloadItemTableViewCell else {
			return UITableViewCell()
		}

		let item = dataSource[indexPath.row]
		cell.setCellEntities(download: item)

		return cell
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return dataSource?.count ?? 0
	}

	override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
		let download = dataSource[indexPath.row]
		if download.size == 0 {
			return nil
		}
		return indexPath
	}

	override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		let download = dataSource[indexPath.row]
		if download.size == 0 {
			return nil
		}
		let deleteAction = UIContextualAction(style: .destructive,
											  title: "Delete",
											  handler: { (_: UIContextualAction, _: UIView, completion: @escaping (Bool) -> Void) in
												let confirmDialog = AlertController("Delete downloaded program?",
																					  "Are you sure you want to delete downloaded program \(download.recording!.program!.fullTitle)?")
												confirmDialog.addAction(AlertButton(.default, title: "DELETE")) {
													let filepath = Path.userDocuments + "\(download.recording!.id).m2ts"

													do {
														try filepath.deleteFile()
														// Realm configuration
														let config = Realm.configuration(class: Download.self)

														// Delete downloaded program from realm
														let realm = try! Realm(configuration: config)
														try! realm.write {
															realm.delete(download)
														}
														// Remove thumbnail from disk when it's not available on recording
														let predicate = NSPredicate(format: "id == %@", download.id)
														if try! Realm().objects(Recording.self).filter(predicate).first == nil {
															for row in 0..<5 {
																ImageCache.default.removeImage(forKey: "\(download.id)-\(row)")
															}
														}
														// Remove search index
														CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: ["\(download.id)-local"]) { error in
															if let error = error {
																Answers.logCustomEvent(withName: "CSSearchableIndex indexing failed", customAttributes: ["error": error])
															}
														}
														completion(true)
													} catch let error as NSError {
														Answers.logCustomEvent(withName: "Delete downloaded program error", customAttributes: ["error": error])

														StatusAlert.instantiate(withImage: #imageLiteral(resourceName: "error"),
																				title: "Delete downloaded program failed",
																				message: error.localizedDescription,
																				canBePickedOrDismissed: false).showInKeyWindow()
														completion(false)
													}
												}
												confirmDialog.addAction(AlertButton(.cancel, title: "CANCEL")) {
													completion(false)
												}
												confirmDialog.show()
		})
		deleteAction.image = #imageLiteral(resourceName: "trash")

		return UISwipeActionsConfiguration(actions: [deleteAction])
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: sender)
		guard let indexPath = tableView.indexPathForSelectedRow else {
			return
		}
		guard let programDetailViewController = segue.destination as? ProgramDetailTableViewController else {
			return
		}
		programDetailViewController.recording = dataSource[indexPath.row].recording
	}
}

// MARK: - 3D touch Peek and Pop delegate
extension DownloadsTableViewController {
	override func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
		if let indexPath = tableView.indexPathForRow(at: location) {
			let download = dataSource[indexPath.row]
			if download.size == 0 {
				return nil
			}
			previewContent = download
			return super.previewingContext(previewingContext, viewControllerForLocation: location)
		}
		return nil
	}
}
