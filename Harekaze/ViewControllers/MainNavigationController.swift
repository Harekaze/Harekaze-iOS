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
import ARNTransitionAnimator

class MainNavigationController: NavigationController, UINavigationControllerDelegate {

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
		self.delegate = self

		// Chinachu API settings
		let userDefaults = NSUserDefaults()
		userDefaults.registerDefaults(["ChinachuWUIAddress": "http://chinachu.local:10772"])
		ChinachuAPI.wuiAddress = userDefaults.stringForKey("ChinachuWUIAddress")!

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
		searchButton.addTarget(self, action: #selector(handleSearchButton), forControlEvents: .TouchUpInside)

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
		dropDown.dataSource = ["Help", "Logout"]

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

	internal func handleSearchButton() {
		let searchNavigationController = self.storyboard!.instantiateViewControllerWithIdentifier("ProgramSearchResultTableViewController")
		let searchBarController = SearchBarController(rootViewController: searchNavigationController)
		searchBarController.modalTransitionStyle = .CrossDissolve
		presentViewController(SearchNavigationController(rootViewController: searchBarController), animated: true, completion: nil)
	}

	// MARK: - Layout methods

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		statusBarView.hidden = MaterialDevice.isLandscape && .iPhone == MaterialDevice.type
	}

	// MARK: - Navigation
	
	func navigationController(navigationController: UINavigationController,
	                          animationControllerForOperation operation: UINavigationControllerOperation,
	                                                          fromViewController fromVC: UIViewController,
	                                                                             toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {

		switch operation {
		case .Push:
			return ShowDetailTransition.createAnimator(.Push, fromVC: fromVC, toVC: toVC)
		case .Pop:
			return ShowDetailTransition.createAnimator(.Pop, fromVC: fromVC, toVC: toVC)
		case .None:
			return nil
		}
	}

}
