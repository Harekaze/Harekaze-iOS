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

class ProgramDetailTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

	// MARK: - Instance fileds

	var program: Program! = nil
	var playButton: FabButton!


	// MARK: - Interface Builder outlets

	@IBOutlet weak var previewImageView: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subTitleLabel: UILabel!
	@IBOutlet weak var channelLabel: UILabel!
	@IBOutlet weak var durationLabel: UILabel!
	@IBOutlet weak var detailLabel: UILabel!
	@IBOutlet weak var summaryView: UIView!
	@IBOutlet weak var informationTable: UITableView!

	
	// MARK: - View initialization

    override func viewDidLoad() {
        super.viewDidLoad()

		var subTitleText = ""
		// Add episode and subtitle
		if program.episode > 0 {
			subTitleText = "\(program.episode) "
		}

		if program.subTitle != "" {
			subTitleText += "\(program.subTitle)"
		}

		titleLabel.text = program.title
		subTitleLabel.text = subTitleText
		channelLabel.text = program.channel!.name
		durationLabel.text = "\(Int(program.duration / 60)) min."
		detailLabel.text = program.detail

		summaryView.sizeToFit()

		// Place play button
		self.playButton = FabButton(frame: CGRect(origin: CGPoint(x: self.view.bounds.width - 16 - 56, y: 180), size: CGSize(width: 56, height: 56))) // TODO: Improvement
		self.playButton.backgroundColor = MaterialColor.red.darken3
		self.playButton.setImage(UIImage(named: "ic_play_arrow_white"), forState: .Normal)
		self.playButton.setImage(UIImage(named: "ic_play_arrow_white"), forState: .Highlighted)
		self.playButton.tintColor = UIColor(white: 0.9, alpha: 0.9)
		self.view.addSubview(self.playButton)


		// Force layout to fit
		self.view.setNeedsLayout()
		self.view.layoutIfNeeded()

		do {
			let request = ChinachuAPI.PreviewImageRequest(id: program.id)
			let urlRequest = try request.buildURLRequest()

			let downloader = KingfisherManager.sharedManager.downloader
			downloader.requestModifier = {
				(request: NSMutableURLRequest) in
				request.setValue(urlRequest.allHTTPHeaderFields?["Authorization"], forHTTPHeaderField: "Authorization")
			}
			previewImageView.kf_setImageWithURL(urlRequest.URL!)

		} catch  {
			print("Failed to load preview image [id: \(program.id).")
		}

		// Setup table view
		self.informationTable.delegate = self
		self.informationTable.dataSource = self

		self.setupTableViewHeight()

		self.informationTable.reloadData()
	}


	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		func generateGradient(size: CGSize) -> UIImage {
			let startColor = UIColor(white: 0, alpha: 0.5).CGColor
			let endColor = UIColor(white: 0, alpha: 0.0).CGColor
			let colors = [startColor, endColor]
			let locations = [0, 0.8] as [CGFloat]
			let space = CGColorSpaceCreateDeviceRGB()
			let gradient = CGGradientCreateWithColors(space, colors, locations)

			UIGraphicsBeginImageContextWithOptions(size, false, 0)
			let context = UIGraphicsGetCurrentContext()
			CGContextDrawLinearGradient(context, gradient, .zero, CGPointMake(0, size.height), [])
			let gradientImage = UIGraphicsGetImageFromCurrentImageContext()
			UIGraphicsEndImageContext()
			return gradientImage
		}

		let portraitImage = generateGradient(CGSize(width: 1, height: 40))
		let landscapeImage = generateGradient(CGSize(width: 1, height: 20))

		// Set navigation bar gradient background
		self.navigationController?.navigationBar.translucent = true
		self.navigationController?.navigationBar.shadowImage = UIImage()
		self.navigationController?.navigationBar.backgroundColor = UIColor.clearColor()
		self.navigationController?.navigationBar.setBackgroundImage(UIImage(CGImage: portraitImage.CGImage!), forBarMetrics: .Default)
		self.navigationController?.navigationBar.setBackgroundImage(UIImage(CGImage: landscapeImage.CGImage!), forBarMetrics: .Compact)
	}


	// MARK: - View deinitialization

	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)

		// Put back original navigation bar style
		self.navigationController?.navigationBar.translucent = false
		self.navigationController?.navigationBar.backgroundColor = MaterialColor.blue.darken1
		self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
		self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Compact)
	}

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}


	// MARK: - View layout

	override func viewWillLayoutSubviews() {
		super.viewWillLayoutSubviews()
	}

	// MARK: - Memory/resource management

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

	// MARK: - Table View height

	func setupTableViewHeight() {
		let cellHeight = self.tableView(self.informationTable, heightForRowAtIndexPath: NSIndexPath(forRow: 0, inSection: 0))
		let cellCount = self.tableView(self.informationTable, numberOfRowsInSection: 0)
		if cellCount == 0 {
			return
		}
		self.informationTable.removeConstraints((self.informationTable.constraints))
		self.informationTable.addConstraint(NSLayoutConstraint(item: self.informationTable, attribute: .Height, relatedBy: .GreaterThanOrEqual, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: cellHeight * CGFloat(cellCount) + 44))
	}


    // MARK: - Table view data source

	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 5
	}

	func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 48
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
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
