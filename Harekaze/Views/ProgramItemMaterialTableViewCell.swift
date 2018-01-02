/**
 *
 * ProgramItemMaterialTableViewCell.swift
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
import Material
import APIKit
import RealmSwift

let genreColor: [String: UIColor] = [
	"anime": Material.Color.pink.accent3,
	"information": Material.Color.teal.accent3,
	"news": Material.Color.lightGreen.accent3,
	"sports": Material.Color.cyan.accent3,
	"variety": Material.Color.yellow.accent3,
	"drama": Material.Color.orange.accent3,
	"music": Material.Color.indigo.accent3,
	"cinema": Material.Color.deepPurple.accent3,
	"etc": Material.Color.grey.lighten1
]

class ProgramItemMaterialTableViewCell: Material.TableViewCell {

	// MARK: - Interface Builder outlets

	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var broadcastInfoLabel: UILabel!
	@IBOutlet weak var programDetailLabel: UILabel!
	@IBOutlet weak var durationLabel: UILabel!

	// MARK: - View initialization

	override func awakeFromNib() {
		layoutMargins = UIEdgeInsets.zero
		contentView.backgroundColor = Material.Color.white
		pulseColor = Material.Color.grey.base
	}

	// MARK: - Entity setter
	func setCellEntities(_ program: Program, navigationController: UINavigationController? = nil) {
		titleLabel.text = program.title
		broadcastInfoLabel.text = "\(program.startTime.string())  ―  \(program.channel!.name)"
		durationLabel.text = "\(program.duration.in(.minute)!) min"

		let detail: String
		// Add episode and subtitle
		if program.episode > 0 {
			detail = "#\(program.episode) \(program.subTitle)"
		} else {
			detail = program.detail
		}
		programDetailLabel.text = detail

		let marker = UIView()
		marker.backgroundColor = genreColor[program.genre]
		self.layout(marker).left().top().bottom(0.5).width(2)
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
