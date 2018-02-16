/**
 *
 * ProgramSearchResultTableViewController.swift
 * Harekaze
 * Created by Yuki MIZUNO on 2016/07/23.
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
import RealmSwift

class ProgramSearchResultTableViewController: MasterProgramTableViewController {

	// MARK: - Private instance fileds
	private var dataSource: Results<Program>!

	// MARK: - View initialization

	override func viewDidLoad() {
		// Table
		self.tableView.register(UINib(nibName: "ProgramItemTableViewCell", bundle: nil), forCellReuseIdentifier: "ProgramItemCell")

		super.viewDidLoad()

		// reset
		self.tableView.emptyDataSetSource = nil
		self.tableView.emptyDataSetDelegate = nil
		self.tableView.headRefreshControl = nil
		self.tableView.tableFooterView = nil
		if let tabBarController = self.navigationController?.parent as? UITabBarController {
			tabBarController.delegate = self
		}
	}

	// MARK: - Resource searcher

	override func updateSearchResults(for searchController: UISearchController) {
		let text = searchController.searchBar.text ?? ""
		searchDataSource(text)
	}

	override func searchDataSource(_ text: String) {
		if text.isEmpty {
			dataSource = nil
		} else {
			let predicate = NSPredicate(format: "title CONTAINS[c] %@", text)
			let realm = try! Realm()
			dataSource = realm.objects(Program.self).filter(predicate).sorted(byKeyPath: "startTime", ascending: false)
			notificationToken?.invalidate()
			notificationToken = dataSource.observe(updateNotificationBlock())
		}
		tableView.reloadData()
	}

	// MARK: - Table view data source

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return dataSource?.count ?? 0
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "ProgramItemCell", for: indexPath) as? ProgramItemTableViewCell else {
			return UITableViewCell()
		}

		let item = dataSource[indexPath.row]
		cell.setCellEntities(item)

		return cell
	}

	// MARK: - prepare segue

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: sender)
		guard let programDetailViewController = segue.destination as? ProgramDetailTableViewController else {
			return
		}
		programDetailViewController.program = dataSource[self.indexPathForSelectedRow.row]
	}
}

// MARK: - 3D touch Peek and Pop delegate
extension ProgramSearchResultTableViewController {
	override func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
		if let indexPath = tableView.indexPathForRow(at: location) {
			previewContent = dataSource[indexPath.row]
			return super.previewingContext(previewingContext, viewControllerForLocation: location)
		}
		return nil
	}
}
