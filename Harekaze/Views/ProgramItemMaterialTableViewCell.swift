//
//  ProgramItemMaterialTableViewCell.swift
//  Harekaze
//
//  Created by Yuki MIZUNO on 2016/07/10.
//  Copyright © 2016年 Yuki MIZUNO. All rights reserved.
//

import UIKit
import Material

class ProgramItemMaterialTableViewCell: MaterialTableViewCell {

	// MARK: - Interface Builder outlets

	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var broadcastInfoLabel: UILabel!
	@IBOutlet weak var programDetailLabel: UILabel!
	@IBOutlet weak var durationLabel: UILabel!

	// MARK: - View initialization

	override func awakeFromNib() {
		layoutMargins = UIEdgeInsetsZero
	}


	// MARK: - Entity setter
	func setCellEntities(program: Program) {
		titleLabel.text = program.title

		// Date formation
		let dateFormatter = NSDateFormatter()
		dateFormatter.dateFormat = "yyyy/MM/dd HH:mm"
		broadcastInfoLabel.text = "\(dateFormatter.stringFromDate(program.startTime))  ―  \(program.channel!.name)"

		durationLabel.text = "\(Int(program.duration / 60)) min"
		programDetailLabel.text = program.detail
	}

}