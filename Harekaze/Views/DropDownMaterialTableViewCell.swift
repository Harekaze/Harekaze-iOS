//
//  DropDownMaterialTableViewCell.swift
//  Harekaze
//
//  Created by Yuki MIZUNO on 2016/07/17.
//  Copyright © 2016年 Yuki MIZUNO. All rights reserved.
//

import UIKit
import Material
import DropDown

class DropDownMaterialTableViewCell: DropDownCell {
	
	// MARK: - Interface Builder outlets

	@IBOutlet weak var pulseView: MaterialPulseView!

	override func awakeFromNib() {
		super.awakeFromNib()
		
		self.bringSubviewToFront(pulseView)
	}

}
