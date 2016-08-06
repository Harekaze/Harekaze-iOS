//
//  ChinachuAuthenticationAlertViewController.swift
//  Harekaze
//
//  Created by Yuki MIZUNO on 2016/08/06.
//  Copyright © 2016年 Yuki MIZUNO. All rights reserved.
//

import UIKit
import Material
import KeychainAccess

class ChinachuAuthenticationAlertViewController: MaterialContentAlertViewController, TextFieldDelegate {

	// MARK: - Instance fields
	var usernameTextField: TextField!
	var passwordTextField: TextField!

	// MARK: - View initialization
	override func viewDidLoad() {
		contentView = MaterialPulseView()

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

		// Resize alertView
		view.removeConstraints(view.constraints)
		view.layout(alertView).centerVertically().left(20).right(20).height(220)
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
