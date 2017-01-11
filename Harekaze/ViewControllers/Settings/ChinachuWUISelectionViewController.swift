/**
 *
 * ChinachuWUISelectionViewController.swift
 * Harekaze
 * Created by Yuki MIZUNO on 2016/08/06.
 * 
 * Copyright (c) 2016-2017, Yuki MIZUNO
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
import SpringIndicator

class ChinachuWUISelectionViewController: MaterialContentAlertViewController, UITableViewDelegate, UITableViewDataSource,
											NetServiceBrowserDelegate, NetServiceDelegate, TextFieldDelegate {

	// MARK: - Instance fields
	var tableView: UITableView!
	var manualInputView: UIView!
	var timeoutAction: [NetServiceBrowser: Foundation.Timer] = [:]
	var services: [NetService] = []
	var dataSource: [NetService] = []
	var saveAction: MaterialAlertAction!
	var fixedSizeConstraint: NSLayoutConstraint!

	// MARK: - View initialization
	override func viewDidLoad() {
		super.viewDidLoad()

		// Alert view size fix
		fixedSizeConstraint = NSLayoutConstraint(item: alertView, attribute: .height, relatedBy: .lessThanOrEqual,
		                                         toItem: nil, attribute: .height, multiplier: 1, constant: 400)
		view.addConstraint(fixedSizeConstraint)

		// Table view
		self.tableView.register(UINib(nibName: "ChinachuWUIListTableViewCell", bundle: nil), forCellReuseIdentifier: "ChinachuWUIListTableViewCell")
		self.tableView.separatorInset = UIEdgeInsets.zero
		self.tableView.rowHeight = 72
		self.tableView.delegate = self
		self.tableView.dataSource = self
		self.tableView.backgroundColor = Material.Color.clear

		// Manual input button
		let toggleManualInputButton = IconButton(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 24, height: 24)))
		let onePasswordButtonImage = UIImage(named: "ic_settings")?.withRenderingMode(.alwaysTemplate)
		toggleManualInputButton.setImage(onePasswordButtonImage, for: .normal)
		toggleManualInputButton.setImage(onePasswordButtonImage, for: .highlighted)
		toggleManualInputButton.tintColor = Material.Color.darkText.secondary
		toggleManualInputButton.addTarget(self, action: #selector(showManualInput), for: .touchUpInside)

		self.alertView.bottomBar?.leftViews = [toggleManualInputButton]

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

	// MARK: - Memory/resource management
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	// MARK: - Table view data source

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return dataSource.count + 1
	}

	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 72
	}

	func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		cell.separatorInset = UIEdgeInsets.zero
		cell.layoutMargins = UIEdgeInsets.zero
		cell.preservesSuperviewLayoutMargins = false
		cell.backgroundColor = Material.Color.clear
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		if (indexPath as NSIndexPath).row == dataSource.count {
			// Show loading cell
			let cell = UITableViewCell()
			cell.selectionStyle = .none
			let loadingView = SpringIndicator()
			loadingView.animating = true
			cell.layout(loadingView).center().size(CGSize(width: 24, height: 24))
			return cell
		}

		guard let cell = tableView.dequeueReusableCell(withIdentifier: "ChinachuWUIListTableViewCell", for: indexPath) as? ChinachuWUIListTableViewCell else {
			return UITableViewCell()
		}

		let service = dataSource[(indexPath as NSIndexPath).row]
		let url = "\(service.type.contains("https") ? "https" : "http")://\(service.hostName!):\(service.port)"

		if let txtRecord = String(data: service.txtRecordData()!, encoding: String.Encoding.utf8) {
			let locked = txtRecord.contains("Password=true")
			cell.lockIcon.image = UIImage(named: locked ? "ic_lock" : "ic_lock_open")
		} else {
			cell.lockIcon.image = UIImage(named: "ic_lock_open")
		}

		cell.titleLabel?.text = service.name
		cell.detailLabel?.text = url

		return cell
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if (indexPath as NSIndexPath).row == dataSource.count {
			return
		}
		let service = dataSource[(indexPath as NSIndexPath).row]
		let url = "\(service.type.contains("https") ? "https" : "http")://\(service.hostName!):\(service.port)"

		// Save values
		ChinachuAPI.wuiAddress = url

		dismiss(animated: true, completion: nil)

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
		self.contentView = UIView()
		self.tableView = UITableView()
		self.manualInputView = UIView()
		self.contentView.height = 200
		self.contentView.layout(self.tableView).edges()
		self.modalPresentationStyle = .overCurrentContext
		self.modalTransitionStyle = .crossDissolve
	}

	internal required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Event handler
	func showManualInput() {
		self.alertView.bottomBar?.dividerColor = Color.clear
		self.tableView.removeFromSuperview()
		self.contentView.height = 100

		// Manual input view
		let addressTextField = TextField()
		addressTextField.placeholder = "Chinachu WUI Address"
		addressTextField.text = ChinachuAPI.wuiAddress
		addressTextField.clearButtonMode = .whileEditing
		addressTextField.isClearIconButtonAutoHandled = true
		addressTextField.placeholderActiveColor = Material.Color.blue.base
		addressTextField.returnKeyType = .done
		addressTextField.autocapitalizationType = .none
		addressTextField.autocorrectionType = .no
		addressTextField.keyboardType = .URL
		addressTextField.delegate = self
		manualInputView.layout(addressTextField).centerVertically().left(16).right(16).height(20)

		// Manual input save button
		saveAction = MaterialAlertAction(title: "SAVE", style: .default, handler: {_ in
			ChinachuAPI.wuiAddress = addressTextField.text!

			self.dismiss(animated: true, completion: nil)

			guard let navigationController = self.presentingViewController as? NavigationController else {
				return
			}
			guard let settingsTableViewController = navigationController.viewControllers.first as? SettingsTableViewController else {
				return
			}
			settingsTableViewController.reloadSettingsValue()
		})
		saveAction.isEnabled = !ChinachuAPI.wuiAddress.isEmpty

		self.contentView.layout(self.manualInputView).edges().height(100)
		self.alertView.bottomBar?.rightViews.append(saveAction)
		self.alertView.bottomBar?.leftViews = []
		self.view.layoutIfNeeded()

		// Change alertView size
		fixedSizeConstraint.constant = 200
		UIView.animate(withDuration: 0.2, animations: {
			self.view.layoutIfNeeded()
			self.view.layer.layoutIfNeeded()
		})
	}

	// MARK: - Local mDNS Service browser

	func findLocalChinachuWUI() {
		let serviceBrowser = NetServiceBrowser()
		serviceBrowser.delegate = self
		timeoutAction[serviceBrowser] = Foundation.Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(stopBrowsering),
		                                                                userInfo: serviceBrowser, repeats: false)
		serviceBrowser.searchForBrowsableDomains()
	}

	func stopBrowsering(_ timer: Foundation.Timer?) {
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
		if let _ = sender.hostName {
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
		UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
			self.alertView.transform = CGAffineTransform.identity.translatedBy(x: 0, y: 0)
			}, completion: nil)
		self.view.endEditing(false)
		return true
	}

	func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
		UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
			self.alertView.transform = CGAffineTransform.identity.translatedBy(x: 0, y: -100)
			}, completion: nil)
		return true
	}

	func textFieldShouldClear(_ textField: UITextField) -> Bool {
		saveAction.isEnabled = false
		return true
	}

	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		guard let addressTextField = textField as? TextField else {
			return false
		}

		let text = NSString(string: textField.text!).replacingCharacters(in: range, with: string)
		if let url = URLComponents(string: text) {
			if (url.scheme != "http" && url.scheme != "https") || url.host == nil || url.host!.isEmpty || url.path != "" {
				addressTextField.placeholderActiveColor = Material.Color.red.base
				addressTextField.dividerActiveColor = Material.Color.red.base
				saveAction.isEnabled = false
			} else {
				addressTextField.placeholderActiveColor = Material.Color.blue.base
				addressTextField.dividerActiveColor = Material.Color.blue.base
				saveAction.isEnabled = true
			}
		} else {
			addressTextField.placeholderActiveColor = Material.Color.red.base
			addressTextField.dividerActiveColor = Material.Color.red.base
			saveAction.isEnabled = false
		}

		return true
	}
}
