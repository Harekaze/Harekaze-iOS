//
//  TimerItemMaterialTableViewCell.swift
//  Harekaze
//
//  Created by Yuki MIZUNO on 2016/08/02.
//  Copyright © 2016年 Yuki MIZUNO. All rights reserved.
//

import UIKit
import Material

class TimerItemMaterialTableViewCell: ProgramItemMaterialTableViewCell {

	// MARK: - Interface Builder outlets
	@IBOutlet weak var warningImageView: UIImageView!
	@IBOutlet weak var warningImageConstraintWidth: NSLayoutConstraint!
	@IBOutlet weak var recordTypeImageView: UIImageView!


	// MARK: - Entity setter
	override func setCellEntities(program: Program, navigationController: UINavigationController? = nil) {
		super.setCellEntities(program)

		guard let timer = program as? Timer else { return }

		if timer.skip {
			let disabledColor = MaterialColor.darkText.others
			titleLabel.textColor = disabledColor
			broadcastInfoLabel.textColor = disabledColor
			programDetailLabel.textColor = disabledColor
			durationLabel.textColor = disabledColor
			warningImageView.tintColor = disabledColor
			recordTypeImageView.tintColor = disabledColor
		}

		if timer.conflict {
			warningImageView.image = UIImage(named: "ic_warning")?.imageWithRenderingMode(.AlwaysTemplate)
			warningImageConstraintWidth.constant = 24
		} else {
			warningImageView.hidden = true
			warningImageConstraintWidth.constant = 0
		}

		if timer.manual {
			recordTypeImageView.image = UIImage(named: "ic_fiber_manual_record")?.imageWithRenderingMode(.AlwaysTemplate)
		} else {
			recordTypeImageView.image = UIImage(named: "ic_fiber_smart_record")?.imageWithRenderingMode(.AlwaysTemplate)
		}
	}


	// MARK: - Reuse preparation
	override func prepareForReuse() {
		super.prepareForReuse()
		titleLabel.textColor = MaterialColor.darkText.primary
		broadcastInfoLabel.textColor = MaterialColor.darkText.secondary
		programDetailLabel.textColor = MaterialColor.darkText.secondary
		durationLabel.textColor = MaterialColor.darkText.secondary
		warningImageView.tintColor = MaterialColor.red.accent2
		recordTypeImageView.tintColor = MaterialColor.darkText.secondary
	}
}
