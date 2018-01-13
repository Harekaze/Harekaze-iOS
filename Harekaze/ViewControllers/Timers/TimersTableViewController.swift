/**
 *
 * TimersTableViewController.swift
 * Harekaze
 * Created by Yuki MIZUNO on 2016/08/02.
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
import KOAlertController

class TimersTableViewController: CommonProgramTableViewController, UITableViewDelegate, UITableViewDataSource {

	// MARK: - Private instance fileds
	private var dataSource: Results<(Timer)>!

	// MARK: - View initialization

	override func viewDidLoad() {
		// Table
		self.tableView.register(UINib(nibName: "TimerItemTableViewCell", bundle: nil), forCellReuseIdentifier: "TimerItemCell")

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
		let predicate = NSPredicate(format: "startTime > %@", Date() as CVarArg)
		let realm = try! Realm()
		dataSource = realm.objects(Timer.self).filter(predicate).sorted(byKeyPath: "startTime", ascending: true)

		// Realm notification
		notificationToken = dataSource.observe(updateNotificationBlock())
	}

	// MARK: - Resource updater

	override func refreshDataSource() {
		let start = CFAbsoluteTimeGetCurrent()
		super.refreshDataSource()

		let request = ChinachuAPI.TimerRequest()
		Session.send(request) { result in
			switch result {
			case .success(let data):
				// Store timer list to realm
				DispatchQueue.global().async {
					let realm = try! Realm()
					try! realm.write {
						realm.add(data, update: true)
						let objectsToDelete = realm.objects(Timer.self).filter { data.index(of: $0) == nil }
						realm.delete(objectsToDelete)
					}
					let end = CFAbsoluteTimeGetCurrent()
					let wait = max(0.0, 3.0 - (end - start))
					DispatchQueue.main.asyncAfter(deadline: .now() + wait) {
						self.refresh.endRefreshing()
						UIApplication.shared.isNetworkActivityIndicatorVisible = false
						if data.isEmpty {
							self.endLoading()
						}
					}
				}

			case .failure(let error):
				Answers.logCustomEvent(withName: "Timer request failed", customAttributes: ["error": error as NSError, "file": #file, "function": #function, "line": #line])
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
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "TimerItemCell", for: indexPath) as? TimerItemTableViewCell else {
			return UITableViewCell()
		}

		let item = dataSource[indexPath.row]
		cell.setCellEntities(item, navigationController: self.navigationController)

		return cell
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return dataSource?.count ?? 0
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		guard let programDetailViewController = self.storyboard!.instantiateViewController(withIdentifier: "ProgramDetailTableViewController") as?
			ProgramDetailTableViewController else {
				return
		}

		programDetailViewController.program = dataSource[indexPath.row]

		self.navigationController?.pushViewController(programDetailViewController, animated: true)
	}

	func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		let timer = dataSource[indexPath.row]
		let action: UIContextualAction!
		if timer.manual {
			// Timer deletion
			action = UIContextualAction(style: .destructive,
												  title: "Delete",
												  handler: { (_: UIContextualAction, _: UIView, completion: @escaping (Bool) -> Void) in
													let confirmDialog = UIAlertController(title: "Delete timer?",
																						  message: "Are you sure you want to delete the timer \(timer.fullTitle)?",
														preferredStyle: .alert)
													let deleteAction = UIAlertAction(title: "DELETE", style: .destructive, handler: {_ in
														confirmDialog.dismiss(animated: true, completion: nil)
														UIApplication.shared.isNetworkActivityIndicatorVisible = true
														let request = ChinachuAPI.TimerDeleteRequest(id: timer.id)
														Session.send(request) { result in
															UIApplication.shared.isNetworkActivityIndicatorVisible = false
															switch result {
															case .success:
																let realm = try! Realm()
																try! realm.write {
																	realm.delete(timer)
																}
																completion(true)
															case .failure(let error):
																let alertController = KOAlertController("Delete timer failed", ChinachuAPI.parseErrorMessage(error))
																alertController.addAction(KOAlertButton(.default, title: "OK")) {}
																self.navigationController?.parent?.present(alertController, animated: false) {}
																completion(false)
															}
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
			action.image = #imageLiteral(resourceName: "trash")
		} else {
			// Timer skipping/un-skipping
			action = UIContextualAction(style: .normal,
												  title: "Skip",
												  handler: { (_: UIContextualAction, _: UIView, completion: @escaping (Bool) -> Void) in
													UIApplication.shared.isNetworkActivityIndicatorVisible = true
													if timer.skip {
														let request = ChinachuAPI.TimerUnskipRequest(id: timer.id)
														Session.send(request) { result in
															UIApplication.shared.isNetworkActivityIndicatorVisible = false
															switch result {
															case .success:
																let realm = try! Realm()
																try! realm.write {
																	timer.skip = false
																}
																completion(true)
															case .failure(let error):
																let alertController = KOAlertController("Unskip timer failed", ChinachuAPI.parseErrorMessage(error))
																alertController.addAction(KOAlertButton(.default, title: "OK")) {}
																self.navigationController?.parent?.present(alertController, animated: false) {}
																completion(false)
															}
														}
													} else {
														let request = ChinachuAPI.TimerSkipRequest(id: timer.id)
														Session.send(request) { result in
															UIApplication.shared.isNetworkActivityIndicatorVisible = false
															switch result {
															case .success:
																let realm = try! Realm()
																try! realm.write {
																	timer.skip = true
																}
																completion(true)
															case .failure(let error):
																let alertController = KOAlertController("Skip timer failed", ChinachuAPI.parseErrorMessage(error))
																alertController.addAction(KOAlertButton(.default, title: "OK")) {}
																self.navigationController?.parent?.present(alertController, animated: false) {}
																completion(false)
															}
														}
													}
			})
			if timer.skip {
				action.image = #imageLiteral(resourceName: "plus")
				action.backgroundColor = UIColor(red: 130/255, green: 177/255, blue: 255/255, alpha: 1)
			} else {
				action.image = #imageLiteral(resourceName: "minus")
				action.backgroundColor = UIColor(red: 255/255, green: 138/255, blue: 128/255, alpha: 1)
			}
		}
		return UISwipeActionsConfiguration(actions: [action])
	}
}
