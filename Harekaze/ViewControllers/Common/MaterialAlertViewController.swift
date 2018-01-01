/**
 *
 * MaterialAlertViewController.swift
 * Harekaze
 * Created by Yuki MIZUNO on 2016/07/18.
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

enum MaterialAlertControllerStyle {
	case alert
}

public enum MaterialAlertActionStyle: Int {
	case `default`
	case cancel
	case destructive
}

typealias ActionBlock = (_ action: MaterialAlertAction?) -> Void

class MaterialAlertAction: FlatButton {

	// MARK: - Private instance fileds
	private var actionBlock: ActionBlock!

	// MARK: - Initialization

	private init() {
		super.init(frame: CGRect.zero)
	}

	convenience init(title: String, style: MaterialAlertActionStyle, handler: ActionBlock?) {
		self.init()
		actionBlock = handler
		self.pulseColor = Material.Color.blue.lighten1
		self.setTitle(title, for: .normal)
		self.titleLabel?.font = RobotoFont.medium(with: 16)
		self.setTitleColor(Material.Color.blue.darken1, for: .normal)
		self.setTitleColor(Material.Color.darkText.dividers, for: .disabled)
		self.addTarget(self, action: #selector(callActionBlock), for: .touchUpInside)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Event handler

	@objc func callActionBlock() {
		actionBlock(self)
		// TODO: dismiss parent MaterialAlertViewController
	}
}

class MaterialAlertViewController: UIViewController {

	// MARK: - Private instance fileds
	private var _buttons: [MaterialAlertAction] = []

	// MARK: - Instance fileds
	var _title: String? // swiftlint:disable:this variable_name
	var _message: String? // swiftlint:disable:this variable_name
	var alertView: Card!

	// MARK: - View initialization

	override func viewDidLoad() {
		super.viewDidLoad()

		alertView = Card()

		let toolbar = Toolbar()

		toolbar.titleLabel.font = RobotoFont.medium(with: 20)
		toolbar.title = _title
		toolbar.titleLabel.textColor = Color.black
		toolbar.titleLabel.textAlignment = .left
		toolbar.frame.size.height = 56
		toolbar.contentEdgeInsets = UIEdgeInsets(top: 24, left: 24, bottom: 10, right: 24)

		let messageLabel = UILabel()
		messageLabel.text = _message
		messageLabel.textColor = Color.grey.base
		messageLabel.numberOfLines = 0
		messageLabel.font = RobotoFont.regular(with: 16)
		alertView.contentView = messageLabel

		let bar = Bar()
		bar.rightViews = self._buttons
		bar.dividerColor = Color.grey.lighten3
		bar.dividerAlignment = .top
		bar.frame.size.height = 56
		bar.contentEdgeInsets = UIEdgeInsets(top: 10, left: 24, bottom: 10, right: 24)

		alertView.toolbar = toolbar
		alertView.bottomBar = bar
		alertView.contentViewEdgeInsets = UIEdgeInsets(top: 10, left: 24, bottom: 24, right: 24)
		alertView.depth.preset = .depth5
		alertView.cornerRadius = 2.0

		view.layout(alertView).centerVertically().left(20).right(20)
		view.backgroundColor = UIColor(white: 0.0, alpha: 0.3)
	}

	// MARK: - Initialization

	init() {
		super.init(nibName: nil, bundle: nil)
	}

	convenience init(title: String, message: String, preferredStyle: MaterialAlertControllerStyle) {
		self.init()
		_title = title
		_message = message
		self.modalPresentationStyle = .overCurrentContext
		self.modalTransitionStyle = .crossDissolve
	}

	internal required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Setup methods
	func addAction(_ action: MaterialAlertAction) {
		self._buttons.append(action)
	}

	// MARK: - Dialog generator
	static func generateSimpleDialog(_ title: String, message: String) -> MaterialAlertViewController {
		let alertController = MaterialAlertViewController(title: title, message: message, preferredStyle: .alert)
		let okAction = MaterialAlertAction(title: "OK", style: .default, handler: {_ in alertController.dismiss(animated: true, completion: nil)})
		alertController.addAction(okAction)
		return alertController
	}
}
