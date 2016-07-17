//
//  MainNavigationController.swift
//  Harekaze
//
//  Created by Yuki MIZUNO on 2016/07/17.
//  Copyright © 2016年 Yuki MIZUNO. All rights reserved.
//

import UIKit
import Material
import DropDown

class MainNavigationController: NavigationController {

	// MARK: - Private instance fileds
	private var statusBarView: MaterialView!
	private var menuButton: IconButton!
	private var searchButton: IconButton!
	private var castButton: IconButton!
	private var moreButton: IconButton!
	private var dropDown: DropDown!

	// MARK: - View initialization

    override func viewDidLoad() {
        super.viewDidLoad()

		// Chinachu API settings
		ChinachuAPI.wuiAddress = "http://chinachu.local:10772"

		// DropDown appearance configuration
		DropDown.appearance().backgroundColor = UIColor.whiteColor()
		DropDown.appearance().cellHeight = 48
		DropDown.appearance().textFont = RobotoFont.regularWithSize(16)
		DropDown.appearance().cornerRadius = 2.0
		DropDown.appearance().direction = .Bottom
		DropDown.appearance().animationduration = 0.2

		// Set status bar
		statusBarView = MaterialView()
		statusBarView.zPosition = 3000
		statusBarView.restorationIdentifier = "StatusBarView"
		statusBarView.backgroundColor = MaterialColor.black.colorWithAlphaComponent(0.12)
		self.view.layout(statusBarView).top(0).horizontally().height(20)

		// Set navigation bar buttons
		let navigationItem = (self.viewControllers.first as! BottomNavigationController).navigationItem
		menuButton = IconButton()
		menuButton.setImage(UIImage(named: "ic_menu_white"), forState: .Normal)
		menuButton.setImage(UIImage(named: "ic_menu_white"), forState: .Highlighted)
		menuButton.addTarget(self, action: #selector(handleMenuButton), forControlEvents: .TouchUpInside)

		searchButton = IconButton()
		searchButton.setImage(UIImage(named: "ic_search_white"), forState: .Normal)
		searchButton.setImage(UIImage(named: "ic_search_white"), forState: .Highlighted)

		castButton = IconButton()
		castButton.setImage(UIImage(named: "ic_cast_white"), forState: .Normal)
		castButton.setImage(UIImage(named: "ic_cast_white"), forState: .Highlighted)

		moreButton = IconButton()
		moreButton.setImage(UIImage(named: "ic_more_vert_white"), forState: .Normal)
		moreButton.setImage(UIImage(named: "ic_more_vert_white"), forState: .Highlighted)
		moreButton.addTarget(self, action: #selector(handleMoreButton), forControlEvents: .TouchUpInside)

		navigationItem.leftControls = [menuButton]
		navigationItem.rightControls = [searchButton, castButton, moreButton]

		// DropDown menu
		dropDown = DropDown()
		dropDown.width = 56 * 3
		dropDown.anchorView = moreButton
		dropDown.cellNib = UINib(nibName: "DropDownMaterialTableViewCell", bundle: nil)
		dropDown.transform = CGAffineTransformMakeTranslation(-8, 0)
		dropDown.selectionAction = { (index, content) in
			print("\(index) - \(content)")
		}
		dropDown.dataSource = ["Settings", "Help", "Logout"]

    }

	// MARK: - Memory/resource management

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

	// MARK: - Event handler

	internal func handleMenuButton() {
		navigationDrawerController?.openLeftView()
	}

	internal func handleMoreButton() {
		dropDown.show()
	}

	// MARK: - Layout methods

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		statusBarView.hidden = MaterialDevice.isLandscape && .iPhone == MaterialDevice.type
	}

}
