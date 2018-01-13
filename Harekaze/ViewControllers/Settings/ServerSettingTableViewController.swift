/**
*
* ServerSettingTableViewController.swift
* Harekaze
* Created by Yuki MIZUNO on 2018/01/14.
*
* Copyright (c) 2016-2018, Yuki MIZUNO
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without
* modification, are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice,
*	this list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice,
*	this list of conditions and the following disclaimer in the documentation
*	 and/or other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors
*	may be used to endorse or promote products derived from this software
*	without specific prior written permission.
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
import InAppSettingsKit
import SpringIndicator
import SwiftyUserDefaults

class ServerSettingTableViewController: UITableViewController, NetServiceBrowserDelegate, NetServiceDelegate, UITextFieldDelegate {

	// MARK: - Instance fields
	var timeoutAction: [NetServiceBrowser: Foundation.Timer] = [:]
	var services: [NetService] = []
	var dataSource: [NetService] = []

	override func viewDidLoad() {
		super.viewDidLoad()
		// Table view
		self.tableView.register(UINib(nibName: "ChinachuWUIListTableViewCell", bundle: nil), forCellReuseIdentifier: "ChinachuWUIListTableViewCell")

		// Discovery Chinachu WUI
		findLocalChinachuWUI()
	}

	// MARK: - View deinitialization
	override func viewWillDisappear(_ animated: Bool) {
		for browser in timeoutAction.keys {
			browser.stop()
		}
		super.viewWillDisappear(animated)
	}

	// MARK: - Table view data source

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 2
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == 0 {
			return 1
		}
		return dataSource.count + 1
	}

	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		if indexPath.section == 0 {
			return 44
		}
		return 72
	}

	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if section == 0 {
			return "Manual"
		}
		return "Nearby..."
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if indexPath.section == 0 {
			let cell = IASKPSTextFieldSpecifierViewCell()
			cell.textField.text = ChinachuAPI.Config[.address]
			cell.textField.clearButtonMode = .whileEditing
			cell.textField.returnKeyType = .done
			cell.textField.autocapitalizationType = .none
			cell.textField.autocorrectionType = .no
			cell.textField.keyboardType = .URL
			cell.textField.delegate = self
			return cell
		}

		if indexPath.row == dataSource.count {
			return tableView.dequeueReusableCell(withIdentifier: "LoadingCell", for: indexPath)
		}

		if let cell = tableView.dequeueReusableCell(withIdentifier: "ChinachuWUIListTableViewCell", for: indexPath) as? ChinachuWUIListTableViewCell {
			cell.setup(service: dataSource[indexPath.row])
			return cell
		}

		return UITableViewCell()
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.row == dataSource.count {
			return
		}
		let service = dataSource[indexPath.row]
		let url = "\(service.type.contains("https") ? "https" : "http")://\(service.hostName!):\(service.port)"

		// Save values
		ChinachuAPI.Config[.address] = url

		self.navigationController?.popViewController(animated: true)
	}

	// MARK: - Local mDNS Service browser

	func findLocalChinachuWUI() {
		let serviceBrowser = NetServiceBrowser()
		serviceBrowser.delegate = self
		timeoutAction[serviceBrowser] = Foundation.Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(stopBrowsering),
																		userInfo: serviceBrowser, repeats: false)
		serviceBrowser.searchForBrowsableDomains()
	}

	@objc func stopBrowsering(_ timer: Foundation.Timer?) {
		(timer?.userInfo as? NetServiceBrowser)?.stop()
	}

	func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
		timeoutAction[browser]?.invalidate()

		service.delegate = self
		service.resolve(withTimeout: 5)
		services.append(service)
	}

	func netServiceBrowser(_ browser: NetServiceBrowser, didFindDomain domainString: String, moreComing: Bool) {
		timeoutAction[browser]?.invalidate()

		let httpServiceBrowser = NetServiceBrowser()
		timeoutAction[httpServiceBrowser] = Foundation.Timer.scheduledTimer(timeInterval: 1, target: self,
																			selector: #selector(stopBrowsering), userInfo: httpServiceBrowser, repeats: false)
		httpServiceBrowser.delegate = self
		httpServiceBrowser.searchForServices(ofType: "_http._tcp.", inDomain: domainString)

		let httpsServiceBrowser = NetServiceBrowser()
		timeoutAction[httpsServiceBrowser] = Foundation.Timer.scheduledTimer(timeInterval: 1, target: self,
																			 selector: #selector(stopBrowsering), userInfo: httpsServiceBrowser, repeats: false)
		httpsServiceBrowser.delegate = self
		httpsServiceBrowser.searchForServices(ofType: "_https._tcp.", inDomain: domainString)
	}

	func netServiceDidResolveAddress(_ sender: NetService) {
		if sender.hostName != nil {
			if sender.name.contains("Chinachu on ") || sender.name.contains("Chinachu Open Server on ") {
				// Don't store duplicated item
				for service in dataSource {
					if service.name == sender.name && service.hostName == sender.hostName && service.port == sender.port {
						return
					}
				}
				dataSource.append(sender)
				tableView.reloadData()
			}
		}
	}

	// MARK: - Text field delegate

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		ChinachuAPI.Config[.address] = textField.text ?? ""
		self.view.endEditing(false)
		return true
	}

	func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
		return true
	}

	func textFieldShouldClear(_ textField: UITextField) -> Bool {
		return true
	}

	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		return true
	}
}
