//
//  MaterialTableAlertViewController.swift
//  Harekaze
//
//  Created by Yuki MIZUNO on 2016/08/06.
//  Copyright © 2016年 Yuki MIZUNO. All rights reserved.
//

import UIKit
import Material

class MaterialTableAlertViewController: MaterialAlertViewController {

	// MARK: - Instance fileds
	var tableView: UITableView!

	// MARK: - View initialization
	
    override func viewDidLoad() {
        super.viewDidLoad()
		tableView = UITableView()
		alertView.contentView = tableView
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

	convenience init(title: String, tableView: UITableView, preferredStyle: MaterialAlertControllerStyle) {
		self.init()
		_title = title
		self.tableView = tableView
		self.modalPresentationStyle = .OverCurrentContext
		self.modalTransitionStyle = .CrossDissolve
	}
	
	internal required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

}
