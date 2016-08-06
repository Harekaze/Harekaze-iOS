//
//  SearchNavigationController.swift
//  Harekaze
//
//  Created by Yuki MIZUNO on 2016/07/23.
//  Copyright © 2016年 Yuki MIZUNO. All rights reserved.
//

import UIKit
import Material

class SearchNavigationController: NavigationController, UINavigationControllerDelegate {

	// MARK: - Private instance fileds
	private var statusBarView: MaterialView!
	private var statusBarHidden: Bool = true


	// MARK: - Initialization

	private init() {
		super.init(nibName: nil, bundle: nil)
	}

	override init(nibName: String?, bundle: NSBundle?) {
		super.init(nibName: nil, bundle: nil)
	}

	override init(rootViewController: UIViewController) {
		super.init(rootViewController: rootViewController)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - View initialization

	override func viewDidLoad() {
		super.viewDidLoad()
		self.delegate = self

		// Hide navigation bar
		self.navigationBar.backgroundColor = MaterialColor.white
		self.navigationBar.translucent = true
		self.navigationBar.hidden = true

		// Set status bar
		statusBarView = MaterialView()
		statusBarView.zPosition = 3000
		statusBarView.restorationIdentifier = "StatusBarView"
		statusBarView.backgroundColor = MaterialColor.black.colorWithAlphaComponent(0.12)
		self.view.layout(statusBarView).top(0).horizontally().height(20)
	}

	// MARK: - Memory/resource management

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	// MARK: - Layout methods

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		statusBarView.hidden = statusBarHidden || MaterialDevice.isLandscape && .iPhone == MaterialDevice.type
	}

	// MARK: - Navigation

	func navigationController(navigationController: UINavigationController,
							  animationControllerForOperation operation: UINavigationControllerOperation,
															  fromViewController fromVC: UIViewController,
																				 toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {

		switch operation {
		case .Push:
			self.navigationBar.backgroundColor = MaterialColor.white
			self.navigationBar.hidden = false
			self.statusBarHidden = false
			return ShowDetailTransition.createAnimator(.Push, fromVC: fromVC, toVC: toVC)
		case .Pop:
			self.navigationBar.hidden = true
			self.statusBarHidden = true
			return ShowDetailTransition.createAnimator(.Pop, fromVC: fromVC, toVC: toVC)
		case .None:
			return nil
		}
	}
	


}
