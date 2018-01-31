/**
*
* DownloadItemTableViewCell.swift
* Harekaze
* Created by Yuki MIZUNO on 2016/08/21.
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
import RealmSwift
import Crashlytics

class DownloadItemTableViewCell: ProgramItemTableViewCell {

	// MARK: - Private instance fields
	private var observation: NSKeyValueObservation?
	private var download: Download!
	private var navigationController: UINavigationController!
	private var etaCalculator: Foundation.Timer!

	// MARK: - Interface Builder outlets
	@IBOutlet weak var progressView: UIProgressView!
	@IBOutlet weak var cancelButton: UIButton!
	@IBOutlet weak var etaLabel: UILabel!

	// MARK: - Entity setter
	func setCellEntities(download: Download, navigationController: UINavigationController) {

		super.setCellEntities(download.recording!.program!)

		self.download = download
		self.navigationController = navigationController

		if download.size > 0 {
			cancelButton.isHidden = true
			etaLabel.isHidden = true
		} else {
			// Set progress bar observer
			if let progress = DownloadManager.shared.progressRequest(download.recording!.id) {
				self.etaCalculator = Foundation.Timer.scheduledTimer(timeInterval: 0.5,
				                                                     target: self,
				                                                     selector: #selector(calculateEstimatedTimeOfArrival),
				                                                     userInfo: nil,
				                                                     repeats: true)
				observation = progress.observe(\.fractionCompleted, options: [.new], changeHandler: {object, change in
					DispatchQueue.main.async {
						self.progressView.setProgress(Float(object.fractionCompleted), animated: true)
					}
				})
			} else {
				cancelButton.isHidden = true
				etaLabel.isHidden = true
			}
		}
	}

	override func prepareForReuse() {
		super.prepareForReuse()
		etaCalculator?.invalidate()
		observation?.invalidate()
		if download.isInvalidated {
			return
		}
	}

	// MARK: - Interface Builder actions

	@IBAction func handleCancelButtonPressed() {
		DownloadManager.shared.stopRequest(download.recording!.id)
		// Stop progress observer
		progressView.setProgress(0, animated: true)
		observation?.invalidate()
		// Stop eta counter
		etaCalculator.invalidate()

		// Realm configuration
		let config = Realm.configuration(class: Download.self)

		// Delete downloaded program from realm
		let realm = try! Realm(configuration: config)
		try! realm.write {
			realm.delete(self.download)
		}
	}

	// MARK: - ETA counter
	@objc func calculateEstimatedTimeOfArrival() {
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
}
