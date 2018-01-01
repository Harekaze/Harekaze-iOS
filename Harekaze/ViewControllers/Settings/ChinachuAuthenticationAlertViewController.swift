/**
 *
 * ChinachuAuthenticationAlertViewController.swift
 * Harekaze
 * Created by Yuki MIZUNO on 2016/08/06.
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
import KeychainAccess
import OnePasswordExtension
import Crashlytics

class ChinachuAuthenticationAlertViewController: MaterialContentAlertViewController, TextFieldDelegate {

	// MARK: - Instance fields
	var usernameTextField: TextField!
	var passwordTextField: TextField!
	var keychainBarButton: UIBarButtonItem!

	// MARK: - View initialization
	override func viewDidLoad() {
		super.viewDidLoad()

		self.alertView.bottomBar?.dividerColor = Color.clear

		// Alert view size fix
		let fixedSizeConstraint = NSLayoutConstraint(item: alertView, attribute: .height, relatedBy: .lessThanOrEqual,
		                                             toItem: nil, attribute: .height, multiplier: 1, constant: 200)
		view.addConstraint(fixedSizeConstraint)

		// Keyboard toolbar setup
		let inputAccesoryToolBar = UIToolbar()

		keychainBarButton = UIBarButtonItem(image: UIImage(named: "key_variant"), style: .plain, target: self, action: #selector(openKeychainDialog))
		let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
		let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(closeKeyboard))

		inputAccesoryToolBar.items = [keychainBarButton, spacer, done]
		inputAccesoryToolBar.sizeToFit()

		// Text Fields

		usernameTextField = TextField()
		usernameTextField.placeholder = "Username"
		usernameTextField.text = ChinachuAPI.Config[.username]
		usernameTextField.clearButtonMode = .whileEditing
		usernameTextField.isClearIconButtonAutoHandled = true
		usernameTextField.placeholderActiveColor = Material.Color.blue.base
		usernameTextField.returnKeyType = .next
		usernameTextField.delegate = self
		usernameTextField.inputAccessoryView = inputAccesoryToolBar
		usernameTextField.autocapitalizationType = .none
		usernameTextField.autocorrectionType = .no

		passwordTextField = TextField()
		passwordTextField.placeholder = "Password"
		passwordTextField.text = ChinachuAPI.password
		passwordTextField.isSecureTextEntry = true
		passwordTextField.isClearIconButtonAutoHandled = true
		passwordTextField.placeholderActiveColor = Material.Color.blue.base
		passwordTextField.returnKeyType = .done
		passwordTextField.delegate = self
		passwordTextField.inputAccessoryView = inputAccesoryToolBar

		contentView.layout(usernameTextField).topLeft(top: 16, left: 16).right(16).height(20)
		contentView.layout(passwordTextField).bottomLeft(bottom: 16, left: 16).right(16).height(20)

		// Add 1Password extension button
		if OnePasswordExtension.shared().isAppExtensionAvailable() {
			let onePasswordButton = IconButton(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: 24, height: 24)))

			let bundle = Bundle(for: OnePasswordExtension.self)
			if let url = bundle.url(forResource: "OnePasswordExtensionResources", withExtension: "bundle") {
				let onePasswordButtonImage = UIImage(named: "onepassword-button", in: Bundle(url: url), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
				onePasswordButton.setImage(onePasswordButtonImage, for: .normal)
				onePasswordButton.setImage(onePasswordButtonImage, for: .highlighted)
				onePasswordButton.tintColor = Material.Color.darkText.secondary
			}
			onePasswordButton.addTarget(self, action: #selector(open1PasswordAppExtension), for: .touchUpInside)
			alertView.bottomBar?.leftViews = [onePasswordButton]
		}
	}

	// MARK: - 1Password App Extension

	@objc func open1PasswordAppExtension() {
//		let url = NSURLComponents(string: ChinachuAPI.Config[.address])
//		let hostname = url?.host?.stringByReplacingOccurrencesOfString(".$", withString: "", options: .RegularExpressionSearch)
		OnePasswordExtension.shared().findLogin(forURLString: ChinachuAPI.Config[.address], for: self, sender: self, completion: { (loginDictionary, _) in
			guard let loginDictionary = loginDictionary else {
				return
			}
			if loginDictionary.isEmpty {
				return
			}
			if let username = loginDictionary[AppExtensionUsernameKey] as? String, let password = loginDictionary[AppExtensionPasswordKey] as? String {
				self.usernameTextField.text = username
				self.passwordTextField.text = password
			}
		})
	}

	// MARK: - Keychain shared password

	@objc func openKeychainDialog() {
		let keychain: Keychain
		if ChinachuAPI.Config[.address].range(of: "^https://", options: .regularExpression) != nil {
			keychain = Keychain(server: ChinachuAPI.Config[.address], protocolType: .https, authenticationType: .httpBasic)
		} else {
			keychain = Keychain(server: ChinachuAPI.Config[.address], protocolType: .http, authenticationType: .httpBasic)
		}

		keychain.getSharedPassword(self.usernameTextField.text!) { (password, _) -> Void in
			if password != nil {
				DispatchQueue.main.async {
					self.passwordTextField.text = password
					self.passwordTextField.isSecureTextEntry = true
					self.passwordTextField.isClearIconButtonEnabled = true
					self.passwordTextField.isVisibilityIconButtonEnabled = false
				}
			}
		}

	}

	// MARK: - Memory/resource management
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	// MARK: - Initialization

	override init() {
		super.init()
	}

	convenience init(title: String) {
		self.init()
		_title = title
		self.contentView = UIView()
		self.contentView.frame.size.height = 100
		self.contentView.backgroundColor = Material.Color.clear
		self.modalPresentationStyle = .overCurrentContext
		self.modalTransitionStyle = .crossDissolve
	}

	internal required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Save authentication information

	func saveAuthentication() {
		ChinachuAPI.Config[.username] = usernameTextField.text!
		ChinachuAPI.password = passwordTextField.text!

		view.endEditing(false)
	}

	// MARK: - Keyboard hide methods

	@objc func closeKeyboard() {
		UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
			self.alertView.transform = CGAffineTransform.identity.translatedBy(x: 0, y: 0)
			}, completion: nil)
		self.view.endEditing(false)
	}

	// MARK: - Text field delegate

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		switch textField {
		case usernameTextField:
			_ = passwordTextField.becomeFirstResponder()
		default:
			textField.resignFirstResponder()
		}

		return true
	}

	func textFieldDidBeginEditing(_ textField: UITextField) {
		keychainBarButton.isEnabled = textField == self.passwordTextField
	}

	func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
		UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
			self.alertView.transform = CGAffineTransform.identity.translatedBy(x: 0, y: -100)
			}, completion: nil)
		return true
	}

	func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		if textField == passwordTextField && textField.text == "" {
			passwordTextField.isClearIconButtonEnabled = false
			passwordTextField.isVisibilityIconButtonEnabled = true
		}
		return true
	}

}
