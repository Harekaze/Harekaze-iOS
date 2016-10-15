/**
 *
 * ProgramDetailTableViewController.swift
 * Harekaze
 * Created by Yuki MIZUNO on 2016/07/12.
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
import Kingfisher
import StretchHeader
import JTMaterialTransition
import DropDown
import APIKit
import SpringIndicator
import RealmSwift
import Crashlytics
import Alamofire

class ProgramDetailTableViewController: UITableViewController, UIViewControllerTransitioningDelegate, ShowDetailTransitionInterface, UIGestureRecognizerDelegate {

	// MARK: - Instance fileds

	var program: Program! = nil
	var download: Download! = nil
	var playButton: FabButton!
	var stretchHeaderView: StretchHeader!
	var infoView: VideoInformationView!
	var transition: JTMaterialTransition!
	var lastOrientation: Bool! = Material.Device.isLandscape
	var castButton: IconButton!
	var moreButton: IconButton!
	var dropDown: DropDown!
	var tabBar: TabBar!
	var dataSource: [[String: (Program) -> String]] = []

	// MARK: - View initialization

	override func viewDidLoad() {
		// Realm configuration
		var config = Realm.Configuration()
		config.fileURL = config.fileURL?.deletingLastPathComponent().appendingPathComponent("downloads.realm")
		config.schemaVersion = Download.SchemeVersion
		config.migrationBlock = {migration, oldSchemeVersion in
			if oldSchemeVersion < Download.SchemeVersion {
				Answers.logCustomEvent(withName: "Local realm store migration", customAttributes: ["migration": migration, "old version": Int(oldSchemeVersion), "new version": Int(Download.SchemeVersion)])
			}
			return
		}

		// Add downloaded program to realm
		let predicate = NSPredicate(format: "id == %@", program.id)
		let realm = try! Realm(configuration: config)
		download = realm.objects(Download.self).filter(predicate).first

		super.viewDidLoad()
		self.extendedLayoutIncludesOpaqueBars = false
		self.navigationController?.interactivePopGestureRecognizer?.delegate = self

		self.view.backgroundColor = Material.Color.clear
		self.tableView.tableFooterView = UIView(frame: self.view.frame)
		self.tableView.tableFooterView?.backgroundColor = Material.Color.white

		// Change navigation back button
		self.navigationController?.navigationBar.backIndicatorImage = UIImage(named: "ic_close_white")
		self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "ic_close_white")

		// Setup stretch header view
		infoView = Bundle.main.loadNibNamed("VideoInformationView", owner: self, options: nil)?.first as! VideoInformationView
		infoView.frame = self.view.frame
		infoView.setup(program)

		stretchHeaderView = StretchHeader()
		stretchHeaderView.backgroundColor = Material.Color.clear
		stretchHeaderView.imageView.backgroundColor = Material.Color.clear

		// Setup tab bar
		tabBar = TabBar(frame: self.view.frame)
		tabBar.backgroundColor = Material.Color.blue.darken2
		tabBar.lineColor = Material.Color.red.accent2
		tabBar.buttons = []
		for title in ["Information", "Related item", "Other service"] {
			let button = FlatButton()
			button.pulseColor = Material.Color.grey.lighten1
			button.titleLabel?.font = RobotoFont.medium(with: 14)
			button.setTitle(title.uppercased(), for: .normal)
			button.setTitleColor(Material.Color.lightText.others, for: .normal)
			button.setTitleColor(Material.Color.lightText.primary, for: .selected)
			button.addTarget(self, action: #selector(handleChangeTabBarButton(_:)), for: .touchUpInside)
			tabBar.buttons.append(button)
		}
		tabBar.buttons.first?.isSelected = true

		// Navigation buttons
		castButton = IconButton()
		castButton.setImage(UIImage(named: "ic_cast_white"), for: .normal)
		castButton.setImage(UIImage(named: "ic_cast_white"), for: .highlighted)

		moreButton = IconButton()
		moreButton.setImage(UIImage(named: "ic_more_vert_white"), for: .normal)
		moreButton.setImage(UIImage(named: "ic_more_vert_white"), for: .highlighted)
		moreButton.addTarget(self, action: #selector(handleMoreButton), for: .touchUpInside)

		navigationItem.rightViews = [castButton, moreButton]

		// DropDown menu
		dropDown = DropDown()
		// DropDown appearance configuration
		dropDown.backgroundColor = UIColor.white
		dropDown.cellHeight = 48
		dropDown.textFont = RobotoFont.regular(with: 16)
		dropDown.cornerRadiusPreset = .cornerRadius1
		dropDown.direction = .bottom
		dropDown.animationduration = 0.2
		dropDown.width = 56 * 3
		dropDown.anchorView = moreButton
		dropDown.cellNib = UINib(nibName: "DropDownMaterialTableViewCell", bundle: nil)
		dropDown.transform = CGAffineTransform(translationX: -8, y: 0)
		dropDown.selectionAction = { (index, content) in
			switch content {
			case "Delete":
				self.confirmDeleteProgram()
			case "Download":
				self.startDownloadVideo()
				let delay = DispatchTime.init(uptimeNanoseconds: UInt64(Int64(0.2 * Double(NSEC_PER_SEC))))
				DispatchQueue.main.asyncAfter(deadline: delay, execute: {
					self.dropDown.dataSource = ["Share", "Delete Program"]
				})
			case "Delete File":
				self.confirmDeleteDownloaded()
			case "Delete Program":
				self.confirmDeleteProgram()
			default:
				break
			}
		}
		if download == nil || DownloadManager.shared.progressRequest(download.id) == nil {
			dropDown.dataSource = ["Share", "Download", "Delete"]
		} else if download.size == 0 {
			dropDown.dataSource = ["Share", "Delete Program"]
		} else {
			dropDown.dataSource = ["Share", "Delete File", "Delete Program"]
		}


		// Place play button
		playButton = FabButton()
		playButton.backgroundColor = Material.Color.red.accent3
		playButton.setImage(UIImage(named: "ic_play_arrow_white"), for: .normal)
		playButton.setImage(UIImage(named: "ic_play_arrow_white"), for: .highlighted)
		playButton.tintColor = UIColor(white: 0.9, alpha: 0.9)
		playButton.addTarget(self, action: #selector(handlePlayButton), for: .touchUpInside)

		// Setup player view transition
		transition = JTMaterialTransition(animatedView: playButton)

		// Thumbnail downloader
		do {
			let request = ChinachuAPI.PreviewImageRequest(id: program.id)
			let urlRequest = try request.buildURLRequest()

			// Loading indicator
			let springIndicator = SpringIndicator()
			stretchHeaderView.imageView.layout(springIndicator).center().width(40).height(40)
			springIndicator.animating = !ImageCache.default.isImageCached(forKey: urlRequest.url!.absoluteString).cached

			// Place holder image
			let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
			UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
			Material.Color.grey.lighten2.setFill()
			UIRectFill(rect)
			let placeholderImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
			UIGraphicsEndImageContext()

			// Loading
			stretchHeaderView.imageView.kf.setImage(with: urlRequest.url!,
			                                        placeholder: placeholderImage,
			                                        options: [.transition(ImageTransition.fade(0.3)),
			                                                  .forceTransition,
			                                                  .requestModifier(AnyModifier(modify: { request in
																var request = request
																request.setValue(urlRequest.allHTTPHeaderFields?["Authorization"], forHTTPHeaderField: "Authorization")
																return request
																}
															))],
			                                        progressBlock: { receivedSize, totalSize in
														springIndicator.stopAnimation(false)
				},
			                                        completionHandler: {(image, error, cacheType, imageURL) -> () in
														springIndicator.stopAnimation(false)
			})

		} catch let error as NSError {
			Answers.logCustomEvent(withName: "Thumbnail load error", customAttributes: ["error": error, "file": #file, "function": #function, "line": #line])
		}

		// Setup table view
		self.tableView.delegate = self
		self.tableView.dataSource = self
		self.tableView.register(UINib(nibName: "ProgramDetailInfoTableViewCell", bundle: nil), forCellReuseIdentifier: "ProgramDetailInfoCell")
		self.tableView.estimatedRowHeight = 48
		self.tableView.rowHeight = UITableViewAutomaticDimension
		self.tableView.reloadData()

		// Setup table view data source
		dataSource.append(["ic_description": { program in program.detail != "" ? program.detail : " "}])
		dataSource.append(["ic_inbox": { program in program.genre.capitalized}])
		dataSource.append(["ic_schedule": { program in
			let dateFormatter = DateFormatter()
			dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
			return dateFormatter.string(from: program.startTime as Date)
			}]
		)
		if program.episode > 0 {
			dataSource.append(["ic_subscriptions": { program in "Episode \(program.episode)"}])
		}
		dataSource.append(["ic_dvr": { program in "\(program.channel!.name) [\(program.channel!.channel)]"}])
		dataSource.append(["ic_timer": { program in "\(Int(program.duration/60)) min."}])
		dataSource.append(["ic_label": { program in program.id.uppercased()}])
		dataSource.append(["ic_developer_board": { program in program.tuner}])
		dataSource.append(["ic_video_label": { program in program.fullTitle}])
		dataSource.append(["ic_folder": { program in program.filePath}])
		dataSource.append(["ic_code": { program in program.command}])

	}


	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		// Set navigation bar transparent background
		self.navigationController?.navigationBar.shadowImage = UIImage()

		// Disable navigation drawer
		navigationDrawerController?.isEnabled = false

		// StretchHeader relocation
		let options = StretchHeaderOptions()
		options.position = .fullScreenTop
		stretchHeaderView.stretchHeaderSize(headerSize: CGSize(width: view.frame.size.width, height: 220 + infoView.estimatedHeight + 48),
		                                    imageSize: CGSize(width: view.frame.size.width, height: 220),
		                                    controller: self,
		                                    options: options)

		let f = stretchHeaderView.frame
		stretchHeaderView.frame = CGRect(x: f.origin.x, y: f.origin.y, width: view.frame.size.width, height: 220 + infoView.estimatedHeight + 48)
		tableView.tableHeaderView = stretchHeaderView
		stretchHeaderView.layout(stretchHeaderView.imageView).horizontally().height(220)
		stretchHeaderView.layout(infoView).bottom(48).horizontally()
		stretchHeaderView.layout(tabBar).bottom().horizontally().height(48)

		// Play button relocation
		stretchHeaderView.layout(playButton).topRight(top: 220 - 28, right: 16).size(CGSize(width: 56, height: 56))
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.tableView.tableFooterView = nil
		self.view.backgroundColor = Material.Color.white
	}

	// MARK: - Event handler

	func handlePlayButton() {
		Foundation.Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(showVideoPlayerView), userInfo: nil, repeats: false)
	}

	internal func handleMoreButton() {
		dropDown.show()
	}

	func confirmDeleteProgram() {
		let confirmDialog = MaterialAlertViewController(title: "Delete program?", message: "Are you sure you want to permanently delete the program \(self.program.fullTitle) immediately?", preferredStyle: .alert)
		let deleteAction = MaterialAlertAction(title: "DELETE", style: .destructive, handler: {action in
			confirmDialog.dismiss(animated: true, completion: nil)
			UIApplication.shared.isNetworkActivityIndicatorVisible = true
			let request = ChinachuAPI.DeleteProgramRequest(id: self.program.id)
			Session.send(request) { result in
				UIApplication.shared.isNetworkActivityIndicatorVisible = false
				switch result {
				case .success(_):
					let request = ChinachuAPI.DeleteProgramFileRequest(id: self.program.id)
					Session.send(request) { result in
						switch result {
						case .success(_):
							let realm = try! Realm()
							try! realm.write {
								realm.delete(self.program)
							}
							self.navigationController?.popViewController(animated: true)
						case .failure(let error):
							let dialog = MaterialAlertViewController.generateSimpleDialog("Delete program failed", message: ChinachuAPI.parseErrorMessage(error))
							self.present(dialog, animated: true, completion: nil)
						}
					}
				case .failure(let error):
					let dialog = MaterialAlertViewController.generateSimpleDialog("Delete program failed", message: ChinachuAPI.parseErrorMessage(error))
					self.present(dialog, animated: true, completion: nil)
				}
			}

		})
		let cancelAction = MaterialAlertAction(title: "CANCEL", style: .cancel, handler: {action in confirmDialog.dismiss(animated: true, completion: nil)})
		confirmDialog.addAction(cancelAction)
		confirmDialog.addAction(deleteAction)

		present(confirmDialog, animated: true, completion: nil)
	}

	func handleChangeTabBarButton(_ button: FlatButton) {
		for btn in tabBar.buttons {
			btn.isSelected = false
		}
		button.isSelected = true
	}

	func showVideoPlayerView() {
		let videoPlayViewController = self.storyboard!.instantiateViewController(withIdentifier: "VideoPlayerViewController") as! VideoPlayerViewController
		videoPlayViewController.program = program
		videoPlayViewController.modalPresentationStyle = .custom
		videoPlayViewController.transitioningDelegate = self
		self.present(videoPlayViewController, animated: true, completion: nil)
	}

	// MARK: - Program download

	func startDownloadVideo() {
		do {
			// Define local store file path
			let documentURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
			let saveDirectoryPath = documentURL.appendingPathComponent(program.id)
			var isDirectory: ObjCBool = false
			if !FileManager.default.fileExists(atPath: saveDirectoryPath.path, isDirectory: &isDirectory) {
				try FileManager.default.createDirectory(at: saveDirectoryPath, withIntermediateDirectories: false, attributes: nil)
			} else if !isDirectory.boolValue {
				Answers.logCustomEvent(withName: "Create directory failed", customAttributes: ["path": saveDirectoryPath])
				return
			}
			let filepath = saveDirectoryPath.appendingPathComponent("file.m2ts")

			// Realm configuration
			var config = Realm.Configuration()
			config.fileURL = config.fileURL!.deletingLastPathComponent().appendingPathComponent("downloads.realm")
			config.schemaVersion = Download.SchemeVersion
			config.migrationBlock = {migration, oldSchemeVersion in
				if oldSchemeVersion < Download.SchemeVersion {
					Answers.logCustomEvent(withName: "Local realm store migration", customAttributes: ["migration": migration, "old version": Int(oldSchemeVersion), "new version": Int(Download.SchemeVersion)])
				}
				return
			}

			// Add downloaded program to realm
			let realm = try Realm(configuration: config)
			let download = Download()
			try realm.write {
				download.id = program!.id
				download.program = realm.create(Program.self, value: self.program, update: true)
				realm.add(download, update: true)
			}

			// Download request
			let request = ChinachuAPI.StreamingMediaRequest(id: program.id)
			let urlRequest: URLRequestConvertible = try request.buildURLRequest()
			let manager = DownloadManager.shared.createManager(program.id) {
				let attr = try! FileManager.default.attributesOfItem(atPath: filepath.path)
				try! realm.write {
					download.size = attr[FileAttributeKey.size] as! Int
				}
				Answers.logCustomEvent(withName: "File download info", customAttributes: [
					"file size": download.size,
					"transcode": ChinachuAPI.transcode
					])
			}
			let downloadRequest = manager.download(urlRequest)
			{ (_, _) in
				return (filepath, [])
				}
				.response { __ in
					if let error = __.error {
						Answers.logCustomEvent(withName: "Download file failed",
							customAttributes: ["error": error, "path": filepath, "request": __.request, "response": __.response])
					} else {
						let attr = try! FileManager.default.attributesOfItem(atPath: filepath.path)
						try! realm.write {
							download.size = attr[FileAttributeKey.size] as! Int
						}
						Answers.logCustomEvent(withName: "File download info", customAttributes: [
							"file size": download.size,
							"transcode": ChinachuAPI.transcode
							])
					}
			}
			// Show dialog
			let dialog = MaterialAlertViewController.generateSimpleDialog("The download has started", message: "Download progress is available at Download page.")
			self.navigationController?.present(dialog, animated: true, completion: nil)

			// Save request
			DownloadManager.shared.addRequest(program.id, request: downloadRequest)
		} catch let error as NSError {
			// Show dialog
			let dialog = MaterialAlertViewController.generateSimpleDialog("Download failed", message: error.localizedDescription)
			self.navigationController?.present(dialog, animated: true, completion: nil)
			Answers.logCustomEvent(withName: "File download error", customAttributes: ["error": error])
		}
	}

	func confirmDeleteDownloaded() {
		let confirmDialog = MaterialAlertViewController(title: "Delete downloaded program?", message: "Are you sure you want to delete downloaded program \(program!.fullTitle)?", preferredStyle: .alert)
		let deleteAction = MaterialAlertAction(title: "DELETE", style: .destructive, handler: {action in
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
					return
				}

				// Delete downloaded program from realm
				let realm = try! Realm(configuration: config)
				try! realm.write {
					realm.delete(self.download)
				}
				self.navigationController?.popViewController(animated: true)
			} catch let error as NSError  {
				Answers.logCustomEvent(withName: "Delete downloaded program error", customAttributes: ["error": error])

				let dialog = MaterialAlertViewController.generateSimpleDialog("Delete downloaded program failed", message: error.localizedDescription)
				self.navigationController?.present(dialog, animated: true, completion: nil)
			}
		})
		let cancelAction = MaterialAlertAction(title: "CANCEL", style: .cancel, handler: {action in
			confirmDialog.dismiss(animated: true, completion: nil)
		})
		confirmDialog.addAction(cancelAction)
		confirmDialog.addAction(deleteAction)

		self.navigationController?.present(confirmDialog, animated: true, completion: nil)
	}

	// MARK: - View controller transitioning delegate

	func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		transition.isReverse = false
		return transition
	}

	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		transition.isReverse = true
		return transition
	}

	// MARK: - View deinitialization

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		// Put back original navigation bar style
		self.navigationController?.navigationBar.isTranslucent = false
		self.navigationController?.navigationBar.backgroundColor = Material.Color.blue.darken1

		// Enable navigation drawer
		navigationDrawerController?.isEnabled = true
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}


	// MARK: - ScrollView Delegate
	override func scrollViewDidScroll(_ scrollView: UIScrollView) {
		stretchHeaderView.updateScrollViewOffset(scrollView)
	}

	// MARK: - UIGestureRecognizer delegate
	func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
		// Disable swipe to pop view
		return false
	}

	// MARK: - View layout

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		if lastOrientation != Material.Device.isLandscape {
			let options = StretchHeaderOptions()
			options.position = .fullScreenTop
			stretchHeaderView.stretchHeaderSize(headerSize: CGSize(width: view.frame.size.width, height: 220 + infoView.estimatedHeight + 48),
			                                    imageSize: CGSize(width: view.frame.size.width, height: 220),
			                                    controller: self,
			                                    options: options)
			let f = stretchHeaderView.frame
			stretchHeaderView.frame = CGRect(x: f.origin.x, y: f.origin.y, width: view.frame.size.width, height: 220 + infoView.estimatedHeight + 48)
			tableView.tableHeaderView = stretchHeaderView
		}
		lastOrientation = Material.Device.isLandscape
	}

	// MARK: - Memory/resource management

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	// MARK: - Table view data source

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return dataSource.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "ProgramDetailInfoCell", for: indexPath) as! ProgramDetailInfoTableViewCell
		let data = dataSource[(indexPath as NSIndexPath).row].first!
		cell.contentLabel.text = data.1(program)
		cell.iconImageView.image = UIImage(named: data.0)
		return cell
	}


	// MARK: - ShowDetailTransitionInterface

	func cloneHeaderView() -> UIImageView {
		let imageView = UIImageView(image: self.stretchHeaderView.imageView.image)
		imageView.contentMode = self.stretchHeaderView.imageView.contentMode
		imageView.clipsToBounds = true
		imageView.isUserInteractionEnabled = false
		imageView.frame = stretchHeaderView.imageView.frame

		return imageView
	}

	func presentationBeforeAction() {
		self.stretchHeaderView.imageView.alpha = 0
		self.playButton.transform = CGAffineTransform(scaleX: 0, y: 0)
	}

	func presentationAnimationAction(_ percentComplete: CGFloat) {
		// Set navigation bar transparent background
		self.navigationController?.navigationBar.isTranslucent = true
		self.navigationController?.navigationBar.backgroundColor = UIColor.clear
	}

	func presentationCompletionAction(_ completeTransition: Bool) {
		UIView.animate(
			withDuration: 0.2,
			delay: 0,
			options: [.transitionCrossDissolve, .curveLinear],
			animations: {
				// Show thumbnail
				self.stretchHeaderView.imageView.alpha = 1
			},
			completion: { finished in
				UIView.animate(
					withDuration: 0.1,
					delay: 0,
					options: [.curveEaseIn],
					animations: {
						// Show play button
						self.playButton.transform = CGAffineTransform.identity
					},
					completion: nil
				)
			}
		)
	}

	func dismissalBeforeAction() {
		self.view.backgroundColor = UIColor.clear
		self.stretchHeaderView.imageView.isHidden = true
	}

	func dismissalAnimationAction(_ percentComplete: CGFloat) {
		// Go down
		self.tableView.frame.origin.y = self.view.frame.size.height
	}


}
