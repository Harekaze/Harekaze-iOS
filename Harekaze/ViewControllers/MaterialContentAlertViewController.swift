//
//  MaterialTableAlertViewController.swift
//  Harekaze
//
//  Created by Yuki MIZUNO on 2016/08/06.
//  Copyright © 2016年 Yuki MIZUNO. All rights reserved.
//

import UIKit
import Material

class MaterialContentAlertViewController: MaterialAlertViewController {

	// MARK: - Instance fileds
	var contentView: UIView!

	// MARK: - View initialization
	
    override func viewDidLoad() {
        super.viewDidLoad()
		alertView.contentView = contentView
		alertView.contentViewInsetPreset = .None
		alertView.contentInsetPreset = .None
		view.layout(alertView).centerVertically().left(20).right(20).height(400)
    }

	// MARK: - Memory/resource management

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

	// MARK: - Initialization

	override init() {
		super.init()
	}

	convenience init(title: String, contentView: UIView, preferredStyle: MaterialAlertControllerStyle) {
		self.init()
		_title = title
		self.contentView = contentView
		self.modalPresentationStyle = .OverCurrentContext
		self.modalTransitionStyle = .CrossDissolve
	}
	
	internal required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

}
