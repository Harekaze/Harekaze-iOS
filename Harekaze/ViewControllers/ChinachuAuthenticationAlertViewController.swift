/**
 *
 * ChinachuAuthenticationAlertViewController.swift
 * Harekaze
 * Created by Yuki MIZUNO on 2016/08/06.
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
import KeychainAccess
import OnePasswordExtension

class ChinachuAuthenticationAlertViewController: MaterialContentAlertViewController, TextFieldDelegate {

	// MARK: - Instance fields
	var usernameTextField: TextField!
	var passwordTextField: TextField!

	// MARK: - View initialization
	override func viewDidLoad() {
		contentView = UIView()
		contentView.backgroundColor = MaterialColor.clear

		// Keyboard toolbar setup
		let inputAccesoryToolBar = UIToolbar()

		let spacer = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: self, action: nil)
		let done = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(closeKeyboard))

		inputAccesoryToolBar.items = [spacer, done]
		inputAccesoryToolBar.sizeToFit()

		// Text Fields

		usernameTextField = TextField()
		usernameTextField.placeholderLabel
		usernameTextField.placeholder = "Username"
		usernameTextField.text = ChinachuAPI.username
		usernameTextField.clearButtonMode = .WhileEditing
		usernameTextField.enableClearIconButton = true
		usernameTextField.placeholderActiveColor = MaterialColor.blue.base
		usernameTextField.returnKeyType = .Next
		usernameTextField.delegate = self
		usernameTextField.inputAccessoryView = inputAccesoryToolBar
		usernameTextField.autocapitalizationType = .None
		usernameTextField.autocorrectionType = .No

		passwordTextField = TextField()
		passwordTextField.placeholder = "Password"
		passwordTextField.enableVisibilityIconButton = true
		passwordTextField.placeholderActiveColor = MaterialColor.blue.base
		passwordTextField.visibilityIconButton?.tintColor = MaterialColor.blue.base.colorWithAlphaComponent(passwordTextField.secureTextEntry ? 0.38 : 0.54)
		passwordTextField.returnKeyType = .Done
		passwordTextField.delegate = self
		passwordTextField.inputAccessoryView = inputAccesoryToolBar

		contentView.layout(usernameTextField).topLeft(top: 16, left: 16).right(16).height(20)
		contentView.layout(passwordTextField).bottomLeft(bottom: 16, left: 16).right(16).height(20)

		super.viewDidLoad()

		// Add 1Password extension button
		if OnePasswordExtension.sharedExtension().isAppExtensionAvailable() {
			let onePasswordButton = IconButton(frame: CGRect(origin: CGPointZero, size: CGSize(width: 24, height: 24)))

			let bundle = NSBundle(forClass: OnePasswordExtension.self)
			if let url = bundle.URLForResource("OnePasswordExtensionResources", withExtension: "bundle") {
				let onePasswordButtonImage = UIImage(named: "onepassword-button", inBundle: NSBundle(URL: url), compatibleWithTraitCollection: nil)?.imageWithRenderingMode(.AlwaysTemplate)
				onePasswordButton.setImage(onePasswordButtonImage, forState: .Normal)
				onePasswordButton.setImage(onePasswordButtonImage, forState: .Highlighted)
				onePasswordButton.tintColor = MaterialColor.darkText.secondary
			}
			onePasswordButton.addTarget(self, action: #selector(open1PasswordAppExtension), forControlEvents: .TouchUpInside)
			alertView.leftButtons = [onePasswordButton]
		}

		// Resize alertView
		view.removeConstraints(view.constraints)
		view.layout(alertView).centerVertically().left(20).right(20).height(220)
	}

	// MARK: - 1Password App Extension

	func open1PasswordAppExtension() {
//		let url = NSURLComponents(string: ChinachuAPI.wuiAddress)
//		let hostname = url?.host?.stringByReplacingOccurrencesOfString(".$", withString: "", options: .RegularExpressionSearch)
		OnePasswordExtension.sharedExtension().findLoginForURLString(ChinachuAPI.wuiAddress, forViewController: self, sender: self, completion: {
			(loginDictionary, error) in
			guard let loginDictionary = loginDictionary else {
				return
			}
			if loginDictionary.count == 0 {
				if error?.code != Int(AppExtensionErrorCodeCancelledByUser) {
					print("Error invoking 1Password App Extension for find login: %@", error)
				}
				return
			}
			if let username = loginDictionary[AppExtensionUsernameKey] as? String, password = loginDictionary[AppExtensionPasswordKey] as? String {
				self.usernameTextField.text = username
				self.passwordTextField.text = password
			}
		})
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
		self.modalPresentationStyle = .OverCurrentContext
		self.modalTransitionStyle = .CrossDissolve
	}

	internal required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}


	// MARK: - Save authentication information

	func saveAuthentication() {
		ChinachuAPI.username = usernameTextField.text!
		ChinachuAPI.password = passwordTextField.text!

		view.endEditing(false)
	}

	// MARK: - Keyboard hide methods

	func closeKeyboard() {
		UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseInOut, animations: {
			self.alertView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, 0)
			}, completion: nil)
		self.view.endEditing(false)
	}


	// MARK: - Text field delegate

	func textFieldShouldReturn(textField: UITextField) -> Bool {
		switch textField {
		case usernameTextField:
			passwordTextField.becomeFirstResponder()
		default:
			textField.resignFirstResponder()
		}

		return true
	}

	func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
		UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseInOut, animations: {
			self.alertView.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, -100)
			}, completion: nil)
		return true
	}

}
