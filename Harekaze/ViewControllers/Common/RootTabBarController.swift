/**
*
* RootTabBarController.swift
* Harekaze
* Created by Yuki MIZUNO on 2018/01/15.
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

class RootTabBarController: UITabBarController {

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if self.childViewControllers.count != 5 {
			return
		}
		if let navigationController = self.childViewControllers[0] as? TransitionableTintColorNavigationController,
			let recordingsViewController = navigationController.topViewController as? RecordingsTableViewController {
			recordingsViewController.refreshDataSource()
		}
		if let navigationController = self.childViewControllers[1] as? TransitionableTintColorNavigationController,
			let timersViewController = navigationController.topViewController as? TimersTableViewController {
			timersViewController.refreshDataSource()
		}
		if let navigationController = self.childViewControllers[2] as? TransitionableTintColorNavigationController,
			let guideViewController = navigationController.topViewController as? GuideViewController {
			guideViewController.refreshDataSource()
		}
	}

	open override var shouldAutorotate: Bool {
		return true
	}

	open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		guard let currentViewController = self.selectedViewController else {
			return .portrait
		}
		guard let navigationController = currentViewController as? UINavigationController else {
			return currentViewController.supportedInterfaceOrientations
		}
		guard let viewController = navigationController.viewControllers.last else {
			return navigationController.supportedInterfaceOrientations
		}
		return viewController.supportedInterfaceOrientations
	}

	open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
		guard let currentViewController = self.selectedViewController else {
			return .portrait
		}
		guard let navigationController = currentViewController as? UINavigationController else {
			return currentViewController.preferredInterfaceOrientationForPresentation
		}
		guard let viewController = navigationController.viewControllers.last else {
			return navigationController.preferredInterfaceOrientationForPresentation
		}
		return viewController.preferredInterfaceOrientationForPresentation
	}
}
