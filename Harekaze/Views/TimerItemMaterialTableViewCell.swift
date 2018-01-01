/**
 *
 * TimerItemMaterialTableViewCell.swift
 * Harekaze
 * Created by Yuki MIZUNO on 2016/08/02.
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
import DRCellSlideGestureRecognizer
import APIKit
import RealmSwift

class TimerItemMaterialTableViewCell: ProgramItemMaterialTableViewCell {

	// MARK: - Interface Builder outlets
	@IBOutlet weak var warningImageView: UIImageView!
	@IBOutlet weak var warningImageConstraintWidth: NSLayoutConstraint!
	@IBOutlet weak var recordTypeImageView: UIImageView!

	// MARK: - Entity setter
	override func setCellEntities(_ program: Program, navigationController: UINavigationController? = nil) {
		super.setCellEntities(program)

		guard let timer = program as? Timer else { return }

		if timer.skip {
			let disabledColor = Material.Color.darkText.others
			titleLabel.textColor = disabledColor
			broadcastInfoLabel.textColor = disabledColor
			programDetailLabel.textColor = disabledColor
			durationLabel.textColor = disabledColor
			warningImageView.tintColor = disabledColor
			recordTypeImageView.tintColor = disabledColor
		} else {
			titleLabel.textColor = Material.Color.darkText.primary
			broadcastInfoLabel.textColor = Material.Color.darkText.secondary
			programDetailLabel.textColor = Material.Color.darkText.secondary
			durationLabel.textColor = Material.Color.darkText.secondary
			warningImageView.tintColor = Material.Color.red.accent2
			recordTypeImageView.tintColor = Material.Color.darkText.secondary
		}

		if timer.conflict {
			warningImageView.image = UIImage(named: "ic_warning")?.withRenderingMode(.alwaysTemplate)
			warningImageConstraintWidth.constant = 24
		} else {
			warningImageView.isHidden = true
			warningImageConstraintWidth.constant = 0
		}

		if timer.manual {
			recordTypeImageView.image = UIImage(named: "ic_fiber_manual_record")?.withRenderingMode(.alwaysTemplate)
		} else {
			recordTypeImageView.image = UIImage(named: "ic_fiber_smart_record")?.withRenderingMode(.alwaysTemplate)
		}

		if let navigationController = navigationController {
			self.setupGestureRecognizer(timer, navigationController: navigationController)
		}
	}

	// MARK: - Setup gesture recognizer

	private func setupGestureRecognizer(_ timer: Timer, navigationController: UINavigationController) {
		// Remove old swipe gesture recognizer
		if let gestureRecognizers = gestureRecognizers {
			for gestureRecognizer in gestureRecognizers {
				self.removeGestureRecognizer(gestureRecognizer)
			}
		}

		let slideGestureRecognizer = DRCellSlideGestureRecognizer()
		slideGestureRecognizer.delegate = self

		if timer.manual {
			// Timer deletion
			let deleteAction = setupTimerDeletionGestureAction(timer: timer, navigationController: navigationController)
			slideGestureRecognizer.addActions([deleteAction])
		} else {
			// Timer skipping/un-skipping
			let skipAction = setupTimerSkipGestureAction(timer: timer, navigationController: navigationController)
			slideGestureRecognizer.addActions([skipAction])
		}

		self.addGestureRecognizer(slideGestureRecognizer)
	}

	private func setupTimerDeletionGestureAction(timer: Timer, navigationController: UINavigationController) -> DRCellSlideAction {
		let deleteAction = DRCellSlideAction(forFraction: -0.25)!
		deleteAction.icon = UIImage(named: "ic_delete_sweep")!
		deleteAction.inactiveBackgroundColor = Material.Color.red.accent1
		deleteAction.activeBackgroundColor = Material.Color.red.accent2
		deleteAction.behavior = .pushBehavior
		deleteAction.didTriggerBlock = { (tableView, indexPath) in
			let confirmDialog = MaterialAlertViewController(title: "Delete timer?",
			                                                message: "Are you sure you want to delete the timer \(timer.fullTitle)?",
				preferredStyle: .alert)
			let deleteAction = MaterialAlertAction(title: "DELETE", style: .destructive, handler: {_ in
				confirmDialog.dismiss(animated: true, completion: nil)
				UIApplication.shared.isNetworkActivityIndicatorVisible = true
				let request = ChinachuAPI.TimerDeleteRequest(id: timer.id)
				Session.send(request) { result in
					UIApplication.shared.isNetworkActivityIndicatorVisible = false
					//slideGestureRecognizer.swipeToOrigin(true, completion: nil)
					self.frame.origin.x = -self.frame.origin.x

					switch result {
					case .success:
						let realm = try! Realm()
						try! realm.write {
							realm.delete(timer)
						}
					case .failure(let error):
						let dialog = MaterialAlertViewController.generateSimpleDialog("Delete timer failed",
						                                                              message: ChinachuAPI.parseErrorMessage(error))
						navigationController.present(dialog, animated: true, completion: nil)
					}
				}

			})
			let cancelAction = MaterialAlertAction(title: "CANCEL", style: .cancel, handler: {_ in
				confirmDialog.dismiss(animated: true, completion: nil)
				//slideGestureRecognizer.swipeToOrigin(true, completion: nil)
				self.frame.origin.x = -self.frame.origin.x
			})
			confirmDialog.addAction(cancelAction)
			confirmDialog.addAction(deleteAction)

			navigationController.present(confirmDialog, animated: true, completion: nil)
		}
		return deleteAction
	}

	private func setupTimerSkipGestureAction(timer: Timer, navigationController: UINavigationController) -> DRCellSlideAction {
		let skipAction = DRCellSlideAction(forFraction: -0.25)!
		if timer.skip {
			skipAction.icon = UIImage(named: "ic_add_circle")!
			skipAction.inactiveBackgroundColor = Material.Color.blue.accent1
			skipAction.activeBackgroundColor = Material.Color.blue.accent2
		} else {
			skipAction.icon = UIImage(named: "ic_remove_circle")!
			skipAction.inactiveBackgroundColor = Material.Color.red.accent1
			skipAction.activeBackgroundColor = Material.Color.red.accent2
		}
		skipAction.behavior = .pushBehavior
		skipAction.didTriggerBlock = { (tableView, indexPath) in
			UIApplication.shared.isNetworkActivityIndicatorVisible = true
			if timer.skip {
				let request = ChinachuAPI.TimerUnskipRequest(id: timer.id)
				Session.send(request) { result in
					UIApplication.shared.isNetworkActivityIndicatorVisible = false
					//slideGestureRecognizer.swipeToOrigin(true, completion: nil)
					self.frame.origin.x = -self.frame.origin.x

					switch result {
					case .success:
						let realm = try! Realm()
						try! realm.write {
							timer.skip = false
						}
					case .failure(let error):
						let dialog = MaterialAlertViewController.generateSimpleDialog("Unskip timer failed",
						                                                              message: ChinachuAPI.parseErrorMessage(error))
						navigationController.present(dialog, animated: true, completion: nil)
					}
				}
			} else {
				let request = ChinachuAPI.TimerSkipRequest(id: timer.id)
				Session.send(request) { result in
					UIApplication.shared.isNetworkActivityIndicatorVisible = false
					//slideGestureRecognizer.swipeToOrigin(true, completion: nil)
					self.frame.origin.x = -self.frame.origin.x

					switch result {
					case .success:
						let realm = try! Realm()
						try! realm.write {
							timer.skip = true
						}
					case .failure(let error):
						let dialog = MaterialAlertViewController.generateSimpleDialog("Skip timer failed",
						                                                              message: ChinachuAPI.parseErrorMessage(error))
						navigationController.present(dialog, animated: true, completion: nil)
					}
				}
			}
		}
		return skipAction
	}

}
