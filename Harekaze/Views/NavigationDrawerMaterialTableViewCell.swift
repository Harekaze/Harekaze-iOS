/**
 *
 * NavigationDrawerMaterialTableViewCell.swift
 * Harekaze
 * Created by Yuki MIZUNO on 2016/07/08.
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

class NavigationDrawerMaterialTableViewCell: Material.TableViewCell {

	override func layoutSubviews() {
		super.layoutSubviews()
		imageView?.frame = CGRect(x: 16, y: self.frame.height - 36, width: 24, height: 24)
		textLabel?.frame = CGRect(x: 72, y: self.frame.height - 40, width: self.frame.width - 16, height: 32)
	}

	override func prepare() {
		super.prepare()

		// Change navigation icon and label position

		// IMPORTANT: Material design guideline: left = 16px
		imageView?.frame = CGRect(x: 16, y: self.frame.height - 36, width: 24, height: 24)
		// IMPORTANT: Material design guideline: left = 72px
		textLabel?.frame = CGRect(x: 72, y: self.frame.height - 40, width: self.frame.width - 16, height: 32)

		// Set icon and label color
		textLabel!.textColor = Material.Color.grey.darken4
		imageView!.tintColor = Material.Color.grey.darken2

		// Set font
		textLabel!.font = RobotoFont.medium

		// Set background color
		backgroundColor = Material.Color.clear

		// Set pulse color
		pulseColor = Material.Color.grey.base

	}

}
