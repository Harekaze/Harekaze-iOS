/**
 *
 * ProgramDetailTableViewController.swift
 * Harekaze
 * Created by Yuki MIZUNO on 2016/07/12.
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
import Kingfisher
import StretchHeader
import DropDown
import APIKit
import SpringIndicator
import RealmSwift
import Crashlytics
import Alamofire
import CoreSpotlight
import MobileCoreServices
import Hero
import FileKit

class ProgramDetailTableViewController: UITableViewController,
	ShowDetailTransitionInterface, UIGestureRecognizerDelegate {

	// MARK: - Instance fileds
	var program: Program! = nil

	// MARK: - Private instance fileds
	private var download: Download! = nil
	private var playButton: FABButton!
	private var stretchHeaderView: StretchHeader!
	private var infoView: VideoInformationView!
	private var lastOrientation: Bool! = Material.Application.isLandscape
	private var castButton: IconButton!
	private var moreButton: IconButton!
	private var dropDown: DropDown!
	private var tabBar: TabBar!
	private var dataSource: [[String: (Program) -> String]] = []

	// MARK: - View initialization

	override func viewDidLoad() {
		let config = Realm.configuration(class: Download.self)
		let realm = try! Realm(configuration: config)

		// Add downloaded program to realm
		let predicate = NSPredicate(format: "id == %@", program.id)
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
		infoView = Bundle.main.loadNibNamed("VideoInformationView", owner: self, options: nil)?.first as? VideoInformationView
		infoView.frame = self.view.frame
		infoView.setup(program)

		stretchHeaderView = StretchHeader()
		stretchHeaderView.backgroundColor = Material.Color.clear
		stretchHeaderView.imageView.backgroundColor = Material.Color.clear

		// Setup tab bar
		tabBar = TabBar(frame: self.view.frame)
		tabBar.backgroundColor = Material.Color.blue.darken2
		tabBar.lineColor = Material.Color.red.accent2
		tabBar.tabItems = []
		for title in ["Information", "Related item", "Other service"] {
			let button = TabItem(title: title.uppercased(), titleColor: Material.Color.lightText.others)
			button.pulseColor = Material.Color.grey.lighten1
			button.titleLabel?.font = RobotoFont.medium(with: 14)
			button.setTitleColor(Material.Color.lightText.primary, for: .selected)
			button.addTarget(self, action: #selector(handleChangeTabBarButton(_:)), for: .touchUpInside)
			tabBar.tabItems.append(button)
		}
		tabBar.tabItems.first?.isSelected = true

		// Navigation buttons
		castButton = IconButton(image: UIImage(named: "ic_cast_white"))

		moreButton = IconButton(image: UIImage(named: "ic_more_vert_white"))
		moreButton.addTarget(self, action: #selector(handleMoreButton), for: .touchUpInside)

		navigationItem.rightViews = [castButton, moreButton]

		// DropDown menu
		dropDown = DropDown(anchorView: moreButton)
		dropDown.cellNib = UINib(nibName: "DropDownMaterialTableViewCell", bundle: nil)
		dropDown.transform = CGAffineTransform(translationX: -8, y: 0)
		dropDown.selectionAction = { (index, content) in
			switch content {
			case "Delete":
				self.confirmDeleteProgram()
			case "Download":
				self.startDownloadVideo()
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: {
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
		playButton = FABButton(image: UIImage(named: "ic_play_arrow_white"), tintColor: UIColor(white: 0.9, alpha: 0.9))
		playButton.backgroundColor = Material.Color.red.accent3
		playButton.addTarget(self, action: #selector(handlePlayButton), for: .touchUpInside)

		// Setup player view transition
		playButton.heroID = "playButton"
		playButton.heroModifiers = [.arc]

		downloadThumbnail(id: program.id)

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
		dataSource.append(["ic_schedule": { program in program.startTime.string()}])
		if program.episode > 0 {
			dataSource.append(["ic_subscriptions": { program in "Episode \(program.episode)"}])
		}
		dataSource.append(["ic_dvr": { program in "\(program.channel!.name) [\(program.channel!.channel)]"}])
		dataSource.append(["ic_timer": { program in "\(program.duration.in(.minute)!) min."}])
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

		// Set navigation bar style
		self.navigationController?.navigationBar.isTranslucent = true
		self.navigationController?.navigationBar.backgroundColor = Material.Color.clear

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
		stretchHeaderView.layout(stretchHeaderView.imageView).horizontally().height(268).top(-48)
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

	// MARK: - Thumbnail downloader

	func downloadThumbnail(id: String) {
		do {
			let request = ChinachuAPI.PreviewImageRequest(id: id)
			let urlRequest = try request.buildURLRequest()

			// Loading indicator
			let springIndicator = SpringIndicator()
			stretchHeaderView.imageView.layout(springIndicator).center().width(40).height(40)
			springIndicator.animating = !ImageCache.default.imageCachedType(forKey: urlRequest.url!.absoluteString).cached

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
			                                        progressBlock: { _, _ in
														springIndicator.animating = false
														springIndicator.stop()
			},
			                                        completionHandler: {(image, error, _, _) -> Void in
														springIndicator.animating = false
														springIndicator.stop()
														guard let image = image else {
															return
														}
														let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeItem as String)
														attributeSet.title = self.program.title
														attributeSet.contentDescription = self.program.detail
														attributeSet.addedDate = self.program.startTime
														attributeSet.duration = self.program.duration as NSNumber?
														attributeSet.thumbnailData = UIImageJPEGRepresentation(image, 0.3)
														let item = CSSearchableItem(uniqueIdentifier: self.program.id, domainIdentifier: "recordings", attributeSet: attributeSet)
														CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [self.program.id], completionHandler: { error in
															if error != nil {
																return
															}
															CSSearchableIndex.default().indexSearchableItems([item], completionHandler: nil)
														})
			})

		} catch let error as NSError {
			Answers.logCustomEvent(withName: "Thumbnail load error", customAttributes: ["error": error, "file": #file, "function": #function, "line": #line])
		}

	}

	// MARK: - Event handler

	@objc func handlePlayButton() {
		showVideoPlayerView()
	}

	@objc internal func handleMoreButton() {
		dropDown.show()
	}

	func confirmDeleteProgram() {
		let confirmDialog = MaterialAlertViewController(title: "Delete program?",
		                                                message: "Are you sure you want to permanently delete the program \(self.program.fullTitle) immediately?",
														preferredStyle: .alert)
		let deleteAction = MaterialAlertAction(title: "DELETE", style: .destructive, handler: {_ in
			confirmDialog.dismiss(animated: true, completion: nil)
			UIApplication.shared.isNetworkActivityIndicatorVisible = true
			let request = ChinachuAPI.DeleteProgramRequest(id: self.program.id)
			Session.send(request) { result in
				UIApplication.shared.isNetworkActivityIndicatorVisible = false
				switch result {
				case .success:
					let realm = try! Realm()
					try! realm.write {
						realm.delete(self.program)
					}
					_ = self.navigationController?.popViewController(animated: true)
				case .failure(let error):
					let dialog = MaterialAlertViewController.generateSimpleDialog("Delete program failed", message: ChinachuAPI.parseErrorMessage(error))
					self.present(dialog, animated: true, completion: nil)
				}
			}

		})
		let cancelAction = MaterialAlertAction(title: "CANCEL", style: .cancel, handler: {_ in confirmDialog.dismiss(animated: true, completion: nil)})
		confirmDialog.addAction(cancelAction)
		confirmDialog.addAction(deleteAction)

		present(confirmDialog, animated: true, completion: nil)
	}

	@objc func handleChangeTabBarButton(_ button: FlatButton) {
		for btn in tabBar.tabItems {
			btn.isSelected = false
		}
		button.isSelected = true
	}

	func showVideoPlayerView() {
		guard let videoPlayViewController = self.storyboard!.instantiateViewController(withIdentifier: "VideoPlayerViewController") as?
			VideoPlayerViewController else {
			return
		}
		videoPlayViewController.program = program
		videoPlayViewController.transitioningDelegate = self as? UIViewControllerTransitioningDelegate
		self.present(videoPlayViewController, animated: true, completion: nil)
	}

	// MARK: - Program download

	func startDownloadVideo() {
		do {
			// Define local store file path
			let saveDirectoryPath = Path.userDocuments + program.id
			if !saveDirectoryPath.exists {
				try saveDirectoryPath.createDirectory()
			} else if !saveDirectoryPath.isDirectory {
				Answers.logCustomEvent(withName: "Create directory failed", customAttributes: ["path": saveDirectoryPath])
				return
			}
			let filepath = saveDirectoryPath + "file.m2ts"

			// Add downloaded program to realm
			let config = Realm.configuration(class: Download.self)
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
				try! realm.write {
					download.size = filepath.attributes[FileAttributeKey.size] as? Int ?? 0
				}
				Answers.logCustomEvent(withName: "File download info", customAttributes: [
					"file size": download.size,
					"transcode": ChinachuAPI.Config[.transcode] && ChinachuAPI.Config[.transcode]
					])
			}
			let downloadRequest = manager.download(urlRequest) { (_, _) in
				return (filepath.url, [])
				}
				.response { response in
					if let error = response.error {
						Answers.logCustomEvent(withName: "Download file failed",
							customAttributes: ["error": error, "path": filepath, "request": response.request as Any, "response": response.response as Any])
					} else {
						try! realm.write {
							download.size = filepath.attributes[FileAttributeKey.size] as? Int ?? 0
						}
						Answers.logCustomEvent(withName: "File download info", customAttributes: [
							"file size": download.size,
							"transcode": ChinachuAPI.Config[.transcode]
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
		let confirmDialog = MaterialAlertViewController(title: "Delete downloaded program?",
		                                                message: "Are you sure you want to delete downloaded program \(program!.fullTitle)?",
														preferredStyle: .alert)
		let deleteAction = MaterialAlertAction(title: "DELETE", style: .destructive, handler: {_ in
			confirmDialog.dismiss(animated: true, completion: nil)

			let filepath = Path.userDocuments + self.download.program!.id + "file.m2ts"

			do {
				try filepath.deleteFile()

				// Delete downloaded program from realm
				let config = Realm.configuration(class: Download.self)
				let realm = try! Realm(configuration: config)
				try! realm.write {
					realm.delete(self.download)
				}
				_ = self.navigationController?.popViewController(animated: true)
			} catch let error as NSError {
				Answers.logCustomEvent(withName: "Delete downloaded program error", customAttributes: ["error": error])

				let dialog = MaterialAlertViewController.generateSimpleDialog("Delete downloaded program failed", message: error.localizedDescription)
				self.navigationController?.present(dialog, animated: true, completion: nil)
			}
		})
		let cancelAction = MaterialAlertAction(title: "CANCEL", style: .cancel, handler: {_ in
			confirmDialog.dismiss(animated: true, completion: nil)
		})
		confirmDialog.addAction(cancelAction)
		confirmDialog.addAction(deleteAction)

		self.navigationController?.present(confirmDialog, animated: true, completion: nil)
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
		if lastOrientation != Material.Application.isLandscape {
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
		lastOrientation = Material.Application.isLandscape
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
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "ProgramDetailInfoCell", for: indexPath) as? ProgramDetailInfoTableViewCell else {
			return UITableViewCell()
		}
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
			completion: { _ in
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
