//
//  VideoInformationView.swift
//  Harekaze
//
//  Created by Yuki MIZUNO on 2016/07/17.
//  Copyright © 2016年 Yuki MIZUNO. All rights reserved.
//

import UIKit
import Material

class VideoInformationView: UIView {

	// MARK: - Interface Builder outlets

	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var subTitleLabel: UILabel!
	@IBOutlet weak var titleView: UIView!


	// MARK: - Content size information
	var height: CGFloat {
		get {
			titleView.setNeedsLayout()
			titleView.layoutIfNeeded()
			return titleView.bounds.height
		}
	}

	// MARK: - Content setup
	func setup(program: Program) {
		titleView.backgroundColor = MaterialColor.blue.darken2
		var subTitleText = ""
		// Add episode and subtitle
		if program.episode > 0 {
			subTitleText = "#\(program.episode) "
		}

		if program.subTitle != "" {
			subTitleText += program.subTitle
		}

		titleLabel.text = program.title
		subTitleLabel.text = subTitleText
	}

}
