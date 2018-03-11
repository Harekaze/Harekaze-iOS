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
	func setCellEntities(_ program: Program) {
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
		programDetailLabel.text = [program.attributedAttributes.joined(), detail].joined(separator: " ")

		categoryLabel.backgroundColor = UIColor(named: program.genre) ?? UIColor.lightGray
		categoryLabel.layer.backgroundColor = UIColor(named: program.genre)?.cgColor ?? UIColor.lightGray.cgColor
		categoryLabel.setNeedsDisplay()
		categoryLabel.layer.setNeedsDisplay()
	}

	func setCellEntities(recording: Recording) {
		self.setCellEntities(recording.program!)
	}

	// MARK: - Cell reuse preparation
	override func prepareForReuse() {
		super.prepareForReuse()

		titleLabel.text = ""
		broadcastInfoLabel.text = ""
		programDetailLabel.text = ""
		durationLabel.text = ""
		categoryLabel.backgroundColor = .clear
		categoryLabel.layer.backgroundColor = UIColor.clear.cgColor
	}
}
