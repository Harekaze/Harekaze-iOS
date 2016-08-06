/**
 *
 * MainNavigationController.swift
 * Harekaze
 * Created by Yuki MIZUNO on 2016/07/17.
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
