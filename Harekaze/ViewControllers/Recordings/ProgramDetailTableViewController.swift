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
	var lastOrientation: Bool! = MaterialDevice.isLandscape
	var castButton: IconButton!
	var moreButton: IconButton!
	var dropDown: DropDown!
	var tabBar: TabBar!
	var dataSource: [[String: (Program) -> String]] = []
	
	// MARK: - View initialization

    override func viewDidLoad() {
		// Realm configuration
		var config = Realm.Configuration()
		config.fileURL = config.fileURL!.URLByDeletingLastPathComponent?.URLByAppendingPathComponent("downloads.realm")

		// Add downloaded program to realm
		let predicate = NSPredicate(format: "id == %@", program.id)
		let realm = try! Realm(configuration: config)
		download = realm.objects(Download).filter(predicate).first

        super.viewDidLoad()
		self.extendedLayoutIncludesOpaqueBars = false
		self.navigationController?.interactivePopGestureRecognizer?.delegate = self

		self.view.backgroundColor = MaterialColor.clear
		self.tableView.tableFooterView = UIView(frame: self.view.frame)
		self.tableView.tableFooterView?.backgroundColor = MaterialColor.white

		// Change navigation back button
		self.navigationController?.navigationBar.backIndicatorImage = UIImage(named: "ic_close_white")
		self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "ic_close_white")

		// Setup stretch header view
		infoView = NSBundle.mainBundle().loadNibNamed("VideoInformationView", owner: self, options: nil).first as! VideoInformationView
		infoView.frame = self.view.frame
		infoView.setup(program)

		stretchHeaderView = StretchHeader()
		stretchHeaderView.backgroundColor = MaterialColor.clear
		stretchHeaderView.imageView.backgroundColor = MaterialColor.clear

		// Setup tab bar
		tabBar = TabBar(frame: self.view.frame)
		tabBar.backgroundColor = MaterialColor.blue.darken2
		tabBar.line.backgroundColor = MaterialColor.red.accent2
		tabBar.buttons = []
		for title in ["Information", "Related item", "Other service"] {
			let button = FlatButton()
			button.pulseColor = MaterialColor.grey.lighten1
			button.titleLabel?.font = RobotoFont.mediumWithSize(14)
			button.setTitle(title.uppercaseString, forState: .Normal)
			button.setTitleColor(MaterialColor.lightText.others, forState: .Normal)
			button.setTitleColor(MaterialColor.lightText.primary, forState: .Selected)
			button.addTarget(self, action: #selector(handleChangeTabBarButton(_:)), forControlEvents: .TouchUpInside)
			tabBar.buttons?.append(button)
		}
		tabBar.buttons?.first?.selected = true

		// Navigation buttons
		castButton = IconButton()
		castButton.setImage(UIImage(named: "ic_cast_white"), forState: .Normal)
		castButton.setImage(UIImage(named: "ic_cast_white"), forState: .Highlighted)

		moreButton = IconButton()
		moreButton.setImage(UIImage(named: "ic_more_vert_white"), forState: .Normal)
		moreButton.setImage(UIImage(named: "ic_more_vert_white"), forState: .Highlighted)
		moreButton.addTarget(self, action: #selector(handleMoreButton), forControlEvents: .TouchUpInside)
		
		navigationItem.rightControls = [castButton, moreButton]

		// DropDown menu
		dropDown = DropDown()
		// DropDown appearance configuration
		dropDown.backgroundColor = UIColor.whiteColor()
		dropDown.cellHeight = 48
		dropDown.textFont = RobotoFont.regularWithSize(16)
		dropDown.cornerRadius = 2.0
		dropDown.direction = .Bottom
		dropDown.animationduration = 0.2
		dropDown.width = 56 * 3
		dropDown.anchorView = moreButton
		dropDown.cellNib = UINib(nibName: "DropDownMaterialTableViewCell", bundle: nil)
		dropDown.transform = CGAffineTransformMakeTranslation(-8, 0)
		dropDown.selectionAction = { (index, content) in
			switch content {
			case "Delete":
				self.confirmDeleteProgram()
			case "Download":
				self.startDownloadVideo()
				let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(0.2 * Double(NSEC_PER_SEC)))
				dispatch_after(delay, dispatch_get_main_queue(), {
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
		if download == nil {
			dropDown.dataSource = ["Share", "Download", "Delete"]
		} else if download.size == 0 {
			dropDown.dataSource = ["Share", "Delete Program"]
		} else {
			dropDown.dataSource = ["Share", "Delete File", "Delete Program"]
		}


		// Place play button
		playButton = FabButton()
		playButton.backgroundColor = MaterialColor.red.accent3
		playButton.setImage(UIImage(named: "ic_play_arrow_white"), forState: .Normal)
		playButton.setImage(UIImage(named: "ic_play_arrow_white"), forState: .Highlighted)
		playButton.tintColor = UIColor(white: 0.9, alpha: 0.9)
		playButton.addTarget(self, action: #selector(handlePlayButton), forControlEvents: .TouchUpInside)

		// Setup player view transition
		transition = JTMaterialTransition(animatedView: playButton)

		// Thumbnail downloader
		do {
			let request = ChinachuAPI.PreviewImageRequest(id: program.id)
			let urlRequest = try request.buildURLRequest()

			let downloader = KingfisherManager.sharedManager.downloader
			downloader.requestModifier = {
				(request: NSMutableURLRequest) in
				request.setValue(urlRequest.allHTTPHeaderFields?["Authorization"], forHTTPHeaderField: "Authorization")
			}

			// Loading indicator
			let springIndicator = SpringIndicator()
			stretchHeaderView.imageView.layout(springIndicator).center().width(40).height(40)
			springIndicator.animating = !ImageCache.defaultCache.cachedImageExistsforURL(urlRequest.URL!)

			// Place holder image
			let rect = CGRectMake(0, 0, 1, 1)
			UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
			MaterialColor.grey.lighten2.setFill()
			UIRectFill(rect)
			let placeholderImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
			UIGraphicsEndImageContext()

			// Loading
			stretchHeaderView.imageView.kf_setImageWithURL(urlRequest.URL!,
			                                               placeholderImage: placeholderImage,
			                                               optionsInfo: [.Transition(ImageTransition.Fade(0.3)), .ForceTransition],
			                                               progressBlock: { receivedSize, totalSize in
															springIndicator.stopAnimation(false)
				},
			                                               completionHandler: { (image, error, cacheType, imageURL) -> () in
															springIndicator.stopAnimation(false)
			})

		} catch let error as NSError {
			Answers.logCustomEventWithName("Thumbnail load error", customAttributes: ["error": error, "file": #file, "function": #function, "line": #line])
		}

		// Setup table view
		self.tableView.delegate = self
		self.tableView.dataSource = self
		self.tableView.registerNib(UINib(nibName: "ProgramDetailInfoTableViewCell", bundle: nil), forCellReuseIdentifier: "ProgramDetailInfoCell")
		self.tableView.estimatedRowHeight = 48
		self.tableView.rowHeight = UITableViewAutomaticDimension
		self.tableView.reloadData()

		// Setup table view data source
		dataSource.append(["ic_description": { program in program.detail != "" ? program.detail : " "}])
		dataSource.append(["ic_inbox": { program in program.genre.capitalizedString}])
		dataSource.append(["ic_schedule": { program in
			let dateFormatter = NSDateFormatter()
			dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
			return dateFormatter.stringFromDate(program.startTime)
			}]
		)
		if program.episode > 0 {
			dataSource.append(["ic_subscriptions": { program in "Episode \(program.episode)"}])
		}
		dataSource.append(["ic_dvr": { program in "\(program.channel!.name) [\(program.channel!.channel)]"}])
		dataSource.append(["ic_timer": { program in "\(Int(program.duration/60)) min."}])
		dataSource.append(["ic_label": { program in program.id.uppercaseString}])
		dataSource.append(["ic_developer_board": { program in program.tuner}])
		dataSource.append(["ic_video_label": { program in program.fullTitle}])
		dataSource.append(["ic_folder": { program in program.filePath}])
		dataSource.append(["ic_code": { program in program.command}])

	}


	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		// Set navigation bar transparent background
		self.navigationController?.navigationBar.shadowImage = UIImage()

		// Disable navigation drawer
		navigationDrawerController?.enabled = false

		// StretchHeader relocation
		let options = StretchHeaderOptions()
		options.position = .FullScreenTop
		stretchHeaderView.stretchHeaderSize(headerSize: CGSizeMake(view.frame.size.width, 220 + infoView.height + 48),
		                                    imageSize: CGSizeMake(view.frame.size.width, 220),
		                                    controller: self,
		                                    options: options)

		let f = stretchHeaderView.frame
		stretchHeaderView.frame = CGRect(x: f.origin.x, y: f.origin.y, width: view.frame.size.width, height: 220 + infoView.height + 48)
		tableView.tableHeaderView = stretchHeaderView
		stretchHeaderView.layout(stretchHeaderView.imageView).horizontally().height(220)
		stretchHeaderView.layout(infoView).bottom(48).horizontally()
		stretchHeaderView.layout(tabBar).bottom().horizontally().height(48)

		// Play button relocation
		stretchHeaderView.layout(playButton).topRight(top: 220 - 28, right: 16).size(width: 56, height: 56)

	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		self.tableView.tableFooterView = nil
		self.view.backgroundColor = MaterialColor.white
	}

	// MARK: - Event handler

	func handlePlayButton() {
		NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(showVideoPlayerView), userInfo: nil, repeats: false)
	}

	internal func handleMoreButton() {
		dropDown.show()
	}

	func confirmDeleteProgram() {
		let confirmDialog = MaterialAlertViewController(title: "Delete program?", message: "Are you sure you want to permanently delete the program \(self.program.fullTitle) immediately?", preferredStyle: .Alert)
		let deleteAction = MaterialAlertAction(title: "DELETE", style: .Destructive, handler: {(action: MaterialAlertAction!) -> Void in
			confirmDialog.dismissViewControllerAnimated(true, completion: nil)
			UIApplication.sharedApplication().networkActivityIndicatorVisible = true
			let request = ChinachuAPI.DeleteProgramRequest(id: self.program.id)
			Session.sendRequest(request) { result in
				UIApplication.sharedApplication().networkActivityIndicatorVisible = false
				switch result {
				case .Success(_):
					let request = ChinachuAPI.DeleteProgramFileRequest(id: self.program.id)
					Session.sendRequest(request) { result in
						switch result {
						case .Success(_):
							let realm = try! Realm()
							try! realm.write {
								realm.delete(self.program)
							}
							self.navigationController?.popViewControllerAnimated(true)
						case .Failure(let error):
							let dialog = MaterialAlertViewController.generateSimpleDialog("Delete program failed", message: ChinachuAPI.parseErrorMessage(error))
							self.presentViewController(dialog, animated: true, completion: nil)
						}
					}
				case .Failure(let error):
					let dialog = MaterialAlertViewController.generateSimpleDialog("Delete program failed", message: ChinachuAPI.parseErrorMessage(error))
					self.presentViewController(dialog, animated: true, completion: nil)
				}
			}

		})
		let cancelAction = MaterialAlertAction(title: "CANCEL", style: .Cancel, handler: {(action: MaterialAlertAction!) -> Void in confirmDialog.dismissViewControllerAnimated(true, completion: nil)})
		confirmDialog.addAction(cancelAction)
		confirmDialog.addAction(deleteAction)

		presentViewController(confirmDialog, animated: true, completion: nil)
	}

	func handleChangeTabBarButton(button: FlatButton) {
		for btn in tabBar.buttons! {
			btn.selected = false
		}
		button.selected = true
	}

	func showVideoPlayerView() {
		let videoPlayViewController = self.storyboard!.instantiateViewControllerWithIdentifier("VideoPlayerViewController") as! VideoPlayerViewController
		videoPlayViewController.program = program
		videoPlayViewController.modalPresentationStyle = .Custom
		videoPlayViewController.transitioningDelegate = self
		self.presentViewController(videoPlayViewController, animated: true, completion: nil)
	}

	// MARK: - Program download

	func startDownloadVideo() {
		do {
			// Define local store file path
			let documentURL = try NSFileManager.defaultManager().URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false)
			let saveDirectoryPath = documentURL.URLByAppendingPathComponent(program.id)
			var isDirectory: ObjCBool = false
			if !NSFileManager.defaultManager().fileExistsAtPath(saveDirectoryPath.path!, isDirectory: &isDirectory) {
				try NSFileManager.defaultManager().createDirectoryAtURL(saveDirectoryPath, withIntermediateDirectories: false, attributes: nil)
			} else if !isDirectory {
				Answers.logCustomEventWithName("Create directory failed", customAttributes: ["path": saveDirectoryPath])
				return
			}
			let filepath = saveDirectoryPath.URLByAppendingPathComponent("file.m2ts")

			// Realm configuration
			var config = Realm.Configuration()
			config.fileURL = config.fileURL!.URLByDeletingLastPathComponent?.URLByAppendingPathComponent("downloads.realm")

			// Add downloaded program to realm
			let realm = try Realm(configuration: config)
			let download = Download()
			try realm.write {
				download.id = program!.id
				download.program = realm.create(Program.self, value: self.program, update: true)
				realm.add(download)
			}

			// Download request
			let request = ChinachuAPI.StreamingMediaRequest(id: program.id)
			let urlRequest = try request.buildURLRequest()
			let downloadRequest = Alamofire.download(urlRequest)
			{ (_, _) in
				return filepath
				}
				.response { (request, response, data, error) in
					if let error = error {
						Answers.logCustomEventWithName("Download file failed",
							customAttributes: ["error": error, "path": filepath, "request": request ?? "", "response": response ?? ""])
					} else {
						let attr = try! NSFileManager.defaultManager().attributesOfItemAtPath(filepath.path!)
						try! realm.write {
							download.size = attr[NSFileSize] as! Int
						}
						Answers.logCustomEventWithName("File download info", customAttributes: [
							"file size": download.size,
							"transcode": ChinachuAPI.transcode
							])
					}
			}
			// Show dialog
			let dialog = MaterialAlertViewController.generateSimpleDialog("The download has started", message: "Download progress is available at Download page.")
			self.navigationController?.presentViewController(dialog, animated: true, completion: nil)

			// Save request
			DownloadManager.sharedInstance.addRequest(program.id, request: downloadRequest)
		} catch let error as NSError {
			// Show dialog
			let dialog = MaterialAlertViewController.generateSimpleDialog("Download failed", message: error.localizedDescription)
			self.navigationController?.presentViewController(dialog, animated: true, completion: nil)
			Answers.logCustomEventWithName("File download error", customAttributes: ["error": error])
		}
	}

	func confirmDeleteDownloaded() {
		let confirmDialog = MaterialAlertViewController(title: "Delete downloaded program?", message: "Are you sure you want to delete downloaded program \(program!.fullTitle)?", preferredStyle: .Alert)
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

				// Delete downloaded program from realm
				let realm = try! Realm(configuration: config)
				try! realm.write {
					realm.delete(self.download)
				}
				self.navigationController?.popViewControllerAnimated(true)
			} catch let error as NSError  {
				Answers.logCustomEventWithName("Delete downloaded program error", customAttributes: ["error": error])

				let dialog = MaterialAlertViewController.generateSimpleDialog("Delete downloaded program failed", message: error.localizedDescription)
				self.navigationController?.presentViewController(dialog, animated: true, completion: nil)
			}
		})
		let cancelAction = MaterialAlertAction(title: "CANCEL", style: .Cancel, handler: {(action: MaterialAlertAction!) in
			confirmDialog.dismissViewControllerAnimated(true, completion: nil)
		})
		confirmDialog.addAction(cancelAction)
		confirmDialog.addAction(deleteAction)

		self.navigationController?.presentViewController(confirmDialog, animated: true, completion: nil)
	}

	// MARK: - View controller transitioning delegate

	func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		transition.reverse = false
		return transition
	}

	func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		transition.reverse = true
		return transition
	}

	// MARK: - View deinitialization

	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)

		// Put back original navigation bar style
		self.navigationController?.navigationBar.translucent = false
		self.navigationController?.navigationBar.backgroundColor = MaterialColor.blue.darken1

		// Enable navigation drawer
		navigationDrawerController?.enabled = true
	}

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}


	// MARK: - ScrollView Delegate
	override func scrollViewDidScroll(scrollView: UIScrollView) {
		stretchHeaderView.updateScrollViewOffset(scrollView)
	}

	// MARK: - UIGestureRecognizer delegate
	func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
		// Disable swipe to pop view
		return false
	}

	// MARK: - View layout

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		if lastOrientation != MaterialDevice.isLandscape {
			let options = StretchHeaderOptions()
			options.position = .FullScreenTop
			stretchHeaderView.stretchHeaderSize(headerSize: CGSizeMake(view.frame.size.width, 220 + infoView.height + 48),
			                                    imageSize: CGSizeMake(view.frame.size.width, 220),
			                                    controller: self,
			                                    options: options)
			let f = stretchHeaderView.frame
			stretchHeaderView.frame = CGRect(x: f.origin.x, y: f.origin.y, width: view.frame.size.width, height: 220 + infoView.height + 48)
			tableView.tableHeaderView = stretchHeaderView
		}
		lastOrientation = MaterialDevice.isLandscape
	}

	// MARK: - Memory/resource management

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return dataSource.count
	}

	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("ProgramDetailInfoCell", forIndexPath: indexPath) as! ProgramDetailInfoTableViewCell
		let data = dataSource[indexPath.row].first!
		cell.contentLabel.text = data.1(program)
		cell.iconImageView.image = UIImage(named: data.0)
		return cell
	}


	// MARK: - ShowDetailTransitionInterface

	func cloneHeaderView() -> UIImageView {
		let imageView = UIImageView(image: self.stretchHeaderView.imageView.image)
		imageView.contentMode = self.stretchHeaderView.imageView.contentMode
		imageView.clipsToBounds = true
		imageView.userInteractionEnabled = false
		imageView.frame = stretchHeaderView.imageView.frame

		return imageView
	}

	func presentationBeforeAction() {
		self.stretchHeaderView.imageView.alpha = 0
		self.playButton.transform = CGAffineTransformMakeScale(0, 0)
	}

	func presentationAnimationAction(percentComplete: CGFloat) {
		// Set navigation bar transparent background
		self.navigationController?.navigationBar.translucent = true
		self.navigationController?.navigationBar.backgroundColor = UIColor.clearColor()
	}

	func presentationCompletionAction(completeTransition: Bool) {
		UIView.animateWithDuration(
			0.2,
			delay: 0,
			options: [.TransitionCrossDissolve, .CurveLinear],
			animations: {
				// Show thumbnail
				self.stretchHeaderView.imageView.alpha = 1
			},
			completion: { finished in
				UIView.animateWithDuration(
					0.1,
					delay: 0,
					options: [.CurveEaseIn],
					animations: {
						// Show play button
						self.playButton.transform = CGAffineTransformIdentity
					},
					completion: nil
				)
			}
		)
	}

	func dismissalBeforeAction() {
		self.view.backgroundColor = UIColor.clearColor()
		self.stretchHeaderView.imageView.hidden = true
	}

	func dismissalAnimationAction(percentComplete: CGFloat) {
		// Go down
		self.tableView.frame.origin.y = self.view.frame.size.height
	}
	

}
