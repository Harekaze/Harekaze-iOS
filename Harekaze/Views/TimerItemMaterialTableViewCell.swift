/**
 *
 * TimerItemMaterialTableViewCell.swift
 * Harekaze
 * Created by Yuki MIZUNO on 2016/08/02.
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
import EECellSwipeGestureRecognizer
import APIKit
import RealmSwift

class TimerItemMaterialTableViewCell: ProgramItemMaterialTableViewCell {

	// MARK: - Interface Builder outlets
	@IBOutlet weak var warningImageView: UIImageView!
	@IBOutlet weak var warningImageConstraintWidth: NSLayoutConstraint!
	@IBOutlet weak var recordTypeImageView: UIImageView!


	// MARK: - Entity setter
	override func setCellEntities(program: Program, navigationController: UINavigationController? = nil) {
		super.setCellEntities(program)

		guard let timer = program as? Timer else { return }

		if timer.skip {
			let disabledColor = MaterialColor.darkText.others
			titleLabel.textColor = disabledColor
			broadcastInfoLabel.textColor = disabledColor
			programDetailLabel.textColor = disabledColor
			durationLabel.textColor = disabledColor
			warningImageView.tintColor = disabledColor
			recordTypeImageView.tintColor = disabledColor
		} else {
			titleLabel.textColor = MaterialColor.darkText.primary
			broadcastInfoLabel.textColor = MaterialColor.darkText.secondary
			programDetailLabel.textColor = MaterialColor.darkText.secondary
			durationLabel.textColor = MaterialColor.darkText.secondary
			warningImageView.tintColor = MaterialColor.red.accent2
			recordTypeImageView.tintColor = MaterialColor.darkText.secondary
		}

		if timer.conflict {
			warningImageView.image = UIImage(named: "ic_warning")?.imageWithRenderingMode(.AlwaysTemplate)
			warningImageConstraintWidth.constant = 24
		} else {
			warningImageView.hidden = true
			warningImageConstraintWidth.constant = 0
		}

		if timer.manual {
			recordTypeImageView.image = UIImage(named: "ic_fiber_manual_record")?.imageWithRenderingMode(.AlwaysTemplate)
		} else {
			recordTypeImageView.image = UIImage(named: "ic_fiber_smart_record")?.imageWithRenderingMode(.AlwaysTemplate)
		}
		
		if let navigationController = navigationController {
			self.setupGestureRecognizer(timer, navigationController: navigationController)
		}
	}


	// MARK: - Setup gesture recognizer
	private func setupGestureRecognizer(timer: Timer, navigationController: UINavigationController) {
		// Remove old swipe gesture recognizer
		if let gestureRecognizers = gestureRecognizers {
			for gestureRecognizer in gestureRecognizers {
				self.removeGestureRecognizer(gestureRecognizer)
			}
		}

		let slideGestureRecognizer = EECellSwipeGestureRecognizer()

		if timer.manual {
			// Timer deletion
			let deleteAction = EECellSwipeAction(fraction: -0.25)
			deleteAction.icon = UIImage(named: "ic_delete_sweep")!
			deleteAction.inactiveBackgroundColor = MaterialColor.red.accent1
			deleteAction.activeBackgroundColor = MaterialColor.red.accent2
			deleteAction.behavior = .Push
			deleteAction.didTrigger = { (tableView, indexPath) in
				func warningDialog(error: SessionTaskError) -> MaterialAlertViewController {
					let message = ChinachuAPI.parseErrorMessage(error)
					let warningAlertController = MaterialAlertViewController(title: "Delete timer failed", message: message, preferredStyle: .Alert)
					let okAction = MaterialAlertAction(title: "OK", style: .Default, handler: {(action: MaterialAlertAction!) -> Void in warningAlertController.dismissViewControllerAnimated(true, completion: nil)})
					warningAlertController.addAction(okAction)
					return warningAlertController
				}

				let confirmDialog = MaterialAlertViewController(title: "Delete timer?", message: "Are you sure you want to delete the timer \(timer.fullTitle)?", preferredStyle: .Alert)
				let deleteAction = MaterialAlertAction(title: "DELETE", style: .Destructive, handler: {(action: MaterialAlertAction!) -> Void in
					confirmDialog.dismissViewControllerAnimated(true, completion: nil)
					UIApplication.sharedApplication().networkActivityIndicatorVisible = true
					let request = ChinachuAPI.TimerDeleteRequest(id: timer.id)
					Session.sendRequest(request) { result in
						UIApplication.sharedApplication().networkActivityIndicatorVisible = false
						slideGestureRecognizer.swipeToOrigin(true, completion: nil)
						switch result {
						case .Success(_):
							let realm = try! Realm()
							try! realm.write {
								realm.delete(timer)
							}
						case .Failure(let error):
							let dialog = warningDialog(error)
							navigationController.presentViewController(dialog, animated: true, completion: nil)
						}
					}

				})
				let cancelAction = MaterialAlertAction(title: "CANCEL", style: .Cancel, handler: {(action: MaterialAlertAction!) in
					confirmDialog.dismissViewControllerAnimated(true, completion: nil)
					slideGestureRecognizer.swipeToOrigin(true, completion: nil)
				})
				confirmDialog.addAction(cancelAction)
				confirmDialog.addAction(deleteAction)

				navigationController.presentViewController(confirmDialog, animated: true, completion: nil)
			}
			slideGestureRecognizer.addActions([deleteAction])
		} else {
			// Timer skipping/un-skipping
			let skipAction = EECellSwipeAction(fraction: -0.25)
			if timer.skip {
				skipAction.icon = UIImage(named: "ic_add_circle")!
				skipAction.inactiveBackgroundColor = MaterialColor.blue.accent1
				skipAction.activeBackgroundColor = MaterialColor.blue.accent2
			} else {
				skipAction.icon = UIImage(named: "ic_remove_circle")!
				skipAction.inactiveBackgroundColor = MaterialColor.red.accent1
				skipAction.activeBackgroundColor = MaterialColor.red.accent2
			}
			skipAction.behavior = .Push
			skipAction.didTrigger = { (tableView, indexPath) in
				func warningDialog(error: SessionTaskError) -> MaterialAlertViewController {
					let message = ChinachuAPI.parseErrorMessage(error)
					let warningAlertController = MaterialAlertViewController(title: "\(timer.skip ? "Skip" : "Unskip") timer failed", message: message, preferredStyle: .Alert)
					let okAction = MaterialAlertAction(title: "OK", style: .Default, handler: {(action: MaterialAlertAction!) -> Void in warningAlertController.dismissViewControllerAnimated(true, completion: nil)})
					warningAlertController.addAction(okAction)
					return warningAlertController
				}

				UIApplication.sharedApplication().networkActivityIndicatorVisible = true

				if timer.skip {
					let request = ChinachuAPI.TimerUnskipRequest(id: timer.id)
					Session.sendRequest(request) { result in
						UIApplication.sharedApplication().networkActivityIndicatorVisible = false
						slideGestureRecognizer.swipeToOrigin(true, completion: nil)
						switch result {
						case .Success(_):
							let realm = try! Realm()
							try! realm.write {
								timer.skip = !timer.skip
							}
						case .Failure(let error):
							let dialog = warningDialog(error)
							navigationController.presentViewController(dialog, animated: true, completion: nil)
						}
					}
				} else {
					let request = ChinachuAPI.TimerSkipRequest(id: timer.id)
					Session.sendRequest(request) { result in
						UIApplication.sharedApplication().networkActivityIndicatorVisible = false
						slideGestureRecognizer.swipeToOrigin(true, completion: nil)
						switch result {
						case .Success(_):
							let realm = try! Realm()
							try! realm.write {
								timer.skip = !timer.skip
							}
						case .Failure(let error):
							let dialog = warningDialog(error)
							navigationController.presentViewController(dialog, animated: true, completion: nil)
						}
					}
				}

			}
			slideGestureRecognizer.addActions([skipAction])
		}

		self.addGestureRecognizer(slideGestureRecognizer)
	}

}
