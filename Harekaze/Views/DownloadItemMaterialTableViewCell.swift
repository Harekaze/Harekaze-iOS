/**
*
* DownloadItemMaterialTableViewCell.swift
* Harekaze
* Created by Yuki MIZUNO on 2016/08/21.
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
import RealmSwift
import EECellSwipeGestureRecognizer
import Crashlytics

class DownloadItemMaterialTableViewCell: ProgramItemMaterialTableViewCell {

	// MARK: - Private instance fields
	private var context = 0
	private var download: Download!
	private var navigationController: UINavigationController!
	private var progressCountStartDate: NSDate!
	private var etaCalculator: NSTimer!

	// MARK: - Interface Builder outlets
	@IBOutlet weak var progressView: UIProgressView!
	@IBOutlet weak var cancelButton: IconButton!
	@IBOutlet weak var etaLabel: UILabel!


	// MARK: - Entity setter
	func setCellEntities(download download: Download, navigationController: UINavigationController) {

		super.setCellEntities(download.program!)

		self.download = download
		self.navigationController = navigationController

		if download.size > 0 {
			cancelButton.hidden = true
			etaLabel.hidden = true
			setupGestureRecognizer()
		} else {
			// Set progress bar observer
			if let progress = DownloadManager.sharedInstance.progressRequest(download.program!.id) {
				if self.progressCountStartDate != nil { return }
				self.progressCountStartDate = download.downloadStartDate
				self.etaCalculator = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(calculateEstimatedTimeOfArrival), userInfo: nil, repeats: true)

				progress.addObserver(self, forKeyPath: "fractionCompleted", options: [.New], context: &context)
			} else {
				cancelButton.hidden = true
				etaLabel.hidden = true
				setupGestureRecognizer()
			}
		}
	}

	// MARK: - Interface Builder actions

	@IBAction func handleCancelButtonPressed() {
		DownloadManager.sharedInstance.stopRequest(download.program!.id)
		progressView.setProgress(0, animated: true)
		// Stop eta counter
		etaCalculator.invalidate()
		print(etaCalculator)

		// Realm configuration
		var config = Realm.Configuration()
		config.fileURL = config.fileURL!.URLByDeletingLastPathComponent?.URLByAppendingPathComponent("downloads.realm")
		config.schemaVersion = 1
		config.migrationBlock = {migration, oldSchemeVersion in
			if oldSchemeVersion < 1 {
				Answers.logCustomEventWithName("Local realm store migration", customAttributes: ["migration": migration, "old version": Int(oldSchemeVersion), "new version": 1])
			}
		}

		// Delete downloaded program from realm
		let realm = try! Realm(configuration: config)
		try! realm.write {
			realm.delete(self.download)
		}
	}

	// MARK: - Observer

	override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String: AnyObject]?, context: UnsafeMutablePointer<Void>) {
		if context == &self.context && keyPath == "fractionCompleted" {
			if let progress = object as? NSProgress {
				dispatch_async(dispatch_get_main_queue()) {
					self.progressView.setProgress(Float(progress.fractionCompleted), animated: true)
				}
			}
		} else {
			super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
		}
	}

	// MARK: - ETA counter
	func calculateEstimatedTimeOfArrival() {
		let currentProgress = Double(self.progressView.progress)
		let progressPerSec = -currentProgress / progressCountStartDate.timeIntervalSinceNow
		let eta = progressPerSec > 0 ? Int((1 - currentProgress) / progressPerSec) : -1

		switch eta {
		case 0..<100:
			etaLabel.text = "ETA \(eta)s"
		case 100..<60*60:
			etaLabel.text = "ETA \(Int(eta / 60))m"
		default:
			etaLabel.text = "ETA n/a"
		}
	}

	// MARK: - Setup gesture recognizer
	private func setupGestureRecognizer() {
		// Remove old swipe gesture recognizer
		if let gestureRecognizers = gestureRecognizers {
			for gestureRecognizer in gestureRecognizers {
				self.removeGestureRecognizer(gestureRecognizer)
			}
		}

		let slideGestureRecognizer = EECellSwipeGestureRecognizer()

		// Download file deletion
		let deleteAction = EECellSwipeAction(fraction: -0.25)
		deleteAction.icon = UIImage(named: "ic_delete_sweep")!
		deleteAction.inactiveBackgroundColor = MaterialColor.red.accent1
		deleteAction.activeBackgroundColor = MaterialColor.red.accent2
		deleteAction.behavior = .Push
		deleteAction.didTrigger = { (tableView, indexPath) in
			let confirmDialog = MaterialAlertViewController(title: "Delete downloaded program?", message: "Are you sure you want to delete downloaded program \(self.download.program!.fullTitle)?", preferredStyle: .Alert)
			let deleteAction = MaterialAlertAction(title: "DELETE", style: .Destructive, handler: {(action: MaterialAlertAction!) -> Void in
				confirmDialog.dismissViewControllerAnimated(true, completion: nil)

				let documentURL = try! NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false)
				let saveDirectoryPath = documentURL.URLByAppendingPathComponent(self.download.program!.id)
				let filepath = saveDirectoryPath.URLByAppendingPathComponent("file.m2ts")

				do {
					try NSFileManager.defaultManager().removeItemAtURL(filepath)
					// Realm configuration
					var config = Realm.Configuration()
					config.fileURL = config.fileURL!.URLByDeletingLastPathComponent?.URLByAppendingPathComponent("downloads.realm")
					config.schemaVersion = 1
					config.migrationBlock = {migration, oldSchemeVersion in
						if oldSchemeVersion < 1 {
							Answers.logCustomEventWithName("Local realm store migration", customAttributes: ["migration": migration, "old version": Int(oldSchemeVersion), "new version": 1])
						}
					}

					// Delete downloaded program from realm
					let realm = try! Realm(configuration: config)
					try! realm.write {
						realm.delete(self.download)
					}
				} catch let error as NSError  {
					Answers.logCustomEventWithName("Delete downloaded program error", customAttributes: ["error": error])

					let dialog = MaterialAlertViewController.generateSimpleDialog("Delete downloaded program failed", message: error.localizedDescription)
					self.navigationController.presentViewController(dialog, animated: true, completion: nil)
				}
				slideGestureRecognizer.swipeToOrigin(true, completion: nil)
			})
			let cancelAction = MaterialAlertAction(title: "CANCEL", style: .Cancel, handler: {(action: MaterialAlertAction!) in
				confirmDialog.dismissViewControllerAnimated(true, completion: nil)
				slideGestureRecognizer.swipeToOrigin(true, completion: nil)
			})
			confirmDialog.addAction(cancelAction)
			confirmDialog.addAction(deleteAction)

			self.navigationController.presentViewController(confirmDialog, animated: true, completion: nil)
		}
		slideGestureRecognizer.addActions([deleteAction])


		self.addGestureRecognizer(slideGestureRecognizer)
	}
	

}
