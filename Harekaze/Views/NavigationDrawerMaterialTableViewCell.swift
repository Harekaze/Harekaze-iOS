//
//  NavigationDrawerMaterialTableViewCell.swift
//  Harekaze
//
//  Created by Yuki MIZUNO on 2016/07/08.
//  Copyright © 2016年 Yuki MIZUNO. All rights reserved.
//

import UIKit
import Material

class NavigationDrawerMaterialTableViewCell: MaterialTableViewCell {

	override func layoutSubviews() {
		super.layoutSubviews()
		imageView?.frame = CGRect(x: 16, y: self.frame.height - 36, width: 24, height: 24)
		textLabel?.frame = CGRect(x: 72, y: self.frame.height - 40, width: self.frame.width - 16, height: 32)
	}

	internal override func prepareView() {
		super.prepareView()

		// Change navigation icon and label position

		// IMPORTANT: Material design guideline: left = 16px
		imageView?.frame = CGRect(x: 16, y: self.frame.height - 36, width: 24, height: 24)
		// IMPORTANT: Material design guideline: left = 72px
		textLabel?.frame = CGRect(x: 72, y: self.frame.height - 40, width: self.frame.width - 16, height: 32)

		// Set icon and label color
		textLabel!.textColor = MaterialColor.grey.darken4
		imageView!.tintColor = MaterialColor.grey.darken2

		// Set font
		textLabel!.font = RobotoFont.medium

		// Set background color
		backgroundColor = MaterialColor.clear

	}

}
