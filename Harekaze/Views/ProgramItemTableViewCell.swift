/**
 *
 * ProgramItemTableViewCell.swift
 * Harekaze
 * Created by Yuki MIZUNO on 2016/07/23.
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

let genreColor: [String: UIColor] = [
	"anime": UIColor(red: 245/255, green: 0/255, blue: 87/255, alpha: 1),
	"information": UIColor(red: 29/255, green: 233/255, blue: 182/255, alpha: 1),
	"news": UIColor(red: 118/255, green: 255/255, blue: 3/255, alpha: 1),
	"sports": UIColor(red: 0/255, green: 229/255, blue: 255/255, alpha: 1),
	"variety": UIColor(red: 255/255, green: 234/255, blue: 0/255, alpha: 1),
	"drama": UIColor(red: 255/255, green: 145/255, blue: 0/255, alpha: 1),
	"music": UIColor(red: 61/255, green: 90/255, blue: 254/255, alpha: 1),
	"cinema": UIColor(red: 101/255, green: 31/255, blue: 255/255, alpha: 1),
	"etc": UIColor(red: 66/255, green: 66/255, blue: 66/255, alpha: 1)
]

class ProgramItemTableViewCell: UITableViewCell {

	// MARK: - Interface Builder outlets

	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var broadcastInfoLabel: UILabel!
	@IBOutlet weak var programDetailLabel: UILabel!
	@IBOutlet weak var durationLabel: UILabel!
	@IBOutlet weak var categoryLabel: UILabel!

	// MARK: - View initialization

	override func awakeFromNib() {
		layoutMargins = UIEdgeInsets.zero
		contentView.backgroundColor = UIColor.white
	}

	// MARK: - Entity setter
	func setCellEntities(_ program: Program, navigationController: UINavigationController? = nil) {
		titleLabel.text = program.title
		broadcastInfoLabel.text = "\(program.startTime.string(dateStyle: .short, timeStyle: .short))  ―  \(program.channel!.name)"
		durationLabel.text = "\(program.duration.in(.minute)!) min"
		categoryLabel.text = " \(program.genre) "

		let detail: String
		// Add episode and subtitle
		if program.episode > 0 {
			detail = "#\(program.episode) \(program.subTitle)"
		} else {
			detail = program.detail
		}
		programDetailLabel.text = detail

		categoryLabel.backgroundColor = genreColor[program.genre]
	}

	func setCellEntities(recording: Recording, navigationController: UINavigationController? = nil) {
		self.setCellEntities(recording.program!, navigationController: navigationController)
	}

	// MARK: - Cell reuse preparation
	override func prepareForReuse() {
		super.prepareForReuse()

		titleLabel.text = ""
		broadcastInfoLabel.text = ""
		programDetailLabel.text = ""
		durationLabel.text = ""
	}
}
