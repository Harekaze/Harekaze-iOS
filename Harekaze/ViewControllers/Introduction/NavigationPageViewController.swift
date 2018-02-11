/**
 *
 * NavigationPageViewController.swift
 * Harekaze
 * Created by Yuki MIZUNO on 2018/02/11.
 *
 * Copyright (c) 2016-2018, Yuki MIZUNO
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *	this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *	this list of conditions and the following disclaimer in the documentation
 *	 and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors
 *	may be used to endorse or promote products derived from this software
 *	without specific prior written permission.
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
import Sparrow

class NavigationPageViewController: UIViewController {

	// MARK: - Private instance fileds
	private let pages = ["WelcomeMessage", "SelectServer", "Authentication", "Complete"]
	private var pageViewController: UIPageViewController! {
		didSet {
			pageViewController.dataSource = self
			pageViewController.setViewControllers([storyboard!.instantiateViewController(withIdentifier: pages.first!)], direction: .forward, animated: false, completion: nil)
			for view in pageViewController.view.subviews {
				if let subView = view as? UIScrollView {
					subView.isScrollEnabled = false
				}
			}
		}
	}

	// MARK: - Instance fileds
	var isNextButtonEnabled: Bool! {
		didSet {
			nextButton.isEnabled = isNextButtonEnabled
			nextButton.backgroundColor = isNextButtonEnabled ? .white : UIColor.white.withAlphaComponent(0.8)
		}
	}

	lazy var goNext: () -> Void = {
		if let viewController = self.pageViewController.viewControllers?.first,
			var nextViewController = self.pageViewController(self.pageViewController, viewControllerAfter: viewController) {
			self.pageViewController.setViewControllers([nextViewController], direction: .forward, animated: true, completion: nil)
			if nextViewController.restorationIdentifier != self.pages.last {
				self.isNextButtonEnabled = false
			} else {
				self.nextButton.setTitle("Start", for: .normal)
				self.isNextButtonEnabled = true
			}
		}
	}

	lazy var goSkipNext: () -> Void = {
		self.goNext()
		self.goNext()
	}

	lazy var nextButtonAction: () -> Void = self.goNext

	// MARK: - IBOutlets
	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var nextButton: UIButton!
	@IBOutlet weak var logoImageView: UIImageView!

	// MARK: - View initialization
	override func viewDidLoad() {
		super.viewDidLoad()
		guard let pageViewController = self.childViewControllers.first as? UIPageViewController else {
			fatalError("Implementation Error")
		}
		self.pageViewController = pageViewController
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		UIView.animate(
			withDuration: 8,
			delay: 1,
			options: .curveEaseIn,
			animations: {
				self.logoImageView.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
		}, completion: { _ in
			UIView.animate(
				withDuration: 4,
				delay: 0,
				options: [.repeat, .curveLinear],
				animations: {
					self.logoImageView.transform = CGAffineTransform(rotationAngle: 2 * CGFloat.pi)
			})
		})
	}

	// MARK: - IBActions
	@IBAction func tapNextButton() {
		if nextButton.titleLabel?.text == "Start" {
			if let delegate = UIApplication.shared.delegate as? AppDelegate {
				guard let launchScreen = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController() else {
					return
				}
				if let logoImage = launchScreen.view.subviews.first as? UIImageView {
					logoImage.heroID = "harekaze"
					launchScreen.isHeroEnabled = true
				}
				self.show(launchScreen, sender: self)
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
					delegate.window?.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
					delegate.window?.makeKeyAndVisible()
					SPLaunchAnimation.slideWithParalax(onWindow: delegate.window!)
				}
			}
		} else {
			nextButtonAction()
		}
	}

	// MARK: - Rotation
	open override var shouldAutorotate: Bool {
		return false
	}

	open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return .portrait
	}

	open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
		return .portrait
	}
}

// MARK: - UIPageViewControllerDataSource
extension NavigationPageViewController: UIPageViewControllerDataSource {
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
		let index = pages.index(of: viewController.restorationIdentifier ?? "")
		if let index = index {
			guard pages.indices.contains(pages.index(before: index)) else {
				return nil
			}
			return storyboard?.instantiateViewController(withIdentifier: pages[pages.index(before: index)])
		}
		return nil
	}

	func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
		let index = pages.index(of: viewController.restorationIdentifier ?? "")
		if let index = index {
			guard pages.indices.contains(pages.index(after: index)) else {
				return nil
			}
			return storyboard?.instantiateViewController(withIdentifier: pages[pages.index(after: index)])
		}
		return nil
	}
}
