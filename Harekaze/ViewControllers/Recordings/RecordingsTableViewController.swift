/**
 *
 * RecordingsTableViewController.swift
 * Harekaze
 * Created by Yuki MIZUNO on 2016/07/10.
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
import StatusAlert
import Kingfisher

class RecordingsTableViewController: MasterProgramTableViewController {

	// MARK: - Private instance fileds
	private var dataSource: Results<(Recording)>! {
		return Recording.dataSource
	}

	// MARK: - View initialization

	override func viewDidLoad() {
		super.viewDidLoad()

		// Table
		self.tableView.register(UINib(nibName: "ProgramItemTableViewCell", bundle: nil), forCellReuseIdentifier: "ProgramItemCell")

		// Realm notification
		notificationToken = dataSource.observe(updateNotificationBlock())

		if dataSource.isEmpty {
			self.refreshDataSource()
		}

		let settingsButton = UIBarButtonItem(image: #imageLiteral(resourceName: "settings"), style: .plain, target: self, action: #selector(showSettingsViewController))
		navigationItem.rightBarButtonItem = settingsButton
	}

	// MARK: - View transition

	@objc internal func showSettingsViewController() {
		guard let settingsNavigationController = storyboard?.instantiateViewController(withIdentifier: "SettingsNavigationController") else {
			return
		}
		self.present(settingsNavigationController, animated: true)
	}

	// MARK: - Resource updater

	override func refreshDataSource() {
		if isLoading == true {
			return
		}
		super.refreshDataSource()
		Recording.refresh(onSuccess: {
			self.tableView.headRefreshControl.endRefreshing()
			self.endLoading()
		}, onFailure: { error in
			Answers.logCustomEvent(withName: "Recording request failed", customAttributes: ["error": error])
			self.tableView.headRefreshControl.endRefreshing()
			self.endLoading(error: error)
		})

	}

	// MARK: - Table view data source

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "ProgramItemCell", for: indexPath) as? ProgramItemTableViewCell else {
			return UITableViewCell()
		}

		let item = dataSource[indexPath.row]
		cell.setCellEntities(recording: item)

		return cell
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return dataSource?.count ?? 0
	}

	override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		let recording = self.dataSource[indexPath.row]
		let deleteAction = UIContextualAction(style: .destructive,
											  title: "Delete",
											  handler: { (_: UIContextualAction, _: UIView, completion: @escaping (Bool) -> Void) in
												let confirmDialog = AlertController("Delete program?", "Are you sure you want to permanently delete the program \(recording.program!.fullTitle) immediately?")
												confirmDialog.addAction(AlertButton(.default, title: "DELETE")) {
													ChinachuAPI.DeleteProgramRequest(id: recording.id).send { result in
														switch result {
														case .success:
															// Remove thumbnail from disk when it's not downloaded
															let config = Realm.configuration(class: Download.self)
															let predicate = NSPredicate(format: "id == %@", recording.id)
															if try! Realm(configuration: config).objects(Download.self).filter(predicate).first == nil {
																for row in 0..<5 {
																	ImageCache.default.removeImage(forKey: "\(recording.id)-\(row)")
																}
															}
															let realm = try! Realm()
															try! realm.write {
																realm.delete(recording)
															}
															completion(true)
														case .failure(let error):
															StatusAlert.instantiate(withImage: #imageLiteral(resourceName: "error"),
																					title: "Delete program failed",
																					message: ChinachuAPI.parseErrorMessage(error),
																					canBePickedOrDismissed: false).showInKeyWindow()
															completion(false)
														}
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
		programDetailViewController.recording = dataSource[indexPath.row]
	}
}

// MARK: - 3D touch Peek and Pop delegate
extension RecordingsTableViewController {
	override func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
		if let indexPath = tableView.indexPathForRow(at: location) {
			previewContent = dataSource[indexPath.row]
			return super.previewingContext(previewingContext, viewControllerForLocation: location)
		}
		return nil
	}
}
