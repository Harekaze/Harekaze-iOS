/**
 *
 * FindServerTableViewController.swift
 * Harekaze
 * Created by Yuki MIZUNO on 2018/02/11.
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
import SVProgressHUD
import StatusAlert
import APIKit

class FindServerTableViewController: ServerSettingTableViewController {

	// MARK: - Private instance fileds
	private var url: String = ""
	private var pageViewController: NavigationPageViewController? {
		return self.parent?.parent as? NavigationPageViewController
	}

	private func checkConnection() {
		// Save values
		ChinachuAPI.Config[.address] = url

		SVProgressHUD.show(withStatus: "Checking connection...")
		let request = ChinachuAPI.StatusRequest()

		let start = DispatchTime.now()
		Session.sendIndicatable(request) { result in
			DispatchQueue.main.asyncAfter(deadline: start + 2) {
				SVProgressHUD.dismiss()
				let errorMessage: String
				switch result {
				case .success(let data):
					if data["connectedCount"] as? Int != nil {
						self.pageViewController?.goSkipNext()
						return
					} else {
						errorMessage = "Data parse error."
					}
				case .failure(let error):
					switch error {
					case .responseError(let responseError as ResponseError):
						switch responseError {
						case .unacceptableStatusCode(let statusCode):
							switch statusCode {
							case 401:
								self.pageViewController?.goNext()
								return
							default:
								errorMessage = ChinachuAPI.parseErrorMessage(error)
							}
						default:
							errorMessage = ChinachuAPI.parseErrorMessage(error)
						}
					default:
						errorMessage = ChinachuAPI.parseErrorMessage(error)
					}
				}
				let errorDialog = AlertController("Connection failed", "\(errorMessage) Please check the URL and server.")
				errorDialog.addAction(AlertButton(.default, title: "OK")) {}
				self.pageViewController?.present(errorDialog, animated: false, completion: nil)
			}
		}
	}

	// MARK: - View deinitialization

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		pageViewController?.nextButtonAction = {
			self.checkConnection()
		}
	}

	// MARK: - Table view data source / delegate

	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let label = UILabel()
		label.textColor = UIColor.white
		label.font = .boldSystemFont(ofSize: 20)
		label.text = self.tableView(tableView, titleForHeaderInSection: section)?.uppercased()
		return label
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.row == dataSource.count {
			return
		}
		let service = dataSource[indexPath.row]
		url = "\(service.type.contains("https") ? "https" : "http")://\(service.hostName!):\(service.port)"
		checkConnection()
	}

	// MARK: - Text field delegate

	override func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		if let oldText = textField.text, let range = Range(range, in: oldText),
			let pageViewController = self.parent?.parent as? NavigationPageViewController {
			url = oldText.replacingCharacters(in: range, with: string)
			let regex = "^((https|http)://)([\\w_\\.\\-]+)(:\\d{1,5})?(/[^/]+)*$"
			let predicate = NSPredicate(format: "SELF MATCHES %@", argumentArray: [regex])
			pageViewController.isNextButtonEnabled = predicate.evaluate(with: url)
		}
		return true
	}
}
