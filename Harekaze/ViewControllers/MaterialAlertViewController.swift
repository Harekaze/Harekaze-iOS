//
//  MaterialAlertViewController.swift
//  Harekaze
//
//  Created by Yuki MIZUNO on 2016/07/18.
//  Copyright © 2016年 Yuki MIZUNO. All rights reserved.
//

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

	private var alertView: CardView!
	private var _title: String?
	private var _message: String?
	private var _buttons: [MaterialAlertAction] = []

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
        // Dispose of any resources that can be recreated.
    }

	// MARK: - Initialization

	private init() {
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
}
