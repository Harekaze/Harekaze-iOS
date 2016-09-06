/**
 *
 * ProgramItemMaterialTableViewCell.swift
 * Harekaze
 * Created by Yuki MIZUNO on 2016/07/23.
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

let genreColor: [String: UIColor] = [
	"anime": MaterialColor.pink.accent3,
	"information": MaterialColor.teal.accent3,
	"news": MaterialColor.lightGreen.accent3,
	"sports": MaterialColor.cyan.accent3,
	"variety": MaterialColor.yellow.accent3,
	"drama": MaterialColor.orange.accent3,
	"music": MaterialColor.indigo.accent3,
	"cinema": MaterialColor.deepPurple.accent3,
	"etc": MaterialColor.grey.lighten1
]

class ProgramItemMaterialTableViewCell: MaterialTableViewCell {

	// MARK: - Interface Builder outlets

	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var broadcastInfoLabel: UILabel!
	@IBOutlet weak var programDetailLabel: UILabel!
	@IBOutlet weak var durationLabel: UILabel!

	// MARK: - View initialization

	override func awakeFromNib() {
		layoutMargins = UIEdgeInsetsZero
		contentView.backgroundColor = MaterialColor.white
	}

	// MARK: - Entity setter
	func setCellEntities(program: Program, navigationController: UINavigationController? = nil) {
		titleLabel.text = program.title

		// Date formation
		let dateFormatter = NSDateFormatter()
		dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
		broadcastInfoLabel.text = "\(dateFormatter.stringFromDate(program.startTime))  ―  \(program.channel!.name)"

		durationLabel.text = "\(Int(program.duration / 60)) min"

		var detail = ""
		// Add episode and subtitle
		if program.episode > 0 {
			detail = "#\(program.episode) \(program.subTitle)"
		} else {
			detail = program.detail
		}
		programDetailLabel.text = detail

		let marker = UIView()
		marker.backgroundColor = genreColor[program.genre]
		self.layout(marker).left().top().bottom(0.5).width(2)


		if let navigationController = navigationController {
			self.setupGestureRecognizer(program, navigationController: navigationController)
		}
	}

	// MARK: - Setup gesture recognizer
	private func setupGestureRecognizer(program: Program, navigationController: UINavigationController) {
		let slideGestureRecognizer = EECellSwipeGestureRecognizer()
		slideGestureRecognizer.delegate = self

		let deleteAction = EECellSwipeAction(fraction: -0.25)
		deleteAction.icon = UIImage(named: "ic_delete_sweep")!
		deleteAction.inactiveBackgroundColor = MaterialColor.red.accent1
		deleteAction.activeBackgroundColor = MaterialColor.red.accent2
		deleteAction.behavior = .Push
		deleteAction.didTrigger = { (tableView, indexPath) in
			let confirmDialog = MaterialAlertViewController(title: "Delete program?", message: "Are you sure you want to permanently delete the program \(program.fullTitle) immediately?", preferredStyle: .Alert)
			let deleteAction = MaterialAlertAction(title: "DELETE", style: .Destructive, handler: {(action: MaterialAlertAction!) -> Void in
				confirmDialog.dismissViewControllerAnimated(true, completion: nil)
				UIApplication.sharedApplication().networkActivityIndicatorVisible = true
				let request = ChinachuAPI.DeleteProgramRequest(id: program.id)
				Session.sendRequest(request) { result in
					UIApplication.sharedApplication().networkActivityIndicatorVisible = false
					switch result {
					case .Success(_):
						let request = ChinachuAPI.DeleteProgramFileRequest(id: program.id)
						Session.sendRequest(request) { result in
							switch result {
							case .Success(_):
								let realm = try! Realm()
								try! realm.write {
									realm.delete(program)
								}
							case .Failure(let error):
								slideGestureRecognizer.swipeToOrigin(true, completion: nil)

								let dialog = MaterialAlertViewController.generateSimpleDialog("Delete program failed", message: ChinachuAPI.parseErrorMessage(error))
								navigationController.presentViewController(dialog, animated: true, completion: nil)
							}
						}
					case .Failure(let error):
						slideGestureRecognizer.swipeToOrigin(true, completion: nil)

						let dialog = MaterialAlertViewController.generateSimpleDialog("Delete program failed", message: ChinachuAPI.parseErrorMessage(error))
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

		self.addGestureRecognizer(slideGestureRecognizer)
	}
	
	// MARK: - Cell reuse preparation
	override func prepareForReuse() {
		super.prepareForReuse()

		titleLabel.text = ""
		broadcastInfoLabel.text = ""
		programDetailLabel.text = ""
		durationLabel.text = ""
	}
	
	// MARK: - Gesture recognizer delegate
	override func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		switch gestureRecognizer.state {
		case .Changed:
			return false
		default:
			if let _ = otherGestureRecognizer.view as? UITableView {
				// Pass-through to UITableView scroll gesture
				return true
			}
			return false
		}
	}
	
	override func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
		let location = touch.locationInView(self)
		return location.x > 58
	}
}