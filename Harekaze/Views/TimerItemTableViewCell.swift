/**
 *
 * TimerItemTableViewCell.swift
 * Harekaze
 * Created by Yuki MIZUNO on 2016/08/02.
 * 
 * Copyright (c) 2016-2018, Yuki MIZUNO
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *     and/or other materials provided with the distribution.
 * 
 * 3. Neither the name of the copyright holder nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

import UIKit
import APIKit
import RealmSwift

class TimerItemTableViewCell: ProgramItemTableViewCell {

	// MARK: - Interface Builder outlets
	@IBOutlet weak var warningImageView: UIImageView!
	@IBOutlet weak var warningImageConstraintWidth: NSLayoutConstraint!
	@IBOutlet weak var manualLabel: UILabel!

	// MARK: - Entity setter
	func setCellEntities(timer: Timer) {
		super.setCellEntities(timer.program!)

		if timer.skip {
			titleLabel.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.38)
			broadcastInfoLabel.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.38)
			programDetailLabel.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.38)
			durationLabel.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.38)
			warningImageView.tintColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.38)
		} else {
			titleLabel.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.87)
			broadcastInfoLabel.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.54)
			programDetailLabel.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.54)
			durationLabel.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.54)
			warningImageView.tintColor = #colorLiteral(red: 1.0, green: 0.3215686275, blue: 0.3215686275, alpha: 1.0)
		}

		if timer.conflict {
			warningImageView.isHidden = false
			warningImageConstraintWidth.constant = 24
		} else {
			warningImageView.isHidden = true
			warningImageConstraintWidth.constant = 0
		}

		manualLabel.isHidden = !timer.manual
	}
}
