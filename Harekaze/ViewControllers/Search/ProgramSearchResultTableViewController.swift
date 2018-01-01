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
import Material
import RealmSwift

class ProgramSearchResultTableViewController: CommonProgramTableViewController, UITableViewDelegate, UITableViewDataSource, TextFieldDelegate {

	// MARK: - Private instance fileds
	private var dataSource: Results<Program>!

	// MARK: - View initialization

	override func viewDidLoad() {
		// Table
		self.tableView.register(UINib(nibName: "ProgramItemMaterialTableViewCell", bundle: nil), forCellReuseIdentifier: "ProgramItemCell")

		super.viewDidLoad()

		// Search control
		let searchController = UISearchController(searchResultsController: nil)
		searchController.searchResultsUpdater = self
		searchController.obscuresBackgroundDuringPresentation = false
		navigationItem.searchController = searchController
		navigationItem.hidesSearchBarWhenScrolling = false

		// Disable refresh control
		refresh.removeTarget(self, action: #selector(refreshDataSource), for: .valueChanged)
		refresh.removeFromSuperview()
		refresh = nil
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		// Setup search bar

		let backButton = IconButton(image: UIImage(named: "ic_arrow_back"), tintColor: Material.Color.darkText.secondary)
		backButton.pulseColor = Material.Color.darkText.secondary
		backButton.addTarget(self, action: #selector(handleBackButton), for: .touchUpInside)

		let moreButton = IconButton(image: UIImage(named: "ic_more_vert"), tintColor: Material.Color.darkText.secondary)
		moreButton.pulseColor = Material.Color.darkText.secondary

		searchBarController?.statusBarStyle = .default
		searchBarController?.searchBar.textField.delegate = self
		searchBarController?.searchBar.leftViews = [backButton]
		searchBarController?.searchBar.rightViews = [moreButton]
		searchBarController?.searchBar.textField.returnKeyType = .search
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		// Close navigation drawer
		navigationDrawerController?.closeLeftView()
		navigationDrawerController?.isEnabled = false

		// Show keyboard when search text is empty
		if searchBarController?.searchBar.textField.text == "" {
			searchBarController?.searchBar.textField.becomeFirstResponder()
		}
	}

	// MARK: - View deinitialization

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		// Change status bar style
		searchBarController?.statusBarStyle = .lightContent

		// Enable navigation drawer
		navigationDrawerController?.isEnabled = false
	}

	// MARK: - Event handler

	@objc internal func handleBackButton() {
		searchBarController?.searchBar.textField.resignFirstResponder()
		dismiss(animated: true, completion: nil)
	}

	// MARK: - Memory/resource management

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	// MARK: - Layout methods

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
	}

	// MARK: - Resource searcher

	internal func searchDataSource(_ text: String) {
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

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if let dataSource = dataSource {
			return dataSource.count
		}
		return 0
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "ProgramItemCell", for: indexPath) as? ProgramItemMaterialTableViewCell else {
			return UITableViewCell()
		}

		let item = dataSource[indexPath.row]
		cell.setCellEntities(item, navigationController: self.navigationController)

		return cell
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let programDetailViewController = self.storyboard!.instantiateViewController(withIdentifier: "ProgramDetailTableViewController") as?
			ProgramDetailTableViewController else {
			return
		}

		programDetailViewController.program = dataSource[indexPath.row]

		self.navigationController?.pushViewController(programDetailViewController, animated: true)
	}

	// MARK: - Text field 

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		if textField.text == "" {
			return false
		}
		searchDataSource(textField.text!)
		textField.resignFirstResponder()
		return true
	}

}

// MARK: - UISearchResultsUpdating

extension ProgramSearchResultTableViewController: UISearchResultsUpdating {
	func updateSearchResults(for searchController: UISearchController) {
		let text = searchController.searchBar.text ?? ""
		searchDataSource(text)
	}
}
