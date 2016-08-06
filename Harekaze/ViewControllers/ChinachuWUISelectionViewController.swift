//
//  ChinachuWUISelectionViewController.swift
//  Harekaze
//
//  Created by Yuki MIZUNO on 2016/08/06.
//  Copyright © 2016年 Yuki MIZUNO. All rights reserved.
//

import UIKit
import Material

class ChinachuWUISelectionViewController: MaterialTableAlertViewController, UITableViewDelegate, UITableViewDataSource, NSNetServiceBrowserDelegate, NSNetServiceDelegate {

	// MARK: - Instance fields
	var timeoutAction: [NSNetServiceBrowser: NSTimer] = [:]
	var services: [NSNetService] = []
	var dataSource: [NSNetService] = []


	// MARK: - View initialization
    override func viewDidLoad() {
        super.viewDidLoad()
		self.tableView.registerNib(UINib(nibName: "ChinachuWUIListTableViewCell", bundle: nil), forCellReuseIdentifier: "ChinachuWUIListTableViewCell")
		self.tableView.separatorInset = UIEdgeInsetsZero
		self.tableView.delegate = self
		self.tableView.dataSource = self
		findLocalChinachuWUI()
    }

	// MARK: - Memory/resource management
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


	// MARK: - Table view data source

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return dataSource.count
	}

	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}

	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 72
	}

	func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
		cell.separatorInset = UIEdgeInsetsZero
		cell.layoutMargins = UIEdgeInsetsZero
		cell.preservesSuperviewLayoutMargins = false
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("ChinachuWUIListTableViewCell", forIndexPath: indexPath) as! ChinachuWUIListTableViewCell

		let service = dataSource[indexPath.row]
		let url = "\(service.type.containsString("https") ? "https" : "http")://\(service.hostName!):\(service.port)"

		if let txtRecord = String(data: service.TXTRecordData()!, encoding: NSUTF8StringEncoding) {
			let locked = txtRecord.containsString("Password=true")
			cell.lockIcon.image = UIImage(named: locked ? "ic_lock" : "ic_lock_open")
		} else {
			cell.lockIcon.image = UIImage(named: "ic_lock_open")
		}

		cell.titleLabel?.text = service.name
		cell.detailLabel?.text = url

		return cell
	}

	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let userDefaults = NSUserDefaults()
		let service = dataSource[indexPath.row]
		let url = "\(service.type.containsString("https") ? "https" : "http")://\(service.hostName!):\(service.port)"

		// Save values
		ChinachuAPI.wuiAddress = url
		userDefaults.setObject(url, forKey: "ChinachuWUIAddress")
		userDefaults.synchronize()

		dismissViewControllerAnimated(true, completion: nil)

		guard let navigationController = presentingViewController as? NavigationController else {
			return
		}
		guard let settingsTableViewController = navigationController.viewControllers.first as? SettingsTableViewController else {
			return
		}
		settingsTableViewController.reloadSettingsValue()
	}
	
	// MARK: - Initialization

	override init() {
		super.init()
	}

	convenience init(title: String) {
		self.init()
		_title = title
		self.tableView = UITableView()
		self.modalPresentationStyle = .OverCurrentContext
		self.modalTransitionStyle = .CrossDissolve
	}
	
	internal required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}


	// MARK: - Local mDNS Service browser

	func findLocalChinachuWUI() {
		let serviceBrowser = NSNetServiceBrowser()
		serviceBrowser.delegate = self
		timeoutAction[serviceBrowser] = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(stopBrowsering), userInfo: serviceBrowser, repeats: false)
		serviceBrowser.searchForBrowsableDomains()
	}

	func stopBrowsering(timer: NSTimer?) {
		timer?.userInfo?.stop()
	}

	func netServiceBrowser(browser: NSNetServiceBrowser, didFindService service: NSNetService, moreComing: Bool) {
		timeoutAction[browser]?.invalidate()

		service.delegate = self
		service.resolveWithTimeout(5)
		services.append(service)

		if !moreComing {
			browser.stop()
		}
	}

	func netServiceBrowser(browser: NSNetServiceBrowser, didFindDomain domainString: String, moreComing: Bool) {
		timeoutAction[browser]?.invalidate()

		let httpServiceBrowser = NSNetServiceBrowser()
		timeoutAction[httpServiceBrowser] = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(stopBrowsering), userInfo: httpServiceBrowser, repeats: false)
		httpServiceBrowser.delegate = self
		httpServiceBrowser.searchForServicesOfType("_http._tcp.", inDomain: domainString)

		let httpsServiceBrowser = NSNetServiceBrowser()
		timeoutAction[httpsServiceBrowser] = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(stopBrowsering), userInfo: httpsServiceBrowser, repeats: false)
		httpsServiceBrowser.delegate = self
		httpsServiceBrowser.searchForServicesOfType("_https._tcp.", inDomain: domainString)

		if !moreComing {
			browser.stop()
		}
	}

	func netServiceDidResolveAddress(sender: NSNetService) {
		if let _ = sender.hostName {
			if sender.name.containsString("Chinachu on ") || sender.name.containsString("Chinachu Open Server on ") {
				dataSource.append(sender)
				tableView.reloadData()
			}
		}
	}

}
