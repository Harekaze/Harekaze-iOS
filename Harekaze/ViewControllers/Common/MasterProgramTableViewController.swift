/**
*
* MasterProgramTableViewController.swift
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
import KafkaRefresh
import RealmSwift
import Crashlytics
import DZNEmptyDataSet

class MasterProgramTableViewController: UITableViewController {

	// MARK: - Instance fileds
	var previewContent: Any?
	var notificationToken: NotificationToken?
	var error: Error?
	var isLoading: Bool = false
	lazy var searchController: UISearchController! = {
		let searchController = UISearchController(searchResultsController: nil)
		let searchBar = searchController.searchBar
		searchBar.tintColor = .white
		searchBar.barTintColor = .white
		searchBar.delegate = self
		searchController.searchResultsUpdater = self
		searchController.obscuresBackgroundDuringPresentation = false
		return searchController
	}()
	var predicate = NSPredicate(value: true)
	var indexPathForSelectedRow: IndexPath!

	// MARK: - View initialization

	override func viewDidLoad() {
		super.viewDidLoad()
		self.navigationController?.navigationBar.prefersLargeTitles = true

		self.clearsSelectionOnViewWillAppear = true
		self.tableView.emptyDataSetSource = self
		self.tableView.emptyDataSetDelegate = self
		self.tableView.tableFooterView = UIView()
		self.registerForPreviewing(with: self, sourceView: tableView)

		// Search control
		navigationItem.searchController = searchController
		navigationItem.hidesSearchBarWhenScrolling = false

		// Set refresh controll
		self.tableView.bindRefreshStyle(.replicatorDot, fill: UIColor(named: "main"), at: .header, refreshHanler: refreshDataSourceWithSwipeRefresh)
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if let searchField = searchController.searchBar.value(forKey: "searchField") as? UITextField {
			searchField.textColor = .white
		}
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
		if isLoading == true {
			return
		}
		let generator = UIImpactFeedbackGenerator(style: .heavy)
		generator.impactOccurred()
		refreshDataSource()
	}

	func refreshDataSource() {
		if isLoading == true {
			return
		}
		isLoading = true
		self.tableView.reloadData()
	}

	func startLoading() {
		error = nil
		isLoading = true
		self.tableView.reloadData()
	}

	func endLoading(error: Error? = nil) {
		self.error = error
		isLoading = false
		self.tableView.reloadData()
	}

	@objc func retryRefreshDataSource() {
		self.tableView.headRefreshControl.beginRefreshing()
		refreshDataSource()
	}

	func updateNotificationBlock<T>() -> ((RealmCollectionChange<T>) -> Void) {
		return { [weak self] (changes: RealmCollectionChange) in
			guard let tableView = self?.tableView else {
				return
			}
			switch changes {
			case .initial:
				tableView.reloadData()
			case .update(_, let deletions, let insertions, let modifications):
				tableView.beginUpdates()
				tableView.insertRows(at: insertions.map({ IndexPath(row: $0, section: 0) }), with: .right)
				tableView.deleteRows(at: deletions.map({ IndexPath(row: $0, section: 0) }), with: .left)
				tableView.reloadRows(at: modifications.map({ IndexPath(row: $0, section: 0) }), with: .fade)
				tableView.endUpdates()
				self?.endLoading()
			case .error(let error):
				fatalError("\(error)")
			}
		}
	}

	func searchDataSource(_ text: String) {
	}
}

// MARK: - Empty view
extension MasterProgramTableViewController: DZNEmptyDataSetSource {
	func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
		if error != nil {
			return #imageLiteral(resourceName: "error")
		}
		return nil
	}

	func imageTintColor(forEmptyDataSet scrollView: UIScrollView!) -> UIColor! {
		return .lightGray
	}

	func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
		if error != nil {
			return NSAttributedString(string: "Error")
		}
		return NSAttributedString(string: "No data")
	}

	func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
		if let error = error as? SessionTaskError {
			return NSAttributedString(string: ChinachuAPI.parseErrorMessage(error))
		} else if let error = error as NSError? {
			return NSAttributedString(string: error.localizedDescription)
		}
		return NSAttributedString(string: "Take a cup of salt cocoa.")
	}

	func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
		return NSAttributedString(string: "RELOAD", attributes: [.foregroundColor: UIColor(named: "main")])
	}

	func customView(forEmptyDataSet scrollView: UIScrollView!) -> UIView! {
		if error != nil || isLoading == false {
			return nil
		}
		return Bundle.main.loadNibNamed("DataLoadingView", owner: self, options: nil)?.first as? UIView
	}
}

extension MasterProgramTableViewController: DZNEmptyDataSetDelegate {
	func emptyDataSet(_ scrollView: UIScrollView!, didTap button: UIButton!) {
		error = nil
		refreshDataSource()
		tableView.reloadData()
	}
}

// MARK: - Table view data source
extension MasterProgramTableViewController {

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
extension MasterProgramTableViewController {
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 84
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		indexPathForSelectedRow = indexPath
		if self.searchController.isActive {
			self.searchController.dismiss(animated: true) {
				self.performSegue(withIdentifier: "showDetail", sender: self)
			}
		} else {
			self.performSegue(withIdentifier: "showDetail", sender: self)
		}
	}
}

// MARK: - 3D touch Peek and Pop delegate
extension MasterProgramTableViewController: UIViewControllerPreviewingDelegate {
	func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
		if let indexPath = tableView.indexPathForRow(at: location) {
			previewingContext.sourceRect = tableView.rectForRow(at: indexPath)

			guard let programDetailViewController = self.storyboard!.instantiateViewController(withIdentifier: "ProgramDetailTableViewController") as?
				ProgramDetailTableViewController else {
					return nil
			}
			if let download = previewContent as? Download {
				programDetailViewController.recording = download.recording
			} else if let recording = previewContent as? Recording {
				programDetailViewController.recording = recording
			} else if let timer = previewContent as? Timer {
				programDetailViewController.timer = timer
			} else if let program = previewContent as? Program {
				programDetailViewController.program = program
			} else {
				return nil
			}
			return programDetailViewController
		}
		return nil
	}

	func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
		guard let programDetailViewController = viewControllerToCommit as? ProgramDetailTableViewController else {
			return
		}
		if let recording = programDetailViewController.recording {
			guard let videoPlayViewController = self.storyboard!.instantiateViewController(withIdentifier: "VideoPlayerViewController") as? VideoPlayerViewController else {
				return
			}
			videoPlayViewController.recording = recording
			videoPlayViewController.modalPresentationStyle = .custom
			self.navigationController?.present(videoPlayViewController, animated: true, completion: nil)
		} else {
			self.navigationController?.pushViewController(programDetailViewController, animated: true)
		}
	}
}

// MARK: - UISearchResultsUpdating

extension MasterProgramTableViewController: UISearchResultsUpdating {
	func updateSearchResults(for searchController: UISearchController) {
		let text = searchController.searchBar.text ?? ""
		if text.isEmpty {
			self.tableView.headRefreshControl?.isHidden = false
			self.tableView.emptyDataSetSource = self
			self.tableView.emptyDataSetDelegate = self
			self.tableView.tableFooterView = UIView()
		} else {
			self.tableView.headRefreshControl?.isHidden = true
			self.tableView.emptyDataSetSource = nil
			self.tableView.emptyDataSetDelegate = nil
			self.tableView.tableFooterView = nil
		}
		searchDataSource(text)
	}
}

// MARK: - UISearchBar delegate

extension MasterProgramTableViewController: UISearchBarDelegate {
	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		predicate = NSPredicate(value: true)
		tableView.reloadData()
	}
}
