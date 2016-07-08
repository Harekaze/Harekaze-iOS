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

	// Change navigation icon and label position
	internal override func prepareView() {
		super.prepareView()
		imageView?.translatesAutoresizingMaskIntoConstraints = false
		textLabel?.translatesAutoresizingMaskIntoConstraints = false

		self.addConstraints([
			NSLayoutConstraint(
				item: imageView!,
				attribute: .Top,
				relatedBy: .Equal,
				toItem: self,
				attribute: .Top,
				multiplier: 1.0,
				constant: 12
			),
			// IMPORTANT: Material design guideline: left = 16px
			NSLayoutConstraint(
				item: imageView!,
				attribute: .Left,
				relatedBy: .Equal,
				toItem: self,
				attribute: .Left,
				multiplier: 1.0,
				constant: 16
			),
			NSLayoutConstraint(
				item: imageView!,
				attribute: .Height,
				relatedBy: .Equal,
				toItem: nil,
				attribute: .Height,
				multiplier: 1.0,
				constant: 24
			),
			NSLayoutConstraint(
				item: imageView!,
				attribute: .Width,
				relatedBy: .Equal,
				toItem: nil,
				attribute: .Width,
				multiplier: 1.0,
				constant: 24
			)
			]
		)


		self.addConstraints([
			NSLayoutConstraint(
				item: textLabel!,
				attribute: .Top,
				relatedBy: .Equal,
				toItem: self,
				attribute: .Top,
				multiplier: 1.0,
				constant: 8
			),
			// IMPORTANT: Material design guideline: left = 72px
			NSLayoutConstraint(
				item: textLabel!,
				attribute: .Left,
				relatedBy: .Equal,
				toItem: self,
				attribute: .Left,
				multiplier: 1.0,
				constant: 72
			),
			NSLayoutConstraint(
				item: textLabel!,
				attribute: .Height,
				relatedBy: .Equal,
				toItem: nil,
				attribute: .Height,
				multiplier: 1.0,
				constant: 32
			)
			]
		)

		// Set icon and label color
		textLabel!.textColor = MaterialColor.grey.darken4
		imageView!.tintColor = MaterialColor.grey.darken2

		// Set font
		textLabel!.font = RobotoFont.medium

		// Set background color
		backgroundColor = MaterialColor.clear

	}

}
