/**
 *
 * MainNavigationController.swift
 * Harekaze
 * Created by Yuki MIZUNO on 2016/07/17.
 * 
 * Copyright (c) 2016-2017, Yuki MIZUNO
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
import ARNTransitionAnimator

class MainNavigationController: NavigationController {

	// MARK: - Private instance fileds
	private var menuButton: IconButton!
	private var searchButton: IconButton!
	private var castButton: IconButton!

	// MARK: - View initialization

	override func viewDidLoad() {
		super.viewDidLoad()
		self.delegate = self as? UINavigationControllerDelegate

		// Set navigation bar buttons
		guard let navigationItem = (self.viewControllers.first as? BottomNavigationController)?.navigationItem else {
			return
		}
		menuButton = IconButton(image: UIImage(named: "ic_menu_white"))
		menuButton.addTarget(self, action: #selector(handleMenuButton), for: .touchUpInside)

		searchButton = IconButton(image: UIImage(named: "ic_search_white"))
		searchButton.addTarget(self, action: #selector(handleSearchButton), for: .touchUpInside)

		castButton = IconButton(image: UIImage(named: "ic_cast_white"))

		navigationItem.titleLabel.textAlignment = .left
		navigationItem.leftViews = [menuButton]
		navigationItem.rightViews = [searchButton, castButton]
	}

	// MARK: - Memory/resource management

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	// MARK: - Event handler

	internal func handleMenuButton() {
		navigationDrawerController?.openLeftView()
	}

	internal func handleSearchButton() {
		let searchNavigationController = self.storyboard!.instantiateViewController(withIdentifier: "ProgramSearchResultTableViewController")
		let searchBarController = SearchBarController(rootViewController: searchNavigationController)
		searchBarController.modalTransitionStyle = .crossDissolve
		present(SearchNavigationController(rootViewController: searchBarController), animated: true, completion: nil)
	}

	// MARK: - Layout methods

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
	}

	// MARK: - Navigation

	func navigationController(_ navigationController: UINavigationController,
	                                   animationControllerFor operation: UINavigationControllerOperation,
	                                   from fromVC: UIViewController,
	                                   to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {

		if fromVC as? TimerDetailTableViewController != nil {
			return nil
		}
		if toVC as? TimerDetailTableViewController != nil {
			return nil
		}

		switch operation {
		case .push:
			let animation = ShowDetailTransition(fromVC: fromVC, toVC: toVC)
			let animator = ARNTransitionAnimator(duration: 0.4, animation: animation)
			return animator.animationController(forPresented: self, presenting: toVC, source: fromVC)
		case .pop:
			let animation = ShowDetailTransition(fromVC: toVC, toVC: fromVC)
			let animator = ARNTransitionAnimator(duration: 0.4, animation: animation)
			return animator.animationController(forDismissed: self)
		case .none:
			return nil
		}
	}

}
