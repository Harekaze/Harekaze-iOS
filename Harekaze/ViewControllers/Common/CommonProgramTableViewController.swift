/**
*
* CommonProgramTableViewController.swift
* Harekaze
* Created by Yuki MIZUNO on 2016/08/11.
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
import KafkaRefresh
import RealmSwift
import Crashlytics

class CommonProgramTableViewController: UITableViewController {

	// MARK: - Instance fileds
	var notificationToken: NotificationToken?

	// MARK: - View initialization

	override func viewDidLoad() {
		super.viewDidLoad()
		self.navigationController?.navigationBar.prefersLargeTitles = true

		// Set stateful views
		loadingView = Bundle.main.loadNibNamed("DataLoadingView", owner: self, options: nil)?.first as? UIView
		emptyView = Bundle.main.loadNibNamed("EmptyDataView", owner: self, options: nil)?.first as? UIView
		if let emptyView = emptyView as? EmptyDataView {
			emptyView.reloadButton.setTitleColor(UIColor(red: 130/255, green: 177/255, blue: 255/255, alpha: 1), for: .normal)
			emptyView.action = { (sender: UIButton) in
				self.refreshDataSource()
			}
		}
		errorView = Bundle.main.loadNibNamed("EmptyDataView", owner: self, options: nil)?.first as? UIView
		if let errorView = errorView as? EmptyDataView {
			errorView.reloadButton.setTitleColor(UIColor(red: 255/255, green: 138/255, blue: 128/255, alpha: 1), for: .normal)
			errorView.y467ImageView.transform = CGAffineTransform(rotationAngle: -15 * CGFloat(Double.pi/180)) // list Y467
			errorView.action = { (sender: UIButton) in
				self.refreshDataSource()
			}
		}

		// Set refresh controll
		self.tableView.bindRefreshStyle(.replicatorDot, fill: UIColor(red: 0.05, green: 0.51, blue: 0.96, alpha: 1.0), at: .header, refreshHanler: refreshDataSourceWithSwipeRefresh)

		// TODO: Show retry Snackbar
	}

	// MARK: - Deinitialization
	deinit {
		notificationToken?.invalidate()
	}

	// MARK: - Rotation

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return .portrait
	}

	override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
		return .portrait
	}

	// MARK: - Resource updater

	func refreshDataSourceWithSwipeRefresh() {
		if lastState == .Loading {
			return
		}
		let generator = UIImpactFeedbackGenerator(style: .heavy)
		generator.impactOccurred()
		refreshDataSource()
	}

	func refreshDataSource() {
		if lastState == .Loading {
			return
		}
		startLoading()
	}

	@objc func retryRefreshDataSource() {
		self.tableView.headRefreshControl.beginRefreshing()
		refreshDataSource()
	}

	func updateNotificationBlock<T>() -> ((RealmCollectionChange<T>) -> Void) {
		return { [weak self] (changes: RealmCollectionChange) in
			guard let tableView = self?.tableView else { return }
			switch changes {
			case .initial:
				tableView.reloadData()
			case .update(_, let deletions, let insertions, let modifications):
				if insertions.count == tableView.numberOfRows(inSection: 0) || tableView.numberOfRows(inSection: 0) == 0 {
					tableView.reloadData()
				} else if modifications.count == 1 {
					tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .fade)
				} else {
					tableView.beginUpdates()
					tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .right)
					tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .left)
					tableView.endUpdates()
				}
				self?.endLoading()
			case .error(let error):
				fatalError("\(error)")
			}
		}
	}

}

// MARK: - Stateful view controller
extension CommonProgramTableViewController: StatefulViewController {
	func hasContent() -> Bool {
		return tableView.numberOfRows(inSection: 0) > 0
	}

	func handleErrorWhenContentAvailable(_ error: Error) {
		Answers.logCustomEvent(withName: "Content Load Error", customAttributes: ["error": error])
		guard let e = error as? SessionTaskError else {
			return
		}
		// TODO: Show error
	}
}

// MARK: - Table view data source
extension CommonProgramTableViewController {

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 0
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		return UITableViewCell()
	}
}

// MARK: - Table view delegate
extension CommonProgramTableViewController {
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 88
	}
}
