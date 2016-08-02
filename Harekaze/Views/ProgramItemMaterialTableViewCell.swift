//
//  ProgramItemMaterialTableViewCell.swift
//  Harekaze
//
//  Created by Yuki MIZUNO on 2016/07/23.
//  Copyright © 2016年 Yuki MIZUNO. All rights reserved.
//

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

	override func drawRect(rect: CGRect) {
		let line = UIBezierPath(rect: CGRect(origin: CGPointZero, size: CGSize(width: 20, height: 88)))
		UIColor.blueColor().setStroke()
		UIColor.redColor().setFill()
		line.stroke()
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

		let deleteAction = EECellSwipeAction(fraction: -0.50)
		deleteAction.icon = UIImage(named: "ic_delete_sweep")!
		deleteAction.inactiveBackgroundColor = MaterialColor.red.accent1
		deleteAction.activeBackgroundColor = MaterialColor.red.accent2
		deleteAction.behavior = .Push
		deleteAction.didTrigger = { (tableView, indexPath) in
			func warningDialog(error: SessionTaskError) -> MaterialAlertViewController {
				var message = ""
				switch error {
				case .ConnectionError(let error as NSError):
					message = error.localizedDescription
				case .RequestError(let error as NSError):
					message = error.localizedDescription
				case .ResponseError(let error as NSError):
					message = error.localizedDescription
				case .ConnectionError:
					message = "Connection error."
				case .RequestError:
					message = "Request error."
				case .ResponseError:
					message = "Response error."
				}
				let warningAlertController = MaterialAlertViewController(title: "Delete program failed", message: message, preferredStyle: .Alert)
				let okAction = MaterialAlertAction(title: "OK", style: .Default, handler: {(action: MaterialAlertAction!) -> Void in warningAlertController.dismissViewControllerAnimated(true, completion: nil)})
				warningAlertController.addAction(okAction)
				return warningAlertController
			}

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

								let dialog = warningDialog(error)
								navigationController.presentViewController(dialog, animated: true, completion: nil)
							}
						}
					case .Failure(let error):
						slideGestureRecognizer.swipeToOrigin(true, completion: nil)

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

		self.addGestureRecognizer(slideGestureRecognizer)
	}
}