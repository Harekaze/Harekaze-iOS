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
import RealmSwift
import Crashlytics
import StatusAlert

class TimersTableViewController: MasterProgramTableViewController {

	// MARK: - Private instance fileds
	private var dataSource: Results<(Timer)>! {
		return Timer.dataSource.filter(self.predicate)
	}

	// MARK: - View initialization

	override func viewDidLoad() {
		// Table
		self.tableView.register(UINib(nibName: "TimerItemTableViewCell", bundle: nil), forCellReuseIdentifier: "TimerItemCell")

		super.viewDidLoad()

		// Realm notification
		notificationToken = dataSource.observe(updateNotificationBlock())

		if dataSource.isEmpty {
			self.refreshDataSource()
		}
	}

	// MARK: - Resource updater

	override func refreshDataSource() {
		if isLoading == true {
			return
		}
		super.refreshDataSource()
		Timer.refresh(onSuccess: {
			self.tableView.headRefreshControl.endRefreshing()
			self.endLoading()
		}, onFailure: { error in
			Answers.logCustomEvent(withName: "Timer request failed", customAttributes: ["error": error])
			self.tableView.headRefreshControl.endRefreshing()
			self.endLoading(error: error)
		})
	}

	// MARK: - Table view data source

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "TimerItemCell", for: indexPath) as? TimerItemTableViewCell else {
			return UITableViewCell()
		}

		let item = dataSource[indexPath.row]
		cell.setCellEntities(timer: item)
		return cell
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return dataSource?.count ?? 0
	}

	override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		let timer = dataSource[indexPath.row]
		let action: UIContextualAction!
		if timer.manual {
			// Timer deletion
			action = UIContextualAction(style: .destructive,
												  title: "Delete",
												  handler: { (_: UIContextualAction, _: UIView, completion: @escaping (Bool) -> Void) in
													let confirmDialog = AlertController("Delete timer?",
																						  "Are you sure you want to delete the timer \(timer.program!.fullTitle)?")
													confirmDialog.addAction(AlertButton(.default, title: "DELETE")) {
														ChinachuAPI.TimerDeleteRequest(id: timer.id).send { result in
															switch result {
															case .success:
																let realm = try! Realm()
																try! realm.write {
																	realm.delete(timer)
																}
																completion(true)
															case .failure(let error):
																StatusAlert.instantiate(withImage: #imageLiteral(resourceName: "error"),
																						title: "Delete timer failed",
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
			action.backgroundColor = #colorLiteral(red: 1, green: 0.3569, blue: 0.3569, alpha: 1)
			action.image = #imageLiteral(resourceName: "trash")
		} else {
			// Timer skipping/un-skipping
			action = UIContextualAction(style: .normal,
												  title: "Skip",
												  handler: { (_: UIContextualAction, _: UIView, completion: @escaping (Bool) -> Void) in
													if timer.skip {
														ChinachuAPI.TimerUnskipRequest(id: timer.id).send { result in
															switch result {
															case .success:
																let realm = try! Realm()
																try! realm.write {
																	timer.skip = false
																}
																completion(true)
															case .failure(let error):
																StatusAlert.instantiate(withImage: #imageLiteral(resourceName: "error"),
																						title: "Unskip timer failed",
																						message: ChinachuAPI.parseErrorMessage(error),
																						canBePickedOrDismissed: false).showInKeyWindow()
																completion(false)
															}
														}
													} else {
														ChinachuAPI.TimerSkipRequest(id: timer.id).send { result in
															switch result {
															case .success:
																let realm = try! Realm()
																try! realm.write {
																	timer.skip = true
																}
																completion(true)
															case .failure(let error):
																StatusAlert.instantiate(withImage: #imageLiteral(resourceName: "error"),
																						title: "Skip timer failed",
																						message: ChinachuAPI.parseErrorMessage(error),
																						canBePickedOrDismissed: false).showInKeyWindow()
																completion(false)
															}
														}
													}
			})
			if timer.skip {
				action.image = #imageLiteral(resourceName: "plus")
				action.backgroundColor = #colorLiteral(red: 1, green: 0.5098, blue: 0.5098, alpha: 1)
			} else {
				action.image = #imageLiteral(resourceName: "minus")
				action.backgroundColor = #colorLiteral(red: 0.5098, green: 0.6314, blue: 1, alpha: 1)
			}
		}
		return UISwipeActionsConfiguration(actions: [action])
	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: sender)
		guard let programDetailViewController = segue.destination as? ProgramDetailTableViewController else {
			return
		}
		programDetailViewController.program = dataSource[self.indexPathForSelectedRow.row].program
	}

	override func searchDataSource(_ text: String) {
		if text.isEmpty {
			predicate = NSPredicate(value: true)
		} else {
			predicate = NSPredicate(format: "program.title CONTAINS[c] %@", text)
		}
		tableView.reloadData()
	}
}

// MARK: - 3D touch Peek and Pop delegate
extension TimersTableViewController {
	override func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
		if let indexPath = tableView.indexPathForRow(at: location) {
			previewContent = dataSource[indexPath.row]
			return super.previewingContext(previewingContext, viewControllerForLocation: location)
		}
		return nil
	}
}
