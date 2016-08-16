/**
 *
 * MaterialAlertViewController.swift
 * Harekaze
 * Created by Yuki MIZUNO on 2016/07/18.
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

enum MaterialAlertControllerStyle {
	case Alert
}

public enum MaterialAlertActionStyle : Int {
	case Default
	case Cancel
	case Destructive
}

typealias ActionBlock = (action: MaterialAlertAction!) -> Void

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
		self.pulseColor = MaterialColor.blue.lighten1
		self.setTitle(title, forState: .Normal)
		self.titleLabel?.font = RobotoFont.mediumWithSize(16)
		self.setTitleColor(MaterialColor.blue.darken1, forState: .Normal)
		self.setTitleColor(MaterialColor.darkText.dividers, forState: .Disabled)
		self.addTarget(self, action: #selector(callActionBlock), forControlEvents: .TouchUpInside)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Event handler

	func callActionBlock() {
		actionBlock(action: self)
		// TODO: dismiss parent MaterialAlertViewController
	}
}


class MaterialAlertViewController: UIViewController {

	// MARK: - Private instance fileds
	private var _buttons: [MaterialAlertAction] = []

	// MARK: - Instance fileds
	var _title: String?
	var _message: String?
	var alertView: CardView!

	// MARK: - View initialization

    override func viewDidLoad() {
        super.viewDidLoad()

		alertView = CardView()

		let titleLabel: UILabel = UILabel()
		titleLabel.text = _title
		titleLabel.textColor = MaterialColor.black
		titleLabel.font = RobotoFont.mediumWithSize(20)
		alertView.titleLabel = titleLabel

		let messageLabel: UILabel = UILabel()
		messageLabel.text = _message
		messageLabel.textColor = MaterialColor.grey.base
		messageLabel.numberOfLines = 0
		messageLabel.font = RobotoFont.regularWithSize(16)
		alertView.contentView = messageLabel

		alertView.depth = .Depth5
		alertView.rightButtons = self._buttons
		alertView.divider = false
		alertView.cornerRadius = 2.0
		alertView.contentViewInset = UIEdgeInsets(top: 10, left: 24, bottom: 24, right: 24)
		alertView.titleLabelInset = UIEdgeInsets(top: 24, left: 24, bottom: 10, right: 24)
		alertView.rightButtonsInsetPreset = MaterialEdgeInset.Square2

		alertView.contentInset = UIEdgeInsetsZero

		view.layout(alertView).centerVertically().left(20).right(20)
		view.backgroundColor = UIColor(white: 0.0, alpha: 0.3)
    }

	// MARK: - Memory/resource management

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

	// MARK: - Initialization

	init() {
		super.init(nibName: nil, bundle: nil)
	}

	convenience init(title: String, message: String, preferredStyle: MaterialAlertControllerStyle) {
		self.init()
		_title = title
		_message = message
		self.modalPresentationStyle = .OverCurrentContext
		self.modalTransitionStyle = .CrossDissolve
	}

	internal required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Setup methods
	func addAction(action: MaterialAlertAction) {
		self._buttons.append(action)
	}

	// MARK: - Dialog generator
	static func generateSimpleDialog(title: String, message: String) -> MaterialAlertViewController {
		let alertController = MaterialAlertViewController(title: title, message: message, preferredStyle: .Alert)
		let okAction = MaterialAlertAction(title: "OK", style: .Default, handler: {(action: MaterialAlertAction!) -> Void in alertController.dismissViewControllerAnimated(true, completion: nil)})
		alertController.addAction(okAction)
		return alertController
	}
}
