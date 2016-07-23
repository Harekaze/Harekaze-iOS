//
//  ProgramDetailTableViewController.swift
//  Harekaze
//
//  Created by Yuki MIZUNO on 2016/07/12.
//  Copyright © 2016年 Yuki MIZUNO. All rights reserved.
//

import UIKit
import Material
import Kingfisher
import StretchHeader
import JTMaterialTransition
import DropDown
import APIKit
import SpringIndicator
import RealmSwift

class ProgramDetailTableViewController: UITableViewController, UIViewControllerTransitioningDelegate, ShowDetailTransitionInterface {

	// MARK: - Instance fileds

	var program: Program! = nil
	var playButton: FabButton!
	var stretchHeaderView: StretchHeader!
	var infoView: VideoInformationView!
	var transition: JTMaterialTransition!
	var lastOrientation: Bool! = MaterialDevice.isLandscape
	var castButton: IconButton!
	var moreButton: IconButton!
	var dropDown: DropDown!
	
	// MARK: - View initialization

    override func viewDidLoad() {
        super.viewDidLoad()
		self.extendedLayoutIncludesOpaqueBars = false

		// Change navigation back button
		self.navigationController?.navigationBar.backIndicatorImage = UIImage(named: "ic_close_white")
		self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(named: "ic_close_white")

		// Setup stretch header view
		infoView = NSBundle.mainBundle().loadNibNamed("VideoInformationView", owner: self, options: nil).first as! VideoInformationView
		infoView.frame = self.view.frame
		infoView.setup(program)

		stretchHeaderView = StretchHeader()

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
		dropDown.width = 56 * 3
		dropDown.anchorView = moreButton
		dropDown.cellNib = UINib(nibName: "DropDownMaterialTableViewCell", bundle: nil)
		dropDown.transform = CGAffineTransformMakeTranslation(-8, 0)
		dropDown.selectionAction = { (index, content) in
			switch content {
			case "Delete":
				self.confirmDeleteProgram()
			default:
				break
			}
		}
		dropDown.dataSource = ["Share", "Download", "Delete"]


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

		} catch  {
			print("Failed to load preview image [id: \(program.id).")
		}

		// Setup table view
		self.tableView.delegate = self
		self.tableView.dataSource = self

		self.tableView.reloadData()
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
		stretchHeaderView.stretchHeaderSize(headerSize: CGSizeMake(view.frame.size.width, 220 + infoView.height),
		                                    imageSize: CGSizeMake(view.frame.size.width, 220),
		                                    controller: self,
		                                    options: options)

		let f = stretchHeaderView.frame
		stretchHeaderView.frame = CGRect(x: f.origin.x, y: f.origin.y, width: view.frame.size.width, height: 220 + infoView.height)
		tableView.tableHeaderView = stretchHeaderView
		stretchHeaderView.layout(stretchHeaderView.imageView).horizontally().height(220)
		stretchHeaderView.layout(infoView).bottom().horizontally()

		// Play button relocation
		stretchHeaderView.layout(playButton).topRight(top: 220 - 28, right: 16).size(width: 56, height: 56)

	}

	// MARK: - Event handler

	func handlePlayButton() {
		NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(showVideoPlayerView), userInfo: nil, repeats: false)
	}

	internal func handleMoreButton() {
		dropDown.show()
	}

	func confirmDeleteProgram() {
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
		let confirmDialog = MaterialAlertViewController(title: "Delete program?", message: "Are you sure you want to permanently delete the program \(self.program.fullTitle) immediately?", preferredStyle: .Alert)
		let deleteAction = MaterialAlertAction(title: "DELETE", style: .Destructive, handler: {(action: MaterialAlertAction!) -> Void in
			confirmDialog.dismissViewControllerAnimated(true, completion: nil)
			let request = ChinachuAPI.DeleteProgramRequest(id: self.program.id)
			Session.sendRequest(request) { result in
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
							let dialog = warningDialog(error)
							self.presentViewController(dialog, animated: true, completion: nil)
						}
					}
				case .Failure(let error):
					let dialog = warningDialog(error)
					self.presentViewController(dialog, animated: true, completion: nil)
				}
			}

		})
		let cancelAction = MaterialAlertAction(title: "CANCEL", style: .Cancel, handler: {(action: MaterialAlertAction!) -> Void in confirmDialog.dismissViewControllerAnimated(true, completion: nil)})
		confirmDialog.addAction(cancelAction)
		confirmDialog.addAction(deleteAction)

		presentViewController(confirmDialog, animated: true, completion: nil)
	}

	func showVideoPlayerView() {
		let videoPlayViewController = self.storyboard!.instantiateViewControllerWithIdentifier("VideoPlayerViewController") as! VideoPlayerViewController
		videoPlayViewController.program = program
		videoPlayViewController.modalPresentationStyle = .Custom
		videoPlayViewController.transitioningDelegate = self
		self.presentViewController(videoPlayViewController, animated: true, completion: nil)
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
	}

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}


	// MAEK: - ScrollView Delegate
	override func scrollViewDidScroll(scrollView: UIScrollView) {
		stretchHeaderView.updateScrollViewOffset(scrollView)
	}

	// MARK: - View layout

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
		if lastOrientation != MaterialDevice.isLandscape {
			let options = StretchHeaderOptions()
			options.position = .FullScreenTop
			stretchHeaderView.stretchHeaderSize(headerSize: CGSizeMake(view.frame.size.width, 220 + infoView.height),
			                                    imageSize: CGSizeMake(view.frame.size.width, 220),
			                                    controller: self,
			                                    options: options)
			let f = stretchHeaderView.frame
			stretchHeaderView.frame = CGRect(x: f.origin.x, y: f.origin.y, width: view.frame.size.width, height: 220 + infoView.height)
			tableView.tableHeaderView = stretchHeaderView
		}
		lastOrientation = MaterialDevice.isLandscape
	}

	// MARK: - Memory/resource management

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 5
	}

	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 48
	}

	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("programInfoCell", forIndexPath: indexPath)
		switch indexPath.row {
		case 0:
			cell.textLabel?.text = "Genre"
			cell.detailTextLabel?.text = program.genre.capitalizedString
		case 1:
			let dateFormatter = NSDateFormatter()
			dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"

			cell.textLabel?.text = "Date"
			cell.detailTextLabel?.text = dateFormatter.stringFromDate(program.startTime)
		case 2:
			cell.textLabel?.text = "Channel"
			cell.detailTextLabel?.text = "\(program.channel!.name) [\(program.channel!.channel)]"
		case 3:
			cell.textLabel?.text = "Duration"
			cell.detailTextLabel?.text = "\(Int(program.duration/60)) min."
		case 4:
			cell.textLabel?.text = "ID"
			cell.detailTextLabel?.text = program.id.uppercaseString
		default: break;
		}
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
		self.tableView.alpha = 0
		self.playButton.transform = CGAffineTransformMakeScale(0, 0)
	}

	func presentationAnimationAction(percentComplete: CGFloat) {
		self.tableView.alpha = 1
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
		self.tableView.alpha = 0
	}
	

}
