/**
*
* CommonProgramTableViewController.swift
* Harekaze
* Created by Yuki MIZUNO on 2016/08/11.
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
import Material
import APIKit
import StatefulViewController
import CarbonKit
import RealmSwift
import Crashlytics

class CommonProgramTableViewController: UIViewController, StatefulViewController {

	// MARK: - Instance fileds
	var refresh: CarbonSwipeRefresh!
	var controlView: Snackbar!
	var controlViewLabel: UILabel!
	var notificationToken: NotificationToken?

	// MARK: - Interface Builder outlets
	@IBOutlet weak var tableView: UITableView!

	// MARK: - View initialization

	override func viewDidLoad() {
		super.viewDidLoad()

		// Set stateful views
		loadingView = Bundle.main.loadNibNamed("DataLoadingView", owner: self, options: nil)?.first as? UIView
		emptyView = Bundle.main.loadNibNamed("EmptyDataView", owner: self, options: nil)?.first as? UIView
		if let emptyView = emptyView as? EmptyDataView {
			emptyView.reloadButton.setTitleColor(Material.Color.blue.accent1, for: .normal)
			emptyView.reloadButton.pulse.color = Material.Color.blue.accent3
			emptyView.action = { (sender: FlatButton) in
				self.refreshDataSource()
			}
		}
		errorView = Bundle.main.loadNibNamed("EmptyDataView", owner: self, options: nil)?.first as? UIView
		if let errorView = errorView as? EmptyDataView {
			errorView.reloadButton.setTitleColor(Material.Color.red.accent1, for: .normal)
			errorView.reloadButton.pulse.color = Material.Color.red.accent3
			errorView.y467ImageView.transform = CGAffineTransform(rotationAngle: -15 * CGFloat(M_PI/180)) // list Y467
			errorView.action = { (sender: FlatButton) in
				self.refreshDataSource()
			}
		}

		// Set refresh controll
		refresh = CarbonSwipeRefresh(scrollView: self.tableView)
		refresh.setMarginTop(0)
		refresh.colors = [Material.Color.blue.base, Material.Color.red.base, Material.Color.orange.base, Material.Color.green.base]
		self.view.addSubview(refresh)
		refresh.addTarget(self, action:#selector(refreshDataSource), for: .valueChanged)

		// Table
		tableView.separatorStyle = .singleLine
		tableView.separatorInset = UIEdgeInsets.zero

		// Control view
		let retryButton: FlatButton = FlatButton()
		retryButton.pulse.color = Material.Color.white
		retryButton.setTitle("RETRY", for: .normal)
		retryButton.setTitleColor(Material.Color.blue.accent1, for: .normal)
		retryButton.addTarget(self, action: #selector(retryRefreshDataSource), for: .touchUpInside)

		controlViewLabel = UILabel()
		controlViewLabel.text = "Error"
		controlViewLabel.textColor = Material.Color.white

		controlView = Snackbar(rightViews: [retryButton])
		controlView.backgroundColor = Material.Color.grey.darken4
		controlView.contentEdgeInsetsPreset = .wideRectangle3
		controlView.contentView.addSubview(controlViewLabel)
		controlView.contentView.grid.views = [controlViewLabel]

		view.layout(controlView).bottom(-56).horizontally().height(56)
		controlView.isHidden = true

	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		// Set navigation title format
		if let bottomNavigationController = self.navigationController?.viewControllers.first as? BottomNavigationController {
			let navigationItem = bottomNavigationController.navigationItem
			navigationItem.titleLabel.font = RobotoFont.medium(with: 20)
			navigationItem.titleLabel.textColor = Material.Color.white
		}
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		// Close navigation drawer
		navigationDrawerController?.closeLeftView()
		navigationDrawerController?.isEnabled = true
	}


	// MARK: - Deinitialization
	deinit {
		notificationToken?.stop()
	}

	// MARK: - Memory/resource management

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	// MARK: - Resource updater

	func refreshDataSource() {
		if lastState == .Loading {
			return
		}

		startLoading()
		UIApplication.shared.isNetworkActivityIndicatorVisible = true

	}

	func retryRefreshDataSource() {
		refresh.startRefreshing()
		refreshDataSource()
		closeControlView()
	}

	func updateNotificationBlock<T>() -> ((RealmCollectionChange<T>) -> Void)  {
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


	// MARK: - Control view

	func closeControlView() {
		for gestureRecognizer in controlView.contentView.gestureRecognizers! {
			controlView.contentView.removeGestureRecognizer(gestureRecognizer)
		}
		controlView.animate(animation: Material.Animation.translateY(translation: 56, duration: 0.3))

		// TODO: - Dispatch after
		//		controlView.hidden = true

	}

	func showControlView() {
		let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(closeControlView))
		controlView.contentView.addGestureRecognizer(tapGestureRecognizer)
		Foundation.Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(closeControlView), userInfo: nil, repeats: false)
		controlView.isHidden = false
		controlView.animate(animation: Material.Animation.translateY(translation: -56, duration: 0.3))
	}

	// MARK: - Stateful view controller

	func hasContent() -> Bool {
		return tableView.numberOfRows(inSection: 0) > 0
	}

	// FIXME: - ambiguous error type
	/*
	func handleErrorWhenContentAvailable(_ error: Error) {
		Answers.logCustomEvent(withName: "Content Load Error", customAttributes: ["error": error as NSError, "file": #file, "function": #function, "line": #line])
		controlViewLabel.text = ChinachuAPI.parseErrorMessage(error)
		showControlView()
	}
	*/

	// MARK: - Table view data source


	func numberOfSectionsInTableView(_ tableView: UITableView) -> Int {
		return 1
	}

	func tableView(_ tableView: UITableView, heightForRowAtIndexPath indexPath: IndexPath) -> CGFloat {
		return 88
	}


}
