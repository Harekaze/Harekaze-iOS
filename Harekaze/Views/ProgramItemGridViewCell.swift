/**
*
* ProgramItemGridViewCell.swift
* Harekaze
* Created by Yuki MIZUNO on 2018/01/04.
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
import G3GridView

class ProgramItemGridViewCell: GridViewCell {
	@IBOutlet weak var timeLabel: UILabel!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var detailLabel: UILabel!

	let categoryColor = [
		"anime": UIColor(red: 0.99, green: 0.74, blue: 0.88, alpha: 1.0),
		"information": UIColor(red: 0.74, green: 0.99, blue: 0.91, alpha: 1.0),
		"news": UIColor(red: 0.84, green: 0.99, blue: 0.74, alpha: 1.0),
		"sports": UIColor(red: 0.74, green: 0.95, blue: 0.99, alpha: 1.0),
		"variety": UIColor(red: 0.98, green: 0.99, blue: 0.74, alpha: 1.0),
		"drama": UIColor(red: 0.99, green: 0.88, blue: 0.77, alpha: 1.0),
		"music": UIColor(red: 0.74, green: 0.79, blue: 0.99, alpha: 1.0),
		"cinema": UIColor(red: 0.84, green: 0.74, blue: 0.99, alpha: 1.0),
		"etc": UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 1.0)
	]

	override func awakeFromNib() {
		super.awakeFromNib()
		// Initialization code
		layer.borderColor = UIColor.gray.cgColor
		layer.borderWidth = 1 / UIScreen.main.scale
	}

	func setCellEntities(_ item: Any & ProgramDuration) {
		guard let program = item as? Program else {
			timeLabel.text = ""
			titleLabel.text = ""
			detailLabel.text = ""
			self.layer.backgroundColor = UIColor.gray.cgColor
			return
		}
		timeLabel.text = String(format: "%02d", program.startTime.minute)
		titleLabel.text = program.title
		detailLabel.text = program.detail
		self.layer.backgroundColor = categoryColor[program.genre]?.cgColor ?? UIColor.white.cgColor
	}
}
