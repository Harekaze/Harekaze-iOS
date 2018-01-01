/**
 *
 * SearchNavigationController.swift
 * Harekaze
 * Created by Yuki MIZUNO on 2016/07/23.
 * 
 * Copyright (c) 2016-2018, Yuki MIZUNO
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

class SearchNavigationController: NavigationController {
	// MARK: - Initialization

	private init() {
		super.init(nibName: nil, bundle: nil)
	}

	override init(nibName: String?, bundle: Bundle?) {
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
		self.delegate = self as? UINavigationControllerDelegate

		// Hide navigation bar
		self.navigationBar.backgroundColor = Material.Color.white
		self.navigationBar.isTranslucent = true
		self.navigationBar.isHidden = true
	}

	// MARK: - Memory/resource management

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
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

		switch operation {
		case .push:
			self.navigationBar.backgroundColor = Material.Color.white
			self.navigationBar.isHidden = false
			let animation = ShowDetailTransition(fromVC: fromVC, toVC: toVC)
			let animator = ARNTransitionAnimator(duration: 0.4, animation: animation)
			return animator.animationController(forPresented: self, presenting: toVC, source: fromVC)
		case .pop:
			self.navigationBar.isHidden = true
			let animation = ShowDetailTransition(fromVC: toVC, toVC: fromVC)
			let animator = ARNTransitionAnimator(duration: 0.4, animation: animation)
			return animator.animationController(forDismissed: self)
		case .none:
			return nil
		}

	}

}
