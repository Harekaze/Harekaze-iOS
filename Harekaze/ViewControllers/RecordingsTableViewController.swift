//
//  RecordingsTableViewController.swift
//  Harekaze
//
//  Created by Yuki MIZUNO on 2016/07/10.
//  Copyright © 2016年 Yuki MIZUNO. All rights reserved.
//


import UIKit
import Material
import APIKit
import CarbonKit

private struct Item {
	var text: String
	var image: UIImage?
}

class RecordingsTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

	// MARK: - Private instance fileds
	private var dataSource: [Program] = []
	private var statusBarView: MaterialView!
	private var refresh: CarbonSwipeRefresh!

	// MARK: - Interface Builder outlets
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var menuButton: IconButton!
	@IBOutlet weak var searchButton: IconButton!
	@IBOutlet weak var castButton: IconButton!
	@IBOutlet weak var moreButton: IconButton!
	
	// MARK: - View initialization

	override func viewDidLoad() {
		super.viewDidLoad()

		// Refresh data stored list
		refreshDataSource()

		// Set refresh controll
		refresh = CarbonSwipeRefresh(scrollView: self.tableView)
		refresh.setMarginTop(0)
		refresh.colors = [MaterialColor.blue.base, MaterialColor.red.base, MaterialColor.orange.base, MaterialColor.green.base]
		self.view.addSubview(refresh)
		refresh.addTarget(self, action:#selector(refreshDataSource), forControlEvents: .ValueChanged)

		// Set status bar
		statusBarView = MaterialView()
		statusBarView.zPosition = 3000
		statusBarView.backgroundColor = MaterialColor.black.colorWithAlphaComponent(0.12)
		self.navigationController?.view.layout(statusBarView).top(0).horizontally().height(20)

		// Set navigation title
		navigationItem.title = "Recordings"
		navigationItem.titleLabel.textAlignment = .Left
		navigationItem.titleLabel.font = RobotoFont.mediumWithSize(20)
		navigationItem.titleLabel.textColor = MaterialColor.white

		// Set navigation bar buttons
		menuButton.addTarget(self, action: #selector(handleMenuButton), forControlEvents: .TouchUpInside)
		navigationItem.leftControls = [menuButton]
		navigationItem.rightControls = [searchButton, castButton, moreButton]

		// Table
		self.tableView.registerNib(UINib(nibName: "ProgramItemMaterialTableViewCell", bundle: nil), forCellReuseIdentifier: "ProgramItemCell")

		tableView.separatorStyle = .SingleLine
		tableView.separatorInset = UIEdgeInsetsZero

		// Uncomment the following line to preserve selection between presentations
		// self.clearsSelectionOnViewWillAppear = false

		// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
		// self.navigationItem.rightBarButtonItem = self.editButtonItem()
	}


	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)

		// Close navigation drawer
		navigationDrawerController?.closeLeftView()
		navigationDrawerController?.enabled = true
	}

	// MARK: - Memory/resource management

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	// MARK: - Layout methods
	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		statusBarView.hidden = MaterialDevice.isLandscape && .iPhone == MaterialDevice.type
	}

	// MARK: - Event handler

	internal func handleMenuButton() {
		navigationDrawerController?.openLeftView()
	}

	// MARK: - Resource updater

	internal func refreshDataSource() {
		ChinachuAPI.wuiAddress = "http://chinachu.local:10772"
		let request = ChinachuAPI.RecordingRequest()
		Session.sendRequest(request) { result in
			switch result {
			case .Success(let data):
				self.dataSource = data.reverse()
				self.tableView.reloadData()
				self.refresh.endRefreshing()
			case .Failure(let error):
				// TODO: show error with Snackbar
				print("error: \(error)")
				self.refresh.endRefreshing()
			}
		}
	}

	// MARK: - Table view data source


	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		// #warning Incomplete implementation, return the number of sections
		return 1
	}

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// #warning Incomplete implementation, return the number of rows
		return dataSource.count
	}


	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell: ProgramItemMaterialTableViewCell = tableView.dequeueReusableCellWithIdentifier("ProgramItemCell", forIndexPath: indexPath) as! ProgramItemMaterialTableViewCell

		// Configure the cell...
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
	
}
