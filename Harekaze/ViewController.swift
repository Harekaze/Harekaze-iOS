//
//  ViewController.swift
//  Harekaze
//
//  Created by Yuki MIZUNO on 2016/06/22.
//  Copyright © 2016年 Yuki MIZUNO. All rights reserved.
//

import UIKit
import Material

class ViewController: UIViewController {

	@IBOutlet weak var menuButton: IconButton!

	@IBOutlet weak var searchButton: IconButton!
	@IBOutlet weak var castButton: IconButton!
	@IBOutlet weak var moreButton: IconButton!

	override func viewDidLoad() {
		super.viewDidLoad()
		prepareNavigationItem()
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		navigationDrawerController?.enabled = true
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	internal func handleMenuButton() {
		navigationDrawerController?.openLeftView()
	}

	/// Prepares the navigationItem.
	private func prepareNavigationItem() {
		navigationItem.title = "Harekaze"
		navigationItem.titleLabel.textAlignment = .Left
		navigationItem.titleLabel.font = RobotoFont.mediumWithSize(20)
		navigationItem.titleLabel.textColor = MaterialColor.white

		menuButton.addTarget(self, action: #selector(handleMenuButton), forControlEvents: .TouchUpInside)

		navigationItem.leftControls = [menuButton]
		navigationItem.rightControls = [searchButton, castButton, moreButton]
	}

}

