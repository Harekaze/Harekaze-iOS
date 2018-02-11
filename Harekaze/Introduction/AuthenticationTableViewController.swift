/**
 *
 * AuthenticationTableViewController.swift
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
import SVProgressHUD
import APIKit

class AuthenticationTableViewController: UITableViewController {

	// MARK: - Private instance fileds
	private var pageViewController: NavigationPageViewController? {
		return self.parent?.parent as? NavigationPageViewController
	}

	private func checkConnection() {
		SVProgressHUD.show(withStatus: "Authenticating...")

		let request = ChinachuAPI.StatusRequest()
		let start = DispatchTime.now()
		Session.sendIndicatable(request) { result in
			DispatchQueue.main.asyncAfter(deadline: start + 2) {
				SVProgressHUD.dismiss()
				let errorMessage: String
				switch result {
				case .success(let data):
					if data["connectedCount"] as? Int != nil {
						self.pageViewController?.goNext()
						return
					} else {
						errorMessage = "Data parse error."
					}
				case .failure(let error):
					errorMessage = ChinachuAPI.parseErrorMessage(error)
				}
				let errorDialog = AlertController("Authentication failed",
												  "\(errorMessage) Please check the username and password.")
				errorDialog.addAction(AlertButton(.default, title: "OK")) {}
				self.pageViewController?.present(errorDialog, animated: false, completion: nil)
			}
		}
	}

	// MARK: - View initialization/deinitialization

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		pageViewController?.nextButtonAction = {
			self.checkConnection()
		}
		pageViewController?.nextButton.setTitle("Authenticate", for: .normal)
	}

	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		pageViewController?.nextButtonAction = {
			self.pageViewController?.goNext()
		}
		pageViewController?.nextButton.setTitle("Start", for: .normal)
	}

	// MARK: - Table view data source

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 2
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 1
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = IASKPSTextFieldSpecifierViewCell()
		let textField = cell.textField!
		textField.clearButtonMode = .whileEditing
		textField.autocapitalizationType = .none
		textField.autocorrectionType = .no
		textField.delegate = self
		if indexPath.section == 0 {
			textField.returnKeyType = .next
			textField.placeholder = "akari"
		} else {
			textField.isSecureTextEntry = true
			textField.returnKeyType = .go
			textField.placeholder = "(optional)"
		}
		return cell
	}

	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if section == 0 {
			return "Username"
		} else {
			return "Password"
		}
	}

	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let label = UILabel()
		label.textColor = UIColor.white
		label.font = .boldSystemFont(ofSize: 20)
		label.text = self.tableView(tableView, titleForHeaderInSection: section)?.uppercased()
		return label
	}
}

extension AuthenticationTableViewController: UITextFieldDelegate {
	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		if let oldText = textField.text, let range = Range(range, in: oldText),
			let pageViewController = self.parent?.parent as? NavigationPageViewController {
			let text = oldText.replacingCharacters(in: range, with: string)
			if textField.isSecureTextEntry {
				ChinachuAPI.Config[.password] = text
			} else {
				ChinachuAPI.Config[.username] = text
				pageViewController.isNextButtonEnabled = !text.isEmpty
			}
		}
		return true
	}

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		if textField.isSecureTextEntry {
			self.checkConnection()
		} else {
			guard let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? IASKPSTextFieldSpecifierViewCell else {
				return true
			}
			cell.textField.becomeFirstResponder()
		}
		return false
	}
}
