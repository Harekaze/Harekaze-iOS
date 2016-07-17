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
import StatefulViewController
import DropDown

private struct Item {
	var text: String
	var image: UIImage?
}

class RecordingsTableViewController: UIViewController, StatefulViewController, UITableViewDelegate, UITableViewDataSource {

	// MARK: - Private instance fileds
	private var dataSource: [Program] = []
	private var refresh: CarbonSwipeRefresh!
	private var controlView: ControlView!
	private var controlViewLabel: UILabel!

	// MARK: - Interface Builder outlets
	@IBOutlet weak var tableView: UITableView!


	// MARK: - View initialization

	override func viewDidLoad() {
		super.viewDidLoad()

		// Set stateful views
		loadingView = NSBundle.mainBundle().loadNibNamed("DataLoadingView", owner: self, options: nil).first as? UIView
		emptyView = UIView()
		emptyView?.backgroundColor = MaterialColor.green.accent1
		errorView = UIView()
		errorView?.backgroundColor = MaterialColor.blue.accent1

		// Setup initial view state
		setupInitialViewState()

		// Set refresh controll
		refresh = CarbonSwipeRefresh(scrollView: self.tableView)
		refresh.setMarginTop(0)
		refresh.colors = [MaterialColor.blue.base, MaterialColor.red.base, MaterialColor.orange.base, MaterialColor.green.base]
		self.view.addSubview(refresh)
		refresh.addTarget(self, action:#selector(refreshDataSource), forControlEvents: .ValueChanged)

		// Refresh data stored list
		refreshDataSource()

		// Set navigation title
		let navigationItem = (self.navigationController!.viewControllers.first as! BottomNavigationController).navigationItem

		navigationItem.title = "Recordings"
		navigationItem.titleLabel.textAlignment = .Left
		navigationItem.titleLabel.font = RobotoFont.mediumWithSize(20)
		navigationItem.titleLabel.textColor = MaterialColor.white

		// Table
		self.tableView.registerNib(UINib(nibName: "ProgramItemMaterialTableViewCell", bundle: nil), forCellReuseIdentifier: "ProgramItemCell")

		tableView.separatorStyle = .SingleLine
		tableView.separatorInset = UIEdgeInsetsZero

		// Control view
		let retryButton: FlatButton = FlatButton()
		retryButton.pulseColor = MaterialColor.white
		retryButton.setTitle("RETRY", forState: .Normal)
		retryButton.setTitleColor(MaterialColor.blue.accent1, forState: .Normal)
		retryButton.addTarget(self, action: #selector(refreshDataSource), forControlEvents: .TouchUpInside)

		controlViewLabel = UILabel()
		controlViewLabel.text = "Error"
		controlViewLabel.textColor = MaterialColor.white

		controlView = ControlView(rightControls: [retryButton])
		controlView.backgroundColor = MaterialColor.grey.darken4
		controlView.contentInsetPreset = .WideRectangle3
		controlView.contentView.addSubview(controlViewLabel)
		controlView.contentView.grid.views = [controlViewLabel]

		view.layout(controlView).bottom(-56).horizontally().height(56)
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

	// MARK: - Resource updater

	internal func refreshDataSource() {
		if lastState == .Loading {
			return
		}
		if lastState == .Content {
			refresh.startRefreshing()
		}

		startLoading()

		let request = ChinachuAPI.RecordingRequest()
		Session.sendRequest(request) { result in
			switch result {
			case .Success(let data):
				self.dataSource = data.reverse()
				self.tableView.reloadData()

				if self.lastState == .Content {
					self.refresh.endRefreshing()
				}
				self.endLoading()
			case .Failure(let error):
				print("error: \(error)")
				self.refresh.endRefreshing()
				self.endLoading(error: error)
			}
		}
	}

	// MARK: - Control view

	func closeControlView() {
		for gestureRecognizer in controlView.contentView.gestureRecognizers! {
			controlView.contentView.removeGestureRecognizer(gestureRecognizer)
		}
		controlView.animate(MaterialAnimation.translateY(56, duration: 0.3))
	}

	func showControlView() {
		let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(closeControlView))
		controlView.contentView.addGestureRecognizer(tapGestureRecognizer)
		NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: #selector(closeControlView), userInfo: nil, repeats: false)
		controlView.animate(MaterialAnimation.translateY(-56, duration: 0.3))
	}

	// MARK: - Stateful view controller

	func hasContent() -> Bool {
		return dataSource.count > 0
	}

	func handleErrorWhenContentAvailable(error: ErrorType) {
		switch error as! SessionTaskError {
		case .ConnectionError(let error as NSError):
			controlViewLabel.text = error.localizedDescription
		case .RequestError(let error as NSError):
			controlViewLabel.text = error.localizedDescription
		case .ResponseError(let error as NSError):
			controlViewLabel.text = error.localizedDescription
		case .ConnectionError:
			controlViewLabel.text = "Connection error."
		case .RequestError:
			controlViewLabel.text = "Request error."
		case .ResponseError:
			controlViewLabel.text = "Response error."
		}
		showControlView()
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
