//
//  VideoInformationView.swift
//  Harekaze
//
//  Created by Yuki MIZUNO on 2016/07/17.
//  Copyright © 2016年 Yuki MIZUNO. All rights reserved.
//

import UIKit

class VideoInformationView: UIView {

	// MARK: - Interface Builder outlets

	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subTitleLabel: UILabel!
	@IBOutlet weak var channelLabel: UILabel!
	@IBOutlet weak var durationLabel: UILabel!
	@IBOutlet weak var detailLabel: UILabel!
	@IBOutlet weak var titleView: UIView!
	@IBOutlet weak var summaryView: UIView!


	// MARK: - Content size information
	var height: CGFloat {
		get {
			titleView.setNeedsLayout()
			titleView.layoutIfNeeded()
			summaryView.setNeedsLayout()
			summaryView.layoutIfNeeded()
			return titleView.bounds.height + summaryView.bounds.height
		}
	}

	// MARK: - Content setup
	func setup(program: Program) {

		var subTitleText = ""
		// Add episode and subtitle
		if program.episode > 0 {
			subTitleText = "#\(program.episode) "
		}

		if program.subTitle != "" {
			subTitleText += "\(program.subTitle)"
		}

		titleLabel.text = program.title
		subTitleLabel.text = subTitleText
		channelLabel.text = program.channel!.name
		durationLabel.text = "\(Int(program.duration / 60)) min."
		detailLabel.text = program.detail
	}

}
