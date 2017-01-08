/**
*
* DownloadItemMaterialTableViewCell.swift
* Harekaze
* Created by Yuki MIZUNO on 2016/08/21.
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
import RealmSwift
import DRCellSlideGestureRecognizer
import Crashlytics

class DownloadItemMaterialTableViewCell: ProgramItemMaterialTableViewCell {

	// MARK: - Private instance fields
	fileprivate var context = 0
	fileprivate var download: Download!
	fileprivate var navigationController: UINavigationController!
	fileprivate var etaCalculator: Foundation.Timer!

	// MARK: - Interface Builder outlets
	@IBOutlet weak var progressView: UIProgressView!
	@IBOutlet weak var cancelButton: IconButton!
	@IBOutlet weak var etaLabel: UILabel!

	// MARK: - Entity setter
	func setCellEntities(download: Download, navigationController: UINavigationController) {

		super.setCellEntities(download.program!)

		self.download = download
		self.navigationController = navigationController

		if download.size > 0 {
			cancelButton.isHidden = true
			etaLabel.isHidden = true
			setupGestureRecognizer()
		} else {
			// Set progress bar observer
			if let progress = DownloadManager.shared.progressRequest(download.program!.id) {
				self.etaCalculator = Foundation.Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(calculateEstimatedTimeOfArrival), userInfo: nil, repeats: true)
				progress.addObserver(self, forKeyPath: "fractionCompleted", options: [.new], context: &context)
			} else {
				cancelButton.isHidden = true
				etaLabel.isHidden = true
				setupGestureRecognizer()
			}
		}
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		etaCalculator?.invalidate()
		if download.isInvalidated {
			return
		}
		if let download = download {
			if let program = download.program {
				if let progress = DownloadManager.shared.progressRequest(program.id) {
					progress.removeObserver(self, forKeyPath: "fractionCompleted", context: &context)
				}
			}
		}
	}

	// MARK: - Interface Builder actions

	@IBAction func handleCancelButtonPressed() {
		DownloadManager.shared.stopRequest(download.program!.id)
		// Stop progress observer
		progressView.setProgress(0, animated: true)
		if let progress = DownloadManager.shared.progressRequest(download.program!.id) {
			progress.removeObserver(self, forKeyPath: "fractionCompleted", context: &context)
		}
		// Stop eta counter
		etaCalculator.invalidate()

		// Realm configuration
		var config = Realm.Configuration()
		config.fileURL = config.fileURL!.deletingLastPathComponent().appendingPathComponent("downloads.realm")
		config.schemaVersion = Download.SchemeVersion
		config.migrationBlock = {migration, oldSchemeVersion in
			if oldSchemeVersion < Download.SchemeVersion {
				Answers.logCustomEvent(withName: "Local realm store migration", customAttributes: ["migration": migration, "old version": Int(oldSchemeVersion), "new version": Int(Download.SchemeVersion)])
			}
		}

		// Delete downloaded program from realm
		let realm = try! Realm(configuration: config)
		try! realm.write {
			realm.delete(self.download)
		}
	}

	// MARK: - Observer

	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if context == &self.context && keyPath == "fractionCompleted" {
			if let progress = object as? Progress {
				DispatchQueue.main.async {
					self.progressView.setProgress(Float(progress.fractionCompleted), animated: true)
				}
			}
		} else {
			super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
		}
	}

	// MARK: - ETA counter
	func calculateEstimatedTimeOfArrival() {
		let currentProgress = Double(self.progressView.progress)
		let progressPerSec = -currentProgress / download.downloadStartDate.timeIntervalSinceNow
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
	fileprivate func setupGestureRecognizer() {
		// Remove old swipe gesture recognizer
		if let gestureRecognizers = gestureRecognizers {
			for gestureRecognizer in gestureRecognizers {
				self.removeGestureRecognizer(gestureRecognizer)
			}
		}

		let slideGestureRecognizer = DRCellSlideGestureRecognizer()
		slideGestureRecognizer.delegate = self

		// Download file deletion
		let deleteAction = DRCellSlideAction(forFraction: -0.25)!
		deleteAction.icon = UIImage(named: "ic_delete_sweep")!
		deleteAction.inactiveBackgroundColor = Material.Color.red.accent1
		deleteAction.activeBackgroundColor = Material.Color.red.accent2
		deleteAction.behavior = .pushBehavior
		deleteAction.didTriggerBlock = { (tableView, indexPath) in
			let confirmDialog = MaterialAlertViewController(title: "Delete downloaded program?", message: "Are you sure you want to delete downloaded program \(self.download.program!.fullTitle)?", preferredStyle: .alert)
			let deleteAction = MaterialAlertAction(title: "DELETE", style: .destructive, handler: {_ in
				confirmDialog.dismiss(animated: true, completion: nil)

				let documentURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
				let saveDirectoryPath = documentURL.appendingPathComponent(self.download.program!.id)
				let filepath = saveDirectoryPath.appendingPathComponent("file.m2ts")

				do {
					try FileManager.default.removeItem(at: filepath)
					// Realm configuration
					var config = Realm.Configuration()
					config.fileURL = config.fileURL!.deletingLastPathComponent().appendingPathComponent("downloads.realm")
					config.schemaVersion = Download.SchemeVersion
					config.migrationBlock = {migration, oldSchemeVersion in
						if oldSchemeVersion < Download.SchemeVersion {
							Answers.logCustomEvent(withName: "Local realm store migration", customAttributes: ["migration": migration, "old version": Int(oldSchemeVersion), "new version": Int(Download.SchemeVersion)])
						}
					}

					// Delete downloaded program from realm
					let realm = try! Realm(configuration: config)
					try! realm.write {
						realm.delete(self.download)
					}
				} catch let error as NSError {
					Answers.logCustomEvent(withName: "Delete downloaded program error", customAttributes: ["error": error])

					let dialog = MaterialAlertViewController.generateSimpleDialog("Delete downloaded program failed", message: error.localizedDescription)
					self.navigationController.present(dialog, animated: true, completion: nil)
				}
//				slideGestureRecognizer.swipeToOrigin(true, completion: nil)
				var position = self.position
				position.x = -position.x
				self.position = position
			})
			let cancelAction = MaterialAlertAction(title: "CANCEL", style: .cancel, handler: {_ in
				confirmDialog.dismiss(animated: true, completion: nil)
//				slideGestureRecognizer.swipeToOrigin(true, completion: nil)
				var position = self.position
				position.x = -position.x
				self.position = position
			})
			confirmDialog.addAction(cancelAction)
			confirmDialog.addAction(deleteAction)

			self.navigationController.present(confirmDialog, animated: true, completion: nil)
		}
		slideGestureRecognizer.addActions([deleteAction])

		self.addGestureRecognizer(slideGestureRecognizer)
	}

}
