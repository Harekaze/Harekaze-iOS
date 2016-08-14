/**
 *
 * ProgramSearchResultTableViewController.swift
 * Harekaze
 * Created by Yuki MIZUNO on 2016/07/23.
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
import StatefulViewController
import Material
import RealmSwift

class ProgramSearchResultTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, StatefulViewController, TextFieldDelegate {


	// MARK: - Private instance fileds
	private var dataSource: Results<Program>!

	// MARK: - Interface Builder outlets
	@IBOutlet weak var tableView: UITableView!

	// MARK: - View initialization

	override func viewDidLoad() {
		super.viewDidLoad()

		// Set stateful views
		// TODO: Create stateful views
		loadingView = UIView()
		loadingView?.backgroundColor = MaterialColor.white
		emptyView = UIView()
		emptyView?.backgroundColor = MaterialColor.blue.accent1
		errorView = UIView()
		errorView?.backgroundColor = MaterialColor.red.accent1

		// Setup initial view state
		setupInitialViewState()

		// Refresh data stored list
		startLoading()

		// Table
		self.tableView.registerNib(UINib(nibName: "ProgramItemMaterialTableViewCell", bundle: nil), forCellReuseIdentifier: "ProgramItemCell")

		tableView.separatorStyle = .SingleLine
		tableView.separatorInset = UIEdgeInsetsZero
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		// Setup search bar

		let backButton: IconButton = IconButton()
		backButton.pulseColor = MaterialColor.darkText.secondary
		backButton.tintColor = MaterialColor.darkText.secondary
		backButton.setImage(UIImage(named: "ic_arrow_back"), forState: .Normal)
		backButton.setImage(UIImage(named: "ic_arrow_back"), forState: .Highlighted)
		backButton.addTarget(self, action: #selector(handleBackButton), forControlEvents: .TouchUpInside)

		let moreButton: IconButton = IconButton()
		moreButton.pulseColor = MaterialColor.darkText.secondary
		moreButton.tintColor = MaterialColor.darkText.secondary
		moreButton.setImage(UIImage(named: "ic_more_vert"), forState: .Normal)
		moreButton.setImage(UIImage(named: "ic_more_vert"), forState: .Highlighted)

		searchBarController?.statusBarStyle = .Default
		searchBarController?.searchBar.textField.delegate = self
		searchBarController?.searchBar.leftControls = [backButton]
		searchBarController?.searchBar.rightControls = [moreButton]
		searchBarController?.searchBar.textField.returnKeyType = .Search
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		// Close navigation drawer
		navigationDrawerController?.closeLeftView()
		navigationDrawerController?.enabled = false

		// Show keyboard when search text is empty
		if searchBarController?.searchBar.textField.text == "" {
			searchBarController?.searchBar.textField.becomeFirstResponder()
		}
	}

	// MARK: - View deinitialization

	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		// Change status bar style
		searchBarController?.statusBarStyle = .LightContent

		// Enable navigation drawer
		navigationDrawerController?.enabled = false
	}

	// MARK: - Event handler

	internal func handleBackButton() {
		searchBarController?.searchBar.textField.resignFirstResponder()
		dismissViewControllerAnimated(true, completion: nil)
	}

	// MARK: - Memory/resource management

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	// MARK: - Layout methods

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		// FIXME: Bad way to remove unknown 20px top margin
		tableView.contentInset = UIEdgeInsetsZero
	}

	// MARK: - Resource searcher

	internal func searchDataSource(text: String) {
		let predicate = NSPredicate(format: "title CONTAINS[c] %@", text)
		let realm = try! Realm()
		dataSource = realm.objects(Program).filter(predicate).sorted("startTime", ascending: false)
		endLoading()
		tableView.reloadData()
	}

	// MARK: - Stateful view controller

	func hasContent() -> Bool {
		return dataSource?.count > 0
	}

	func handleErrorWhenContentAvailable(error: ErrorType) {
	}

	// MARK: - Table view data source


	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if let dataSource = dataSource {
			return dataSource.count
		}
		return 0
	}


	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell: ProgramItemMaterialTableViewCell = tableView.dequeueReusableCellWithIdentifier("ProgramItemCell", forIndexPath: indexPath) as! ProgramItemMaterialTableViewCell

		let item = dataSource[indexPath.row]
		cell.setCellEntities(item)

		return cell
	}


	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 88
	}


	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let programDetailViewController = self.storyboard!.instantiateViewControllerWithIdentifier("ProgramDetailTableViewController") as! ProgramDetailTableViewController

		programDetailViewController.program = dataSource[indexPath.row]

		self.navigationController?.pushViewController(programDetailViewController, animated: true)
	}

	// MARK: - Text field 

	func textFieldShouldReturn(textField: UITextField) -> Bool {
		if textField.text == "" {
			return false
		}
		searchDataSource(textField.text!)
		textField.resignFirstResponder()
		return true
	}

}
