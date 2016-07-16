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

class ProgramDetailTableViewController: UITableViewController, UIViewControllerTransitioningDelegate {

	// MARK: - Instance fileds

	var program: Program! = nil
	var playButton: FabButton!
	var stretchHeaderView: StretchHeader!
	var infoView: VideoInformationView!
	var transition: JTMaterialTransition!
	
	// MARK: - View initialization

    override func viewDidLoad() {
        super.viewDidLoad()

		// Setup stretch header view
		infoView = NSBundle.mainBundle().loadNibNamed("VideoInformationView", owner: self, options: nil).first as! VideoInformationView
		infoView.frame = self.view.frame
		infoView.setup(program)

		stretchHeaderView = StretchHeader()


		// Place play button
		playButton = FabButton()
		playButton.backgroundColor = MaterialColor.red.darken3
		playButton.setImage(UIImage(named: "ic_play_arrow_white"), forState: .Normal)
		playButton.setImage(UIImage(named: "ic_play_arrow_white"), forState: .Highlighted)
		playButton.tintColor = UIColor(white: 0.9, alpha: 0.9)
		playButton.addTarget(self, action: #selector(handlePlayButton), forControlEvents: .TouchUpInside)

		// Setup player view transition
		transition = JTMaterialTransition(animatedView: playButton)

		// Preview image downloader
		do {
			let request = ChinachuAPI.PreviewImageRequest(id: program.id)
			let urlRequest = try request.buildURLRequest()

			let downloader = KingfisherManager.sharedManager.downloader
			downloader.requestModifier = {
				(request: NSMutableURLRequest) in
				request.setValue(urlRequest.allHTTPHeaderFields?["Authorization"], forHTTPHeaderField: "Authorization")
			}

			stretchHeaderView.imageView.kf_setImageWithURL(urlRequest.URL!)

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
		self.navigationController?.navigationBar.translucent = true
		self.navigationController?.navigationBar.shadowImage = UIImage()
		self.navigationController?.navigationBar.backgroundColor = UIColor.clearColor()

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
		if let nav = navigationController {
			for view: AnyObject in nav.view.subviews {
				if let id = view.restorationIdentifier! {
					if id == "StatusBarView" {
						let statusBarView = view as! UIView
						let lastState = statusBarView.hidden
						statusBarView.hidden = MaterialDevice.isLandscape && .iPhone == MaterialDevice.type
						if lastState != statusBarView.hidden {
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
						break
					}
				}
			}
		}
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

}
